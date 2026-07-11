# Driver & Fleet Accountability Management System

A two-in-one fleet accountability platform for anti-theft, odometer fraud
verification, fuel variance detection, and maintenance audits: one **Flutter
web console** for fleet managers and one **Flutter Android app** for
drivers, built from a single shared Dart codebase.

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
- `lib/data/mock_data.dart` — seed data
- `lib/state/fleet_data_provider.dart` — shared state (Provider /
  ChangeNotifier), persistence, and the anti-fraud business rules
- `lib/web/` — Fleet Manager web console screens
- `lib/mobile/` — Android driver app screens
- `lib/root/adaptive_root.dart` — picks the web console vs. driver app
  based on platform, with an in-app toggle to preview the other
- `lib/theme/` — shared dark/amber design tokens
