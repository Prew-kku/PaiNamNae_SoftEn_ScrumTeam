const express = require('express');
const auditController = require('../controllers/audit.controller');
const { protect, requireAdmin } = require('../middlewares/auth');

const router = express.Router();

// GET /api/audit/logs
router.get(
    '/logs',
    protect,
    requireAdmin,
    auditController.getLogs
);

module.exports = router;
