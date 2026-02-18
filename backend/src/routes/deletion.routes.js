//Thongchai595-6
const express = require("express");
const router = express.Router();
const deletionController = require("../controllers/deletion.controller");
const { protect, requireAdmin } = require("../middlewares/auth");

// User Request
router.post("/request", protect, deletionController.requestDeletion);

// Admin Actions
router.get("/admin/requests", protect, requireAdmin, deletionController.getRequests);
router.get("/admin/requests/:id", protect, requireAdmin, deletionController.getRequestById);
router.patch("/admin/requests/:id/approve", protect, requireAdmin, deletionController.approveRequest);
router.patch("/admin/requests/:id/reject", protect, requireAdmin, deletionController.rejectRequest);

module.exports = router;
