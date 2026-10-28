const { pool } = require('./database');

const runMigration = async () => {
  const client = await pool.connect();
  try {
    console.log('[Migration] Adding verification columns to users table...');
    await client.query('BEGIN');

    await client.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE,
      ADD COLUMN IF NOT EXISTS verification_code VARCHAR(10);
    `);

    // Fix jobs table missing category column
    console.log('[Migration] Checking jobs table columns...');
    await client.query(`
      ALTER TABLE jobs
      ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'Khác';
    `);

    await client.query('COMMIT');
    console.log('[Migration] ✅ Successfully added is_verified and verification_code columns');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[Migration] ❌ Error:', err);
  } finally {
    client.release();
    process.exit();
  }
};

runMigration();
