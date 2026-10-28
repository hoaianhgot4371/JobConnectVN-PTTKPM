const { query } = require('./src/config/database');

const fixDatabase = async () => {
  try {
    console.log('🔄 Đang tạo các bảng còn thiếu...');

    // Tạo bảng job_interactions
    await query(`
      CREATE TABLE IF NOT EXISTS job_interactions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        job_id INTEGER REFERENCES jobs(id) ON DELETE CASCADE,
        type VARCHAR(20) NOT NULL, -- 'like', 'save', 'share'
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, job_id, type)
      );
    `);
    console.log('✅ Bảng job_interactions đã sẵn sàng.');

    // Tạo bảng user_reviews (đánh giá ứng viên/nhà tuyển dụng)
    await query(`
      CREATE TABLE IF NOT EXISTS user_reviews (
        id SERIAL PRIMARY KEY,
        reviewer_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        target_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        rating INTEGER CHECK (rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);
    console.log('✅ Bảng user_reviews đã sẵn sàng.');

    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi fix DB:', err);
    process.exit(1);
  }
};

fixDatabase();

