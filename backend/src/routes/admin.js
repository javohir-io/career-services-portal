const express = require('express');
const usersRepo = require('../repositories/usersRepo');
const jobsRepo = require('../repositories/jobsRepo');
const savedJobsRepo = require('../repositories/savedJobsRepo');
const applicationsRepo = require('../repositories/applicationsRepo');
const interviewsRepo = require('../repositories/interviewsRepo');
const { adminMiddleware } = require('../middleware/admin');

const router = express.Router();
router.use(adminMiddleware);

function publicUser(user) {
  const { passwordHash, ...rest } = user;
  return rest;
}

async function attachJobInfo(records) {
  const jobIds = [...new Set(records.map((r) => r.jobId))];
  const jobs = await jobsRepo.findByIds(jobIds);
  const jobById = new Map(jobs.map((j) => [j.id, j]));
  return records.map((r) => ({
    ...r,
    job: jobById.get(r.jobId)
      ? { title: jobById.get(r.jobId).title, company: jobById.get(r.jobId).company }
      : null,
  }));
}

// GET /api/admin/stats — quick counts, useful for "is anything happening?"
router.get('/stats', async (req, res, next) => {
  try {
    const [users, jobs, savedJobs, applications, interviews] =
      await Promise.all([
        usersRepo.count(),
        jobsRepo.count(),
        savedJobsRepo.count(),
        applicationsRepo.count(),
        interviewsRepo.count(),
      ]);
    res.json({ users, jobs, savedJobs, applications, interviews });
  } catch (err) {
    next(err);
  }
});

// GET /api/admin/users — every registered student (no password hashes)
router.get('/users', async (req, res, next) => {
  try {
    const users = await usersRepo.listAll();
    res.json({ users: users.map(publicUser) });
  } catch (err) {
    next(err);
  }
});

// GET /api/admin/applications — every submitted resume/application
router.get('/applications', async (req, res, next) => {
  try {
    const applications = await applicationsRepo.listAll();
    res.json({ applications: await attachJobInfo(applications) });
  } catch (err) {
    next(err);
  }
});

// GET /api/admin/interviews — every scheduled interview
router.get('/interviews', async (req, res, next) => {
  try {
    const interviews = await interviewsRepo.listAll();
    res.json({ interviews: await attachJobInfo(interviews) });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
