const asyncHandler = require('express-async-handler');
const paymentService = require('../services/payment.service');
const ApiError = require('../utils/ApiError');

const getPayment = asyncHandler(async (req, res) => {
  const userId = req.user.sub;
  const data = await paymentService.getPaymentByBooking(req.params.id, userId);
  res.status(200).json({ success: true, message: 'Payment retrieved successfully', data });
});

const submitPaymentSlip = asyncHandler(async (req, res) => {
  const passengerId = req.user.sub;
  if (!req.file) throw new ApiError(400, 'Payment slip image is required');
  const { method } = req.body;
  const data = await paymentService.submitPaymentSlip(req.params.id, passengerId, req.file, method);
  res.status(200).json({ success: true, message: 'Payment slip submitted successfully', data });
});

const verifyPayment = asyncHandler(async (req, res) => {
  const driverId = req.user.sub;
  const { method } = req.body;
  const data = await paymentService.verifyPayment(req.params.id, driverId, { method });
  res.status(200).json({ success: true, message: 'Payment verified successfully', data });
});

const rejectPayment = asyncHandler(async (req, res) => {
  const driverId = req.user.sub;
  const { rejectReason } = req.body;
  const data = await paymentService.rejectPayment(req.params.id, driverId, rejectReason);
  res.status(200).json({ success: true, message: 'Payment rejected', data });
});

const declareCashPayment = asyncHandler(async (req, res) => {
  const passengerId = req.user.sub;
  const data = await paymentService.declareCashPayment(req.params.id, passengerId);
  res.status(200).json({ success: true, message: 'Cash payment declared', data });
});

module.exports = {
  getPayment,
  submitPaymentSlip,
  declareCashPayment,
  verifyPayment,
  rejectPayment
};
