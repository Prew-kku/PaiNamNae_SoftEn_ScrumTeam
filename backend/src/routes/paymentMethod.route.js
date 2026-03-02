const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth');
const paymentController = require('../controllers/paymentMethod.controller');

router.use(protect);

// แก้ Path ให้ตรงกับ Frontend
router.get('/payment-info', paymentController.getPaymentInfo);
router.put('/payment-info/promptpay', paymentController.updatePromptPay);

router.post('/bank-accounts', paymentController.addBankAccount);
router.put('/bank-accounts/:id', paymentController.updateBankAccount);
router.delete('/bank-accounts/:id', paymentController.deleteBankAccount);

module.exports = router;