// Thongchai595-6
const prisma = require("../utils/prisma");
const bcrypt = require("bcrypt");
const ApiError = require("../utils/ApiError");

const requestDeletion = async (userId, password, reason) => {
    // 1. ตรวจสอบ User
    const user = await prisma.user.findUnique({
        where: { id: userId }
    });

    if (!user) throw new ApiError(404, "User not found");

    // 2. ตรวจสอบ Password
    const isPasswordCorrect = await bcrypt.compare(password, user.password);
    if (!isPasswordCorrect) throw new ApiError(401, "Incorrect password");

    // 3. ตรวจสอบคำขอค้าง (Prevent Double Request)
    const existingRequest = await prisma.deletionRequest.findUnique({
        where: { userId },
    });

    if (existingRequest) throw new ApiError(400, "Deletion request already pending");

    // 4. ดำเนินการ Suspend User และสร้าง Request
    // ใช้ Transaction เพื่อความถูกต้องของข้อมูล
    await prisma.$transaction(async (tx) => {
        // ตั้ง isActive = false (Login ไม่ได้, สมัครใหม่ด้วย Email เดิมไม่ได้เพราะติด Unique Constraint)
        await tx.user.update({
            where: { id: userId },
            data: { isActive: false }
        });

        // สร้าง DeletionRequest สถานะ PENDING
        await tx.deletionRequest.create({
            data: {
                userId,
                reason,
                status: "PENDING",
                // backupData
                backupData: {
                    initiatedAt: new Date(),
                    note: "Waiting for admin approval to perform full backup"
                }
            }
        });
    });

    return { message: "Deletion requested. Account suspended. Waiting for admin approval." };
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

    const userId = request.userId;

    // 1. โหลดข้อมูลทั้งหมดเพื่อทำ Backup
    const user = await prisma.user.findUnique({
        where: { id: userId },
        include: {
            vehicles: true,
            bookings: true,
            createdRoutes: true,
            driverVerification: true,
        },
    });

    if (!user) {
        // กรณีไม่เจอ User (อาจจะถูกลบไปแล้ว) ให้เคลียร์ Request ทิ้ง
        await prisma.deletionRequest.delete({ where: { id: requestId } });
        throw new ApiError(404, "User not found");
    }

    // เตรียมข้อมูล Backup (Anonymized ในระดับ Audit Log ได้ถ้าต้องการ หรือเก็บ Raw ไว้เป็นหลักฐาน)
    const backupData = {
        userProfile: {
            id: user.id,
            username: user.username,
            email: user.email,
            role: user.role,
            createdAt: user.createdAt,
        },
        data: {
            vehicles: user.vehicles,
            bookings: user.bookings,
            routes: user.createdRoutes,
            verification: user.driverVerification
        }
    };

    // 2. & 3. Transaction: สร้าง Audit Log และ Hard Delete User
    await prisma.$transaction(async (tx) => {
        // สร้าง Audit Log
        await tx.deletionAudit.create({
            data: {
                originalUserId: user.id,
                originalEmail: user.email,
                reason: request.reason,
                status: "COMPLETED",
                performedBy: "ADMIN",
                backupData: backupData
            }
        });

        // HARD DELETE User
        await tx.user.delete({
            where: { id: userId }
        });
    });

    return { message: "User hard deleted and audit log created." };
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
            data: { isActive: true }
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
    getAllDeletionRequests,
    approveDeletion,
    rejectDeletion,
};
