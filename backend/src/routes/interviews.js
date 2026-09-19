const express = require('express');
const { v4: uuid } = require('uuid');
const jobsRepo = require('../repositories/jobsRepo');
const interviewsRepo = require('../repositories/interviewsRepo');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// POST /api/interviews (auth required)
// Body: { jobId, applicationId?, date (ISO string), timeSlot, reason? }
router.post('/', authMiddleware, async (req, res, next) => {
  try {
    const { jobId, applicationId, date, timeSlot, reason } = req.body;

    if (!jobId || !date || !timeSlot) {
      return res
        .status(400)
        .json({ error: 'jobId, date and timeSlot are required' });
    }

    const job = await jobsRepo.findById(jobId);
    if (!job) return res.status(404).json({ error: 'Job not found' });

    const interview = await interviewsRepo.create({
      id: uuid(),
      userId: req.userId,
      jobId,
      applicationId: applicationId || null,
      date,
      timeSlot,
      reason,
      status: 'scheduled',
    });

    res.status(201).json({ interview });
  } catch (err) {
    next(err);
  }
});

// GET /api/interviews (auth required)
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const interviews = await interviewsRepo.listForUser(req.userId);
    res.json({ interviews });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
