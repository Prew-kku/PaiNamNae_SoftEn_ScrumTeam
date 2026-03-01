//Thongchai595-6
const cron = require("node-cron");
const prisma = require("./prisma");
const crypto = require("crypto");
const { deleteFromCloudinary } = require("./cloudinary");

const REDACTED_LOCATION = { redacted: true, scope: "PDPA_RETENTION_90D" };

const getCloudinaryPublicIdFromUrl = (urlString) => {
    if (!urlString || typeof urlString !== "string") return null;

    try {
        const url = new URL(urlString);
        const marker = "/upload/";
        const uploadIndex = url.pathname.indexOf(marker);
        if (uploadIndex === -1) return null;

        let publicPath = url.pathname.slice(uploadIndex + marker.length);
        publicPath = publicPath.replace(/^v\d+\//, "");
        publicPath = publicPath.replace(/\.[^/.]+$/, "");
        publicPath = decodeURIComponent(publicPath);

        return publicPath || null;
    } catch (error) {
        return null;
    }
};

const createDeletionAuditRef = (userId, requestId) => {
    const secret = process.env.DELETION_AUDIT_HASH_SECRET || "deletion-audit-default-pepper";
    return crypto
        .createHmac("sha256", secret)
        .update(`${userId}:${requestId}`)
        .digest("hex")
        .slice(0, 32);
};

const initCronJobs = () => {
    // รันทุกเที่ยงคืน (00:00)
    cron.schedule("0 0 * * *", async () => {
        console.log("Running User Deletion Cleanup Job...");

        const now = new Date();

        // หาเคสที่อนุมัติแล้ว และครบกำหนด 90 วัน
        const expiredRequests = await prisma.deletionRequest.findMany({
            where: {
                status: "APPROVED",
                scheduledDeleteAt: {
                    lte: now,
                },
            },
        });

        for (const req of expiredRequests) {
            try {
                // 1. เตรียม anonymized identity แบบไม่สามารถระบุตัวตนเดิมได้
                const user = await prisma.user.findUnique({
                    where: { id: req.userId },
                    select: {
                        profilePicture: true,
                        nationalIdPhotoUrl: true,
                        selfiePhotoUrl: true,
                    },
                });

                const driverVerifications = await prisma.driverVerification.findMany({
                    where: { userId: req.userId },
                    select: {
                        licensePhotoUrl: true,
                        selfiePhotoUrl: true,
                    },
                });

                const emailHash = crypto
                    .createHash("sha256")
                    .update(`${req.userId}-${Date.now()}`)
                    .digest("hex")
                    .slice(0, 24);

                const anonymizedUsername = `deleted_${emailHash.slice(0, 12)}`;
                const anonymizedEmail = `deleted+${emailHash}@deleted.local`;

                const cloudinaryUrls = [
                    user?.profilePicture,
                    user?.nationalIdPhotoUrl,
                    user?.selfiePhotoUrl,
                    ...driverVerifications.flatMap((item) => [item.licensePhotoUrl, item.selfiePhotoUrl]),
                ].filter(Boolean);

                const cloudinaryPublicIds = [...new Set(cloudinaryUrls.map(getCloudinaryPublicIdFromUrl).filter(Boolean))];

                await prisma.$transaction(async (tx) => {
                    const redactedDriverRoutes = await tx.route.updateMany({
                        where: { driverId: req.userId },
                        data: {
                            startLocation: REDACTED_LOCATION,
                            endLocation: REDACTED_LOCATION,
                            conditions: null,
                            routePolyline: null,
                            distanceMeters: null,
                            durationSeconds: null,
                            routeSummary: null,
                            distance: null,
                            duration: null,
                            waypoints: null,
                            landmarks: null,
                            steps: null,
                        },
                    });

                    const redactedPassengerBookings = await tx.booking.updateMany({
                        where: { passengerId: req.userId },
                        data: {
                            pickupLocation: REDACTED_LOCATION,
                            dropoffLocation: REDACTED_LOCATION,
                            cancelReason: null,
                        },
                    });

                    const redactedBookingsOnOwnedRoutes = await tx.booking.updateMany({
                        where: {
                            route: {
                                driverId: req.userId,
                            },
                        },
                        data: {
                            pickupLocation: REDACTED_LOCATION,
                            dropoffLocation: REDACTED_LOCATION,
                        },
                    });

                    await tx.deletionAudit.create({
                        data: {
                            requestId: req.id,
                            originalUserId: createDeletionAuditRef(req.userId, req.id),
                            originalEmail: null,
                            reason: req.reason,
                            status: "ANONYMIZED",
                            performedBy: "SYSTEM_CRON",
                            backupData: {
                                evidenceType: "IRREVERSIBLE_ANONYMIZATION",
                                retentionDays: 90,
                                cloudinaryAssetCount: cloudinaryPublicIds.length,
                                routeRedactedCount: redactedDriverRoutes.count,
                                bookingPassengerRedactedCount: redactedPassengerBookings.count,
                                bookingRouteRedactedCount: redactedBookingsOnOwnedRoutes.count,
                                containsPersonalData: false,
                            }
                        }
                    });

                    await tx.driverVerification.deleteMany({
                        where: { userId: req.userId },
                    });

                    await tx.user.update({
                        where: { id: req.userId },
                        data: {
                            username: anonymizedUsername,
                            email: anonymizedEmail,
                            firstName: "Deleted",
                            lastName: "User",
                            gender: null,
                            phoneNumber: null,
                            profilePicture: null,
                            nationalIdNumber: null,
                            nationalIdPhotoUrl: null,
                            nationalIdExpiryDate: null,
                            selfiePhotoUrl: null,
                            otpCode: null,
                            isActive: false,
                            deletionPending: false,
                        },
                    });

                    await tx.deletionRequest.update({
                        where: { id: req.id },
                        data: {
                            status: "DELETED",
                            scheduledDeleteAt: now,
                        },
                    });

                    await tx.deletionAudit.create({
                        data: {
                            requestId: req.id,
                            originalUserId: createDeletionAuditRef(req.userId, req.id),
                            originalEmail: null,
                            reason: req.reason,
                            status: "DELETED",
                            performedBy: "SYSTEM_CRON",
                            backupData: {
                                containsPersonalData: false,
                            },
                        }
                    });
                });

                for (const publicId of cloudinaryPublicIds) {
                    try {
                        await deleteFromCloudinary(publicId);
                    } catch (error) {
                        console.error(`Failed to delete Cloudinary asset ${publicId}:`, error.message);
                    }
                }

                console.log(`Anonymized user ${req.userId}`);

            } catch (error) {
                console.error(`Failed to delete user ${req.userId}:`, error);
            }
        }
    });
};

module.exports = initCronJobs;
