const { pool } = require('./src/config/database');

async function fixJobsTable() {
  try {
    console.log('--- Bắt đầu sửa bảng "jobs" ---');

    // 1. Thêm các cột nếu thiếu
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS user_id INT');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT \'Khác\'');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS views INT DEFAULT 0');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS skills JSONB DEFAULT \'[]\'');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS requirements JSONB DEFAULT \'[]\'');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS benefits JSONB DEFAULT \'[]\'');

    // 2. Gắn các tin đăng "mồ côi" (không có user_id) cho tài khoản đầu tiên hoặc tài khoản test (tuỳ chọn)
    // Nếu bạn đã có dữ liệu, hãy đảm bảo các tin đăng có user_id đúng với id của bạn trong bảng users.
    
    // 3. Chuẩn hoá dữ liệu null
    await pool.query("UPDATE jobs SET is_active = TRUE WHERE is_active IS NULL");
    await pool.query("UPDATE jobs SET category = 'Khác' WHERE category IS NULL");
    await pool.query("UPDATE jobs SET skills = '[]' WHERE skills IS NULL");

    console.log('--- Sửa bảng jobs thành công! ---');
  } catch (err) {
    console.error('--- Lỗi fixJobsTable:', err);
  } finally {
    await pool.end();
  }
}

fixJobsTable();
