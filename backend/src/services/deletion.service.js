// Thongchai595-6
const prisma = require("../utils/prisma");
const bcrypt = require("bcrypt");
const ApiError = require("../utils/ApiError");

const ACTIVE_BOOKING_STATUSES = ["PENDING", "CONFIRMED"];
const getGracePeriodDays = () => {
    const days = Number(process.env.ACCOUNT_DELETION_GRACE_DAYS || 30);
    if (Number.isNaN(days)) return 30;
    return Math.min(30, Math.max(7, days));
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

    // 3. ตรวจสอบคำขอค้าง (Prevent Double Request)
    const existingRequest = await prisma.deletionRequest.findFirst({
        where: {
            userId,
            status: "PENDING",
        },
    });

    if (existingRequest) throw new ApiError(400, "Deletion request already pending");

    // 4. ดำเนินการ Suspend User และสร้าง Request
    // ใช้ Transaction เพื่อความถูกต้องของข้อมูล
    await prisma.$transaction(async (tx) => {
        // ตั้ง isActive = false (Login ไม่ได้, สมัครใหม่ด้วย Email เดิมไม่ได้เพราะติด Unique Constraint)
        await tx.user.update({
            where: { id: userId },
            data: {
                isActive: false,
                deletionPending: true,
            }
        });

        // สร้าง DeletionRequest สถานะ PENDING
        await tx.deletionRequest.create({
            data: {
                userId,
                reason,
                status: "PENDING",
                approvedAt: null,
                scheduledDeleteAt: null,
                // backupData
                backupData: {
                    initiatedAt: new Date(),
                    note: "Waiting for admin approval to perform full backup"
                }
            }
        });
    });

    return {
        message: "Deletion requested. Account deactivated immediately.",
        status: "PENDING",
        gracePeriodDays: getGracePeriodDays(),
    };
};

const cancelDeletionByUser = async (userId) => {
    const request = await prisma.deletionRequest.findFirst({
        where: {
            userId,
            status: "PENDING",
        },
    });

    if (!request) throw new ApiError(404, "No pending deletion request found");

    await prisma.$transaction(async (tx) => {
        await tx.user.update({
            where: { id: userId },
            data: {
                isActive: true,
                deletionPending: false,
            },
        });

        await tx.deletionRequest.delete({
            where: { id: request.id },
        });
    });

    return { message: "Deletion request cancelled. Account reactivated." };
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
            username: true,
            email: true,
            role: true,
            createdAt: true,
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

    await prisma.deletionRequest.update({
        where: { id: requestId },
        data: {
            status: "APPROVED",
            approvedAt,
            scheduledDeleteAt,
            backupData: {
                ...existingBackupData,
                userProfile: {
                    id: user.id,
                    username: user.username,
                    email: user.email,
                    role: user.role,
                    createdAt: user.createdAt,
                },
                precheck: summary,
            },
        },
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
        // เปิดใช้งานให้ User อีกครั้ง
        await tx.user.update({
            where: { id: request.userId },
            data: {
                isActive: true,
                deletionPending: false,
            }
        });

        // ลบคำขอทิ้ง
        await tx.deletionRequest.delete({
            where: { id: requestId }
        });
    });

    return { message: "Deletion request rejected. Account reactivated." };
};

module.exports = {
    requestDeletion,
    cancelDeletionByUser,
    getAllDeletionRequests,
    approveDeletion,
    rejectDeletion,
};
