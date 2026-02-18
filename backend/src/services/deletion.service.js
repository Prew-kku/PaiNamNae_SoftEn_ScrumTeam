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

const getAllDeletionRequests = async (filters = {}) => {
    const { status, role, type, search } = filters;

    const where = {};

    if (status) {
        // Support comma-separated status
        const statuses = status.split(',').map(s => s.toUpperCase());
        where.status = { in: statuses };
    }

    if (role) {
        where.user = { role: role.toUpperCase() };
    }

    // DeletionRequest is strictly 'deletion', but if we had other types field, we would filter.
    // Assuming 'type' filter from frontend corresponds to DeletionRequest (which is one type). 
    // If frontend sends type='incident', this service should probably return empty or ignore if strictly deletion service.

    if (search) {
        where.OR = [
            { user: { username: { contains: search, mode: 'insensitive' } } },
            { user: { email: { contains: search, mode: 'insensitive' } } },
            { user: { firstName: { contains: search, mode: 'insensitive' } } },
            { user: { lastName: { contains: search, mode: 'insensitive' } } }
        ];
    }

    return await prisma.deletionRequest.findMany({
        where,
        orderBy: { requestedAt: "desc" },
        include: {
            user: { select: { id: true, email: true, username: true, role: true, firstName: true, lastName: true, profilePicture: true } }
        }
    });
};


const emailService = require("../services/email.service"); // Import email service

const approveDeletion = async (requestId) => {
    const request = await prisma.deletionRequest.findUnique({
        where: { id: requestId },
        include: { user: true }
    });

    if (!request) throw new ApiError(404, "Request not found");

    const userId = request.userId;
    const user = request.user;

    if (!user) {
        // กรณีไม่เจอ User (อาจจะถูกลบไปแล้ว) ให้เคลียร์ Request ทิ้ง
        await prisma.deletionRequest.delete({ where: { id: requestId } });
        throw new ApiError(404, "User not found");
    }

    // คำนวณวันที่จะ Hard Delete (90 วันจากนี้)
    const scheduledDate = new Date();
    scheduledDate.setDate(scheduledDate.getDate() + 90);

    // อัปเดตสถานะ Request และกำหนดวันลบ
    const updatedRequest = await prisma.deletionRequest.update({
        where: { id: requestId },
        data: {
            status: "APPROVED",
            approvedAt: new Date(),
            scheduledDeleteAt: scheduledDate
        }
    });

    // ส่งอีเมลแจ้งเตือน User
    try {
        await emailService.sendEmail(
            user.email,
            "คำขอลบบัญชีของคุณได้รับการอนุมัติ",
            `คำขอของคุณได้รับการอนุมัติแล้ว บัญชีของคุณจะถูกลบถาวรในวันที่ ${scheduledDate.toLocaleDateString('th-TH')} หากคุณเปลี่ยนใจ กรุณาติดต่อเราก่อนวันดังกล่าว`
        );
    } catch (error) {
        console.error("Failed to send approval email:", error);
    }

    return {
        message: "Request approved. Account scheduled for deletion in 90 days.",
        data: updatedRequest
    };
};

const rejectDeletion = async (requestId, adminReason) => {
    const request = await prisma.deletionRequest.findUnique({
        where: { id: requestId },
        include: { user: true }
    });

    if (!request) throw new ApiError(404, "Request not found");

    await prisma.$transaction(async (tx) => {
        // เปิดใช้งานให้ User อีกครั้ง
        await tx.user.update({
            where: { id: request.userId },
            data: { isActive: true }
        });

        // อัปเดตสถานะเป็น REJECTED (แทนการลบทิ้ง เพื่อเก็บประวัติ) หรือลบทิ้งตาม Business Logic
        // แต่ User บอกว่า "Admin ติกเครื่องหมายกากะบาด ... แจ้งไปที่ email"
        // การเก็บ History ดีกว่า
        await tx.deletionRequest.update({
            where: { id: requestId },
            data: {
                status: "REJECTED",
                // ถ้ามี field เก็บเหตุผลการปฏิเสธใน Schema ก็ใส่ได้ (ใน Schema ปัจจุบันไม่มี adminNote ชัดเจน อาจต้องใช้ reason เดิมหรือเพิ่ม field)
                // แต่ Schema มีแค่ reason (ของ user).
                // เราจะส่งผลทางอีเมลเป็นหลัก
            }
        });
    });

    // ส่งอีเมลแจ้งเตือน User
    try {
        await emailService.sendEmail(
            request.user.email,
            "คำขอลบบัญชีของคุณถูกปฏิเสธ",
            `คำขอของคุณถูกปฏิเสธโดยแอดมิน\nเหตุผล: ${adminReason || 'ไม่ระบุ'}\nบัญชีของคุณกลับมาใช้งานได้ตามปกติ`
        );
    } catch (error) {
        console.error("Failed to send rejection email:", error);
    }

    return { message: "Deletion request rejected. Account reactivated." };
};

const getRequestById = async (id) => {
    const request = await prisma.deletionRequest.findUnique({
        where: { id },
        include: { user: true }
    });
    if (!request) throw new ApiError(404, "Request not found");
    return request;
};

const executeHardDelete = async (requestId) => {
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
        return;
    }

    // เตรียมข้อมูล Backup
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
                performedBy: "SYSTEM_CRON",
                backupData: backupData
            }
        });

        // HARD DELETE User (Cascade should handle relations, but user might want explicit cleanup?)
        // Schema says: user User @relation(fields: [userId], references: [id], onDelete: Cascade)
        // So deleting user should delete related data.
        await tx.user.delete({
            where: { id: userId }
        });
    });

    return { message: "User hard deleted and audit log created." };
};

module.exports = {
    requestDeletion,
    getAllDeletionRequests,
    approveDeletion,
    rejectDeletion,
    getRequestById,
    executeHardDelete,
};
