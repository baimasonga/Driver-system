# Driver & Fleet Accountability Management System

A two-in-one fleet accountability platform for anti-theft, odometer fraud
verification, fuel variance detection, and maintenance audits: one **Flutter
web console** for fleet managers and one **Flutter Android app** for
drivers, built from a single shared Dart codebase.

## `flutter_app/` — Flutter redesign (web + Android)

This is the primary application going forward. It shares one codebase
(models, business/fraud-detection logic, and state) across two front-ends:

- **Web console** (`flutter build web`) — vehicles, drivers, trips, fuel
  approvals, maintenance workflow, spare parts & tyres, exceptions
  ("blackbox" investigations), incidents, policy rules, and an immutable
  audit trail.
- **Android driver app** (`flutter build apk`) — driver sign-in, trip
  request/gate sign-out/sign-in, fuel claims, defect/maintenance reporting,
  pre/post-trip inspection checklists, and incident reporting.

Both sides implement the same anti-fraud rules (odometer-vs-GPS distance
checks, fuel consumption variance detection, invoice-vs-quotation checks)
so a discrepancy raised by a driver's phone shows up immediately in the
manager's exception queue. Either app can preview the other from its own
UI for training/demo purposes.

### Run locally

**Prerequisites:** [Flutter SDK](https://flutter.dev) (stable channel)

```bash
cd flutter_app
flutter pub get

# Web (fleet manager console)
flutter run -d chrome

# Android (driver app) — requires a connected device/emulator
flutter run -d android
```

### Build

```bash
flutter build web      # outputs to flutter_app/build/web
flutter build apk      # outputs to flutter_app/build/app/outputs/flutter-apk
```

See `flutter_app/lib/` for the source layout: `models/` (domain types),
`data/mock_data.dart` (seed data), `state/fleet_data_provider.dart` (shared
state + business rules), `web/` (manager console screens), `mobile/`
(driver app screens), and `theme/` (shared dark/amber design tokens).

## Legacy React/Vite prototype

The original React prototype (`src/`) that this system was redesigned from
is kept for reference.

**Prerequisites:** Node.js

```bash
npm install
npm run dev
```
