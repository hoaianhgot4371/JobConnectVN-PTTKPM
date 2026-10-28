const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const { query } = require('../config/database');
const { sendVerificationEmail } = require('../config/email');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// ── Helper: generate JWT ────────────────────────────────────────────────────
const signToken = (userId) =>
  jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

// ── Helper: safe user object (strip password) ───────────────────────────────
const safeUser = (row) => {
  const { password, ...rest } = row;
  return rest;
};

// ── POST /auth/register ──────────────────────────────────────────────────────
const register = async (req, res) => {
  try {
    const { email, password, name, role = 'student' } = req.body;

    // Validate
    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, mật khẩu và họ tên là bắt buộc' });
    }
    if (!['student', 'employer'].includes(role)) {
      return res.status(400).json({ error: 'Vai trò không hợp lệ (student | employer)' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Mật khẩu phải có ít nhất 6 ký tự' });
    }

    // Check duplicate email
    const exists = await query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);
    if (exists.rows.length) {
      return res.status(409).json({ error: 'Email đã được sử dụng' });
    }

    // Hash password
    const hashed = await bcrypt.hash(password, 12);

    // Generate verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Insert
    const result = await query(
      `INSERT INTO users (email, password, name, role, verification_code)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [email.toLowerCase(), hashed, name.trim(), role, verificationCode]
    );

    const user = result.rows[0];
    const token = signToken(user.id);

    // Send email async
    sendVerificationEmail(user.email, verificationCode);

    res.status(201).json({
      message: 'Đăng ký thành công. Vui lòng kiểm tra email để lấy mã xác thực.',
      token,
      user: safeUser(user),
    });
  } catch (err) {
    console.error('[Auth] register error:', err);
    res.status(500).json({ error: 'Lỗi server khi đăng ký' });
  }
};

// ── POST /auth/login ──────────────────────────────────────────────────────────
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email/SĐT và mật khẩu là bắt buộc' });
    }

    // Support login by email or phone
    const result = await query(
      'SELECT * FROM users WHERE email = $1 OR phone = $1',
      [email.toLowerCase()]
    );

    if (!result.rows.length) {
      return res.status(401).json({ error: 'Email/SĐT hoặc mật khẩu không đúng' });
    }

    const user = result.rows[0];

    if (!user.is_active) {
      return res.status(403).json({ error: 'Tài khoản đã bị vô hiệu hoá' });
    }

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ error: 'Email/SĐT hoặc mật khẩu không đúng' });
    }

    const token = signToken(user.id);

    res.json({
      message: 'Đăng nhập thành công',
      token,
      user: safeUser(user),
    });
  } catch (err) {
    console.error('[Auth] login error:', err);
    res.status(500).json({ error: 'Lỗi server khi đăng nhập' });
  }
};

// ── POST /auth/verify ─────────────────────────────────────────────────────────
const verifyEmail = async (req, res) => {
  try {
    const { code } = req.body;
    const userId = req.user.id;

    if (!code) {
      return res.status(400).json({ error: 'Mã xác thực là bắt buộc' });
    }

    const result = await query('SELECT verification_code FROM users WHERE id = $1', [userId]);
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    if (result.rows[0].verification_code !== code) {
      return res.status(400).json({ error: 'Mã xác thực không đúng' });
    }

    await query(
      'UPDATE users SET is_verified = TRUE, verification_code = NULL WHERE id = $1',
      [userId]
    );

    res.json({ message: 'Xác thực tài khoản thành công' });
  } catch (err) {
    console.error('[Auth] verifyEmail error:', err);
    res.status(500).json({ error: 'Lỗi server khi xác thực' });
  }
};

// ── POST /auth/resend-code ────────────────────────────────────────────────────
const resendCode = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get user info
    const result = await query('SELECT email, is_verified FROM users WHERE id = $1', [userId]);
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    if (result.rows[0].is_verified) {
      return res.status(400).json({ error: 'Tài khoản đã được xác thực' });
    }

    // Generate new code
    const newCode = Math.floor(100000 + Math.random() * 900000).toString();

    await query('UPDATE users SET verification_code = $1 WHERE id = $2', [newCode, userId]);

    // Send email
    await sendVerificationEmail(result.rows[0].email, newCode);

    res.json({ message: 'Đã gửi lại mã xác thực vào email của bạn' });
  } catch (err) {
    console.error('[Auth] resendCode error:', err);
    res.status(500).json({ error: 'Lỗi server khi gửi lại mã' });
  }
};

// ── POST /auth/google ────────────────────────────────────────────────────────
const googleLogin = async (req, res) => {
  try {
    const { idToken, role = 'student' } = req.body;
    if (!idToken) return res.status(400).json({ error: 'idToken là bắt buộc' });

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { email, name, sub: googleId, picture: avatar_url } = payload;

    let userResult = await query('SELECT * FROM users WHERE google_id = $1 OR email = $2', [googleId, email.toLowerCase()]);
    let user;

    if (userResult.rows.length === 0) {
      // Create new user (Google users are auto-verified)
      const resNew = await query(
        `INSERT INTO users (email, password, name, role, google_id, avatar_url, is_verified)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
        [email.toLowerCase(), 'google-oauth-pwd', name, role, googleId, avatar_url, true]
      );
      user = resNew.rows[0];
    } else {
      user = userResult.rows[0];
      if (!user.google_id) {
        await query('UPDATE users SET google_id = $1, is_verified = TRUE WHERE id = $2', [googleId, user.id]);
        user.google_id = googleId;
        user.is_verified = true;
      }
    }

    const token = signToken(user.id);
    res.json({ message: 'Đăng nhập Google thành công', token, user: safeUser(user) });
  } catch (err) {
    console.error('[Auth] googleLogin error:', err);
    res.status(401).json({ error: 'Xác thực Google thất bại' });
  }
};

// ── User Reviews & Profile ───────────────────────────────────────────────────
const getMe = async (req, res) => {
  try {
    const result = await query(
      `SELECT id, email, name, role, avatar_url, bio, phone, location,
              university, major, skills, cv_url, free_time, experience,
              company_name, company_field, company_website, company_address,
              company_logo, company_desc, is_verified, is_active, created_at
       FROM users WHERE id = $1`,
      [req.user.id]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('[Auth] getMe error:', err);
    res.status(500).json({ error: 'Lỗi server khi lấy thông tin cá nhân' });
  }
};

const getReviewStats = async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await query(
      `SELECT COALESCE(AVG(rating), 0) as avg_rating, COUNT(*) as review_count
       FROM user_reviews WHERE target_id = $1`,
      [userId]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error('[Auth] getReviewStats error:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ── POST /auth/reputation ──────────────────────────────────────────────────────
const addReview = async (req, res) => {
  try {
    const { targetId, rating, comment } = req.body;
    const reviewerId = req.user.id;

    if (!targetId || !rating) {
      return res.status(400).json({ error: 'targetId và rating là bắt buộc' });
    }

    await query(
      `INSERT INTO user_reviews (reviewer_id, target_id, rating, comment)
       VALUES ($1, $2, $3, $4)`,
      [reviewerId, targetId, rating, comment]
    );

    res.json({ message: 'Đã gửi đánh giá' });
  } catch (err) {
    console.error('[Auth] addReview error:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      name, bio, phone, location,
      // Student
      university, major, skills, free_time, experience,
      // Employer
      company_name, company_field, company_website,
      company_address, company_desc,
    } = req.body;

    const result = await query(
      `UPDATE users SET
        name            = COALESCE($1, name),
        bio             = COALESCE($2, bio),
        phone           = COALESCE($3, phone),
        location        = COALESCE($4, location),
        university      = COALESCE($5, university),
        major           = COALESCE($6, major),
        skills          = COALESCE($7, skills),
        free_time       = COALESCE($8, free_time),
        experience      = COALESCE($9, experience),
        company_name    = COALESCE($10, company_name),
        company_field   = COALESCE($11, company_field),
        company_website = COALESCE($12, company_website),
        company_address = COALESCE($13, company_address),
        company_desc    = COALESCE($14, company_desc),
        updated_at      = NOW()
       WHERE id = $15
       RETURNING id, email, name, role, avatar_url, bio, phone, location,
                 university, major, skills, cv_url, free_time, experience,
                 company_name, company_field, company_website, company_address,
                 company_logo, company_desc, is_verified, created_at, updated_at`,
      [
        name, bio, phone, location,
        university, major, skills ? skills : null, free_time, experience,
        company_name, company_field, company_website, company_address, company_desc,
        userId,
      ]
    );

    res.json({
      message: 'Cập nhật hồ sơ thành công',
      user: result.rows[0],
    });
  } catch (err) {
    console.error('[Auth] updateProfile error:', err);
    res.status(500).json({ error: 'Lỗi server khi cập nhật hồ sơ' });
  }
};

// ── PUT /auth/change-password ──────────────────────────────────────────────────
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Vui lòng nhập mật khẩu cũ và mới' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Mật khẩu mới phải có ít nhất 6 ký tự' });
    }

    const result = await query('SELECT password FROM users WHERE id = $1', [req.user.id]);
    const match = await bcrypt.compare(currentPassword, result.rows[0].password);
    if (!match) {
      return res.status(401).json({ error: 'Mật khẩu hiện tại không đúng' });
    }

    const hashed = await bcrypt.hash(newPassword, 12);
    await query('UPDATE users SET password = $1, updated_at = NOW() WHERE id = $2', [hashed, req.user.id]);

    res.json({ message: 'Đổi mật khẩu thành công' });
  } catch (err) {
    console.error('[Auth] changePassword error:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ── GET /students ────────────────────────────────────────────────────────────
const getStudents = async (req, res) => {
  try {
    const { q, skill, university } = req.query;
    let sql = `SELECT id, email, name, role, avatar_url, skills, location, bio, university, major, experience
               FROM users
               WHERE role = 'student' AND is_active = TRUE`;
    const params = [];

    if (q) {
      params.push(`%${q}%`);
      sql += ` AND (name ILIKE $${params.length} OR email ILIKE $${params.length} OR bio ILIKE $${params.length})`;
    }

    if (skill) {
      params.push(skill);
      sql += ` AND $${params.length} = ANY(skills)`;
    }

    if (university) {
      params.push(`%${university}%`);
      sql += ` AND university ILIKE $${params.length}`;
    }

    sql += ` ORDER BY created_at DESC`;

    const result = await query(sql, params);
    res.json(result.rows);
  } catch (err) {
    console.error('[Auth] getStudents error:', err);
    res.status(500).json({ error: 'Lỗi server khi lấy danh sách sinh viên' });
  }
};

module.exports = {
  register,
  login,
  verifyEmail,
  resendCode,
  googleLogin,
  getMe,
  getStudents,
  updateProfile,
  changePassword,
  getReviewStats,
  addReview,
};
