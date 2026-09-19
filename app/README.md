# Career Services Portal — Flutter App (Now Wired to a Real Backend)

A Flutter implementation of the "University Internship & Career Services
Portal" Figma design, now connected to a real Node/Express REST API
(see the separate `career_portal_backend` project) instead of mock data.

## Screens included

| Screen | File |
|---|---|
| Splash (restores session, preloads jobs) | `lib/screens/splash_screen.dart` |
| Log In | `lib/screens/login_screen.dart` |
| Register | `lib/screens/register_screen.dart` |
| Home / Job listings (search) | `lib/screens/home_jobs_screen.dart` |
| Saved internships | `lib/screens/saved_jobs_screen.dart` |
| Student Dashboard (profile) | `lib/screens/student_dashboard_screen.dart` |
| Edit Profile | `lib/screens/edit_profile_screen.dart` |
| Job Detail (Description / Company tabs) | `lib/screens/job_detail_screen.dart` |
| Resume Submission (real file upload) | `lib/screens/resume_submission_screen.dart` |
| Interview Scheduling (calendar) | `lib/screens/interview_scheduling_screen.dart` |
| Booking Confirmation | `lib/screens/booking_confirmation_screen.dart` |
| Bottom-nav shell (Home / Saved / Profile) | `lib/screens/main_nav_screen.dart` |

## Architecture

```
lib/
  models/          Job, AppUser — plain data classes with fromJson()
  services/        ApiClient (base HTTP + auth token), AuthService,
                    JobService, ApplicationService, InterviewService
  state/           AppState — ChangeNotifier holding session + job list,
                    calls into services and notifies screens
  screens/         UI, one file per screen
  widgets/         Shared UI pieces (form fields, job cards, etc.)
  theme/           Centralized colors/typography
```

Screens never call `http` directly — they call `AppStateScope.of(context)`
methods (`login`, `register`, `loadJobs`, `toggleSaved`, `updateProfile`,
`logout`) or a service directly for one-off actions
(`ApplicationService.submitApplication`, `InterviewService.scheduleInterview`).
`ApiClient` centralizes the base URL, auth header, JSON parsing, and
turns any non-2xx response into an `ApiException` with the server's
error message.

## 1. Run the backend first

```bash
cd career_portal_backend
npm install
cp .env.example .env
npm start
```

This starts the API at `http://localhost:3000`. See that project's
README for the full endpoint reference.

## 2. Point the Flutter app at it

The API base URL is compiled in via `--dart-define` (see
`lib/services/api_client.dart`). Default is `http://localhost:3000`,
which works for:
- Windows/macOS/Linux desktop
- Chrome (web)
- iOS Simulator

If you're using the **Android emulator**, `localhost` refers to the
emulator itself, not your machine — use the special alias instead:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

For a **physical device**, use your computer's LAN IP (both devices
must be on the same network) and make sure your firewall allows
inbound connections on port 3000:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.23:3000
```

## 3. Install Flutter dependencies & run

```bash
flutter pub get
flutter create .        # only needed once, to generate platform folders
flutter run -d chrome   # or -d windows, -d <device-id>, etc.
```

## What's real now vs. still mocked

**Real (talks to the backend):**
- Register / Login (JWT stored via `shared_preferences`, restored on
  app restart)
- Job listing + search
- Save/unsave (bookmark) a job — persisted server-side per user
- Edit Profile (name, university, degree, phone, about)
- Resume submission — real multipart file upload (PDF/DOC/DOCX)
- Interview scheduling — persisted server-side

**Still front-end only / not wired up:**
- "Forgot password" button (no-op)
- Google / Apple sign-in buttons (decorative — no OAuth wired up)
- Push notifications (the bell icon is decorative)
- Company logos are still colored icon badges — see
  `lib/widgets/company_logo.dart` for how to swap in real images

## Next steps for production

- Swap `shared_preferences` token storage for `flutter_secure_storage`
  (more appropriate for auth tokens; skipped here to avoid extra native
  setup for the MVP).
- Add token refresh / expiry handling — right now an expired token just
  logs the user out silently on next launch (see `AppState.bootstrap`).
- Point the backend at a real database (see the backend README).
- Add proper error/empty/loading states polish, retry with backoff, etc.

