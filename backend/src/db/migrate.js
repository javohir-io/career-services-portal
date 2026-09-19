require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('./pool');
const { SEED_JOBS } = require('./seedJobs');

async function migrate() {
  console.log('Connecting to database...');
  const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf-8');

  console.log('Creating tables (if they do not already exist)...');
  await pool.query(schema);
  console.log('Schema is up to date.');

  const { rows } = await pool.query('SELECT COUNT(*)::int AS count FROM jobs');
  if (rows[0].count === 0) {
    console.log('Jobs table is empty — seeding sample internships...');
    for (const job of SEED_JOBS) {
      await pool.query(
        `INSERT INTO jobs
           (id, title, company, location, logo_asset, tags, description, requirements, company_about)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         ON CONFLICT (id) DO NOTHING`,
        [
          job.id,
          job.title,
          job.company,
          job.location,
          job.logoAsset,
          job.tags,
          job.description,
          job.requirements,
          job.companyAbout,
        ]
      );
    }
    console.log(`Seeded ${SEED_JOBS.length} sample jobs.`);
  } else {
    console.log(`Jobs table already has ${rows[0].count} row(s) — skipping seed.`);
  }

  console.log('Migration complete.');
  await pool.end();
}

migrate().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
