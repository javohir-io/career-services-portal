const express = require('express');
const { v4: uuid } = require('uuid');
const jobsRepo = require('../repositories/jobsRepo');
const savedJobsRepo = require('../repositories/savedJobsRepo');
const { authMiddleware } = require('../middleware/auth');
const { adminMiddleware } = require('../middleware/admin');
const { imageUpload, imageUrlFor } = require('../middleware/imageUpload');

const router = express.Router();

// GET /api/jobs?search=...
router.get('/', async (req, res, next) => {
  try {
    const { search } = req.query;
    const jobs = await jobsRepo.listAll({ search });
    res.json({ jobs });
  } catch (err) {
    next(err);
  }
});

// GET /api/jobs/saved (auth required) — must be declared before /:id
router.get('/saved', authMiddleware, async (req, res, next) => {
  try {
    const savedIds = await savedJobsRepo.listSavedJobIds(req.userId);
    const jobs = await jobsRepo.findByIds(savedIds);
    res.json({ jobs: jobs.map((j) => ({ ...j, isSaved: true })) });
  } catch (err) {
    next(err);
  }
});

// GET /api/jobs/:id
router.get('/:id', async (req, res, next) => {
  try {
    const job = await jobsRepo.findById(req.params.id);
    if (!job) return res.status(404).json({ error: 'Job not found' });
    res.json({ job });
  } catch (err) {
    next(err);
  }
});

// POST /api/jobs/:id/save (auth required) — toggles saved state
router.post('/:id/save', authMiddleware, async (req, res, next) => {
  try {
    const job = await jobsRepo.findById(req.params.id);
    if (!job) return res.status(404).json({ error: 'Job not found' });

    const isSaved = await savedJobsRepo.toggle(req.userId, job.id);
    res.json({ jobId: job.id, isSaved });
  } catch (err) {
    next(err);
  }
});

// ---- Admin-only job management (requires x-admin-key header) ----

// POST /api/jobs — create a new job posting
router.post('/', adminMiddleware, async (req, res, next) => {
  try {
    const {
      title,
      company,
      location,
      logoAsset,
      tags,
      description,
      requirements,
      companyAbout,
    } = req.body;

    if (!title || !company || !location || !description) {
      return res.status(400).json({
        error: 'title, company, location and description are required',
      });
    }

    const job = await jobsRepo.create({
      id: uuid(),
      title,
      company,
      location,
      logoAsset,
      tags,
      description,
      requirements,
      companyAbout,
    });
    res.status(201).json({ job });
  } catch (err) {
    next(err);
  }
});

// PUT /api/jobs/:id — update an existing job posting
router.put('/:id', adminMiddleware, async (req, res, next) => {
  try {
    const existing = await jobsRepo.findById(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Job not found' });

    const job = await jobsRepo.update(req.params.id, req.body);
    res.json({ job });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/jobs/:id — remove a job posting
router.delete('/:id', adminMiddleware, async (req, res, next) => {
  try {
    const deleted = await jobsRepo.remove(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Job not found' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// POST /api/jobs/:id/image — upload/replace a job's cover image
// (admin key required, multipart/form-data, file field name: "image")
router.post('/:id/image', adminMiddleware, (req, res, next) => {
  imageUpload.single('image')(req, res, async (err) => {
    if (err) return res.status(400).json({ error: err.message });

    try {
      const existing = await jobsRepo.findById(req.params.id);
      if (!existing) return res.status(404).json({ error: 'Job not found' });
      if (!req.file) {
        return res.status(400).json({ error: 'image file is required' });
      }

      const job = await jobsRepo.update(req.params.id, {
        imageUrl: imageUrlFor(req.file.filename),
      });
      res.json({ job });
    } catch (dbErr) {
      next(dbErr);
    }
  });
});

module.exports = router;
