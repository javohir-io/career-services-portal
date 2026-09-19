const express = require('express');
const multer = require('multer');
const path = require('path');
const { v4: uuid } = require('uuid');
const jobsRepo = require('../repositories/jobsRepo');
const applicationsRepo = require('../repositories/applicationsRepo');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${uuid()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (req, file, cb) => {
    const allowed = ['.pdf', '.doc', '.docx'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (!allowed.includes(ext)) {
      return cb(new Error('Only PDF, DOC, or DOCX files are allowed'));
    }
    cb(null, true);
  },
});

// POST /api/applications (auth required, multipart/form-data)
// Fields: jobId, firstName, lastName, address, city, university, phone,
// email, skillLevel. File field name: "resume".
router.post('/', authMiddleware, (req, res, next) => {
  upload.single('resume')(req, res, async (err) => {
    if (err) return res.status(400).json({ error: err.message });

    try {
      const {
        jobId,
        firstName,
        lastName,
        address,
        city,
        university,
        phone,
        email,
        skillLevel,
      } = req.body;

      if (
        !jobId ||
        !firstName ||
        !lastName ||
        !phone ||
        !email ||
        !skillLevel
      ) {
        return res.status(400).json({ error: 'Missing required fields' });
      }
      if (!req.file) {
        return res.status(400).json({ error: 'Resume file is required' });
      }

      const job = await jobsRepo.findById(jobId);
      if (!job) return res.status(404).json({ error: 'Job not found' });

      const application = await applicationsRepo.create({
        id: uuid(),
        userId: req.userId,
        jobId,
        firstName,
        lastName,
        address,
        city,
        university,
        phone,
        email,
        skillLevel,
        resumeFileName: req.file.filename,
        resumeOriginalName: req.file.originalname,
        resumeUrl: `/uploads/${req.file.filename}`,
      });

      res.status(201).json({ application });
    } catch (dbErr) {
      next(dbErr);
    }
  });
});

// GET /api/applications (auth required) - the logged-in user's applications
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const applications = await applicationsRepo.listForUser(req.userId);
    res.json({ applications });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
