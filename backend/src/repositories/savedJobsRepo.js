const pool = require('../db/pool');

async function isSaved(userId, jobId) {
  const { rows } = await pool.query(
    'SELECT 1 FROM saved_jobs WHERE user_id = $1 AND job_id = $2',
    [userId, jobId]
  );
  return rows.length > 0;
}

/** Toggles saved state and returns the new state (true = now saved). */
async function toggle(userId, jobId) {
  const alreadySaved = await isSaved(userId, jobId);

  if (alreadySaved) {
    await pool.query(
      'DELETE FROM saved_jobs WHERE user_id = $1 AND job_id = $2',
      [userId, jobId]
    );
    return false;
  }

  await pool.query(
    'INSERT INTO saved_jobs (user_id, job_id) VALUES ($1, $2)',
    [userId, jobId]
  );
  return true;
}

async function listSavedJobIds(userId) {
  const { rows } = await pool.query(
    'SELECT job_id FROM saved_jobs WHERE user_id = $1',
    [userId]
  );
  return rows.map((r) => r.job_id);
}

async function count() {
  const { rows } = await pool.query(
    'SELECT COUNT(*)::int AS count FROM saved_jobs'
  );
  return rows[0].count;
}

module.exports = { isSaved, toggle, listSavedJobIds, count };
