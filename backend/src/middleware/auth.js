const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

// Simple in-memory cache to reduce DB hits on every request
const userCache = new Map();
const CACHE_TTL = 60 * 1000; // 1 minute

// ── Verify JWT token ────────────────────────────────────────────────────────
const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Không có token xác thực' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    // Check cache first
    const cached = userCache.get(userId);
    if (cached && (Date.now() - cached.timestamp < CACHE_TTL)) {
      req.user = cached.user;
      return next();
    }

    // Fetch fresh user from DB if not in cache or expired
    const result = await query(
      'SELECT id, email, name, role, avatar_url, skills, location, is_active FROM users WHERE id = $1',
      [userId]
    );

    if (!result.rows.length || !result.rows[0].is_active) {
      return res.status(401).json({ error: 'Tài khoản không hợp lệ hoặc đã bị vô hiệu hoá' });
    }

    const user = result.rows[0];
    req.user = user;
    
    // Update cache
    userCache.set(userId, { user, timestamp: Date.now() });
    
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token đã hết hạn, vui lòng đăng nhập lại' });
    }
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Token không hợp lệ' });
    }
    console.error('[Auth] verifyToken error:', err);
    res.status(500).json({ error: 'Lỗi xác thực' });
  }
};

// ── Require specific role ───────────────────────────────────────────────────
const requireRole = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user.role)) {
    return res.status(403).json({
      error: `Chức năng này yêu cầu vai trò: ${roles.join(' hoặc ')}`,
    });
  }
  next();
};

// ── Optional auth (attach user if token present, else continue) ─────────────
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      req.user = null;
      return next();
    }
    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    // Check cache for optional auth too
    const cached = userCache.get(userId);
    if (cached && (Date.now() - cached.timestamp < CACHE_TTL)) {
      req.user = cached.user;
      return next();
    }

    const result = await query(
      'SELECT id, email, name, role, avatar_url, skills, location FROM users WHERE id = $1 AND is_active = TRUE',
      [userId]
    );
    req.user = result.rows[0] || null;
    
    if (req.user) {
      userCache.set(userId, { user: req.user, timestamp: Date.now() });
    }
  } catch {
    req.user = null;
  }
  next();
};

module.exports = { verifyToken, requireRole, optionalAuth };
