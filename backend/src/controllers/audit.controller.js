const auditService = require('../services/audit.service');
const asyncHandler = require('express-async-handler');

const getLogs = asyncHandler(async (req, res) => {
    const logs = await auditService.getLogs(req.query);
    res.status(200).json({
        success: true,
        data: logs
    });
});

module.exports = {
    getLogs
};
