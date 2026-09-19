const pool = require('../db/pool');

function rowToApplication(row) {
  if (!row) return null;
  return {
    id: row.id,
    userId: row.user_id,
    jobId: row.job_id,
    firstName: row.first_name,
    lastName: row.last_name,
    address: row.address,
    city: row.city,
    university: row.university,
    phone: row.phone,
    email: row.email,
    skillLevel: row.skill_level,
    resumeFileName: row.resume_file_name,
    resumeOriginalName: row.resume_original_name,
    resumeUrl: row.resume_url,
    createdAt: row.created_at,
  };
}

async function create(app) {
  const { rows } = await pool.query(
    `INSERT INTO applications
       (id, user_id, job_id, first_name, last_name, address, city, university,
        phone, email, skill_level, resume_file_name, resume_original_name, resume_url)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
     RETURNING *`,
    [
      app.id,
      app.userId,
      app.jobId,
      app.firstName,
      app.lastName,
      app.address || '',
      app.city || '',
      app.university || '',
      app.phone,
      app.email,
      app.skillLevel,
      app.resumeFileName,
      app.resumeOriginalName,
      app.resumeUrl,
    ]
  );
  return rowToApplication(rows[0]);
}

async function listForUser(userId) {
  const { rows } = await pool.query(
    'SELECT * FROM applications WHERE user_id = $1 ORDER BY created_at DESC',
    [userId]
  );
  return rows.map(rowToApplication);
}

async function listAll() {
  const { rows } = await pool.query(
    'SELECT * FROM applications ORDER BY created_at DESC'
  );
  return rows.map(rowToApplication);
}

async function count() {
  const { rows } = await pool.query(
    'SELECT COUNT(*)::int AS count FROM applications'
  );
  return rows[0].count;
}

module.exports = { create, listForUser, listAll, count };
