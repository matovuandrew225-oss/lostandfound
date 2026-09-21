# Lost & Found

Lost & Found is a university community platform for reporting lost property, posting found items, searching active listings, and securely reconnecting owners with their belongings.

This repository contains the Flutter client only. A private Replit backend owns authentication, PostgreSQL, file storage, authorization, business logic, admin APIs, and audit logging. The client never connects directly to PostgreSQL and never contains database credentials.

## Current foundation

- Material 3 responsive Flutter application for mobile, tablet, desktop preview, and Flutter Web.
- API-backed email authentication, registration, password reset, and secure session persistence.
- Responsive student home with search, lost/found actions, recent listings, profile, and sign out.
- Backend API-backed lost/found report flow with categories and optional image upload.
- A typed API client boundary that keeps HTTP and session handling out of widgets.
- Model, repository, widget-state, loading, empty, error, and success handling.

## Technology

- Flutter / Dart
- Replit backend REST API
- PostgreSQL, private storage, and server-enforced roles behind the API
- Material 3

## Project structure

```text
lib/
  core/          configuration and theme
  models/        domain models
  services/      API client and repositories
  screens/       auth, setup, home, search, reports, profile
  widgets/       reusable listing cards
test/            Dart and Flutter tests
```

## Backend contract

The backend should expose the following frontend-facing routes:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/session`
- `POST /api/auth/password-reset`
- `GET /api/items`
- `POST /api/items`
- `POST /api/items/:id/images`
- `GET /api/categories`

The backend must validate inputs, enforce roles, scope data to the authenticated user, and return consistent JSON responses. Admin routes and database migrations belong in the private Replit backend and are intentionally not tracked in this frontend repository.

## Run locally in VS Code

Install Flutter 3.22+ and an Android, iOS, or Chrome target, then run:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://your-replit-backend.example/api
```

For Chrome:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://your-replit-backend.example/api
```

The app stops on a configuration screen when the required public values are absent. This is deliberate so a deployment never silently runs with fake data.

## Validation

```bash
flutter analyze
flutter test
flutter build web
```

Flutter is not installed in the Replit environment used to create this initial foundation, so these commands must be run in a Flutter-enabled VS Code environment after installing dependencies.

## Security

- Passwords are handled by the private backend and are never stored by this client.
- Database credentials, private storage credentials, JWT secrets, and service keys stay in Replit Secrets.
- Authorization is enforced by the backend, not by hidden Flutter buttons.
- Admin access and audit logging are server-side concerns.
- The client stores only the session token required to call the API, using platform secure storage.
- Keep `.env` and production configuration out of Git. The included `.env.example` contains placeholders only.

## GitHub workflow

Work from the original repository root, review `git diff`, run the Flutter checks, commit with a meaningful message, and push to the configured remote. Do not force-push or reset shared history.

## Roadmap

The next phases are: item details, claim review, secure conversations, notifications, saved items, admin dashboard/CMS, moderation, analytics, backend integration tests, and Flutter-enabled build validation.