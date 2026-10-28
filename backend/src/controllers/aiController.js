const axios = require('axios');
const { query } = require('../config/database');

const calcMatchScore = (user, job) => {
  const userSkills = (user.skills || []).map((skill) => skill.toLowerCase());
  const jobSkills = (job.skills || []).map((skill) => skill.toLowerCase());

  let skillScore = 0;
  if (jobSkills.length > 0) {
    const matched = userSkills.filter((skill) => jobSkills.includes(skill)).length;
    skillScore = matched / jobSkills.length;
  }

  let locationScore = 0;
  if (user.location && job.location) {
    const userLocation = user.location.toLowerCase();
    const jobLocation = job.location.toLowerCase();
    if (userLocation === jobLocation) locationScore = 1;
    else if (userLocation.includes(jobLocation) || jobLocation.includes(userLocation)) {
      locationScore = 0.6;
    }
  }

  let experienceScore = 0.5;
  if (user.experience && job.description) {
    const keywordCount = (user.skills || []).filter((skill) =>
      job.description.toLowerCase().includes(skill.toLowerCase())
    ).length;
    experienceScore = Math.min(1, 0.4 + keywordCount * 0.1);
  }

  const total = Math.round((0.5 * skillScore + 0.3 * locationScore + 0.2 * experienceScore) * 100);
  return Math.max(0, Math.min(100, total));
};

const normalizeText = (value) => {
  return (value || '')
    .toString()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .trim();
};

const asArray = (value) => {
  if (!value) return [];
  if (Array.isArray(value)) return value.map((item) => item.toString()).filter(Boolean);
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) return parsed.map((item) => item.toString()).filter(Boolean);
    } catch (_) {}
    return value.split(',').map((item) => item.trim()).filter(Boolean);
  }
  return [];
};

const hasTextMatch = (left, right) => {
  const normalizedLeft = normalizeText(left);
  const normalizedRight = normalizeText(right);
  if (!normalizedLeft || !normalizedRight) return false;
  return normalizedLeft.includes(normalizedRight) || normalizedRight.includes(normalizedLeft);
};

const getMatchedSkills = (userSkills, jobSkills) => {
  return userSkills.filter((userSkill) =>
    jobSkills.some((jobSkill) => hasTextMatch(userSkill, jobSkill))
  );
};

const buildRecommendation = (user, job) => {
  const userSkills = asArray(user.skills);
  const jobSkills = asArray(job.skills);
  const requirements = asArray(job.requirements);
  const matchedSkills = getMatchedSkills(userSkills, jobSkills);
  const missingSkills = jobSkills
    .filter((jobSkill) => !matchedSkills.some((matchedSkill) => hasTextMatch(matchedSkill, jobSkill)))
    .slice(0, 4);

  const skillScore = jobSkills.length > 0 ? matchedSkills.length / jobSkills.length : 0.35;
  const locationScore = user.location && job.location && hasTextMatch(user.location, job.location) ? 1 : 0;
  const majorScore = user.major && (
    hasTextMatch(user.major, job.category) ||
    hasTextMatch(user.major, job.title) ||
    hasTextMatch(user.major, job.description)
  ) ? 1 : 0;
  const experienceScore = user.experience && (
    hasTextMatch(user.experience, job.title) ||
    hasTextMatch(user.experience, job.description) ||
    requirements.some((item) => hasTextMatch(user.experience, item))
  ) ? 1 : 0.35;
  const cvBonus = user.cv_url ? 0.08 : 0;

  const matchScore = Math.max(
    0,
    Math.min(
      100,
      Math.round((0.48 * skillScore + 0.18 * locationScore + 0.16 * majorScore + 0.18 * experienceScore + cvBonus) * 100)
    )
  );

  const reasons = [];
  if (matchedSkills.length > 0) {
    reasons.push(`Khop ky nang: ${matchedSkills.slice(0, 3).join(', ')}`);
  }
  if (locationScore > 0) {
    reasons.push(`Dia diem phu hop voi ${user.location}`);
  }
  if (majorScore > 0) {
    reasons.push('Nganh hoc hoac dinh huong gan voi cong viec');
  }
  if (experienceScore >= 1) {
    reasons.push('Kinh nghiem trong ho so lien quan den mo ta viec');
  }
  if (user.cv_url) {
    reasons.push('Ho so da co CV, co the ung tuyen nhanh');
  }
  if (reasons.length === 0) {
    reasons.push('Cong viec dang mo va co the phu hop de kham pha them');
  }

  let companyFit = 'Phu hop de tham khao';
  if (matchScore >= 75) companyFit = 'Rat phu hop voi ho so';
  else if (matchScore >= 55) companyFit = 'Phu hop voi ky nang hien co';
  else if (missingSkills.length > 0) companyFit = 'Can bo sung them ky nang';

  return {
    ...job,
    match_score: matchScore,
    matched_skills: matchedSkills,
    missing_skills: missingSkills,
    recommendation_reason: reasons.join(' - '),
    company_fit: companyFit,
  };
};

const getRecommendedJobs = async (req, res) => {
  try {
    const userResult = await query(
      `SELECT id, name, skills, location, experience, major, university, bio, cv_url, free_time
       FROM users WHERE id = $1`,
      [req.user.id]
    );
    const user = userResult.rows[0];

    const jobsResult = await query(
      `SELECT j.*, u.name AS employer_name, u.company_name, u.company_logo,
              u.company_desc, u.company_website, u.company_field
       FROM jobs j JOIN users u ON j.user_id = u.id
       WHERE j.is_active = TRUE
         AND j.id NOT IN (SELECT job_id FROM applications WHERE user_id = $1)
       ORDER BY j.created_at DESC LIMIT 100`,
      [user.id]
    );

    const scored = jobsResult.rows
      .map((job) => buildRecommendation(user, job))
      .sort((left, right) => right.match_score - left.match_score)
      .slice(0, 10);

    res.json({
      jobs: scored,
      profile: {
        skills: asArray(user.skills),
        major: user.major,
        location: user.location,
        has_cv: Boolean(user.cv_url),
      },
    });
  } catch (err) {
    console.error('[AI] getRecommendedJobs error:', err.message);
    res.status(500).json({ error: 'Loi server' });
  }
};

const getRecommendedCandidates = async (req, res) => {
  try {
    const { job_id } = req.query;
    const jobResult = await query(
      'SELECT * FROM jobs WHERE id = $1 AND user_id = $2',
      [job_id, req.user.id]
    );

    if (!jobResult.rows.length) {
      return res.status(403).json({ error: 'Khong co quyen' });
    }

    const job = jobResult.rows[0];
    const usersResult = await query(
      `SELECT id, name, skills, location, experience
       FROM users
       WHERE role = 'student' AND is_active = TRUE
       LIMIT 200`
    );

    const scored = usersResult.rows
      .map((user) => ({ ...user, match_score: calcMatchScore(user, job) }))
      .sort((left, right) => right.match_score - left.match_score)
      .slice(0, 20);

    res.json({ candidates: scored });
  } catch (err) {
    console.error('[AI] getRecommendedCandidates error:', err.message);
    res.status(500).json({ error: 'Loi server' });
  }
};

const analyzeJobFit = async (req, res) => {
  try {
    const { id } = req.params;

    const userResult = await query(
      `SELECT id, name, skills, location, experience, major, university, bio, cv_url, free_time
       FROM users WHERE id = $1`,
      [req.user.id]
    );
    const user = userResult.rows[0];

    const jobResult = await query(
      `SELECT j.*, u.name AS employer_name, u.company_name, u.company_logo,
              u.company_desc, u.company_website, u.company_field
       FROM jobs j
       JOIN users u ON j.user_id = u.id
       WHERE j.id = $1 AND j.is_active = TRUE`,
      [id]
    );

    if (!jobResult.rows.length) {
      return res.status(404).json({ error: 'Khong tim thay cong viec' });
    }

    const analyzedJob = buildRecommendation(user, jobResult.rows[0]);
    return res.json({
      job: analyzedJob,
      profile: {
        skills: asArray(user.skills),
        major: user.major,
        location: user.location,
        has_cv: Boolean(user.cv_url),
      },
    });
  } catch (err) {
    console.error('[AI] analyzeJobFit error:', err.message);
    res.status(500).json({ error: 'Loi server' });
  }
};

const buildAIInstructions = (prompt, context = {}, user = {}) => {
  const parts = [
    'Ban la tro ly AI cua JobConnect VN.',
    'Tra loi bang tieng Viet, ro rang, ngan gon va thuc te.',
    'Tap trung vao viec lam ban thoi gian, CV, ung tuyen, phong van va nha tuyen dung.',
  ];

  if (user.role) parts.push(`Vai tro nguoi dung: ${user.role}.`);
  if (user.name) parts.push(`Ten nguoi dung: ${user.name}.`);

  if (context && Object.keys(context).length > 0) {
    parts.push(`Ngu canh JSON: ${JSON.stringify(context).slice(0, 3000)}.`);
  }

  parts.push(`Cau hoi: ${prompt}`);
  return parts.join('\n');
};

const buildFallbackAnswer = (prompt, context = {}) => {
  const normalizedPrompt = (prompt || '').toLowerCase();
  const jobTitle = context.jobTitle || context.title;
  const companyName = context.companyName || context.company_name;

  if (normalizedPrompt.includes('cv') || normalizedPrompt.includes('resume')) {
    return [
      'AI ben ngoai hien chua kha dung, nhung ban co the cai thien CV theo cac diem sau:',
      '- Dua kinh nghiem lien quan len dau, moi y nen co ket qua cu the.',
      '- Ghi ro ca lam, dia diem co the di chuyen va ky nang phu hop.',
      '- Them 3-5 ky nang trung voi tin tuyen dung.',
      '- Xuat CV thanh PDF truoc khi nop de tranh loi dinh dang.',
    ].join('\n');
  }

  if (normalizedPrompt.includes('phong van') || normalizedPrompt.includes('interview')) {
    return [
      'Goi y chuan bi phong van:',
      '- Chuan bi phan gioi thieu ban than trong 45-60 giay.',
      '- Lay 2-3 yeu cau chinh trong mo ta viec de noi kinh nghiem tuong ung.',
      '- Hoi lai ve lich lam, luong, thu viec va cach cham cong.',
      '- Sau phong van nen gui tin nhan cam on ngan gon.',
    ].join('\n');
  }

  if (jobTitle || companyName) {
    return [
      `Voi ${jobTitle ? `cong viec "${jobTitle}"` : 'cong viec nay'}${companyName ? ` tai ${companyName}` : ''}:`,
      '- Kiem tra lich lam, dia diem va muc luong co phu hop voi ban khong.',
      '- Doi chieu ky nang cua ban voi yeu cau trong tin dang.',
      '- Khi ung tuyen, viet loi nhan ngan gon: vi sao phu hop, khi nao bat dau, lich ranh.',
      '- Neu thieu thong tin ve luong hoac ca lam, nen hoi nha tuyen dung truoc khi nhan viec.',
    ].join('\n');
  }

  return [
    'AI ben ngoai hien chua kha dung, minh tra loi nhanh theo bo quy tac cua JobConnect:',
    '- Neu ban dang tim viec: hay loc theo dia diem, ca lam va ky nang manh nhat.',
    '- Neu ban dang ung tuyen: cap nhat ho so, tai CV len va viet loi nhan ngan gon cho tung viec.',
    '- Neu ban la nha tuyen dung: mo ta ro muc luong, ca lam, yeu cau va quyen loi de tang ty le ung tuyen.',
  ].join('\n');
};

const hasApiKey = (value) => {
  return typeof value === 'string' && value.trim().length > 0;
};

const chatWithOpenAICompatibleProvider = async ({
  apiKey,
  baseUrl,
  model,
  prompt,
  provider,
}) => {
  if (!hasApiKey(apiKey)) {
    throw new Error(`${provider} API key is missing`);
  }

  const normalizedBaseUrl = baseUrl.replace(/\/+$/, '');
  const response = await axios.post(
    `${normalizedBaseUrl}/chat/completions`,
    {
      model,
      messages: [
        {
          role: 'system',
          content: 'Ban la tro ly AI cua JobConnect VN. Tra loi bang tieng Viet, ngan gon, ro rang va thuc te.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.4,
      max_tokens: 800,
    },
    {
      timeout: 30000,
      headers: {
        Authorization: `Bearer ${apiKey.trim()}`,
        'Content-Type': 'application/json',
      },
    }
  );

  const answer = response.data?.choices?.[0]?.message?.content?.trim();
  if (!answer) {
    throw new Error(`${provider} returned an empty response`);
  }

  return answer;
};

const chatWithGroq = async (prompt) => {
  return chatWithOpenAICompatibleProvider({
    provider: 'groq',
    apiKey: process.env.GROQ_API_KEY,
    baseUrl: process.env.GROQ_BASE_URL || 'https://api.groq.com/openai/v1',
    model: process.env.GROQ_MODEL || 'llama-3.1-8b-instant',
    prompt,
  });
};

const chatWithZai = async (prompt) => {
  return chatWithOpenAICompatibleProvider({
    provider: 'zai',
    apiKey: process.env.ZAI_API_KEY,
    baseUrl: process.env.ZAI_BASE_URL || 'https://api.z.ai/api/paas/v4',
    model: process.env.ZAI_MODEL || 'glm-4.5-flash',
    prompt,
  });
};

const getProviderOrder = () => {
  const provider = (process.env.AI_PROVIDER || process.env.AI_TYPE || 'groq').toLowerCase();
  if (provider === 'zai' || provider === 'z.ai') return ['zai', 'groq'];
  if (provider === 'groq' || provider === 'grod') return ['groq', 'zai'];
  return ['groq', 'zai'];
};

const runProvider = async (provider, prompt) => {
  if (provider === 'groq') return chatWithGroq(prompt);
  if (provider === 'zai') return chatWithZai(prompt);
  throw new Error(`Unsupported provider: ${provider}`);
};

const chatWithAI = async (req, res) => {
  const { prompt, message, context = {} } = req.body || {};
  const userPrompt = (prompt || message || '').trim();

  if (!userPrompt) {
    return res.status(400).json({ error: 'Noi dung khong hop le' });
  }

  const providerOrder = getProviderOrder();
  const fullPrompt = buildAIInstructions(userPrompt, context, req.user);

  for (const provider of providerOrder) {
    try {
      const answer = await runProvider(provider, fullPrompt);
      return res.json({ answer, source: provider });
    } catch (err) {
      console.error(`[AI] ${provider} failed:`, err.message);
    }
  }

  return res.json({
    answer: buildFallbackAnswer(userPrompt, context),
    source: 'fallback',
  });
};

const analyzeProfile = async (req, res) => {
  res.json({
    message: 'Chuc nang dang bao tri',
  });
};

module.exports = {
  getRecommendedJobs,
  getRecommendedCandidates,
  analyzeJobFit,
  analyzeProfile,
  chatWithAI,
};
