# Driver & Fleet Accountability Management System

A two-in-one fleet accountability platform for anti-theft, odometer fraud
verification, fuel variance detection, and maintenance audits: one **Flutter
web console** for fleet managers and one **Flutter Android app** for
drivers, built from a single shared Dart codebase, backed by **Supabase**
(Postgres + Realtime) and hosted on **Cloudflare Workers** at
https://drivesys.mohamedamadubangura.workers.dev.

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
console via Supabase Realtime — no refresh needed. Access is gated by a
single Supabase Auth sign-in shared by both apps: which UI a signed-in user
lands on is decided by their role, not by platform.

## Sign-in

Both apps share one login screen (email + password). Demo accounts, seeded
with the rest of the demo dataset:

| Role    | Email                          | Password    |
|---------|---------------------------------|-------------|
| Manager | `manager@fleet-org.com`         | `Fleet2026!`|
| Driver  | `alhaji.kamara@fleet-org.com`   | `Fleet2026!`|
| Driver  | `sorie.turay@fleet-org.com`     | `Fleet2026!`|
| Driver  | `musa.conteh@fleet-org.com`     | `Fleet2026!`|
| Driver  | `fatmata.sesay@fleet-org.com`   | `Fleet2026!`|

Rotate/replace these before using the app with anyone other than reviewers.

## Backend: Supabase

Connection details live in `lib/config/supabase_config.dart` (the
publishable/anon key is meant to be public — Supabase enforces access via
Row Level Security, not by keeping that key secret).

- Project: **driver-fleet-accountability** (`pdzellpeglmjqxmnzgyx`, `eu-west-1`)
- Schema: one table per domain entity (`vehicles`, `drivers`, `trips`,
  `fuel_requests`, `maintenance_requests`, `exception_records`, `incidents`,
  `audit_logs`, `policy_rules`, `spare_parts`, `tyres`, `inspections`) plus
  `profiles` (maps a Supabase Auth user to a `manager`/`driver` role and,
  for drivers, the linked `drivers.id`), seeded with the same demo dataset
  the app shipped with, all publishing to Realtime.
- **RLS is real now:** every table requires an authenticated session.
  Managers (`profiles.role = 'manager'`) get full read/write. Drivers can
  only read/write rows tied to their own `driver_id` (their own trips, fuel
  requests, maintenance requests, incidents, inspections, exceptions filed
  about them, and their assigned vehicle). `spare_parts`, `tyres`, and
  `audit_logs` reads are manager-only. See the `real_rls_policies` and
  `auth_profiles_and_seed_users` migrations for the exact policies.
- **Still open:** Supabase's "leaked password protection" (HaveIBeenPwned
  check) is off by default on a new project — worth switching on in
  Authentication → Policies in the dashboard before real use.

## Hosting: Cloudflare Workers

The web console (`flutter build web` → `build/web`) is a static SPA, served
as a Cloudflare **Workers** static-assets deployment (`wrangler.toml` has
`name = "drivesys"` and an `[assets]` block), publishing to
https://drivesys.mohamedamadubangura.workers.dev. Two ways to ship it:

1. **GitHub Actions** (`.github/workflows/deploy-cloudflare-workers.yml`) —
   builds and deploys on every push to `main` via `cloudflare/wrangler-action`.
   Requires two repo secrets:
   - `CLOUDFLARE_API_TOKEN` — a Cloudflare API token with *Workers Scripts:
     Edit* permission
   - `CLOUDFLARE_ACCOUNT_ID` — found in the Cloudflare dashboard sidebar

2. **Manual, via Wrangler** (`wrangler.toml` is already set up):
   ```bash
   flutter build web --release
   npx wrangler deploy
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
- `lib/state/auth_provider.dart` — Supabase Auth session + `profiles` lookup
- `lib/state/fleet_data_provider.dart` — shared state (Provider /
  ChangeNotifier), Supabase read/write + Realtime sync, and the anti-fraud
  business rules
- `lib/web/` — Fleet Manager web console screens
- `lib/mobile/` — Android driver app screens
- `lib/root/adaptive_root.dart` — routes signed-out users to the login
  screen, then signed-in users to the web console or driver app by role
- `lib/theme/` — shared dark/amber design tokens
