const { query } = require('../config/database');

const parseNullableDate = (value) => {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
};

// ── POST /apply ─────────────────────────────────────────────────────────────
const applyJob = async (req, res) => {
  try {
    // Check verification
    const user = await query('SELECT is_verified FROM users WHERE id = $1', [req.user.id]);
    if (!user.rows[0].is_verified) {
      return res.status(403).json({ error: 'Bạn cần xác thực tài khoản để ứng tuyển công việc' });
    }

    const { job_id, cover_letter } = req.body;
    const userId = req.user.id;

    if (!job_id) {
      return res.status(400).json({ error: 'job_id là bắt buộc' });
    }

    // Check job exists
    const jobResult = await query(
      'SELECT id, user_id, title FROM jobs WHERE id = $1 AND is_active = TRUE',
      [job_id]
    );
    if (!jobResult.rows.length) {
      return res.status(404).json({ error: 'Không tìm thấy công việc' });
    }
    if (jobResult.rows[0].user_id === userId) {
      return res.status(400).json({ error: 'Không thể ứng tuyển vào bài của chính mình' });
    }

    // CV url: use uploaded file or from user profile
    let cvUrl = req.file ? `/uploads/cv/${req.file.filename}` : null;
    if (!cvUrl) {
      const userResult = await query('SELECT cv_url FROM users WHERE id = $1', [userId]);
      cvUrl = userResult.rows[0]?.cv_url || null;
    }

    // Calculate basic match score
    const [userProfileResult, jobSkillsResult] = await Promise.all([
      query('SELECT skills, location FROM users WHERE id = $1', [userId]),
      query('SELECT skills, location FROM jobs WHERE id = $1', [job_id]),
    ]);

    const userSkills = userProfileResult.rows[0]?.skills || [];
    const jobSkills = jobSkillsResult.rows[0]?.skills || [];
    const userLocation = userProfileResult.rows[0]?.location || '';
    const jobLocation = jobSkillsResult.rows[0]?.location || '';

    let skillScore = 0;
    if (jobSkills.length > 0) {
      const matched = userSkills.filter(s =>
        jobSkills.some(js => js.toLowerCase() === s.toLowerCase())
      ).length;
      skillScore = Math.round((matched / jobSkills.length) * 100);
    }
    const locationScore = userLocation && jobLocation &&
      userLocation.toLowerCase().includes(jobLocation.toLowerCase()) ? 100 : 0;
    const matchScore = Math.round(0.7 * skillScore + 0.3 * locationScore);

    const result = await query(
      `INSERT INTO applications (job_id, user_id, cv_url, cover_letter, match_score)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [job_id, userId, cvUrl, cover_letter, matchScore]
    );

    // Create notification for employer
    await query(
      `INSERT INTO notifications (user_id, type, title, body, ref_id, ref_type)
       VALUES ($1, 'new_application', 'Ứng viên mới', $2, $3, 'application')`,
      [
        jobResult.rows[0].user_id,
        `${req.user.name} vừa ứng tuyển vào "${jobResult.rows[0].title}"`,
        result.rows[0].id,
      ]
    );

    res.status(201).json({
      message: 'Ứng tuyển thành công',
      application: result.rows[0],
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Bạn đã ứng tuyển vào công việc này rồi' });
    }
    console.error('[Apply] applyJob error:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ── GET /applications?type=sent|received ──────────────────────────────────────
const getApplications = async (req, res) => {
  try {
    const { type = 'sent', status, job_id, page = 1, limit = 50 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let params = [req.user.id];
    let sql;

    if (type === 'sent') {
      // Student: applications they sent
      let filter = 'WHERE a.user_id = $1';
      if (status) {
        params.push(status);
        filter += ` AND a.status = $${params.length}`;
      }
      sql = `
        SELECT a.*, j.title, j.salary, j.location, j.type, j.shift,
               u.name AS employer_name, u.company_name, u.company_logo
        FROM applications a
        JOIN jobs j ON a.job_id = j.id
        JOIN users u ON j.user_id = u.id
        ${filter}
        ORDER BY a.created_at DESC
        LIMIT ${parseInt(limit)} OFFSET ${offset}
      `;
    } else {
      // Employer: applications received for their jobs
      let filter = 'WHERE j.user_id = $1';
      
      if (job_id) {
        params.push(job_id);
        filter += ` AND a.job_id = $${params.length}`;
      }
      
      if (status) {
        params.push(status);
        filter += ` AND a.status = $${params.length}`;
      }

      sql = `
        SELECT a.*, j.title AS job_title, j.id AS job_id,
               u.name, u.email, u.avatar_url, u.skills, u.university, u.major,
               u.location AS applicant_location
        FROM applications a
        JOIN jobs j ON a.job_id = j.id
        JOIN users u ON a.user_id = u.id
        ${filter}
        ORDER BY a.match_score DESC, a.created_at DESC
        LIMIT ${parseInt(limit)} OFFSET ${offset}
      `;
    }

    const result = await query(sql, params);
    res.json({ applications: result.rows });
  } catch (err) {
    console.error('[Apply] getApplications error:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ── PUT /applications/:id/status ──────────────────────────────────────────────
const updateApplicationStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, status_note, note, interview_at, interview_location } = req.body;

    const validStatuses = ['pending', 'viewed', 'interview', 'accepted', 'rejected'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Trạng thái không hợp lệ' });
    }

    // Verify employer owns the job
    const check = await query(
      `SELECT a.id, a.user_id, j.title
       FROM applications a
       JOIN jobs j ON a.job_id = j.id
       WHERE a.id = $1 AND j.user_id = $2`,
      [id, req.user.id]
    );
    if (!check.rows.length) {
      return res.status(403).json({ error: 'Không có quyền cập nhật đơn này' });
    }

    const normalizedNote = (status_note || note || '').toString().trim() || null;
    const normalizedInterviewAt = parseNullableDate(interview_at);
    const normalizedInterviewLocation =
      (interview_location || '').toString().trim() || null;

    const result = await query(
      `UPDATE applications
       SET status = $1::varchar,
           status_note = COALESCE($3, status_note),
           interview_at = CASE
             WHEN $1::text = 'interview' THEN COALESCE($4, interview_at)
             ELSE interview_at
           END,
           interview_location = CASE
             WHEN $1::text = 'interview' THEN COALESCE($5, interview_location)
             ELSE interview_location
           END,
           updated_at = NOW()
       WHERE id = $2 RETURNING *`,
      [status, id, normalizedNote, normalizedInterviewAt, normalizedInterviewLocation]
    );

    // Notify applicant
    const statusMessages = {
      viewed:    'Hồ sơ của bạn đã được xem',
      interview: 'Bạn được mời phỏng vấn!',
      accepted:  '🎉 Chúc mừng! Bạn đã được nhận',
      rejected:  'Rất tiếc, hồ sơ của bạn chưa phù hợp lần này',
    };
    if (statusMessages[status]) {
      const details = [`Đơn ứng tuyển "${check.rows[0].title}"`];
      if (status === 'interview') {
        if (normalizedInterviewAt) {
          details.push(`Thời gian: ${normalizedInterviewAt.toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' })}`);
        }
        if (normalizedInterviewLocation) {
          details.push(`Địa điểm/link: ${normalizedInterviewLocation}`);
        }
      }
      if (normalizedNote) {
        details.push(`Ghi chú: ${normalizedNote}`);
      }

      await query(
        `INSERT INTO notifications (user_id, type, title, body, ref_id, ref_type)
         VALUES ($1, 'application_update', $2, $3, $4, 'application')`,
        [
          check.rows[0].user_id,
          statusMessages[status],
          details.join('\n'),
          id,
        ]
      );
    }

    res.json({ message: 'Cập nhật trạng thái thành công', application: result.rows[0] });
  } catch (err) {
    console.error('[Apply] updateStatus error:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

module.exports = { applyJob, getApplications, updateApplicationStatus };
