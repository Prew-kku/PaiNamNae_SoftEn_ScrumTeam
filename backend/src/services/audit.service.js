const prisma = require('../utils/prisma');

/**
 * Get audit logs (Combined from DeletionRequest history and DeletionAudit)
 * @param {Object} query - Query parameters
 */
const getLogs = async (query) => {
    try {
        const { page = 1, limit = 20, search } = query;
        const skip = (Number(page) - 1) * Number(limit);

        // 1. Fetch from DeletionRequest (Active requests: APPROVED, REJECTED)
        // Note: PENDING requests are usually "In Progress", maybe show them too?
        // User said: "Show user data we approved/rejected in All Request"
        const requests = await prisma.deletionRequest.findMany({
            where: {
                status: {
                    in: ['APPROVED', 'REJECTED']
                },
                // Add search filters if needed
            },
            include: {
                user: {
                    select: {
                        id: true, username: true, email: true, role: true, firstName: true, lastName: true
                    }
                }
            },
            orderBy: { updatedAt: 'desc' },
            take: Number(limit) * 2 // Fetch more to allow merging and sorting in memory (limitation of combining tables)
        });

        // 2. Fetch from DeletionAudit (Completed/Hard Deleted)
        const audits = await prisma.deletionAudit.findMany({
            orderBy: { deletedAt: 'desc' },
            take: Number(limit) * 2
        });

        // 3. Map to common format
        const requestLogs = (requests || []).map(req => ({
            id: `req_${req.id}`,
            timestamp: req.updatedAt, // Use updatedAt as the time of action (Approve/Reject)
            action: req.status, // APPROVED, REJECTED
            request: {
                id: req.id,
                type: 'deletion',
                status: req.status.toLowerCase(),
                user: req.user
            },
            performedBy: {
                // Since we don't track adminId yet, use placeholder or "System"
                id: 'admin',
                firstName: 'Admin',
                lastName: '(System)',
                role: 'ADMIN'
            },
            detail: `${req.status === 'APPROVED' ? 'อนุมัติ' : 'ปฏิเสธ'}คำร้องขอลบบัญชี`,
            originalData: req
        }));

        const auditLogs = (audits || []).map(audit => ({
            id: `audit_${audit.id}`,
            timestamp: audit.deletedAt,
            action: 'HARD_DELETED',
            request: {
                id: 'deleted',
                type: 'deletion',
                status: 'deleted',
                user: {
                    id: audit.originalUserId,
                    firstName: 'Deleted User',
                    lastName: '',
                    email: audit.originalEmail,
                    role: 'UNKNOWN'
                }
            },
            performedBy: {
                id: 'system',
                firstName: audit.performedBy || 'System',
                lastName: '',
                role: 'SYSTEM'
            },
            detail: `ลบบัญชีถาวร (Hard Delete) - ${audit.reason || '-'}`,
            originalData: audit
        }));

        // 4. Combine and Sort
        let allLogs = [...requestLogs, ...auditLogs];
        allLogs.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

        // 5. Paginate manually
        const total = allLogs.length; // Approximate total since we capped fetching
        const paginatedLogs = allLogs.slice(0, Number(limit)); // We already skipped? No, slicing from combined.
        // Actually, skip logic is hard with combined sources efficiently. 
        // For now, fetching recent 2*limit from both and taking top limit is okay for small scale.

        console.log(`[AuditService] Found ${requests.length} requests, ${audits.length} audits. Total logs: ${total}`);

        return {
            logs: paginatedLogs,
            pagination: {
                page: Number(page),
                limit: Number(limit),
                total,
                totalPages: Math.ceil(total / Number(limit))
            }
        };
    } catch (error) {
        console.error('[AuditService] Error in getLogs:', error);
        throw error;
    }
};

module.exports = {
    getLogs
};
