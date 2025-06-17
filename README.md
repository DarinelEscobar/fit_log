# Fit Log

Fit Log is a Flutter application for tracking workout routines and logging your training sessions. All data is stored locally in Excel (`.xlsx`) files so you can easily back up or edit them with any spreadsheet program.

## Features

- Manage workout plans and exercises.
- Start a routine and record sets with reps, weight and RIR.
- Session timer with fatigue, mood and notes at the end of each workout.
- History tab showing previous workout sessions and logs.
- Bottom navigation with tabs for Home, Routines, Logs and more.
- New **Data** screen to export or import all tables as a backup.
- Backups are copied to your Downloads folder and can be shared directly from the app.

## Getting Started

1. Install [Flutter](https://flutter.dev/) (version `3.5` or newer).
2. Fetch the dependencies:

   ```bash
   flutter pub get
   ```
3. Launch the application on a device or emulator:

   ```bash
   flutter run
   ```

On first launch, the app creates the Excel files defined in `kTableSchemas`. This is triggered by `XlsxInitializer.ensureXlsxFilesExist()` during startup.

## Project Structure

- `lib/main.dart` – entry point that ensures the Excel tables exist and runs the app.
- `lib/src/` – source code organized by feature.
  - `features/routines` – workout plans and routine screens.
  - `features/history` – logs and session history screens.
  - `navigation/main_scaffold.dart` – bottom navigation setup.

The main scaffold registers five tabs including Routines and Logs.

## Running Tests

A smoke test is provided under `test/`:

```bash
flutter test
```

## Notes

- Statistics and profile sections are placeholders for future updates.
- Data is stored in the application documents directory as `.xlsx` files, making it simple to export or edit externally.
- When exporting from the Data screen a ZIP file is also copied to your Downloads directory for easy access.
- The Data screen can import either a full `fitlog_backup.zip` or an individual `.xlsx` table to replace existing data.
