const nodemailer = require('nodemailer');

/**
 * GMAIL SMTP EMAIL SERVICE
 * Host: smtp.gmail.com | Port: 587
 * Requires: App Password (not your normal password)
 */
const transporter = nodemailer.createTransport({
    service: 'gmail', // built-in support for Gmail
    auth: {
        user: (process.env.SMTP_USER || '').trim(),
        pass: (process.env.SMTP_PASS || '').trim(), // Must be App Password
    },
});

/**
 * Handle Account Deletion Email
 */
const sendAccountDeletionEmail = async (to, username) => {
    const fromEmail = (process.env.SMTP_USER || '').trim(); // Gmail usually forces sender to be the auth user

    const mailOptions = {
        from: `"Pai Nam Nae Admin System" <${fromEmail}>`,
        to: to,
        subject: 'แจ้งเตือน: บัญชีผู้ใช้งาน Pai Nam Nae ของคุณถูกลบแล้ว',
        html: `
            <div style="font-family: sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #d9534f;">แจ้งการลบบัญชีผู้ใช้งาน</h2>
                <p>สวัสดีคุณ <strong>${username}</strong>,</p>
                <p>เราขอแจ้งให้ทราบว่า บัญชีผู้ใช้งานของคุณในระบบ <strong>Pai Nam Nae</strong> ได้ถูกลบโดยผู้ดูแลระบบเรียบร้อยแล้ว</p>
                <div style="background: #fdfdfd; padding: 15px; border-left: 4px solid #d9534f; margin: 20px 0;">
                    <p style="margin: 0;">หากนี่เป็นความผิดพลาด หรือต้องการความช่วยเหลือเพิ่มเติม กรุณาติดต่อ Admin</p>
                </div>
                <hr style="border: none; border-top: 1px solid #eee;">
                <p style="font-size: 11px; color: #999; text-align: center;">© 2026 Pai Nam Nae Security System. This is an automated notification.</p>
            </div>
        `,
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('✅ Success: Real email delivered to:', to);
        return info;
    } catch (error) {
        console.error('❌ Email Status:', error.message);
        return null;
    }
};

module.exports = {
    sendAccountDeletionEmail,
};
