const pool = require('../db/pool');

function rowToInterview(row) {
  if (!row) return null;
  return {
    id: row.id,
    userId: row.user_id,
    jobId: row.job_id,
    applicationId: row.application_id,
    date: row.date,
    timeSlot: row.time_slot,
    reason: row.reason,
    status: row.status,
    createdAt: row.created_at,
  };
}

async function create(interview) {
  const { rows } = await pool.query(
    `INSERT INTO interviews
       (id, user_id, job_id, application_id, date, time_slot, reason, status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
     RETURNING *`,
    [
      interview.id,
      interview.userId,
      interview.jobId,
      interview.applicationId || null,
      interview.date,
      interview.timeSlot,
      interview.reason || '',
      interview.status || 'scheduled',
    ]
  );
  return rowToInterview(rows[0]);
}

async function listForUser(userId) {
  const { rows } = await pool.query(
    'SELECT * FROM interviews WHERE user_id = $1 ORDER BY date DESC',
    [userId]
  );
  return rows.map(rowToInterview);
}

async function listAll() {
  const { rows } = await pool.query(
    'SELECT * FROM interviews ORDER BY date DESC'
  );
  return rows.map(rowToInterview);
}

async function count() {
  const { rows } = await pool.query(
    'SELECT COUNT(*)::int AS count FROM interviews'
  );
  return rows[0].count;
}

module.exports = { create, listForUser, listAll, count };
