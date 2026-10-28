require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const path    = require('path');
const { createTables } = require('./config/migrate');
const runChatMigration = require('./config/chat_migration');

const app  = express();
const PORT = process.env.PORT || 3001;

// ── Middleware ────────────────────────────────────────────────────────────────
app.use(cors({
  origin: '*', // Replace with your Flutter app origin in production
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Static files (uploads) ────────────────────────────────────────────────────
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'JobConnect VN API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api', require('./routes/index'));

// ── 404 handler ───────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.path} không tồn tại` });
});

// ── Global error handler ──────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('[Server] Unhandled error:', err);

  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ error: 'File quá lớn (tối đa 10MB)' });
  }
  if (err.message?.includes('không được hỗ trợ')) {
    return res.status(400).json({ error: err.message });
  }

  res.status(500).json({ error: 'Lỗi server không xác định' });
});

// ── Startup ───────────────────────────────────────────────────────────────────
async function start() {
    try {
        console.log('[Server] 🔄 Running database migrations...');
        await createTables();
        await runChatMigration(); // Run chat migration

        app.listen(PORT, '0.0.0.0', () => {
            console.log(`[Server] 🚀 Server running on http://0.0.0.0:${PORT}`);
        });
    } catch (err) {
        console.error('[Server] ❌ Failed to start server:', err);
        process.exit(1);
    }
}

start();
