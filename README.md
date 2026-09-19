# Lost & Found

Lost & Found is a university community platform for reporting lost property, posting found items, searching active listings, and securely reconnecting owners with their belongings.

This repository contains the Flutter client and Supabase database migration. It is intentionally backend-backed: there is no fake login or in-memory replacement for Supabase.

## Current foundation

- Material 3 responsive Flutter application for mobile, tablet, desktop preview, and Flutter Web.
- Supabase email authentication, registration, password reset, and session persistence.
- Responsive student home with search, lost/found actions, recent listings, profile, and sign out.
- Database-backed lost/found report flow with categories and optional image upload to Supabase Storage.
- Supabase PostgreSQL schema for profiles, categories, items, images, claims, messages, notifications, saved items, moderation reports, and audit logs.
- Row Level Security policies for user-owned data and a server-enforced admin role.
- Model, repository, widget-state, loading, empty, error, and success handling.

## Technology

- Flutter / Dart
- Supabase Auth, PostgreSQL, Storage, and Row Level Security
- Material 3

## Project structure

```text
lib/
  core/          configuration and theme
  models/        domain models
  services/      Supabase repositories
  screens/       auth, setup, home, search, reports, profile
  widgets/       reusable listing cards
supabase/
  migrations/    PostgreSQL schema, policies, seed categories
test/            Dart and Flutter tests
```

## Supabase setup

1. Create a Supabase project.
2. Open the SQL editor and run `supabase/migrations/20260919000000_initial_schema.sql`.
3. Enable email authentication in Supabase Auth. Configure email confirmation and SMTP for production.
4. Copy the project URL and anon key. The Flutter app must only receive the anon key; never put a service-role key in the client.
5. Create the first admin using a protected SQL session or Supabase server-side process:

   ```sql
   update public.profiles
   set role = 'ADMIN'
   where email = 'admin@your-university.example';
   ```

   Do not expose admin promotion in the Flutter UI. Replace the example address with the verified account you intend to administer.

## Run locally in VS Code

Install Flutter 3.22+ and an Android, iOS, or Chrome target, then run:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

For Chrome:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
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

- Passwords are handled by Supabase Auth and are never stored by this client.
- All sensitive tables use RLS.
- Users can only create/update/delete their own items and messages.
- Admin access is enforced through the `profiles.role` value and the `is_admin()` database function.
- Audit logs are not writable by normal users.
- Storage paths are scoped to the authenticated user.
- Keep `.env` and production configuration out of Git. The included `.env.example` contains placeholders only.

## GitHub workflow

Work from the original repository root, review `git diff`, run the Flutter checks, commit with a meaningful message, and push to the configured remote. Do not force-push or reset shared history.

## Roadmap

The schema is prepared for the next production phases: item details, claim review, secure conversations, notifications, saved items, admin dashboard, moderation, analytics, and expanded integration/security tests.