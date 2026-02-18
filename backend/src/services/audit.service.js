const prisma = require('../utils/prisma');

/**
 * Get audit logs (Combined from DeletionRequest history and DeletionAudit)
 * @param {Object} query - Query parameters
 */
const getLogs = async (query) => {
    try {
        const {
            page = 1,
            limit = 20,
            search = '',
            action = '',
            requestType = '',
            adminId = '',
            dateFrom = '',
            dateTo = '',
        } = query;
        const skip = (Number(page) - 1) * Number(limit);

        if (requestType && String(requestType).toLowerCase() !== 'deletion') {
            return {
                logs: [],
                pagination: {
                    page: Number(page),
                    limit: Number(limit),
                    total: 0,
                    totalPages: 1,
                },
            };
        }

        const eventTimeFilter = {};
        if (dateFrom) {
            const from = new Date(dateFrom);
            if (!Number.isNaN(from.getTime())) {
                eventTimeFilter.gte = from;
            }
        }
        if (dateTo) {
            const to = new Date(dateTo);
            if (!Number.isNaN(to.getTime())) {
                to.setHours(23, 59, 59, 999);
                eventTimeFilter.lte = to;
            }
        }

        const where = {
            ...(action ? { status: String(action).toUpperCase() } : {}),
            ...(adminId ? { performedBy: String(adminId).toUpperCase() } : {}),
            ...(Object.keys(eventTimeFilter).length ? { eventTime: eventTimeFilter } : {}),
            ...(search
                ? {
                    OR: [
                        { reason: { contains: search, mode: 'insensitive' } },
                        { originalEmail: { contains: search, mode: 'insensitive' } },
                        { originalUserId: { contains: search, mode: 'insensitive' } },
                        {
                            request: {
                                user: {
                                    OR: [
                                        { email: { contains: search, mode: 'insensitive' } },
                                        { username: { contains: search, mode: 'insensitive' } },
                                        { firstName: { contains: search, mode: 'insensitive' } },
                                        { lastName: { contains: search, mode: 'insensitive' } },
                                    ],
                                },
                            },
                        },
                    ],
                }
                : {}),
        };

        const [total, audits] = await Promise.all([
            prisma.deletionAudit.count({ where }),
            prisma.deletionAudit.findMany({
                where,
                orderBy: { eventTime: 'desc' },
                skip,
                take: Number(limit),
                include: {
                    request: {
                        include: {
                            user: {
                                select: {
                                    id: true,
                                    username: true,
                                    email: true,
                                    role: true,
                                    firstName: true,
                                    lastName: true,
                                },
                            },
                        },
                    },
                },
            }),
        ]);

        const logs = (audits || []).map((audit) => {
            const req = audit.request;
            const reqUser = req?.user;

            return {
                id: audit.id,
                timestamp: audit.eventTime,
                action: audit.status,
                request: {
                    id: req?.id || audit.requestId || null,
                    type: 'deletion',
                    status: req?.status?.toLowerCase?.() || 'deleted',
                    user: reqUser
                        ? reqUser
                        : {
                            id: audit.originalUserId,
                            firstName: 'Deleted',
                            lastName: 'User',
                            username: 'deleted-user',
                            email: audit.originalEmail,
                            role: 'UNKNOWN',
                        },
                },
                performedBy: {
                    id: audit.performedBy || 'SYSTEM',
                    firstName: audit.performedBy || 'System',
                    lastName: '',
                    role: audit.performedBy || 'SYSTEM',
                },
                detail: audit.reason || '-',
                backupData: audit.backupData || null,
                originalData: audit,
            };
        });

        return {
            logs,
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
