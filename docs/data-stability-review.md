# Data stability corrections — 1.1.5+7

## Import failure in 1.1.4

The selected legacy incremental ZIP contained 7,040 workout sets, 373 sessions and 12 routines, with no SQLite snapshot. The old history parsers called `Sheet.rows` twice per iteration; the Excel library rebuilds the entire rectangular grid on each call. The real import exceeded the normal 30-second desktop test deadline. Caching that grid once restored all records and allowed a subsequent reopen in approximately four seconds in the local SQLite test. This is a desktop measurement, not a phone latency claim.

Import validation and history workbook generation now run with Flutter `compute`. The application paints a loading screen before storage initialization, and offers retry on startup failure while retaining stored data. Normal release initialization no longer adds the 30 starter exercises. Demo fixtures remain exclusive to `main_demo.dart`; the release uses `main.dart`.

Android release verification also exposed uncaught runtime font download failures. Space Grotesk and Manrope now ship as verified local font assets with their OFL licenses. Runtime font fetching is disabled in the normal entrypoint, and an offline font-loading regression covers all twelve bundled weights. The release manifest has no INTERNET permission; no application server is started by the normal APK.

## Resolved risks

| Risk | Correction |
| --- | --- |
| A second workout of the same routine/day loses records | Schema 4 adds a session identity; final save derives it from the workout start. History and active exercise comparisons group by that identity. |
| An older backup erases newer records | ZIP/database/spreadsheet imports merge instead of replacing live storage. Current configured routines, presets, profile and edited modern sets take precedence. |
| Same-exercise swap silently resets sets | Completed rows expose EDIT. A reset explicitly warns and can be cancelled. Different-exercise swaps warn before discarding completed sets. |
| Swapping to an already-present exercise breaks GlobalKeys | Reject the duplicate before changing logs or cards. Recovery also normalizes duplicate exercise cards from old drafts. |
| Automatic backup skips later records on an exported day | Compare per-day record signatures, so additional sets/sessions or edits make that date eligible again. Custom exports use temporary workbooks instead of truncating resident compatibility history. |
| Final save partially commits | Sets, session summary and draft removal commit together. The screen blocks input during save, serializes outstanding draft writes, retains sets on failure and allows retry. |
| Import appears idle or leaves screens stale | Busy state disables other data actions and back navigation; success/errors are visible. Invalidate routine-detail, warm-up, profile, History and Performance caches after merging. |

## Merge and compatibility rules

- Validate staged files before touching live storage; merge the core SQLite tables in one transaction. Never copy a backup database over the open live database.
- Prefer an exact catalog ID/name match, then an existing matching name. If an ID identifies a different name and no matching record exists, allocate a new local ID and remap the imported relationships together. Routine names are not required to be unique.
- Keep existing routine composition and warm-up configuration when already populated. Add missing routines, exercises and history without removing current records.
- Keep current modern sets when a restored session/exercise/set already exists. Old day-only rows use deterministic legacy identities and full-content deduplication; they cannot reveal whether two otherwise identical rows originally came from different sessions.
- Existing profile settings win; missing ancillary rows and measurements merge. File preparation failures restore the previous ancillary files. SQLite remains authoritative if compatibility workbook regeneration fails after a successful merge.
- Restore a missing valid active draft from a full snapshot only when its catalog IDs remain compatible; an existing local draft wins.
- Preserve all historical headers. New spreadsheet exports append `workout_session_key`; the legacy session spreadsheet's numeric `session_id` remains a row ID.
- Records previously absent from both storage and backups cannot be reconstructed. No mock or demo history is substituted.

## Verification

- `flutter test --no-pub` across data integrity/import/export, active workout widgets, finish session, Data Management, History, Performance and latency/progress regressions: **123 tests passed in ten focused files**.
- The actual 22:15 backup imported and reopened in the local SQLite regression: **7,040 sets, 373 sessions and 12 routines**. The source ZIP was left unchanged.
- `flutter analyze --no-pub --no-fatal-infos`: exit 0, no errors or warnings; twelve existing informational findings remain in unchanged files.
- `flutter build apk --release --no-pub -t lib/main.dart`: succeeded. Normal APK **1.1.5+7**, package `com.yourcompany.fit_log`, no embedded database/spreadsheet files or demo training data.
- Release SHA-256: `4EAEEA2C5282A677A535CD7F7B84D08E11B658160B10BEB5FD9980421C99EC1A`.
- Signing certificate SHA-256: `6296a3ef924ced13c2344d843aa783111a29b61b2fc7a1e07a1fe9045f993490`, unchanged from 1.1.4.
- A dedicated Android API 34 emulator accepted an in-place update from 1.1.4 using `adb install -r`, without uninstalling or clearing app data. Import through Android's file picker recovered all **7,040 / 373 / 12** records; Routines, History and Performance populated. Reimporting the ZIP preserved the same counts; SQLite integrity check returned `ok`.
- Force-stop and cold launch retained the imported routines. The final APK's launch/reimport/cold-launch checks produced no Flutter or Android runtime errors, including the former font failures.
- Delivery copies: `<local path omitted>` and `G:\My Drive\FILES\FitLog-1.1.5-release.apk`; both copies were verified to match the release hash above.

No physical phone validation was performed. Existing records already missing from both storage and backups, including indistinguishable old same-day sessions, cannot be reconstructed. Real-data ZIP copies, temporary databases and screenshots stay outside the repository.
