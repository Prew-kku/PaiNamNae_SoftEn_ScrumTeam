const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const nodemailer = require('nodemailer');

const testEmail = async () => {
    const smtpPass = (process.env.SMTP_PASS || '').trim();
    const smtpUser = (process.env.SMTP_USER || '').trim();

    console.log('--- Gmail SMTP Diagnostics ---');
    console.log('SMTP_HOST:', 'smtp.gmail.com');
    console.log('SMTP_USER:', smtpUser);
    console.log('SMTP_PASS length:', smtpPass.length);

    if (!smtpPass || !smtpUser) {
        console.error('❌ ERROR: Missing credentials in .env file.');
        return;
    }

    if (smtpPass.length < 16) {
        console.warn('⚠️ WARNING: Password seems too short. Make sure it is an App Password (16 characters).');
    }

    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: smtpUser,
            pass: smtpPass,
        },
    });

    const mailOptions = {
        from: `"Pai Nam Nae Admin System" <${smtpUser}>`,
        to: smtpUser, // Send to self
        subject: 'Gmail SMTP Test Email',
        text: 'If you see this, your Gmail SMTP configuration is correct! 🎉',
    };

    console.log('\nAttempting to send test email...');
    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('✅ Success! Message ID:', info.messageId);
        console.log('Email sent successfully. Check your inbox (and Spam).');
    } catch (error) {
        console.error('\n❌ FAILED to send email.');
        console.error('Error Message:', error.message);
        if (error.message.includes('Username and Password not accepted')) {
            console.log('💡 TIP: Make sure you are using an APP PASSWORD, not your login password.');
        }
    }
};

testEmail();
