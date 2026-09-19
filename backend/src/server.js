require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');

const pool = require('./db/pool');
const authRoutes = require('./routes/auth');
const jobsRoutes = require('./routes/jobs');
const applicationsRoutes = require('./routes/applications');
const interviewsRoutes = require('./routes/interviews');
const adminRoutes = require('./routes/admin');

// Ensure the uploads folder (and its images/ subfolder) exist on
// startup. This matters for a fresh `git clone` — uploads/ is
// gitignored on purpose (it holds user-submitted files), so it won't
// exist until the server creates it. Without this, the very first
// resume/image upload would fail with ENOENT.
const UPLOAD_ROOT = path.join(__dirname, '..', 'uploads');
fs.mkdirSync(path.join(UPLOAD_ROOT, 'images'), { recursive: true });

const app = express();

app.use(cors()); // Dev-friendly: allow all origins. Restrict in production.
app.use(morgan('dev')); // Logs every request to the console, e.g.
                         // "POST /api/auth/register 201 15.2 ms"
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
app.use('/admin', express.static(path.join(__dirname, '..', 'public', 'admin')));

app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'connected', time: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      database: 'unreachable',
      error: err.message,
    });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/jobs', jobsRoutes);
app.use('/api/applications', applicationsRoutes);
app.use('/api/interviews', interviewsRoutes);
app.use('/api/admin', adminRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: `No route for ${req.method} ${req.path}` });
});

// Generic error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Career Services Portal API running on http://localhost:${PORT}`);
  console.log(`Admin panel:  http://localhost:${PORT}/admin`);
});

