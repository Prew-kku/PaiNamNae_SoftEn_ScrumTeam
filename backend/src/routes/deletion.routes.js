//Thongchai595-6
const express = require("express");
const router = express.Router();
const deletionController = require("../controllers/deletion.controller");

// ใช้ชื่อ protect กับ requireAdmin ตามที่มีใน src/middlewares/auth.js
const { protect, requireAdmin } = require("../middlewares/auth");

// User
router.post("/request", protect, deletionController.requestDeletion);

// Admin
router.get("/admin/requests", protect, requireAdmin, deletionController.getRequests);
router.patch("/admin/requests/:id/approve", protect, requireAdmin, deletionController.approveRequest);
router.patch("/admin/requests/:id/reject", protect, requireAdmin, deletionController.rejectRequest);

module.exports = router;
