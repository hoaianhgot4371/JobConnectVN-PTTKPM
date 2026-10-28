const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload dirs exist
const UPLOAD_DIR = path.join(__dirname, '../../uploads');
['cv', 'avatar', 'company', 'chat'].forEach(dir => {
  const full = path.join(UPLOAD_DIR, dir);
  if (!fs.existsSync(full)) fs.mkdirSync(full, { recursive: true });
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let subdir = 'chat';
    if (file.fieldname === 'cv')     subdir = 'cv';
    if (file.fieldname === 'avatar') subdir = 'avatar';
    if (file.fieldname === 'logo')   subdir = 'company';
    cb(null, path.join(UPLOAD_DIR, subdir));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const uniqueName = `${req.user?.id || 'anon'}_${Date.now()}${ext}`;
    cb(null, uniqueName);
  },
});

const fileFilter = (req, file, cb) => {
  const allowedImages = /jpeg|jpg|png|webp/;
  const allowedDocs   = /pdf|doc|docx/;
  const ext = path.extname(file.originalname).toLowerCase().replace('.', '');

  if (file.fieldname === 'cv' && allowedDocs.test(ext)) return cb(null, true);
  if ((file.fieldname === 'avatar' || file.fieldname === 'logo') && allowedImages.test(ext)) return cb(null, true);
  if (file.fieldname === 'file' && (allowedImages.test(ext) || allowedDocs.test(ext))) return cb(null, true);

  cb(new Error(`File type .${ext} không được hỗ trợ`));
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

module.exports = { upload };
