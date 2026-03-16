const cron = require('node-cron');
const prisma = require('../utils/prisma');
const deletionService = require('../services/deletion.service');

// Run every day at specific time (e.g., 03:00 AM)
cron.schedule('0 3 * * *', async () => {
    console.log('[Cron] Checking for expired deletion requests...');

    try {
        const now = new Date();

        // Find approved requests where scheduledDeleteAt has passed
        const expiredRequests = await prisma.deletionRequest.findMany({
            where: {
                status: 'APPROVED',
                scheduledDeleteAt: {
                    lte: now
                }
            },
            include: { user: true }
        });

        console.log(`[Cron] Found ${expiredRequests.length} expired requests.`);

        for (const req of expiredRequests) {
            try {
                console.log(`[Cron] Processing hard delete for user ${req.userId}...`);

                // Reuse existing approveDeletion helper or create a new internal function
                // But approveDeletion is for *scheduling*. We need *execution*.

                // Logic hard delete:
                const userId = req.userId;
                const user = req.user;

                if (!user) {
                    await prisma.deletionRequest.delete({ where: { id: req.id } });
                    continue;
                }

                // 1. Create Audit Log / Backup (Same logic as old approveDeletion)
                // We should probably extract this logic to service, but for now implementing here or calling service helper

                // Let's create a dedicated service method for hard delete in deletion.cron.js or service

                await deletionService.executeHardDelete(req.id);

            } catch (err) {
                console.error(`[Cron] Failed to process request ${req.id}:`, err);
            }
        }

    } catch (error) {
        console.error('[Cron] Error checking expired requests:', error);
    }
});

module.exports = cron;
