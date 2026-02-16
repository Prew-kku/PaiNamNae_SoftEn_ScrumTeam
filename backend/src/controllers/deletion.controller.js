// Thongchai595-6
const deletionService = require('../services/deletion.service');

// User ขอ Delete
exports.requestDeletion = async (req, res, next) => {
    try {
        const { reason, additionalDetails } = req.body;

        const result = await deletionService.rejectDeletion(
            req.user.id,
            reason,
            additionalDetails
        )
    
    res.json({
        succes: true,
        requestId: result.id,
    })
} catch (error) {
    next(error);
}
}

// Admin อนุมัติคำขอลบ
exports.approveDeletion = async (req, res, next) => {
    try {
        await deletionService.approveDeletion(req.params.id, req.user.id)
        res.json({ success: true })
    } catch (error) {
        next(error)
    }
}

// Admin ปฏิเสธคำขอลบ
exports.rejectDeletion = async (req, res, next) => {
    try {
        const { note } = req.body
        await deletionService.rejectDeletion(req.params.id, req.user.id, note)
        res.json({ success: true })
    } catch (error) {
        next(error)
    }
}