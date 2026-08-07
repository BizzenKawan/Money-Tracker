# Money Tracker

A private, offline expense and income tracker built for the Bikram Sambat
(Nepali) calendar — built because every money-tracker app on the Play Store
only understood the Gregorian calendar, and getting paid on a Nepali month
made that a real problem.

Built with [Flutter](https://flutter.dev) and Dart. Sideloaded directly to a
phone rather than published to the Play Store.

## Features

- Full Bikram Sambat calendar throughout — home screen grouped by BS month,
  a calendar grid view for backdating forgotten entries, monthly history
- Expense / Income / Transfer tracking across multiple accounts
- Fully custom categories — any of 16 colours × ~110 icons, drag to reorder
- Calculator-style amount entry (`50 + 30` → 80, then save)
- Charts: category breakdown donut chart, per-category drill-down with a
  daily trend line
- Monthly budgets with a progress gauge
- Sound and haptic feedback on taps and saves
- Backup and restore to a single file, plus CSV export
- Everything stored locally in SQLite — no server, no account, no internet
  permission

## Tech

- **Flutter / Dart** — UI and app logic
- **sqflite** — local database
- **nepali_utils** / **nepali_date_picker** — Bikram Sambat calendar and date
  picker
- **fl_chart** — charts
- **audioplayers** — bundled sound effects
- **share_plus** / **file_picker** — backup export and restore

## Running it

```
flutter pub get
flutter run
```

Build a release APK to sideload:

```
flutter build apk --release
```

The output APK is at `build/app/outputs/flutter-apk/app-release.apk`.

## Note on privacy

This repository contains only the app's source code. No personal transaction
data is included or ever leaves the phone the app is installed on — the
database lives in the app's private storage, not in this project.
