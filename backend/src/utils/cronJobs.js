//Thongchai595-6
const cron = require("node-cron");
const prisma = require("./prisma");
const crypto = require("crypto");

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
                // 1. สร้าง Audit Log ว่าได้ลบจริงแล้ว
                const originalData = req.backupData?.userProfile || {};

                const emailHash = crypto
                    .createHash("sha256")
                    .update(`${req.userId}-${Date.now()}`)
                    .digest("hex")
                    .slice(0, 24);

                const anonymizedUsername = `deleted_${req.userId.slice(-10)}`;
                const anonymizedEmail = `deleted+${emailHash}@deleted.local`;

                await prisma.$transaction(async (tx) => {
                    await tx.deletionAudit.create({
                        data: {
                            originalUserId: req.userId,
                            originalEmail: originalData.email || "unknown",
                            reason: req.reason,
                            status: "COMPLETED",
                            performedBy: "SYSTEM_CRON",
                            backupData: req.backupData
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

                    await tx.deletionRequest.delete({
                        where: { id: req.id },
                    });
                });

                console.log(`Anonymized user ${req.userId}`);

            } catch (error) {
                console.error(`Failed to delete user ${req.userId}:`, error);
            }
        }
    });
};

module.exports = initCronJobs;
