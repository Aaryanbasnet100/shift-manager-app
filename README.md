# ShiftFlow Enterprise

A multi-tenant shift-scheduling SaaS for restaurants, built with **Flutter Web + Firebase (Firestore)**. Dark neon design system (cyan `#00E5FF` → purple `#8A2BE2` on deep black).

## Features

- **Multi-tenant workspaces** — each restaurant is an isolated workspace (`restaurants/{id}`), entered via a workspace gate
- **Four roles** — super admin (founder terminal), workspace admin, manager, employee, routed by an `appRole` field
- **Dashboards** — role-aware home hubs with animated stat cards, next-shift countdown, on-shift-now headcount
- **Scheduling** — manager week view with real start/end times, drag-to-reschedule, weekly recurring shifts, location filters, shift templates with availability-aware auto-fill
- **Requests** — shift swaps, drop offers, an open-shift marketplace with volunteer/claim flow, vacation requests with approve/deny + reason notes
- **Availability** — per-weekday available/preferred/unavailable, enforced as non-blocking scheduler warnings
- **Time clock** — clock in/out tied to shifts, manager attendance log with late/early badges and corrections
- **Compliance guardrails** — configurable max hours/day, max consecutive days, min rest, warned at assignment time
- **Reports** — scheduled vs worked hours, labor cost, per-employee bars, overtime/understaffing alerts, CSV export
- **Audit log, announcements, targeted notifications, shift reminders, EN/DE localization**

## Getting started

```bash
flutter pub get
flutter run -d chrome
```

Demo workspace: enter `mcd_01` at the gate (it self-seeds on first use). Admin login: `admin` / `admin`.

### Firebase setup

1. The project uses the Firebase config in `lib/firebase_options.dart` (regenerate with `flutterfire configure` for your own project).
2. Enable **Anonymous sign-in** (Authentication → Sign-in method) — the app signs in anonymously at startup.
3. Deploy the rules: `firebase deploy --only firestore:rules` (see `firestore.rules`).

## Architecture

```
lib/
├── main.dart                  # bootstrap + theme
├── i18n/strings.dart          # EN/DE dictionary, t() helper
├── theme/app_colors.dart      # design-system colors
├── models/models.dart         # Firestore data models (null-safe, additive schema)
├── services/                  # pure logic: shift time math, conflicts, availability,
│                              # password hashing, Austria time, audit logging
├── widgets/                   # shared neon UI: buttons, calendar, stat cards,
│                              # adaptive scaffold (responsive sidebar), bell, drawer
└── screens/                   # auth gate + role shells + reports
```

**Schema policy:** all changes are additive — new collections or optional fields with safe defaults. Legacy documents always load. Deletes are soft (`archived: true`).

## Tests

```bash
flutter test
```

Unit tests cover the shift-time math, conflict/occurrence rules, availability defaults, password hashing (including legacy plaintext upgrade), and CET/CEST switching; widget tests cover the shared components. CI runs analyze + tests on every push.

## Known limitations

- Authentication is workspace-scoped username/password against Firestore (hashed, but not Firebase Auth accounts yet) — per-tenant server-side security rules require that migration
- Timestamps are stored as Austria-local ISO strings, not UTC
- Shift reminders are in-app only (no FCM push)
