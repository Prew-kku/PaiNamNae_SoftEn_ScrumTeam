// Thongchai595-6
const prisma = require("../utils/prisma");
const bcrypt = require("bcrypt");
const ApiError = require("../utils/ApiError");

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
            containsPersonalData: false,
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
                    containsPersonalData: false,
                    note: "Minimal retention metadata only"
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
                    containsPersonalData: false,
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

const getAllDeletionRequests = async () => {
    return await prisma.deletionRequest.findMany({
        orderBy: { requestedAt: "desc" },
        include: {
            user: { select: { id: true, email: true, username: true, role: true } }
        }
    });
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

const rejectDeletion = async (requestId) => {
    const request = await prisma.deletionRequest.findUnique({
        where: { id: requestId }
    });

    if (!request) throw new ApiError(404, "Request not found");

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
                reason: request.reason,
                status: "REJECTED",
                performedBy: "ADMIN",
                backupData: {
                    containsPersonalData: false,
                },
            },
        });
    });

    return { message: "Deletion request rejected and retained for audit. Account reactivated." };
};

module.exports = {
    requestDeletion,
    cancelDeletionByUser,
    getAllDeletionRequests,
    approveDeletion,
    rejectDeletion,
};
