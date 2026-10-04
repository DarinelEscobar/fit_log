# Changelog

## [1.1.6+8] - 2026-10-04

### Features
- **Workout UI**: Refined the Kinetic Noir screens, motion, and compact layouts across Routines, History, Performance, warm-up, exercise progress, active workouts, and session review.
- **Focused Set Logging**: Keep the exercise, prescribed reps, RIR, tempo, and set target visible; expand only the active set while completed and upcoming sets stay compact.
- **History & Performance**: Group sessions by week, make routine/exercise filtering easier to scan, and add clearer volume and exercise progress trends.
- **Backups**: Combine export and sharing into one verified ZIP flow with incremental, full, and custom date ranges; imports add missing records while preserving current data.

### Reliability
- **Session Identity**: Preserve separate workouts for the same routine on the same day and keep imported session keys compatible with legacy tables.
- **Safe Restore**: Validate before merging, serialize data actions during restore, report success or failure, and refresh affected screens.
- **Safe Workout Changes**: Protect completed logs during exercise swaps, prevent duplicate exercises from breaking active cards, and save workout sets and session summaries atomically with retry on failure.
- **Local Startup**: Bundle font assets and keep demo workout fixtures out of the normal app entrypoint.

## [1.1.0+2] - 2026-06-23

### Features
* **Exercise Creation**: Added the ability to create and customize new exercises from the library.
* **Settings**: Added weight display unit configurations (Kg / Lb) integrated into routine management.
* **Workout Recovery**: Added active workout session recovery to avoid losing progress if the app is closed.
* **UI/UX Refactoring**: Significant enhancements to the performance and routine screens, including empty state handling.
* **Branding**: Replaced old logos with the new vector SVG format (Toru mascot) and updated app launcher icons.
* **Performance Tracking**: New data fetching methods and updated UI for performance tracking.

### Fixes & Chores
* **Tests**: Fixed flaky test timing issues related to clipboard and snackbar behavior.
* **Storage**: Lazy xlsx bootstrap and minimal initial exercise seed.
* **Dependencies**: Updated Gradle and Kotlin plugin versions.
* **Repository**: Removed obsolete Flutter project files and `flutter_wifi_run.ps1` from history.
