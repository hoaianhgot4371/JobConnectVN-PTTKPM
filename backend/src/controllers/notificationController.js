const { query } = require('../config/database');

const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 30 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const result = await query(
      `SELECT * FROM notifications
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.user.id, parseInt(limit), offset]
    );

    const unreadCount = await query(
      'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = FALSE',
      [req.user.id]
    );

    res.json({
      notifications: result.rows,
      unread_count: parseInt(unreadCount.rows[0].count),
    });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server' });
  }
};

const markRead = async (req, res) => {
  try {
    const { id } = req.params;
    if (id === 'all') {
      await query(
        'UPDATE notifications SET is_read = TRUE WHERE user_id = $1',
        [req.user.id]
      );
    } else {
      await query(
        'UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2',
        [id, req.user.id]
      );
    }
    res.json({ message: 'Đã đánh dấu đã đọc' });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server' });
  }
};

module.exports = { getNotifications, markRead };
