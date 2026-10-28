const { pool } = require('./src/config/database');

async function fix() {
  try {
    console.log('--- Starting DB fix ---');

    // Fix users table for verification_code
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_code VARCHAR(10)');
    console.log('Column "verification_code" checked/added.');

    // Add necessary columns for verification and Gmail/Social login
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255)');
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE');
    console.log('Google login and verification columns checked/added.');

    // ── CHAT SYSTEM ─────────────────────────────────────────────────────────
    await pool.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id          SERIAL PRIMARY KEY,
        sender_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        receiver_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        content     TEXT NOT NULL,
        is_read     BOOLEAN DEFAULT FALSE,
        created_at  TIMESTAMPTZ DEFAULT NOW()
      );
    `);
    console.log('Table "messages" checked/created.');

    // ── LIKES / SHARES / FEEDS ──────────────────────────────────────────────
    await pool.query(`
      CREATE TABLE IF NOT EXISTS job_interactions (
        id          SERIAL PRIMARY KEY,
        user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        job_id      INT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
        type        VARCHAR(20) NOT NULL CHECK (type IN ('like', 'share', 'save')),
        created_at  TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(user_id, job_id, type)
      );
    `);
    console.log('Table "job_interactions" checked/created.');

    // ── REVIEWS / REPUTATION ────────────────────────────────────────────────
    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_reviews (
        id          SERIAL PRIMARY KEY,
        target_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        reviewer_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment     TEXT,
        role        VARCHAR(20) NOT NULL, -- role of the target being reviewed
        created_at  TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(target_id, reviewer_id)
      );
    `);
    console.log('Table "user_reviews" checked/created.');

    console.log('--- DB fix completed successfully ---');
  } catch (err) {
    console.error('--- DB fix failed ---');
    console.error(err);
  } finally {
    await pool.end();
  }
}

fix();

