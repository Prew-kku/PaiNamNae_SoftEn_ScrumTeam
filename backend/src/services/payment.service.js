const prisma = require('../utils/prisma');
const ApiError = require('../utils/ApiError');
const { uploadToCloudinary, deleteFromCloudinary } = require('../utils/cloudinary');

const getPaymentByBooking = async (bookingId, userId) => {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: {
      payment: true,
      route: { select: { driverId: true } }
    }
  });
  if (!booking) throw new ApiError(404, 'Booking not found');
  if (booking.passengerId !== userId && booking.route.driverId !== userId) {
    throw new ApiError(403, 'Forbidden');
  }
  return booking.payment;
};

const submitPaymentSlip = async (bookingId, passengerId, file, method) => {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: {
      payment: true,
      route: { select: { driverId: true, pricePerSeat: true } }
    }
  });
  if (!booking) throw new ApiError(404, 'Booking not found');
  let isFellowPaying = false;
  if (booking.passengerId !== passengerId) {
    // Allow a fellow passenger (COMPLETED booking in same route) to pay on behalf
    const requesterBooking = await prisma.booking.findFirst({
      where: { routeId: booking.routeId, passengerId, status: 'COMPLETED' }
    });
    if (!requesterBooking) throw new ApiError(403, 'Forbidden');
    isFellowPaying = true;
  }
  if (booking.status !== 'COMPLETED') {
    throw new ApiError(400, 'Booking must be COMPLETED before submitting payment');
  }
  if (!booking.payment) throw new ApiError(404, 'Payment record not found');
  if (!['PENDING', 'REJECTED'].includes(booking.payment.status)) {
    throw new ApiError(400, 'Payment slip can only be submitted when status is PENDING or REJECTED');
  }

  // ลบสลิปเดิมจาก Cloudinary ถ้ามี (กรณี re-submit)
  if (booking.payment.slipPublicId) {
    try {
      await deleteFromCloudinary(booking.payment.slipPublicId);
    } catch (e) {
      console.error('Failed to delete old slip from Cloudinary:', e);
    }
  }

  const { url, public_id } = await uploadToCloudinary(file.buffer, 'painamnae/payment-slips');

  const updated = await prisma.$transaction(async (tx) => {
    const payment = await tx.payment.update({
      where: { id: booking.payment.id },
      data: {
        status: 'SUBMITTED',
        method: method || 'PROMPTPAY',
        slipUrl: url,
        slipPublicId: public_id,
        submittedAt: new Date(),
        rejectedAt: null,
        rejectReason: null,
        ...(isFellowPaying && { paidBy: passengerId })
      }
    });

    await tx.notification.create({
      data: {
        userId: booking.route.driverId,
        type: 'BOOKING',
        title: 'ผู้โดยสารส่งหลักฐานการชำระเงินแล้ว',
        body: 'กรุณาตรวจสอบและยืนยันการรับเงิน',
        metadata: {
          kind: 'PAYMENT_SUBMITTED',
          bookingId,
          paymentId: payment.id
        }
      }
    });

    return payment;
  });

  return updated;
};

const verifyPayment = async (bookingId, driverId, opts = {}) => {
  const { method } = opts;

  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: {
      payment: true,
      route: { select: { driverId: true } }
    }
  });
  if (!booking) throw new ApiError(404, 'Booking not found');
  if (booking.route.driverId !== driverId) throw new ApiError(403, 'Forbidden');
  if (!booking.payment) throw new ApiError(404, 'Payment record not found');

  const isCash = method === 'CASH';
  if (isCash) {
    if (booking.payment.status !== 'PENDING') {
      throw new ApiError(400, 'Cash payment can only be verified when status is PENDING');
    }
  } else {
    if (booking.payment.status !== 'SUBMITTED') {
      throw new ApiError(400, 'Payment must be SUBMITTED before verifying');
    }
  }

  const updated = await prisma.$transaction(async (tx) => {
    const payment = await tx.payment.update({
      where: { id: booking.payment.id },
      data: {
        status: 'VERIFIED',
        method: isCash ? 'CASH' : booking.payment.method,
        verifiedAt: new Date()
      }
    });

    await tx.notification.create({
      data: {
        userId: booking.passengerId,
        type: 'BOOKING',
        title: 'คนขับยืนยันรับเงินแล้ว',
        body: 'การชำระเงินสมบูรณ์ ขอบคุณที่ใช้บริการ',
        metadata: {
          kind: 'PAYMENT_VERIFIED',
          bookingId,
          paymentId: payment.id
        }
      }
    });

    return payment;
  });

  return updated;
};

const rejectPayment = async (bookingId, driverId, rejectReason) => {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: {
      payment: true,
      route: { select: { driverId: true } }
    }
  });
  if (!booking) throw new ApiError(404, 'Booking not found');
  if (booking.route.driverId !== driverId) throw new ApiError(403, 'Forbidden');
  if (!booking.payment) throw new ApiError(404, 'Payment record not found');
  if (booking.payment.status !== 'SUBMITTED') {
    throw new ApiError(400, 'Payment must be SUBMITTED before rejecting');
  }

  const updated = await prisma.$transaction(async (tx) => {
    const payment = await tx.payment.update({
      where: { id: booking.payment.id },
      data: {
        status: 'REJECTED',
        rejectedAt: new Date(),
        rejectReason: rejectReason || null
      }
    });

    await tx.notification.create({
      data: {
        userId: booking.passengerId,
        type: 'BOOKING',
        title: 'หลักฐานการชำระเงินไม่ถูกต้อง',
        body: rejectReason
          ? `เหตุผล: ${rejectReason} กรุณาส่งหลักฐานใหม่`
          : 'กรุณาส่งหลักฐานการชำระเงินใหม่อีกครั้ง',
        metadata: {
          kind: 'PAYMENT_REJECTED',
          bookingId,
          paymentId: payment.id,
          rejectReason
        }
      }
    });

    return payment;
  });

  return updated;
};

const declareCashPayment = async (bookingId, passengerId) => {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: {
      payment: true,
      route: { select: { driverId: true } }
    }
  });
  if (!booking) throw new ApiError(404, 'Booking not found');
  let isFellowPaying = false;
  if (booking.passengerId !== passengerId) {
    // Allow a fellow passenger (COMPLETED booking in same route) to declare cash on behalf
    const requesterBooking = await prisma.booking.findFirst({
      where: { routeId: booking.routeId, passengerId, status: 'COMPLETED' }
    });
    if (!requesterBooking) throw new ApiError(403, 'Forbidden');
    isFellowPaying = true;
  }
  if (booking.status !== 'COMPLETED') {
    throw new ApiError(400, 'Booking must be COMPLETED');
  }
  if (!booking.payment) throw new ApiError(404, 'Payment record not found');
  if (!['PENDING'].includes(booking.payment.status)) {
    throw new ApiError(400, 'Can only declare cash when payment is PENDING');
  }

  return prisma.$transaction(async (tx) => {
    const payment = await tx.payment.update({
      where: { id: booking.payment.id },
      data: { method: 'CASH', ...(isFellowPaying && { paidBy: passengerId }) }
    });

    await tx.notification.create({
      data: {
        userId: booking.route.driverId,
        type: 'BOOKING',
        title: 'ผู้โดยสารแจ้งชำระด้วยเงินสด',
        body: 'กรุณายืนยันการรับเงินสดเมื่อได้รับเงินจากผู้โดยสาร',
        metadata: {
          kind: 'PAYMENT_CASH_DECLARED',
          bookingId,
          paymentId: payment.id
        }
      }
    });

    return payment;
  });
};

module.exports = {
  getPaymentByBooking,
  submitPaymentSlip,
  declareCashPayment,
  verifyPayment,
  rejectPayment
};
