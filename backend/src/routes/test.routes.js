const express = require('express');
const router = express.Router();
const cronJobs = require('../utils/cronJobs');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// จำลองการรัน Cron Job ลบข้อมูล (ทำงานทันทีที่เรียก)
router.post('/cron/deletion', async (req, res) => {
    try {
        await cronJobs.runDeletionCleanup();
        res.status(200).json({ message: "Deletion cron job executed successfully." });
    } catch (error) {
        res.status(500).json({ message: "Error executing deletion cron job", error: error.message });
    }
});

// จำลองการข้ามเวลา 90 วัน สำหรับคำร้องลบข้อมูลเฉพาะ ID
router.put('/cron/fast-forward/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const request = await prisma.deletionRequest.findUnique({ where: { id } });

        if (!request) return res.status(404).json({ message: "Request not found" });
        if (request.status !== 'APPROVED') return res.status(400).json({ message: "Request must be APPROVED first" });

        // สร้างวันที่ย้อนหลังไป 91 วัน
        const pastDate = new Date();
        pastDate.setDate(pastDate.getDate() - 91);

        await prisma.deletionRequest.update({
            where: { id },
            data: {
                approvedAt: pastDate,
                scheduledDeleteAt: pastDate,
            }
        });

        res.status(200).json({
            message: "Time fast-forwarded 90 days. The request is now eligible for deletion.",
            newDate: pastDate
        });
    } catch (error) {
        res.status(500).json({ message: "Error fast-forwarding time", error: error.message });
    }
});

module.exports = router;
