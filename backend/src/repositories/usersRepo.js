const pool = require('../db/pool');

function rowToUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    passwordHash: row.password_hash,
    university: row.university,
    degreeProgram: row.degree_program,
    phone: row.phone,
    about: row.about,
    title: row.title,
    profilePhotoUrl: row.profile_photo_url,
    createdAt: row.created_at,
  };
}

async function findByEmail(email) {
  const { rows } = await pool.query(
    'SELECT * FROM users WHERE lower(email) = lower($1)',
    [email]
  );
  return rowToUser(rows[0]);
}

async function findById(id) {
  const { rows } = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
  return rowToUser(rows[0]);
}

async function create(user) {
  const { rows } = await pool.query(
    `INSERT INTO users
       (id, name, email, password_hash, university, degree_program, phone, about, title)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
     RETURNING *`,
    [
      user.id,
      user.name,
      user.email,
      user.passwordHash,
      user.university || '',
      user.degreeProgram || '',
      user.phone || '',
      user.about || '',
      user.title || 'Student',
    ]
  );
  return rowToUser(rows[0]);
}

async function update(id, fields) {
  const columnByField = {
    name: 'name',
    university: 'university',
    degreeProgram: 'degree_program',
    phone: 'phone',
    about: 'about',
    profilePhotoUrl: 'profile_photo_url',
  };

  const setClauses = [];
  const values = [];
  let paramIndex = 1;

  for (const [field, column] of Object.entries(columnByField)) {
    if (fields[field] !== undefined) {
      setClauses.push(`${column} = $${paramIndex}`);
      values.push(fields[field]);
      paramIndex += 1;
    }
  }

  if (setClauses.length === 0) return findById(id);

  values.push(id);
  const { rows } = await pool.query(
    `UPDATE users SET ${setClauses.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
    values
  );
  return rowToUser(rows[0]);
}

async function listAll() {
  const { rows } = await pool.query(
    'SELECT * FROM users ORDER BY created_at DESC'
  );
  return rows.map(rowToUser);
}

async function count() {
  const { rows } = await pool.query('SELECT COUNT(*)::int AS count FROM users');
  return rows[0].count;
}

module.exports = { findByEmail, findById, create, update, listAll, count };
