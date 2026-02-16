// Thongchai595-6 
const prisma = require('../utils/prisma');
const ApiError = require('../utils/ApiError');
const dayjs = require('dayjs');
const { Profiler } = require('react');

// User ขอลบข้อมูล
exports.requestDeletion = async (userId, reason, additionalDetails) => {
    return prisma.$transaction(async (tx) => {
        // เช็คว่ามี Pending ไหม
        const existing = await tx.deletionRequest.findFirst({
            where: {
                userId,
                type: "deletion",
                status: "pending",
            },
        });

        if (existing) {
            throw new ApiError(400, 'มีคำขอลบบัญชีที่ยังรอดำเนินการอยู่แล้ว');
        }

        // สร้าง deletion request 
        const request = await tx.request.create({
            deta: {
                type: "deletion",
                status: "pending",
                userId,
                deletion: {
                    create: {
                        reason,
                        description,
                    },
                },
            },
        })

        // SOFT DELETE ทันทีหลังขอลบ
        await tx.user.update({
            where: { id: userId },
            data: {
                isActivate: false,
                deletedAt: new Date(),

                email: `deleted_${userId}@deleted.local`,
                username: `deleted_${userId}`,
                password: "deleted",

                firtName: null,
                lastName: null,
                phoneNumber: null,
                profilePicture: null,
            },
        })
        return request
    })
} 

// Admin อนุมัติคำขอลบ
exports.approveDeletion = async (requestId, adminNote) => {
    const request = await prisma.request.findUnique({
        where: { id: requestId },
    })

    if (!request || request.type !== "deletion") {
        throw new ApiError(404, 'ไม่พบคำขอลบบัญชี');
    }

    // update status เป็น approved + นับถอยหลังลบ 90 วัน
    await prisma.request.update({
        where: { id: requestId },
        data: {
            status: "approved",
            deletion: {
                update: {
                    approvedAt: new Date(),
                },
            },
        },
    })
    
    await prisma.update({
        where: { id: request.userId },
        data: {
            haedDeleteScheduledAt: dayjs().add(90, 'day').toDate(),
        },
    })
    return true
}
 
// Admin ปฏิเสธคำขอลบ
exports.rejectDeletion = async (requestId, adminNote) => {
    const request = await prisma.request.findUnique({
        where: { id: requestId },
    })

    if (!request || request.type !== "deletion") {
        throw new ApiError(404, 'ไม่พบคำขอลบบัญชี');
    }

    await prisma.request.update({
        where: { id: requestId },
        data: {
            status: "rejected",
            deletion: {
                update: {
                    adminNote: note || "มีการปฏิเสธคำขอลบบัญชี",
                    reviewedById: adminId,
                    reviewedAt: new Date(),
                },
            },
        },
    })
    return true
}