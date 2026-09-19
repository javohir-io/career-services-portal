# Career Services Portal — Backend API

A REST API built with Node.js + Express, backed by **PostgreSQL**, for
the Flutter app. Includes a small built-in admin web page for managing
job postings and viewing signups/applications/interviews.

## 1. Install PostgreSQL

If you don't already have it:

- **Windows**: download the installer from
  [postgresql.org/download/windows](https://www.postgresql.org/download/windows/)
  (or `winget install PostgreSQL.PostgreSQL`). During setup you'll set
  a password for the `postgres` superuser — remember it.
- **macOS**: `brew install postgresql@16 && brew services start postgresql@16`
- **Linux**: `sudo apt install postgresql` (Debian/Ubuntu) then
  `sudo systemctl start postgresql`

Then create a database for this project. Easiest via the command line:

```bash
# Windows: open "SQL Shell (psql)" from the Start menu instead, or:
psql -U postgres -c "CREATE DATABASE career_portal;"
```

(Or use pgAdmin, which installs alongside PostgreSQL on Windows/macOS —
right-click "Databases" → Create → Database → name it `career_portal`.)

## 2. Configure and install

```bash
cd career_portal_backend
npm install
cp .env.example .env      # on Windows (PowerShell): copy .env.example .env
```

Open `.env` and set `DATABASE_URL` to match what you set up in step 1:

```
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/career_portal
```

Also set `JWT_SECRET` and `ADMIN_API_KEY` to your own random strings
(anything long and unguessable works for local dev).

## 3. Create the tables

```bash
npm run migrate
```

This creates the `users`, `jobs`, `saved_jobs`, `applications`, and
`interviews` tables if they don't exist yet, and seeds 3 sample jobs
if the `jobs` table is empty. Safe to re-run any time.

> **Already had this running before?** Re-run `npm run migrate` after
> pulling an update — it only adds new columns/tables with
> `IF NOT EXISTS`, so your existing users/jobs/applications are safe.

## 4. Start the server

```bash
npm start
```

Server runs at `http://localhost:3000`. Uploaded resumes are saved
under `uploads/` and served at `http://localhost:3000/uploads/<filename>`.
Every request is also logged to this terminal window as it happens.

Use `npm run dev` instead of `npm start` to auto-restart on file
changes (uses Node's built-in `--watch`, no nodemon needed).

## 5. Open the admin panel

Go to **http://localhost:3000/admin** in your browser. Enter the
`ADMIN_API_KEY` you set in `.env` to unlock it. From there you can:

- See live counts (Overview tab)
- Add / edit / delete job postings (Jobs tab) — these show up in the
  Flutter app immediately on next refresh
- Browse registered students (Users tab)
- Browse submitted applications, including a link to each uploaded
  resume (Applications tab)
- Browse scheduled interviews (Interviews tab)

This is a single self-contained HTML page (`public/admin/index.html`)
with no build step — open it in a text editor if you want to tweak
the styling or add fields.

**Security note:** the admin key is a simple shared secret (like a
password), not a full login system with sessions/roles. Fine for local
development or a small trusted team; if you deploy this publicly,
put the `/admin` path and `/api/admin/*` routes behind something
stronger (a VPN, IP allowlist, or a real admin-user table with
sessions) before sharing the URL.

## Connecting from the Flutter app

- **Android emulator**: use `http://10.0.2.2:3000` as the base URL
  (the emulator's alias for your machine's `localhost`).
- **iOS simulator / macOS / Windows desktop / Chrome**: use
  `http://localhost:3000` directly.
- **Physical device**: use your computer's LAN IP, e.g.
  `http://192.168.1.23:3000`, and make sure your firewall allows
  inbound connections on port 3000.

This is set in the Flutter app at `lib/services/api_client.dart` via
`--dart-define=API_BASE_URL=...` (see the Flutter README).

## Auth

All authenticated endpoints expect:

```
Authorization: Bearer <token>
```

The token is returned from `/api/auth/register` and `/api/auth/login`.

## API Reference

### Auth

| Method | Path | Auth | Body | Response |
|---|---|---|---|---|
| POST | `/api/auth/register` | No | `{ name, email, password, university?, phone? }` | `{ token, user }` |
| POST | `/api/auth/login` | No | `{ email, password }` | `{ token, user }` |
| GET | `/api/auth/me` | Yes | — | `{ user }` |
| PUT | `/api/auth/me` | Yes | `{ name?, university?, degreeProgram?, phone?, about? }` | `{ user }` |
| POST | `/api/auth/me/photo` | Yes | `multipart/form-data`, file field `photo` (jpg/png/webp/gif, ≤5MB) | `{ user }` |

`user` shape: `{ id, name, email, university, degreeProgram, phone, about, title, profilePhotoUrl, createdAt }`

### Jobs

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/api/jobs?search=` | No | Returns `{ jobs: [...] }`, optional case-insensitive search across title/company/location |
| GET | `/api/jobs/saved` | Yes | Returns the current user's saved/bookmarked jobs |
| GET | `/api/jobs/:id` | No | Returns `{ job }` |
| POST | `/api/jobs/:id/save` | Yes | Toggles save state, returns `{ jobId, isSaved }` |
| POST | `/api/jobs` | Admin key | Create a job posting |
| PUT | `/api/jobs/:id` | Admin key | Update a job posting |
| DELETE | `/api/jobs/:id` | Admin key | Delete a job posting |
| POST | `/api/jobs/:id/image` | Admin key | Upload/replace a job's cover image — `multipart/form-data`, file field `image` (jpg/png/webp/gif, ≤5MB) |

### Applications (resume submission)

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/api/applications` | Yes | `multipart/form-data` with fields `jobId, firstName, lastName, address, city, university, phone, email, skillLevel` and file field `resume` (pdf/doc/docx, ≤10MB) |
| GET | `/api/applications` | Yes | Returns the current user's submitted applications |

### Interviews

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/api/interviews` | Yes | `{ jobId, applicationId?, date (ISO 8601), timeSlot, reason? }` |
| GET | `/api/interviews` | Yes | Returns the current user's scheduled interviews |

### Health check

`GET /api/health` → `{ status, database, time }` — also verifies the
database connection is alive, not just that the server process is up.

### Admin (requires `x-admin-key` header — same as `/admin` page)

| Method | Path | Notes |
|---|---|---|
| GET | `/api/admin/stats` | Counts of users/jobs/savedJobs/applications/interviews |
| GET | `/api/admin/users` | All registered users (no password hashes) |
| GET | `/api/admin/applications` | All submitted applications, with job title/company attached |
| GET | `/api/admin/interviews` | All scheduled interviews, with job title/company attached |

## Project structure

```
src/
  db/
    pool.js        PostgreSQL connection pool
    schema.sql      CREATE TABLE statements (all IDs are TEXT, not UUID —
                     keeps human-readable slugs for seed jobs)
    seedJobs.js     The 3 sample jobs, used by migrate.js
    migrate.js      Run via `npm run migrate`
  repositories/      One file per table — all raw SQL lives here
    usersRepo.js
    jobsRepo.js
    savedJobsRepo.js
    applicationsRepo.js
    interviewsRepo.js
  middleware/
    auth.js          Verifies the student's JWT
    admin.js          Verifies the x-admin-key header
  routes/            Express routes — call repositories, never raw SQL directly
public/
  admin/index.html   The admin web page (served at /admin)
uploads/             Uploaded resumes (created automatically)
```

## Next steps for production

- Replace the shared-secret admin key with a real admin-user table +
  session/JWT-based login if this will ever be reachable outside your
  own machine.
- Move uploaded resumes to cloud storage (S3, GCS) instead of local
  disk once you deploy.
- Restrict CORS (`app.use(cors())` in `src/server.js`) to your actual
  app's origin(s) in production.
- Add rate limiting (`express-rate-limit`) on `/api/auth/*`.
- Add input validation (e.g. `zod` or `express-validator`) for stricter
  request checking than the manual checks currently in each route.
- Add a connection-pool health check / retry on startup so the server
  fails fast with a clear message if Postgres isn't reachable yet.
