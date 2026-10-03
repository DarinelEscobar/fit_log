<p align="center">
  <img src="docs/images/fitlog_logo.svg" alt="FitLog - Train, Progress, You" width="460" />
</p>

<p align="center">Routine-based training, fast session logging, and local-first workout backups.</p>

Fit Log is a Flutter workout tracker focused on routine-based training, fast in-session logging, and local-first data ownership. The app is designed for lifters who want structured routines, quick set registration during a workout, and backup-friendly data they can keep on-device.

The current product experience is built around three primary tabs:

- `Routines` for routine management, exercise browsing, editing, and active sessions
- `History` for saved sessions, workout totals, and session details
- `Performance` for analytics based on current active routines and exercise-level progress

## Product Overview

Fit Log helps users do four things well:

1. Build and manage structured workout routines
2. Start an active session and log sets quickly with `kg`, reps, RIR, rest timing, and notes
3. Finish a session with a dedicated summary flow for energy, mood, notes, and saved logs
4. Export or import the app state through ZIP or table-level `.xlsx` files

The app uses a dark Kinetic-Noir visual system: violet accents, Space Grotesk headings, Manrope body text, rounded Material icons, and restrained surfaces. Native Flutter transitions take 160–220 ms and respect the device's reduced-motion setting. No additional animation dependency is required.

## Implemented UX

### Primary Navigation

- `Routines Library`: entry screen for the app, optimized for quick drill-down into a program
- `History`: compact saved-session cards and training totals
- `Performance Dashboard`: analytics for current active routines only, filtered by a selected time window

### Routine Flow

- `Exercise List`: routine detail before a workout starts, with search and direct access to exercise progress
- `Routine Editor`: full routine editing flow for metadata, exercises, and programmed set details
- `Active Workout Session`: pinned exercise name, target reps, RIR and tempo; one expanded set at a time; fixed `LOG SET` and exercise navigation controls
- `Finish Session Summary`: full-screen end-of-workout review before saving the session
- `Exercise Progress Detail`: exercise-centric progress screen accessed from the exercise list

### Secondary Flow

- `Data Management`: export/import backups opened from the Routines `Manage` menu

## Implemented Screens

The screenshots below document the earlier visual baseline. Run the current app to inspect the compact layouts and interactions described here.

### Routines Library

This screen is the main planning hub and the app entry point. Users can inspect active routines, reactivate inactive ones, create plans, enter a specific routine, and open backup tools from `Manage`.

![Routines Library](docs/images/screens/routines-library.png)

### Data Management

The data screen handles export, share, and import flows. It is intentionally isolated from the main tabs so users can perform backup operations without mixing them into the training flow.

![Data Management](docs/images/screens/data-management.png)

### Exercise List

This is the pre-workout view for a selected routine. It shows the programmed exercises, supports filtering, and provides a direct `Progress` action for each exercise before the session starts.

![Exercise List](docs/images/screens/exercise-list.png)

### Routine Editor

The editor is a form-driven workflow for changing routine metadata and programmed exercise details without dropping into JSON or raw data editing.

![Routine Editor](docs/images/screens/routine-editor.png)

### Active Workout Session

The active session keeps the current exercise name, RIR and tempo visible while scrolling. Logging a set collapses it into a compact summary and opens the next pending set. Completed and upcoming sets can be selected for editing; correcting a completed set does not restart its rest timer. The rest countdown appears after logging, while planned rest remains in plan details. The fixed `LOG SET` action and previous/next exercise controls remain reachable when the keyboard opens. Set count controls, notes, draft recovery and session persistence retain their existing behavior.

![Active Workout Session](docs/images/screens/active-workout-session.png)

### Finish Session Summary

The finish screen is a dedicated full-screen review of the session draft before persisting the workout logs and session summary.

![Finish Session Summary](docs/images/screens/finish-session-summary.png)

### Performance Dashboard

The dashboard aggregates training data for the currently active routines in the selected window. It shows volume, day coverage, muscle focus, and recent PR-style signals.

![Performance Dashboard](docs/images/screens/performance-dashboard.png)

### Exercise Progress Detail

The progress detail screen is exercise-centric. It aggregates logs by `exerciseId` and provides estimated 1RM, total volume, trend, and recent session context for a single exercise.

![Exercise Progress Detail](docs/images/screens/exercise-progress-detail.png)

## Data Model and Storage

Fit Log uses a hybrid local storage model:

- `SQLite` is the runtime source for routines, exercises, plan details, workout logs, and workout sessions
- `.xlsx` tables are retained for compatibility, import/export, and human-readable backups
- startup warmup seeds or rebuilds the runtime cache from `.xlsx` when needed

Current tables and backup artifacts include:

- `fit_log.db`
- `workout_plan.xlsx`
- `exercise.xlsx`
- `plan_exercise.xlsx`
- `workout_log.xlsx`
- `workout_session.xlsx`
- `user.xlsx`
- `body_metrics.xlsx`
- `muscle.xlsx`
- `exercise_target.xlsx`

Operationally, the app now favors SQLite for responsive reads and writes during normal use, while still exporting a portable ZIP backup that includes both the database and spreadsheet-compatible tables.

## Current Navigation Model

The current app shell exposes three primary tabs from the bottom navigation:

- `Routines`
- `History`
- `Performance`

The following screens are secondary routes opened from those tabs:

- `Data Management`
- `Exercise List`
- `Routine Editor`
- `Exercise Progress Detail`
- `Active Workout Session`
- `Finish Session Summary`

## Performance and Analytics Scope

The analytics layer is intentionally scoped and should be read with these constraints in mind:

- `Performance Dashboard` is based on current active routines only
- the time selector changes the window, but does not include inactive routines unless they are active again
- `Exercise Progress Detail` is keyed by `exerciseId`, so continuity depends on keeping the same exercise record instead of deleting and recreating it as a new id

This makes the dashboard good for understanding the current training block, while the exercise detail view is better for following a specific lift over time.

## Development Setup

### Requirements

- Flutter `3.5` or newer
- Dart SDK compatible with the version declared in `pubspec.yaml`

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Preview with fictional workout data

On a fresh emulator or an empty app database:

```bash
flutter run -t lib/main_demo.dart
```

This separate development entrypoint seeds fictional routines, warm-up steps and recent workout history for visual review. It skips seeding when routines, logs or sessions already exist, and a second launch does not duplicate the fixture. The normal `lib/main.dart` entrypoint does not seed demo data. The fixture is for UI review, not a prescribed training plan.

At startup the app:

1. ensures the expected `.xlsx` tables exist
2. warms up the SQLite routine/runtime cache
3. initializes local notifications used by the workout flow

## Development Notes

- The app is organized under `lib/src/` by feature and responsibility
- UI lives in `presentation`
- domain contracts live in `domain`
- repositories and storage adapters live in `data`

Important runtime entrypoints:

- [main.dart](lib/main.dart)
- [app.dart](lib/src/app.dart)
- [main_scaffold.dart](lib/src/navigation/main_scaffold.dart)
- [workout_storage_service.dart](lib/src/data/services/workout_storage_service.dart)

## Backup and Import

The app features a unified **Export & Share Backup** flow alongside non-destructive **Import Backup**:

- **Unified Export & Share**: Generating a backup automatically presents the system share sheet in a single flow without requiring a separate share step.
- **Range Presets & Selection**:
  - **Automatic Incremental**: Exports only missing workout sessions and logs since the last successful export.
  - **Full Backup**: Packages the complete SQLite database archive along with all historical spreadsheets.
  - **Custom Range**: Allows selecting explicit inclusive start and end dates with real-time validation and preview.
- **ZIP Archive Format**: Names include exported bounds (e.g. `fitlog_backup_2026-09-07_to_2026-09-13.zip` or `fitlog_backup_full_2026-10-02.zip`).
- **Non-destructive Restore**: Restores complete backups or merges incremental ranges into the existing database without data loss.
- **Local Ownership**: Preserves offline ownership of training data while keeping runtime operations optimized for SQLite. Successful export ranges are tracked in local SQLite metadata.

## Validation

Run the main validation steps with:

```bash
flutter test
```

And for targeted static validation:

```bash
flutter analyze
```

## Status

The redesigned experience currently covers the main workflow from app entry to routine management, active workout logging, session summary, analytics, and backup operations. Future design folders outside the implemented screen list are not part of the shipped README documentation yet.
