const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const { upload } = require('../middleware/upload');

const auth    = require('../controllers/authController');
const jobs    = require('../controllers/jobController');
const users   = require('../controllers/authController');
const apply   = require('../controllers/applyController');
const ai      = require('../controllers/aiController');
const notif   = require('../controllers/notificationController');
const uploads = require('../controllers/uploadController');
const chat = require('../controllers/chatController');

// ── AUTH ──────────────────────────────────────────────────────────────────────
router.post('/auth/register',         auth.register);
router.post('/auth/login',            auth.login);
router.post('/auth/google',           auth.googleLogin);
router.post('/auth/verify',           verifyToken, auth.verifyEmail);
router.post('/auth/resend-code',      verifyToken, auth.resendCode);
router.get ('/auth/me',               verifyToken, auth.getMe);
router.get ('/students',              verifyToken, requireRole('employer'), auth.getStudents);
router.put ('/auth/profile',          verifyToken, auth.updateProfile);
router.put ('/auth/change-password',  verifyToken, auth.changePassword);
router.get ('/auth/reputation/:userId', verifyToken, auth.getReviewStats);
router.post('/auth/reputation',         verifyToken, auth.addReview);

// ── CHAT ──────────────────────────────────────────────────────────────────────
router.get ('/chat/conversations',    verifyToken, chat.getConversations);
router.get ('/chat/messages/:conversationId', verifyToken, chat.getMessages);
router.post('/chat/send',             verifyToken, chat.sendMessage);

// ── JOBS ──────────────────────────────────────────────────────────────────────
router.get ('/jobs',                  jobs.getJobs);
router.get ('/jobs/employer/mine',    verifyToken, requireRole('employer'), jobs.getMyJobs);
router.get ('/jobs/:id',              jobs.getJobById);
router.post('/jobs',                  verifyToken, requireRole('employer'), jobs.createJob);
router.put ('/jobs/:id',              verifyToken, requireRole('employer'), jobs.updateJob);
router.delete('/jobs/:id',            verifyToken, requireRole('employer'), jobs.deleteJob);
router.post('/jobs/:id/interact',     verifyToken, jobs.interactJob);

// ── APPLY ─────────────────────────────────────────────────────────────────────
router.post('/apply',                 verifyToken, requireRole('student'),
  upload.single('cv'), apply.applyJob);
router.get ('/applications',          verifyToken, apply.getApplications);
router.put ('/applications/:id/status', verifyToken, requireRole('employer'),
  apply.updateApplicationStatus);

// ── AI ────────────────────────────────────────────────────────────────────────
router.get('/recommended-jobs',       verifyToken, requireRole('student'), ai.getRecommendedJobs);
router.get('/recommended-candidates', verifyToken, requireRole('employer'), ai.getRecommendedCandidates);
router.get('/ai/jobs/:id/analysis',   verifyToken, requireRole('student'), ai.analyzeJobFit);
router.get('/profile-analysis',       verifyToken, ai.analyzeProfile);
router.post('/ai/chat',               verifyToken, ai.chatWithAI);

// ── NOTIFICATIONS ─────────────────────────────────────────────────────────────
router.get('/notifications',          verifyToken, notif.getNotifications);
router.put('/notifications/:id/read', verifyToken, notif.markRead);

// ── UPLOADS ───────────────────────────────────────────────────────────────────
router.post('/upload/avatar',         verifyToken, upload.single('avatar'),  uploads.uploadAvatar);
router.post('/upload/cv',             verifyToken, upload.single('cv'),      uploads.uploadCV);
router.delete('/upload/cv',           verifyToken,                           uploads.deleteCV);
router.post('/upload/logo',           verifyToken, requireRole('employer'), upload.single('logo'), uploads.uploadCompanyLogo);

module.exports = router;
