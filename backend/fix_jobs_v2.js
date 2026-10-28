const { pool } = require('./src/config/database');

async function fix() {
  try {
    console.log('--- [Fix] Bắt đầu chuẩn hóa dữ liệu Công việc ---');

    // 1. Thêm cột user_id nếu chưa có
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS user_id INT');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT \'Khác\'');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS views INT DEFAULT 0');

    // 2. Lấy ID của Nhà tuyển dụng đầu tiên (thường là tài khoản bạn đang dùng để test)
    const employerRes = await pool.query("SELECT id, name FROM users WHERE role = 'employer' LIMIT 1");
    
    if (employerRes.rows.length > 0) {
      const eid = employerRes.rows[0].id;
      const ename = employerRes.rows[0].name;
      
      // Gán tất cả tin đăng chưa có chủ cho Nhà tuyển dụng này
      const updateRes = await pool.query('UPDATE jobs SET user_id = $1 WHERE user_id IS NULL', [eid]);
      console.log(`> Đã gán ${updateRes.rowCount} tin đăng cho Nhà tuyển dụng: ${ename} (ID: ${eid})`);
    } else {
      console.log('> Cảnh báo: Không tìm thấy tài khoản Nhà tuyển dụng nào. Hãy đăng ký một tài khoản trước.');
    }

    // 3. Đảm bảo dữ liệu mảng không bị lỗi null
    await pool.query("UPDATE jobs SET skills = '[]' WHERE skills IS NULL");
    await pool.query("UPDATE jobs SET requirements = '[]' WHERE requirements IS NULL");
    await pool.query("UPDATE jobs SET benefits = '[]' WHERE benefits IS NULL");
    await pool.query("UPDATE jobs SET is_active = TRUE WHERE is_active IS NULL");

    console.log('--- [Fix] Hoàn thành! Vui lòng khởi động lại server Node.js ---');
  } catch (err) {
    console.error('--- [Fix] Lỗi thực thi:', err);
  } finally {
    await pool.end();
  }
}

fix();
