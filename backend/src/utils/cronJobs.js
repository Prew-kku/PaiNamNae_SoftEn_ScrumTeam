//Thongchai595-6
const cron = require("node-cron");
const prisma = require("./prisma");

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

                await prisma.deletionAudit.create({
                    data: {
                        originalUserId: req.userId,
                        originalEmail: originalData.email || "unknown",
                        reason: req.reason,
                        status: "COMPLETED",
                        performedBy: "SYSTEM_CRON",
                        backupData: req.backupData 
                    }
                });

                // 2. HARD DELETE
                // การลบ User จะลบ DeletionRequest และข้อมูลอื่นๆ ไปด้วย (Cascade)
                await prisma.user.delete({
                    where: { id: req.userId },
                });

                console.log(`Hard deleted user ${req.userId}`);

            } catch (error) {
                console.error(`Failed to delete user ${req.userId}:`, error);
            }
        }
    });
};

module.exports = initCronJobs;
