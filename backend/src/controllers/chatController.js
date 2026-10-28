const { query } = require('../config/database');

async function getOrCreateConversation(currentUserId, otherUserId) {
  const result = await query(`
    SELECT conversation_id FROM conversation_participants
    WHERE user_id IN ($1, $2)
    GROUP BY conversation_id HAVING COUNT(DISTINCT user_id) = 2
  `, [currentUserId, otherUserId]);

  if (result.rows.length > 0) return result.rows[0].conversation_id;

  const newConv = await query('INSERT INTO conversations DEFAULT VALUES RETURNING id');
  const convId = newConv.rows[0].id;
  await query('INSERT INTO conversation_participants (conversation_id, user_id) VALUES ($1, $2), ($1, $3)',
    [convId, currentUserId, otherUserId]);

  return convId;
}

exports.getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await query(`
      SELECT c.id, c.updated_at,
        (SELECT json_build_object('id', u.id, 'name', u.name, 'avatar', u.avatar_url)
         FROM users u JOIN conversation_participants cp2 ON cp2.user_id = u.id
         WHERE cp2.conversation_id = c.id AND u.id != $1 LIMIT 1) as other_user,
        (SELECT json_build_object('text', m.message_text, 'type', m.message_type, 'created_at', m.created_at)
         FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message
      FROM conversations c
      JOIN conversation_participants cp ON cp.conversation_id = c.id
      WHERE cp.user_id = $1 ORDER BY c.updated_at DESC
    `, [userId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    let { conversationId } = req.params;
    const { otherUserId } = req.query;

    // Nếu ID là null hoặc 0, thử tìm theo otherUserId
    if (!conversationId || conversationId === 'null' || conversationId === '0') {
      if (otherUserId) {
        const convResult = await query(`
          SELECT conversation_id FROM conversation_participants 
          WHERE user_id IN ($1, $2)
          GROUP BY conversation_id HAVING COUNT(DISTINCT user_id) = 2
        `, [userId, otherUserId]);
        if (convResult.rows.length > 0) conversationId = convResult.rows[0].conversation_id;
        else return res.json([]); // Chưa có lịch sử
      } else return res.status(400).json({ error: 'Thiếu ID' });
    }

    const result = await query(`
      SELECT m.*, (m.sender_id = $1) as is_me, j.title as job_title
      FROM messages m
      LEFT JOIN jobs j ON m.job_id = j.id
      WHERE m.conversation_id = $2::int
      ORDER BY m.created_at ASC
    `, [userId, conversationId]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.sendMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { conversationId, otherUserId, message, type, jobId } = req.body;
    let convId = conversationId;
    if ((!convId || convId === 0) && otherUserId) {
      convId = await getOrCreateConversation(senderId, otherUserId);
    }
    const result = await query(`
      INSERT INTO messages (conversation_id, sender_id, message_text, message_type, job_id)
      VALUES ($1, $2, $3, $4, $5) RETURNING *, true as is_me
    `, [convId, senderId, message, type || 'text', jobId || null]);
    await query('UPDATE conversations SET updated_at = NOW() WHERE id = $1', [convId]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
