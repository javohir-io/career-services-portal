const pool = require('../db/pool');

function rowToJob(row) {
  if (!row) return null;
  return {
    id: row.id,
    title: row.title,
    company: row.company,
    location: row.location,
    logoAsset: row.logo_asset,
    tags: row.tags || [],
    description: row.description,
    requirements: row.requirements || [],
    companyAbout: row.company_about,
    imageUrl: row.image_url,
    createdAt: row.created_at,
  };
}

async function listAll({ search } = {}) {
  if (search) {
    const { rows } = await pool.query(
      `SELECT * FROM jobs
       WHERE lower(title) LIKE $1
          OR lower(company) LIKE $1
          OR lower(location) LIKE $1
       ORDER BY created_at DESC`,
      [`%${search.toLowerCase()}%`]
    );
    return rows.map(rowToJob);
  }

  const { rows } = await pool.query('SELECT * FROM jobs ORDER BY created_at DESC');
  return rows.map(rowToJob);
}

async function findByIds(ids) {
  if (ids.length === 0) return [];
  const { rows } = await pool.query('SELECT * FROM jobs WHERE id = ANY($1)', [
    ids,
  ]);
  return rows.map(rowToJob);
}

async function findById(id) {
  const { rows } = await pool.query('SELECT * FROM jobs WHERE id = $1', [id]);
  return rowToJob(rows[0]);
}

async function create(job) {
  const { rows } = await pool.query(
    `INSERT INTO jobs
       (id, title, company, location, logo_asset, tags, description, requirements, company_about, image_url)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
     RETURNING *`,
    [
      job.id,
      job.title,
      job.company,
      job.location,
      job.logoAsset || 'default',
      job.tags || [],
      job.description,
      job.requirements || [],
      job.companyAbout || '',
      job.imageUrl || null,
    ]
  );
  return rowToJob(rows[0]);
}

async function update(id, fields) {
  const columnByField = {
    title: 'title',
    company: 'company',
    location: 'location',
    logoAsset: 'logo_asset',
    tags: 'tags',
    description: 'description',
    requirements: 'requirements',
    companyAbout: 'company_about',
    imageUrl: 'image_url',
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
    `UPDATE jobs SET ${setClauses.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
    values
  );
  return rowToJob(rows[0]);
}

async function remove(id) {
  const { rowCount } = await pool.query('DELETE FROM jobs WHERE id = $1', [id]);
  return rowCount > 0;
}

async function count() {
  const { rows } = await pool.query('SELECT COUNT(*)::int AS count FROM jobs');
  return rows[0].count;
}

module.exports = {
  listAll,
  findByIds,
  findById,
  create,
  update,
  remove,
  count,
};
