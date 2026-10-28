const { pool } = require('./database');

const createTables = async () => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ── USERS ──────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id          SERIAL PRIMARY KEY,
        email       VARCHAR(255) UNIQUE NOT NULL,
        password    VARCHAR(255) NOT NULL,
        name        VARCHAR(255) NOT NULL,
        role        VARCHAR(20) NOT NULL DEFAULT 'student'
                    CHECK (role IN ('student', 'employer')),
        avatar_url  TEXT,
        bio         TEXT,
        phone       VARCHAR(20),
        location    VARCHAR(255),
        is_verified BOOLEAN DEFAULT FALSE,
        verification_code VARCHAR(10),
        google_id   VARCHAR(255),

        -- Student fields
        university  VARCHAR(255),
        major       VARCHAR(255),
        skills      TEXT[],
        cv_url      TEXT,
        free_time   VARCHAR(255),
        experience  TEXT,

        -- Employer fields
        company_name    VARCHAR(255),
        company_field   VARCHAR(255),
        company_website VARCHAR(255),
        company_address VARCHAR(255),
        company_logo    TEXT,
        company_desc    TEXT,

        is_active   BOOLEAN DEFAULT TRUE,
        created_at  TIMESTAMPTZ DEFAULT NOW(),
        updated_at  TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // ── JOBS ───────────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS jobs (
        id          SERIAL PRIMARY KEY,
        user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title       VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        salary      VARCHAR(100),
        location    VARCHAR(255),
        category    VARCHAR(100) DEFAULT 'Khác',
        type        VARCHAR(50) DEFAULT 'Part-time'
                    CHECK (type IN ('Full-time','Part-time','Internship','Remote')),
        shift       VARCHAR(100),
        skills      TEXT[],
        requirements TEXT[],
        benefits    TEXT[],
        is_active   BOOLEAN DEFAULT TRUE,
        views       INT DEFAULT 0,
        expires_at  TIMESTAMPTZ,
        created_at  TIMESTAMPTZ DEFAULT NOW(),
        updated_at  TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // ── APPLICATIONS ───────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS applications (
        id          SERIAL PRIMARY KEY,
        job_id      INT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
        user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        cv_url      TEXT,
        cover_letter TEXT,
        status      VARCHAR(30) DEFAULT 'pending'
                    CHECK (status IN ('pending','viewed','interview','accepted','rejected')),
        match_score INT DEFAULT 0,
        created_at  TIMESTAMPTZ DEFAULT NOW(),
        updated_at  TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(job_id, user_id)
      );
    `);

    await client.query(`ALTER TABLE applications ADD COLUMN IF NOT EXISTS status_note TEXT;`);
    await client.query(`ALTER TABLE applications ADD COLUMN IF NOT EXISTS interview_at TIMESTAMPTZ;`);
    await client.query(`ALTER TABLE applications ADD COLUMN IF NOT EXISTS interview_location TEXT;`);

    // ── CONVERSATIONS ──────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS conversations (
        id SERIAL PRIMARY KEY,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // ── CONVERSATION PARTICIPANTS ──────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS conversation_participants (
        conversation_id INT REFERENCES conversations(id) ON DELETE CASCADE,
        user_id INT REFERENCES users(id) ON DELETE CASCADE,
        PRIMARY KEY (conversation_id, user_id)
      );
    `);

    // ── MESSAGES ───────────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        conversation_id INT REFERENCES conversations(id) ON DELETE CASCADE,
        sender_id INT REFERENCES users(id) ON DELETE CASCADE,
        message_text TEXT NOT NULL,
        message_type VARCHAR(20) DEFAULT 'text',
        job_id INT REFERENCES jobs(id) ON DELETE SET NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // ── NOTIFICATIONS ──────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id          SERIAL PRIMARY KEY,
        user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type        VARCHAR(50) NOT NULL,
        title       VARCHAR(255) NOT NULL,
        body        TEXT,
        ref_id      INT,
        ref_type    VARCHAR(50),
        is_read     BOOLEAN DEFAULT FALSE,
        created_at  TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // ── JOB INTERACTIONS ──────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS job_interactions (
        id          SERIAL PRIMARY KEY,
        user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        job_id      INT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
        type        VARCHAR(20) NOT NULL, -- 'like', 'save', 'share'
        created_at  TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(user_id, job_id, type)
      );
    `);

    // ── USER REVIEWS ───────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_reviews (
        id          SERIAL PRIMARY KEY,
        reviewer_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        target_id   INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment     TEXT,
        created_at  TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(reviewer_id, target_id)
      );
    `);

    // ── INDEXES ────────────────────────────────────────────────────────────
    await client.query(`CREATE INDEX IF NOT EXISTS idx_jobs_user ON jobs(user_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_jobs_active ON jobs(is_active);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_apps_job ON applications(job_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_apps_user ON applications(user_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_msgs_conv ON messages(conversation_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_notifs_user ON notifications(user_id, is_read);`);

    await client.query('COMMIT');
    console.log('[DB] ✅ All tables and indexes updated successfully');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[DB] ❌ Migration failed:', err);
    throw err;
  } finally {
    client.release();
  }
};

module.exports = { createTables };
