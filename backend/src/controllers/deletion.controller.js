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

const cancelDeletion = catchAsync(async (req, res) => {
    const userId = req.user.sub || req.user.id;
    const result = await deletionService.cancelDeletionByUser(userId);
    res.status(200).json(result);
});

const getRequests = catchAsync(async (req, res) => {
    const requests = await deletionService.getAllDeletionRequests();
    res.status(200).json(requests);
});

const approveRequest = catchAsync(async (req, res) => {
    const { id } = req.params;
    const result = await deletionService.approveDeletion(id);
    res.status(200).json(result);
});

const rejectRequest = catchAsync(async (req, res) => {
    const { id } = req.params;
    const result = await deletionService.rejectDeletion(id);
    res.status(200).json(result);
});

module.exports = {
    requestDeletion,
    cancelDeletion,
    getRequests,
    approveRequest,
    rejectRequest,
};

