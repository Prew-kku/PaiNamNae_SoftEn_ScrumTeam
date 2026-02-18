// Thongchai595-6

const deletionService = require("../services/deletion.service");

const catchAsync = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

const requestDeletion = catchAsync(async (req, res) => {

    const { password, reason } = req.body;
    const userId = req.user.sub || req.user.id;

    const result = await deletionService.requestDeletion(userId, password, reason);
    res.status(200).json(result);
});

const getRequests = catchAsync(async (req, res) => {
    const { status, role, type, q } = req.query;
    const requests = await deletionService.getAllDeletionRequests({ status, role, type, search: q });
    res.status(200).json(requests);
});

const getRequestById = catchAsync(async (req, res) => {
    const { id } = req.params;
    const request = await deletionService.getRequestById(id);
    res.status(200).json(request);
});

const approveRequest = catchAsync(async (req, res) => {
    const { id } = req.params;
    const result = await deletionService.approveDeletion(id);
    res.status(200).json({ message: "Approved. Scheduled for hard delete in 90 days.", data: result });
});

const rejectRequest = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { adminReason } = req.body;
    const result = await deletionService.rejectDeletion(id, adminReason);
    res.status(200).json({ message: "Rejected. Data retained permanently.", data: result });
});

module.exports = {
    requestDeletion,
    getRequests,
    getRequestById,
    approveRequest,
    rejectRequest,
};

