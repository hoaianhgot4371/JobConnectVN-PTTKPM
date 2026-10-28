const fs = require('fs/promises');
const path = require('path');
const { query } = require('../config/database');

const uploadAvatar = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Không có file được gửi lên' });
    const url = `/uploads/avatar/${req.file.filename}`;
    await query('UPDATE users SET avatar_url = $1, updated_at = NOW() WHERE id = $2', [url, req.user.id]);
    res.json({ message: 'Upload avatar thành công', avatar_url: url });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server' });
  }
};

const uploadCV = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Không có file được gửi lên' });
    const url = `/uploads/cv/${req.file.filename}`;
    await query('UPDATE users SET cv_url = $1, updated_at = NOW() WHERE id = $2', [url, req.user.id]);
    res.json({ message: 'Upload CV thành công', cv_url: url });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server' });
  }
};

const uploadCompanyLogo = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Không có file được gửi lên' });
    const url = `/uploads/company/${req.file.filename}`;
    await query('UPDATE users SET company_logo = $1, updated_at = NOW() WHERE id = $2', [url, req.user.id]);
    res.json({ message: 'Upload logo thành công', company_logo: url });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server' });
  }
};

const deleteCV = async (req, res) => {
  try {
    const result = await query('SELECT cv_url FROM users WHERE id = $1', [req.user.id]);
    const cvUrl = result.rows[0]?.cv_url;

    await query('UPDATE users SET cv_url = NULL, updated_at = NOW() WHERE id = $1', [req.user.id]);

    if (cvUrl?.startsWith('/uploads/cv/')) {
      const filePath = path.join(__dirname, '../..', cvUrl.replace(/^\/+/, ''));
      await fs.unlink(filePath).catch(() => {});
    }

    res.json({ message: 'Xoa CV thanh cong', cv_url: null });
  } catch (err) {
    res.status(500).json({ error: 'Loi server' });
  }
};

module.exports = { uploadAvatar, uploadCV, deleteCV, uploadCompanyLogo };
