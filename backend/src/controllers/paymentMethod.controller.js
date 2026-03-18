const asyncHandler = require('express-async-handler');
const prisma = require('../utils/prisma');

// 1. ดึงข้อมูล PromptPay และ บัญชีธนาคารทั้งหมด (สำหรับตอนโหลดหน้าเว็บ)
exports.getPaymentInfo = asyncHandler(async (req, res) => {
    const userId = req.user.sub; // ดึง ID จาก token ที่ auth.js ถอดรหัสไว้

    const user = await prisma.user.findUnique({
        where: { id: userId },
        include: { bankAccounts: true }
    });

    res.json({
        promptPayId: user.promptPayId,
        bankAccounts: user.bankAccounts
    });
});

// 2. บันทึก/อัปเดต หมายเลข PromptPay
exports.updatePromptPay = asyncHandler(async (req, res) => {
    const userId = req.user.sub;
    const { promptPayId } = req.body;

    if (!promptPayId || !/^\d{10}$|^\d{13}$/.test(promptPayId)) {
        return res.status(400).json({ success: false, message: 'หมายเลข PromptPay ต้องเป็นตัวเลข 10 หรือ 13 หลักเท่านั้น' });
    }

    await prisma.user.update({
        where: { id: userId },
        data: { promptPayId }
    });

    res.json({ success: true, promptPayId });
});

// 3. เพิ่มบัญชีธนาคารใหม่
exports.addBankAccount = asyncHandler(async (req, res) => {
    const userId = req.user.sub;
    const { bankCode, customBankName, accountNumber, accountName } = req.body;

    const newAccount = await prisma.bankAccount.create({
        data: {
            userId,
            bankCode,
            customBankName,
            accountNumber,
            accountName
        }
    });

    res.status(201).json(newAccount);
});

// 4. แก้ไขบัญชีธนาคาร
exports.updateBankAccount = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { bankCode, customBankName, accountNumber, accountName } = req.body;

    // ตรวจสอบก่อนว่าบัญชีนี้เป็นของ User คนนี้จริงๆ ป้องกันการแฮกแก้ไขของคนอื่น
    const account = await prisma.bankAccount.findUnique({ where: { id } });
    if (!account || account.userId !== req.user.sub) {
        res.status(403);
        throw new Error('ไม่ได้รับอนุญาตให้แก้ไขบัญชีนี้');
    }

    const updatedAccount = await prisma.bankAccount.update({
        where: { id },
        data: { bankCode, customBankName, accountNumber, accountName }
    });

    res.json(updatedAccount);
});

// 5. ลบบัญชีธนาคาร
exports.deleteBankAccount = asyncHandler(async (req, res) => {
    const { id } = req.params;

    const account = await prisma.bankAccount.findUnique({ where: { id } });
    if (!account || account.userId !== req.user.sub) {
        res.status(403);
        throw new Error('ไม่ได้รับอนุญาตให้ลบบัญชีนี้');
    }

    await prisma.bankAccount.delete({ where: { id } });
    res.json({ success: true, message: 'ลบบัญชีเรียบร้อยแล้ว' });
});