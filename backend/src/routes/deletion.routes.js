//Thongchai595-6
const express = require('express')
const router = express.Router()
const auth = require('../middlewares/auth')
const ctrl = require('../controllers/deletion.controller')


// User ขอ Delete
router.post('/request', auth(), ctrl.requestDeletion)

// Admin อนุมัติคำขอลบ
router.post('/:id/approve', auth('admin'), ctrl.approveDeletion)
// Admin ปฏิเสธคำขอลบ
router.post('/:id/reject', auth('admin'), ctrl.rejectDeletion)

module.exports = router