const { query } = require('../config/database');

const toTextArray = (value, fallback = []) => {
  if (value === undefined || value === null) return fallback;

  let items = value;
  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed) return fallback;

    try {
      const parsed = JSON.parse(trimmed);
      items = Array.isArray(parsed) ? parsed : [trimmed];
    } catch (_) {
      items = trimmed.split(',');
    }
  }

  if (!Array.isArray(items)) return fallback;

  return items
    .map((item) => String(item).trim())
    .filter((item) => item.length > 0);
};

/**
 * ── POST /jobs ──
 * Đăng tin tuyển dụng mới
 */
const createJob = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Kiểm tra xác thực
    const userRes = await query('SELECT is_verified FROM users WHERE id = $1', [userId]);
    if (!userRes.rows[0].is_verified) {
      return res.status(403).json({ error: 'Bạn cần xác thực tài khoản để đăng bài tuyển dụng' });
    }

    const {
      title, description, salary, location,
      type = 'Part-time', shift, skills = [],
      requirements = [], benefits = [], expires_at,
      category = 'Khác',
      is_active = true,
    } = req.body;

    if (!title || !description) {
      return res.status(400).json({ error: 'Tiêu đề và mô tả là bắt buộc' });
    }

    const result = await query(
      `INSERT INTO jobs
         (user_id, title, description, salary, location, type, shift,
          skills, requirements, benefits, expires_at, category, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8::text[], $9::text[], $10::text[], $11, $12, $13)
       RETURNING *, 0::int AS applicant_count`,
      [
        userId, title, description, salary, location,
        type, shift, toTextArray(skills), toTextArray(requirements),
        toTextArray(benefits), expires_at || null, category, is_active
      ]
    );

    console.log(`[Jobs] Đã tạo công việc ID: ${result.rows[0].id} cho User: ${userId}`);
    res.status(201).json({ message: 'Đăng bài thành công', job: result.rows[0] });
  } catch (err) {
    console.error('[Jobs] createJob error:', err);
    res.status(500).json({ error: 'Lỗi server khi đăng bài' });
  }
};

/**
 * ── GET /jobs/employer/mine ──
 * Lấy danh sách tin đã đăng của chính Nhà tuyển dụng
 */
const getMyJobs = async (req, res) => {
  try {
    const userId = req.user.id;
    console.log(`[Jobs] Truy xuất tin đăng cho Nhà tuyển dụng ID: ${userId}`);
    
    const result = await query(
      `SELECT j.*, 
              (SELECT COUNT(*) FROM applications a WHERE a.job_id = j.id)::int AS applicant_count
       FROM jobs j
       WHERE j.user_id = $1
       ORDER BY j.created_at DESC`,
      [userId]
    );

    console.log(`[Jobs] Tìm thấy ${result.rows.length} tin đăng.`);
    res.json({ jobs: result.rows });
  } catch (err) {
    console.error('[Jobs] getMyJobs error:', err);
    res.status(500).json({ error: 'Không thể tải danh sách tin đã đăng' });
  }
};

/**
 * ── GET /jobs ──
 * Lấy danh sách việc làm (Công khai)
 */
const getJobs = async (req, res) => {
  try {
    const { search, location, type, category, limit = 20, offset = 0 } = req.query;
    const currentUserId = req.user?.id || 0;

    let filter = 'WHERE j.is_active = TRUE';
    const params = [];

    if (search) {
      params.push(`%${search}%`);
      filter += ` AND (j.title ILIKE $${params.length} OR j.description ILIKE $${params.length})`;
    }
    if (location) {
      params.push(`%${location}%`);
      filter += ` AND j.location ILIKE $${params.length}`;
    }
    if (type) {
      params.push(type);
      filter += ` AND j.type = $${params.length}`;
    }
    if (category) {
      params.push(category);
      filter += ` AND j.category = $${params.length}`;
    }

    const countRes = await query(`SELECT COUNT(*) FROM jobs j ${filter}`, params);

    const result = await query(
      `SELECT j.*, u.name as employer_name, u.company_name, u.company_logo,
              (SELECT EXISTS(SELECT 1 FROM job_interactions WHERE job_id = j.id AND user_id = $${params.length + 1} AND type = 'save')) as is_saved
       FROM jobs j
       JOIN users u ON j.user_id = u.id
       ${filter}
       ORDER BY j.created_at DESC
       LIMIT $${params.length + 2} OFFSET $${params.length + 3}`,
      [...params, currentUserId, parseInt(limit), parseInt(offset)]
    );

    res.json({
      total: parseInt(countRes.rows[0].count),
      jobs: result.rows,
    });
  } catch (err) {
    console.error('[Jobs] getJobs error:', err);
    res.status(500).json({ error: 'Lỗi lấy danh sách việc làm' });
  }
};

/**
 * ── GET /jobs/:id ──
 */
const getJobById = async (req, res) => {
  try {
    const { id } = req.params;
    await query('UPDATE jobs SET views = views + 1 WHERE id = $1', [id]);

    const result = await query(
      `SELECT j.*, u.name AS employer_name, u.company_name, u.company_logo, u.company_desc,
              (SELECT COUNT(*) FROM applications a WHERE a.job_id = j.id)::int AS applicant_count
       FROM jobs j
       JOIN users u ON j.user_id = u.id
       WHERE j.id = $1`,
      [id]
    );

    if (!result.rows.length) return res.status(404).json({ error: 'Không tìm thấy công việc' });
    res.json({ job: result.rows[0] });
  } catch (err) {
    console.error('[Jobs] getJobById error:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

/**
 * ── PUT /jobs/:id ──
 */
const updateJob = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const owned = await query('SELECT id FROM jobs WHERE id = $1 AND user_id = $2', [id, userId]);
    if (!owned.rows.length) return res.status(403).json({ error: 'Không có quyền sửa bài này' });

    const { title, description, salary, location, type, shift, skills, requirements, benefits, is_active, expires_at, category } = req.body;
    
    const result = await query(
      `WITH updated AS (
        UPDATE jobs SET 
          title=COALESCE($1,title), description=COALESCE($2,description), salary=COALESCE($3,salary), 
          location=COALESCE($4,location), type=COALESCE($5,type), shift=COALESCE($6,shift), 
          skills=COALESCE($7::text[],skills), requirements=COALESCE($8::text[],requirements), benefits=COALESCE($9::text[],benefits), 
          is_active=COALESCE($10,is_active), expires_at=COALESCE($11,expires_at), category=COALESCE($12,category), 
          updated_at=NOW()
         WHERE id=$13 RETURNING *
       )
       SELECT updated.*,
              (SELECT COUNT(*) FROM applications a WHERE a.job_id = updated.id)::int AS applicant_count
       FROM updated`,
      [
        title, description, salary, location, type, shift, 
        skills === undefined ? null : toTextArray(skills), 
        requirements === undefined ? null : toTextArray(requirements), 
        benefits === undefined ? null : toTextArray(benefits), 
        is_active, expires_at, category, id
      ]
    );
    res.json({ message: 'Cập nhật thành công', job: result.rows[0] });
  } catch (err) {
    console.error('[Jobs] updateJob error:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

/**
 * ── DELETE /jobs/:id ──
 */
const deleteJob = async (req, res) => {
  try {
    const { id } = req.params;
    const owned = await query('SELECT id FROM jobs WHERE id = $1 AND user_id = $2', [id, req.user.id]);
    if (!owned.rows.length) return res.status(403).json({ error: 'Không có quyền xoá bài này' });
    await query('DELETE FROM jobs WHERE id = $1', [id]);
    res.json({ message: 'Xoá bài thành công' });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server' });
  }
};

/**
 * ── POST /jobs/:id/interact ──
 */
const interactJob = async (req, res) => {
  try {
    const { id } = req.params;
    const { type } = req.body; // 'save'
    const userId = req.user.id;
    if (type !== 'save') return res.status(400).json({ error: 'Loại tương tác không hợp lệ' });

    const exists = await query('SELECT id FROM job_interactions WHERE user_id=$1 AND job_id=$2 AND type=$3', [userId, id, type]);
    if (exists.rows.length) {
      await query('DELETE FROM job_interactions WHERE id=$1', [exists.rows[0].id]);
      return res.json({ action: 'removed' });
    }

    await query('INSERT INTO job_interactions (user_id,job_id,type) VALUES ($1,$2,$3)', [userId, id, type]);
    res.json({ action: 'added' });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server' });
  }
};

module.exports = { createJob, getJobs, getJobById, updateJob, deleteJob, getMyJobs, interactJob };
