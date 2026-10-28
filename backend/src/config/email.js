const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true, // use SSL
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Verify transporter configuration
transporter.verify((error, success) => {
  if (error) {
    console.error('[Email] ❌ Transporter error:', error);
  } else {
    console.log('[Email] ✅ Server is ready to take our messages');
  }
});

const sendVerificationEmail = async (email, code) => {
  try {
    const mailOptions = {
      from: `"JobConnect VN" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Xác thực tài khoản JobConnect VN',
      html: `
        <div style="font-family: sans-serif; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
          <h2 style="color: #4B30D4;">Chào mừng bạn đến với JobConnect VN!</h2>
          <p>Mã xác thực của bạn là:</p>
          <div style="background: #F0EDFF; padding: 15px; font-size: 24px; font-weight: bold; text-align: center; color: #4B30D4; border-radius: 5px;">
            ${code}
          </div>
          <p>Vui lòng nhập mã này vào ứng dụng để hoàn tất việc xác thực tài khoản.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="font-size: 12px; color: #888;">Nếu bạn không thực hiện đăng ký này, vui lòng bỏ qua email.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`[Email] Verification email sent to ${email}`);
    return true;
  } catch (error) {
    console.error('[Email] Error sending email:', error);
    return false;
  }
};

module.exports = { sendVerificationEmail };

