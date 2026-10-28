const { pool } = require('./src/config/database');

async function fixChat() {
  try {
    console.log('--- Fixing Chat Schema ---');

    // Drop old tables to ensure clean state and correct columns
    await pool.query('DROP TABLE IF EXISTS messages CASCADE');
    await pool.query('DROP TABLE IF EXISTS conversation_participants CASCADE');
    await pool.query('DROP TABLE IF EXISTS conversations CASCADE');

    // 1. Create Conversations table
    await pool.query(`
      CREATE TABLE conversations (
        id SERIAL PRIMARY KEY,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // 2. Create Conversation Participants table
    await pool.query(`
      CREATE TABLE conversation_participants (
        conversation_id INT REFERENCES conversations(id) ON DELETE CASCADE,
        user_id INT REFERENCES users(id) ON DELETE CASCADE,
        PRIMARY KEY (conversation_id, user_id)
      );
    `);

    // 3. Create Messages table
    await pool.query(`
      CREATE TABLE messages (
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

    console.log('--- Chat Schema Fixed Successfully ---');
  } catch (err) {
    console.error('--- Error fixing chat schema ---');
    console.error(err);
  } finally {
    await pool.end();
  }
}

fixChat();
