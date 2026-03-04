// Thongchai595-6
const prisma = require("../utils/prisma");
const bcrypt = require("bcrypt");
const ApiError = require("../utils/ApiError");
const emailService = require("./email.service");

const ACTIVE_BOOKING_STATUSES = ["PENDING", "CONFIRMED"];
const DELETION_GRACE_DAYS = 90;
const getGracePeriodDays = () => {
    return DELETION_GRACE_DAYS;
};

const addDays = (date, days) => {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
};

const getApprovalBlockers = async (userId) => {
    const [activePassengerBookings, activeDriverBookings] = await Promise.all([
        prisma.booking.count({
            where: {
                passengerId: userId,
                status: { in: ACTIVE_BOOKING_STATUSES },
            },
        }),
        prisma.booking.count({
            where: {
                route: { driverId: userId },
                status: { in: ACTIVE_BOOKING_STATUSES },
            },
        }),
    ]);

    const blockers = [];
    if (activePassengerBookings > 0 || activeDriverBookings > 0) {
        blockers.push("มี booking ที่ยังไม่สิ้นสุด");
    }

    return {
        blockers,
        summary: {
            activePassengerBookings,
            activeDriverBookings,
        },
    };
};

const buildAuditUserRef = (userId) => `user_${userId}`;

const requestDeletion = async (userId, password, reason) => {
    // 1. ตรวจสอบ User
    const user = await prisma.user.findUnique({
        where: { id: userId }
    });

    if (!user) throw new ApiError(404, "User not found");

    // 2. ตรวจสอบ Password
    if (!password) throw new ApiError(400, "Password is required");
    if (!reason || !String(reason).trim()) throw new ApiError(400, "Reason is required");

    const isPasswordCorrect = await bcrypt.compare(password, user.password);
    if (!isPasswordCorrect) throw new ApiError(401, "Incorrect password");

    // 3. ตรวจสอบคำขอที่ยัง active (รองรับการเก็บประวัติหลายแถว)
    const existingRequest = await prisma.deletionRequest.findFirst({
        where: {
            userId,
            status: { in: ["PENDING", "APPROVED"] },
        },
        orderBy: { requestedAt: "desc" },
    });

    if (existingRequest?.status === "PENDING") {
        throw new ApiError(400, "Deletion request already pending");
    }

    if (existingRequest?.status === "APPROVED") {
        throw new ApiError(400, "Deletion request already approved");
    }

    // 4. ดำเนินการ Suspend User และสร้าง Request
    // ใช้ Transaction เพื่อความถูกต้องของข้อมูล
    await prisma.$transaction(async (tx) => {
        const requestedAt = new Date();

        const driverRoutes = await tx.route.findMany({
            where: { driverId: userId },
            select: {
                id: true,
                driverId: true,
                vehicleId: true,
                departureTime: true,
                status: true,
                cancelledAt: true,
                cancelledBy: true,
                availableSeats: true,
                pricePerSeat: true,
                startLocation: true,
                endLocation: true,
                routePolyline: true,
                distanceMeters: true,
                durationSeconds: true,
                routeSummary: true,
                distance: true,
                duration: true,
                waypoints: true,
                landmarks: true,
                steps: true,
                createdAt: true,
                updatedAt: true,
                bookings: {
                    select: {
                        id: true,
                        passengerId: true,
                        numberOfSeats: true,
                        status: true,
                        cancelledAt: true,
                        cancelledBy: true,
                        cancelReason: true,
                        pickupLocation: true,
                        dropoffLocation: true,
                        createdAt: true,
                    },
                    orderBy: { createdAt: "desc" },
                },
            },
            orderBy: { departureTime: "desc" },
        });

        const passengerBookings = await tx.booking.findMany({
            where: { passengerId: userId },
            select: {
                id: true,
                routeId: true,
                passengerId: true,
                numberOfSeats: true,
                status: true,
                cancelledAt: true,
                cancelledBy: true,
                cancelReason: true,
                pickupLocation: true,
                dropoffLocation: true,
                createdAt: true,
                route: {
                    select: {
                        id: true,
                        driverId: true,
                        vehicleId: true,
                        departureTime: true,
                        status: true,
                        cancelledAt: true,
                        cancelledBy: true,
                        availableSeats: true,
                        pricePerSeat: true,
                        startLocation: true,
                        endLocation: true,
                        routePolyline: true,
                        distanceMeters: true,
                        durationSeconds: true,
                        routeSummary: true,
                        distance: true,
                        duration: true,
                        waypoints: true,
                        landmarks: true,
                        steps: true,
                        createdAt: true,
                        updatedAt: true,
                    },
                },
            },
            orderBy: { createdAt: "desc" },
        });

        const passengerBookingTransition = await tx.booking.groupBy({
            by: ["status"],
            where: { passengerId: userId },
            _count: { _all: true },
        });

        const driverRouteTransition = await tx.route.groupBy({
            by: ["status"],
            where: { driverId: userId },
            _count: { _all: true },
            _sum: { availableSeats: true },
        });

        const passengerBookingDeleteResult = await tx.booking.deleteMany({
            where: { passengerId: userId },
        });

        const driverRouteDeleteResult = await tx.route.deleteMany({
            where: { driverId: userId },
        });

        const transitionSummary = {
            bookingByStatus: passengerBookingTransition.map((item) => ({
                status: item.status,
                count: item._count?._all || 0,
            })),
            routeByStatus: driverRouteTransition.map((item) => ({
                status: item.status,
                count: item._count?._all || 0,
                totalAvailableSeats: item._sum?.availableSeats || 0,
            })),
            deletedAtRequestTime: {
                passengerBookingCount: passengerBookingDeleteResult.count,
                driverRouteCount: driverRouteDeleteResult.count,
            },
            travelRouteSnapshotSummary: {
                driverRouteCount: driverRoutes.length,
                passengerBookingCount: passengerBookings.length,
            },
            containsPersonalData: true,
        };

        // ตั้ง isActive = false (Login ไม่ได้, สมัครใหม่ด้วย Email เดิมไม่ได้เพราะติด Unique Constraint)
        await tx.user.update({
            where: { id: userId },
            data: {
                isActive: false,
                deletionPending: true,
            }
        });

        // สร้าง DeletionRequest เป็นแถวใหม่ทุกครั้ง เพื่อเก็บประวัติย้อนหลัง
        const deletionRequest = await tx.deletionRequest.create({
            data: {
                userId,
                reason,
                status: "PENDING",
                approvedAt: null,
                scheduledDeleteAt: null,
                backupData: {
                    initiatedAt: requestedAt,
                    transitionSummary,
                    travelRouteSnapshot: {
                        driverRoutes,
                        passengerBookings,
                    },
                    containsPersonalData: true,
                    note: "Retention metadata and travel route snapshot"
                }
            }
        });

        await tx.deletionAudit.create({
            data: {
                requestId: deletionRequest.id,
                originalUserId: buildAuditUserRef(userId),
                originalEmail: null,
                eventTime: requestedAt,
                reason,
                status: "REQUESTED",
                performedBy: "USER",
                backupData: {
                    transitionSummary,
                    travelRouteSnapshot: {
                        driverRouteCount: driverRoutes.length,
                        passengerBookingCount: passengerBookings.length,
                    },
                    containsPersonalData: true,
                },
            },
        });
    });

    return {
        message: "Deletion requested. Account deactivated immediately.",
        status: "PENDING",
        gracePeriodDays: getGracePeriodDays(),
    };
};

const cancelDeletionByUser = async (userId) => {
    const now = new Date();
    const request = await prisma.deletionRequest.findFirst({
        where: {
            userId,
            status: { in: ["PENDING", "APPROVED"] },
        },
        orderBy: { requestedAt: "desc" },
    });

    if (!request || !["PENDING", "APPROVED"].includes(request.status)) {
        throw new ApiError(404, "No cancellable deletion request found");
    }

    if (request.status === "APPROVED") {
        if (!request.scheduledDeleteAt || request.scheduledDeleteAt <= now) {
            throw new ApiError(400, "Cannot cancel deletion after retention period has ended");
        }
    }

    await prisma.$transaction(async (tx) => {
        await tx.user.update({
            where: { id: userId },
            data: {
                isActive: true,
                deletionPending: false,
            },
        });

        const existingBackupData = request.backupData && typeof request.backupData === "object"
            ? request.backupData
            : {};

        await tx.deletionRequest.update({
            where: { id: request.id },
            data: {
                status: "CANCELLED",
                backupData: {
                    ...existingBackupData,
                    cancellation: {
                        cancelledAt: now,
                        cancelledBy: "USER",
                        previousStatus: request.status,
                        containsPersonalData: false,
                    },
                },
            },
        });

        await tx.deletionAudit.create({
            data: {
                requestId: request.id,
                originalUserId: buildAuditUserRef(userId),
                originalEmail: null,
                eventTime: now,
                reason: request.reason,
                status: "CANCELLED",
                performedBy: "USER",
                backupData: {
                    previousStatus: request.status,
                    containsPersonalData: false,
                },
            },
        });
    });

    return {
        message: "Deletion request cancelled. Account reactivated.",
        cancelledStatus: request.status,
    };
};

const getAllDeletionRequests = async (query = {}) => {
    const {
        page = 1,
        limit = 20,
        status = "",
        role = "",
        q = "",
        type = "",
    } = query;

    if (type && String(type).toLowerCase() !== "deletion") {
        return {
            data: [],
            pagination: {
                page: Number(page),
                limit: Number(limit),
                total: 0,
                totalPages: 1,
            },
        };
    }

    const allowedStatuses = ["PENDING", "APPROVED", "REJECTED", "CANCELLED", "DELETED"];
    const normalizedStatus = String(status || "").toUpperCase();

    const where = {
        ...(normalizedStatus && allowedStatuses.includes(normalizedStatus)
            ? { status: normalizedStatus }
            : {}),
        ...(role ? { user: { role: String(role).toUpperCase() } } : {}),
        ...(q
            ? {
                user: {
                    ...(role ? { role: String(role).toUpperCase() } : {}),
                    OR: [
                        { email: { contains: q, mode: "insensitive" } },
                        { username: { contains: q, mode: "insensitive" } },
                        { firstName: { contains: q, mode: "insensitive" } },
                        { lastName: { contains: q, mode: "insensitive" } },
                    ],
                },
            }
            : {}),
    };

    const safeLimit = Math.max(1, Number(limit) || 20);
    const safePage = Math.max(1, Number(page) || 1);
    const skip = (safePage - 1) * safeLimit;

    const [total, requests] = await Promise.all([
        prisma.deletionRequest.count({ where }),
        prisma.deletionRequest.findMany({
            where,
            orderBy: { requestedAt: "desc" },
            skip,
            take: safeLimit,
            include: {
                user: {
                    select: {
                        id: true,
                        email: true,
                        username: true,
                        role: true,
                        firstName: true,
                        lastName: true,
                        profilePicture: true,
                    },
                },
            },
        }),
    ]);

    return {
        data: requests,
        pagination: {
            page: safePage,
            limit: safeLimit,
            total,
            totalPages: Math.max(1, Math.ceil(total / safeLimit)),
        },
    };
};

const getDeletionRequestById = async (requestId) => {
    const request = await prisma.deletionRequest.findUnique({
        where: { id: requestId },
        include: {
            user: {
                select: {
                    id: true,
                    email: true,
                    username: true,
                    role: true,
                    firstName: true,
                    lastName: true,
                    profilePicture: true,
                },
            },
            audits: {
                orderBy: { eventTime: "desc" },
            },
        },
    });

    if (!request) throw new ApiError(404, "Request not found");
    return request;
};


const approveDeletion = async (requestId) => {
    const request = await prisma.deletionRequest.findUnique({
        where: { id: requestId }
    });

    if (!request) throw new ApiError(404, "Request not found");

    if (request.status !== "PENDING") {
        throw new ApiError(400, "Only pending deletion request can be approved");
    }

    const userId = request.userId;

    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
            id: true,
            role: true,
        },
    });

    if (!user) throw new ApiError(404, "User not found");

    const { blockers, summary } = await getApprovalBlockers(userId);
    if (blockers.length > 0) {
        throw new ApiError(409, `Cannot approve deletion: ${blockers.join(", ")}`);
    }

    const approvedAt = new Date();
    const gracePeriodDays = getGracePeriodDays();
    const scheduledDeleteAt = addDays(approvedAt, gracePeriodDays);

    const existingBackupData = request.backupData && typeof request.backupData === "object"
        ? request.backupData
        : {};

    await prisma.$transaction(async (tx) => {
        await tx.deletionRequest.update({
            where: { id: requestId },
            data: {
                status: "APPROVED",
                approvedAt,
                scheduledDeleteAt,
                backupData: {
                    ...existingBackupData,
                    approvedContext: {
                        role: user.role,
                        approvedBy: "ADMIN",
                        gracePeriodDays,
                        containsPersonalData: false,
                    },
                    precheck: summary,
                },
            },
        });

        await tx.deletionAudit.create({
            data: {
                requestId,
                originalUserId: buildAuditUserRef(userId),
                originalEmail: null,
                eventTime: approvedAt,
                reason: request.reason,
                status: "APPROVED",
                performedBy: "ADMIN",
                backupData: {
                    gracePeriodDays,
                    scheduledDeleteAt,
                    containsPersonalData: false,
                },
            },
        });
    });

    return {
        message: "Deletion request approved and scheduled for anonymization.",
        approvedAt,
        scheduledDeleteAt,
        gracePeriodDays,
    };
};

const rejectDeletion = async (requestId, adminReason) => {
    const request = await prisma.deletionRequest.findUnique({
        where: { id: requestId },
        include: {
            user: {
                select: {
                    id: true,
                    email: true,
                    username: true,
                },
            },
        },
    });

    if (!request) throw new ApiError(404, "Request not found");

    const normalizedAdminReason = String(adminReason || "").trim();

    await prisma.$transaction(async (tx) => {
        const rejectedAt = new Date();
        // เปิดใช้งานให้ User อีกครั้ง
        await tx.user.update({
            where: { id: request.userId },
            data: {
                isActive: true,
                deletionPending: false,
            }
        });

        const existingBackupData = request.backupData && typeof request.backupData === "object"
            ? request.backupData
            : {};

        await tx.deletionRequest.update({
            where: { id: requestId },
            data: {
                status: "REJECTED",
                backupData: {
                    ...existingBackupData,
                    rejection: {
                        rejectedAt,
                        rejectedBy: "ADMIN",
                        adminReason: normalizedAdminReason || null,
                        containsPersonalData: false,
                    },
                },
            },
        });

        await tx.deletionAudit.create({
            data: {
                requestId,
                originalUserId: buildAuditUserRef(request.userId),
                originalEmail: null,
                eventTime: rejectedAt,
                reason: normalizedAdminReason || request.reason,
                status: "REJECTED",
                performedBy: "ADMIN",
                backupData: {
                    adminReason: normalizedAdminReason || null,
                    containsPersonalData: false,
                },
            },
        });
    });

    if (request.user?.email) {
        const reasonText = normalizedAdminReason || "คำขอยังไม่ผ่านเงื่อนไขที่กำหนด";
        const subject = "แจ้งผลคำขอลบบัญชี: ไม่อนุมัติ";
        const html = `
            <div style="font-family: sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #d9534f;">แจ้งผลคำขอลบบัญชี</h2>
                <p>สวัสดีคุณ <strong>${request.user.username || "ผู้ใช้งาน"}</strong>,</p>
                <p>คำขอลบบัญชีของคุณในระบบ <strong>Pai Nam Nae</strong> ถูกปฏิเสธโดยผู้ดูแลระบบ</p>
                <div style="background: #fdfdfd; padding: 15px; border-left: 4px solid #d9534f; margin: 20px 0;">
                    <p style="margin: 0;"><strong>เหตุผล:</strong> ${reasonText}</p>
                </div>
                <p>บัญชีของคุณถูกเปิดใช้งานกลับแล้ว สามารถเข้าสู่ระบบได้ตามปกติ</p>
                <hr style="border: none; border-top: 1px solid #eee;">
                <p style="font-size: 11px; color: #999; text-align: center;">© 2026 Pai Nam Nae Security System. This is an automated notification.</p>
            </div>
        `;

        await emailService.sendEmail(request.user.email, subject, html);
    }

    return { message: "Deletion request rejected and retained for audit. Account reactivated." };
};

module.exports = {
    requestDeletion,
    cancelDeletionByUser,
    getAllDeletionRequests,
    getDeletionRequestById,
    approveDeletion,
    rejectDeletion,
};
