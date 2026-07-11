# Driver & Fleet Accountability Management System

A two-in-one fleet accountability platform for anti-theft, odometer fraud
verification, fuel variance detection, and maintenance audits: one **Flutter
web console** for fleet managers and one **Flutter Android app** for
drivers, built from a single shared Dart codebase, backed by **Supabase**
(Postgres + Realtime) and hosted on **Cloudflare Pages**.

- **Web console** (`flutter build web`) — vehicles, drivers, trips, fuel
  approvals, maintenance workflow, spare parts & tyres, exceptions
  ("blackbox" investigations), incidents, policy rules, and an immutable
  audit trail.
- **Android driver app** (`flutter build apk`) — driver sign-in, trip
  request/gate sign-out/sign-in, fuel claims, defect/maintenance reporting,
  pre/post-trip inspection checklists, and incident reporting.

Both sides read and write the same Supabase project, so a discrepancy raised
by a driver's phone (odometer-vs-GPS distance checks, fuel consumption
variance, invoice-vs-quotation checks) shows up live on the manager's web
console via Supabase Realtime — no refresh needed. Either app can preview
the other from its own UI for training/demo purposes.

## Backend: Supabase

Connection details live in `lib/config/supabase_config.dart` (the
publishable/anon key is meant to be public — Supabase enforces access via
Row Level Security, not by keeping that key secret).

- Project: **driver-fleet-accountability** (`pdzellpeglmjqxmnzgyx`, `eu-west-1`)
- Schema: one table per domain entity (`vehicles`, `drivers`, `trips`,
  `fuel_requests`, `maintenance_requests`, `exception_records`, `incidents`,
  `audit_logs`, `policy_rules`, `spare_parts`, `tyres`, `inspections`),
  seeded with the same demo dataset the app shipped with, all publishing to
  Realtime.
- **Security status (please read):** RLS is enabled on every table, but
  since there is no driver/manager login yet, the policies are currently
  permissive (`USING (true)`) — anyone holding the public anon key can
  read/write, the same trust model the previous local-only prototype had.
  This is a placeholder, not a real security boundary. Before this goes
  in front of real drivers, add Supabase Auth (email/password or magic
  link) plus a `profiles` table mapping `auth.uid()` to a driver/manager
  role, and swap the placeholder policies for ones scoped to that.

## Hosting: Cloudflare Pages

The web console (`flutter build web` → `build/web`) is a static SPA, which
deploys cleanly to Cloudflare Pages. Two ways to ship it:

1. **GitHub Actions** (`.github/workflows/deploy-cloudflare-pages.yml`) —
   builds and deploys on every push to `main`. Requires two repo secrets,
   which only you can create (this environment has no Cloudflare
   credentials):
   - `CLOUDFLARE_API_TOKEN` — a Cloudflare API token with *Pages: Edit*
     permission
   - `CLOUDFLARE_ACCOUNT_ID` — found in the Cloudflare dashboard sidebar

   The workflow deploys to a Pages project named `driver-fleet-accountability`
   (create it once in the Cloudflare dashboard, or let the first deploy
   create it).

2. **Manual, via Wrangler** (`wrangler.toml` is already set up):
   ```bash
   flutter build web --release
   npx wrangler pages deploy build/web --project-name=driver-fleet-accountability
   ```

The Android driver app isn't hosted on Cloudflare — build an APK/AAB and
ship it via the Play Store or a direct download link (Cloudflare R2 works
fine as a simple download host if you want one).

## Run locally

**Prerequisites:** [Flutter SDK](https://flutter.dev) (stable channel)

```bash
flutter pub get

# Web (fleet manager console)
flutter run -d chrome

# Android (driver app) — requires a connected device/emulator
flutter run -d android
```

## Build

```bash
flutter build web      # outputs to build/web
flutter build apk      # outputs to build/app/outputs/flutter-apk
```

## Source layout

- `lib/models/` — domain types (Vehicle, Driver, Trip, FuelRequest,
  MaintenanceRequest, ExceptionRecord, AuditLog, PolicyRule, Incident, ...)
- `lib/config/supabase_config.dart` — Supabase project URL + publishable key
- `lib/data/supabase_mappers.dart` — snake_case row ⇄ camelCase model glue
- `lib/state/fleet_data_provider.dart` — shared state (Provider /
  ChangeNotifier), Supabase read/write + Realtime sync, and the anti-fraud
  business rules
- `lib/web/` — Fleet Manager web console screens
- `lib/mobile/` — Android driver app screens
- `lib/root/adaptive_root.dart` — picks the web console vs. driver app
  based on platform, with an in-app toggle to preview the other
- `lib/theme/` — shared dark/amber design tokens
