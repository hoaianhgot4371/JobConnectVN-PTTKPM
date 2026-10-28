const { pool } = require('./src/config/database');

async function addCategoryColumn() {
  try {
    console.log('--- Adding category column to jobs table ---');
    await pool.query('ALTER TABLE jobs ADD COLUMN IF NOT EXISTS category VARCHAR(100)');
    console.log('Column "category" added successfully.');
  } catch (err) {
    console.error('Error adding category column:', err);
  } finally {
    await pool.end();
  }
}

addCategoryColumn();

