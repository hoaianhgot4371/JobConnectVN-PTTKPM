const { pool } = require('./database');

async function runChatMigration() {
  const client = await pool.connect();
  try {
    console.log('[DB] 🔄 Running chat migrations...');

    // Create conversations table
    await client.query(`
      CREATE TABLE IF NOT EXISTS conversations (
        id SERIAL PRIMARY KEY,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Create conversation_participants table
    await client.query(`
      CREATE TABLE IF NOT EXISTS conversation_participants (
        conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        PRIMARY KEY (conversation_id, user_id)
      );
    `);

    // Create messages table
    // job_id is optional, used for sharing a job post
    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        conversation_id INTEGER REFERENCES conversations(id) ON DELETE CASCADE,
        sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        message_text TEXT,
        message_type VARCHAR(20) DEFAULT 'text', -- 'text', 'job_share'
        job_id INTEGER REFERENCES jobs(id) ON DELETE SET NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('[DB] ✅ Chat tables created successfully');
  } catch (err) {
    console.error('[DB] ❌ Chat migration error:', err);
  } finally {
    client.release();
  }
}

module.exports = runChatMigration;

