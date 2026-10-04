# Refresh FitLog documentation, integrate the redesign, and publish 1.1.7

This ExecPlan is a living document. Keep `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` synchronized with reality during execution.

```yaml
plan_status: in_progress
created: 2026-10-04
last_updated: 2026-10-04
```

## Purpose / Big Picture

Prepare a reviewable FitLog 1.1.7 release from the committed `feat/fitlog-ui-redesign` worktree. Update README screenshots to show the current app, document the delivered UI and data-safety behavior, build and validate the update APK, integrate the feature history into the repository's actual default branch (`origin/master`), and publish the APK through the repository's existing GitHub Release workflow. The earlier `v1.1.6` tag is immutable and its CI run failed before producing an APK; preserve it and use the next version/tag. A reviewer must be able to compare screenshots to the working app, install the signed APK over 1.1.5 without clearing data, and download `fit_log-v1.1.7.apk` from the GitHub release.

## Scope

- Document the implemented compact routine/session UI, History and Performance screens, unified backup flow, safe same-day session identity, non-destructive restore, and save/import protections.
- Replace stale README screen captures using only fictional demo data in a dedicated emulator. Add current History and warm-up images and link all representative product screens in README.
- Prepare version `1.1.7+9` and release notes, validate the release APK, integrate the feature branch into `origin/master`, and publish tag `v1.1.7` so `.github/workflows/release.yml` builds and uploads the signed APK.
- Fix the release-test font mock so Linux CI loads tracked font assets rather than probing a Windows-only Flutter SDK path.

## Non-goals

- Do not edit the protected primary checkout `<local path omitted>`; it has unrelated user changes in `AGENTS.md`, active-workout and warm-up files, notifications, tests, and remote attachments.
- Do not add app features, change backup/data contracts, modify signing keys or GitHub secrets, or replace the existing GitHub workflow unless execution evidence shows a concrete release blocker.
- Do not include real workout records, exported backups, or personal data in screenshots or release assets.

## Context and Orientation

- Repository/worktree: `<local path omitted>`, branch `feat/fitlog-ui-redesign`. The UI/docs history and v1.1.6 candidate are committed at `1471083`, which is also on `origin/master` and tagged `v1.1.6`; the cross-platform test fix and 1.1.7 release notes are the current uncommitted follow-up.
- The protected local `master` checkout is two commits behind its tracking ref and has user-owned dirty files that overlap feature paths. Preserve that checkout; perform branch integration in this clean feature worktree or another clean Git checkout.
- Current README links ten mobile screenshots under `docs/images/screens/`; eleven image files exist, including the unlinked legacy `home-dashboard.png`. The ten linked images have been refreshed from the current UI; the data-management capture shows the additive import flow. README describes the current screens and navigation.
- The reviewed UI release was built as `1.1.6+8`; tag `v1.1.6` was pushed to `origin` and the workflow failed before signing/build/upload. Preserve this historical tag/run. The follow-up release must use version `1.1.7+9` and tag `v1.1.7`. `docs/data-stability-review.md` records the 1.1.5+7 recovery and compatibility evidence; retain prior release reports and dates as history.
- `.github/workflows/release.yml` triggers on `v*` tags, runs `flutter test`, checks four Android signing secrets, builds a signed release APK, and publishes `fit_log-${GITHUB_REF_NAME}.apk` to a GitHub Release. Remote `origin` is `git@github.com:DarinelEscobar/fit_log.git`; GitHub metadata confirms `master` is the public default branch. The 1.1.6 candidate is already fast-forwarded to `origin/master`; its tag workflow failed before signing/build/upload. `gh` CLI is absent from PATH.
- The `v1.1.6` tag points to `1471083` on `origin/master`; its release workflow run `37221689409` failed in tests. The `v1.1.7` tag must be checked for availability before publication.
- `lib/main_demo.dart` seeds fictional workout data only into an empty store and then delegates to `lib/main.dart`. Use a new, dedicated QA emulator/storage location for captures. The normal release entrypoint is `lib/main.dart` and must not ship seeded training data.
- Existing canonical docs are `README.md`, `CHANGELOG.md`, `docs/ui-polish-review.md`, and `docs/data-stability-review.md`. Repository inspection found no canonical ERD; this release does not change the schema or data model, so no ERD is needed.

## Interfaces and Contracts

- Keep Android package ID `com.yourcompany.fit_log`; set Flutter package version to `1.1.7+9` (version name 1.1.7, code 9) so installation updates earlier versions in place.
- Preserve the release workflow contract: tag `v1.1.7` starts `.github/workflows/release.yml`, which runs the full Flutter suite and publishes `fit_log-v1.1.7.apk` after a successful signed build.
- Keep screenshots inside `docs/images/screens/` and link them by repository-relative Markdown paths from README. Screens show the real app UI populated only with the synthetic fixture from `main_demo.dart`; do not expose unredacted user data.
- Preserve earlier release records and the existing backup compatibility statements; current 1.1.5 behavior is detailed in `docs/data-stability-review.md`.

## Dependency Map

| ID | Milestone | Depends on | Parallelizable |
| --- | --- | --- | --- |
| M0 | Update README and current screen captures | None | No |
| M1 | Version, document, and validate release candidate | M0 | No |
| M2 | Integrate into origin/master and publish the GitHub APK | M1 | No |

`depends_on` in milestone metadata is the source of dependency truth. This table is a readable projection and must match it.

## Concurrency Design

Run directly and sequentially. Screenshot capture, README changes, version documentation, release validation, Git integration, and tag-triggered publication all share one release candidate and one mutable Git history. The screenshot emulator will hold synthetic data only; the existing user-device emulator, app data, and protected primary checkout are not runtime resources for this plan. No workers or parallel lanes are requested or appropriate.

## Milestones

### M0 - Refresh README and screenshot the current UI

```yaml
id: M0
status: completed
depends_on: []
parallelizable: false
owned_paths:
  - README.md
  - docs/images/screens/
runtime_resources:
  - Dedicated Android QA emulator using a fresh synthetic demo store; screenshot output limited to docs/images/screens/
```

#### Implementation

Boot a fresh, isolated Android emulator and run the current feature branch UI with the fictional fixture. Capture fresh images of the current root Routines library, routine exercise list/editor, warm-up preview, active workout, finish summary, History, Performance, exercise progress, and Data Management. Replace the existing stale images that README uses and add missing History/warm-up captures. Keep genuine app screen content and the README's repository-relative links; exclude Android file picker/recovery data, personal session notes, debugging overlays, and fake device chrome. Do not invent a separate Home tab: `MainScaffold` exposes only Routines, History, and Performance. Update the README copy to say these are current captures and accurately describe the implemented functionality and navigation.

#### Tests

- Check every README image link resolves to an existing tracked screenshot and verify each new PNG decodes at its full dimensions.
- Inspect the captured Data Management and active-workout screens against the implemented non-destructive import, current set focus, and recovery states before accepting the images.

#### Local validation

```text
git diff --check
```

Run the repository-local link/image validation described above and inspect the changed README and screenshots. Expect no missing Markdown targets, truncated captures, or debug/demo disclaimer in the release UI copy. Do not run app tests solely to complete this documentation milestone.

#### Documentation

Update `README.md` and the image artifacts under `docs/images/screens/`. Reuse the existing screen gallery and filenames wherever they identify the same screen. There is no schema change; no ERD update is required. Keep implementation and backup claims aligned with `docs/data-stability-review.md` and existing `docs/ui-polish-review.md`.

#### Acceptance criteria

- README contains representative, current captures for the root Routines screen and all documented secondary screens, including History and the warm-up preview.
- The screenshots agree with the current release candidate and no longer show the superseded destructive backup flow.
- All screenshot examples use the isolated fictional demo store; unrelated and user-owned checkout data is untouched.

#### Completion gate

Mark M0 complete only after the images have been captured from the current app, visually checked, every README image link resolves and decodes, and `git diff --check` passes. Record the exact image paths and which views were observed.

### M1 - Prepare and validate FitLog 1.1.7+9

```yaml
id: M1
status: completed
depends_on: [M0]
parallelizable: false
owned_paths:
  - pubspec.yaml
  - CHANGELOG.md
  - docs/ui-polish-review.md
  - test/data_screen_unified_flow_test.dart
runtime_resources:
  - Local Flutter release build and fresh Android QA emulator; existing device and primary-checkout data are excluded
```

#### Implementation

Set `pubspec.yaml` to `1.1.7+9`. Keep the existing 1.1.6 feature notes and document its failed CI attempt accurately; add a concise 1.1.7 follow-up entry. Fix `test/data_screen_unified_flow_test.dart` to serve fonts from tracked `assets/fonts/`, making the test fixture portable across Windows and Ubuntu without changing production behavior. Build the signed normal release from `lib/main.dart`.

#### Tests

- Run the focused failing-flow test and the same complete Flutter test command that the existing release workflow will run.
- Verify a clean release APK can update the existing 1.1.6 app without uninstalling; inspect its package, version name/code, release signature, and assets for embedded workout data. Prior M1 already verified the 1.1.5-to-1.1.6 transition.
- Launch the release APK in the clean demo QA emulator and confirm the principal screenshot views render after the version bump.

#### Local validation

```text
flutter pub get
flutter test
flutter analyze --no-pub --no-fatal-infos
flutter build apk --release --no-pub -t lib/main.dart
git diff --check
```

The portable fixture's focused tests and full workflow test suite must pass. Static analysis may report the twelve pre-existing informational findings recorded for untouched files in `docs/data-stability-review.md`; it must report no new warnings or errors. Verify package `com.yourcompany.fit_log`, version `1.1.7`, version code `9`, non-debuggable release and the established certificate. Keep the keystore and `android/key.properties` private and unstaged.

#### Documentation

Update `CHANGELOG.md` and append the 1.1.7 candidate/validation record to `docs/ui-polish-review.md`, including the prior 1.1.6 workflow failure and recovery. README and screenshots are delivered by M0. `docs/data-stability-review.md` remains the canonical detail for backup/data guarantees. No schema/ERD update applies.

#### Acceptance criteria

- Version name/code are 1.1.7/9; the package ID and signing certificate preserve update compatibility.
- The focused tests and full `flutter test` pass; analysis and normal signed release build pass; release contains no seeded workout database or spreadsheet data.
- An in-place install over 1.1.6 retains the synthetic QA routine and the updated app opens to its routines screen.
- Changelog accurately summarizes shipped features and limitations; UI review report records verifiable build/test evidence without rewriting prior reports.

#### Completion gate

Mark M1 complete only after every listed command succeeds, the APK identity/signature/embedded-data checks are observed, an in-place 1.1.6 update and the updated routines screen are confirmed in the isolated emulator, and changed docs accurately match the built candidate. Record APK SHA-256 and local artifact path.

### M2 - Integrate the candidate and publish the GitHub APK

```yaml
id: M2
status: in_progress
depends_on: [M1]
parallelizable: false
owned_paths:
  - Git ref refs/heads/master
  - Git ref refs/tags/v1.1.7
  - GitHub Actions release workflow and release asset
runtime_resources:
  - origin Git repository and authenticated GitHub Release workflow; no local user data or untracked signing secrets
```

#### Implementation

Fetch `origin` immediately before publication and verify its default branch remains `master`, `origin/master` is an ancestor of the release candidate, tag `v1.1.7` is unused, and the protected primary checkout is still left alone. The feature history and initial v1.1.6 candidate are already on `origin/master`; this follow-up fix is based on that published state. Commit final review changes using exact task paths and fast-forward `origin/master`. Preserve `v1.1.6` and its failed workflow; push annotated tag `v1.1.7` at the exact validated release commit to activate `.github/workflows/release.yml`. Follow the existing workflow; do not rotate secrets or create a parallel release mechanism.

If master branch protection rejects the direct fast-forward, publish the reviewed feature branch and use the repository's normal PR merge path. The request explicitly authorizes integrating the worktree into the default branch and launching the release; use that authorization for the PR merge after required checks pass.

#### Tests

- Confirm the remote commit on `master` contains the validated docs, screenshots, release code/version, and feature history.
- Confirm GitHub Actions ran the `Release APK` workflow for `v1.1.7`, all tests and signing passed, and release asset `fit_log-v1.1.7.apk` is publicly listed and downloadable.
- Check the GitHub release APK reports version 1.1.7+9, the expected package ID, and the established certificate; record its SHA-256.

#### Local validation

```text
git status --short --branch
git fetch origin
git merge-base --is-ancestor origin/master HEAD
git ls-remote --tags --refs origin refs/tags/v1.1.7
```

Before pushing, confirm the primary checkout's original user changes remain untouched and run the release suite/build again if the integrated tree differs from M1's tested commit. After publication verify `origin/master` and `v1.1.7` point to the intended commits and inspect the completed workflow and release. Never force-push. A workflow secret or remote policy failure is not success; diagnose it and record a concrete blocker if owner action is genuinely required.

#### Documentation

Finalize release artifact SHA-256, GitHub release URL, workflow result, screenshot inventory, and delivery outcome in the 1.1.7 section of `docs/ui-polish-review.md`; make README screenshots reflect those captured screens. Finish the ExecPlan with changed paths and release evidence. Reuse the existing CHANGELOG, UI release report, README and data-stability report. No ERD applies.

#### Acceptance criteria

- All reviewed feature commits are integrated into `origin/master` without force-push, unreviewed changes, or modifying the protected primary checkout's user files.
- The `v1.1.7` GitHub Release exists and contains the workflow-built, correctly signed `fit_log-v1.1.7.apk`.
- Documentation and README show the released version, the implemented features and real app screenshots; reported artifact hashes correspond to verified files.

#### Completion gate

Mark M2 complete only after the default branch contains the validated candidate and the tag-triggered workflow has succeeded, the signed APK is downloadable on GitHub and its package/version/certificate are verified, the release report is accurate, and the primary checkout remains intact. If publication is blocked by a remote access or secrets issue, leave M2 blocked with the precise error and preserve all validated local work.

## Integrated Validation and Acceptance

Run `flutter test`, `flutter analyze --no-pub --no-fatal-infos`, `flutter build apk --release --no-pub -t lib/main.dart`, and `git diff --check` on the final integrated candidate. Inspect every README screenshot link and representative screen capture. Confirm same-signature in-place installation, no embedded user/demo datasets in the normal release APK, branch ancestry, successful v1.1.7 tag workflow, published GitHub release and APK identity. Confirm the remote default branch and feature commits are fully integrated and the protected primary checkout has its original user changes unchanged.

## Risks, Idempotence, and Recovery

- Risk: release workflow checks signing secrets only after tag push. Re-run validation and ensure the local signed APK is intact before creating the version tag; inspect workflow output. Missing owner-controlled secrets block publishing and must not be papered over with an unsigned or differently signed APK.
- Risk: master branch protection or upstream advances before merge. Fetch and inspect new commits first; merge upstream into the feature branch and rerun affected release gates, or use the authorized PR path. Never force-update master or replace user changes in the primary checkout.
- Risk: screenshots could disclose personal training information. Use only a fresh, isolated `main_demo.dart` store; review each capture before staging.
- Re-run behavior: screenshot capture may be repeated in the isolated emulator; version/tag publication is not idempotent once a release tag exists. Preserve the failed v1.1.6 run and use the unused higher v1.1.7 patch release; never rewrite an existing release tag.
- Recovery: before publication, revert only reviewed task paths in the feature worktree. After a tag-triggered workflow starts, preserve its run and asset, diagnose in place, and correct only a higher patch/version with an unused tag if release immutability requires it.

## Progress

- [2026-10-04 17:07Z] ExecPlan created from repository inspection. Explicit authorization to execute, commit task changes, integrate the worktree into the default branch, and launch the GitHub APK was given in the user request.
- [2026-10-04 17:12Z] M0 started after validating all three pending milestones, their dependency graph, clean feature worktree, protected dirty-checkout baseline, and local non-mutating push checks. First action: capture the current app using fresh synthetic demo data.
- [2026-10-04 17:27Z] M0 completed: refreshed all eight README-linked legacy captures and added current History and warm-up captures. Reviewed the screenshots visually; ten README image links resolve and all eleven PNGs decode at full size; `git diff --check` passed. Started M1 version and release validation.
- [2026-10-04 17:35Z] M1 completed: set 1.1.6+8, recorded release notes, ran `flutter pub get`, all 146 `flutter test` tests, analyzer with zero errors/warnings (12 existing infos), and built/verified the signed release APK. A `1.1.5+7` install upgraded with `adb install -r` to version code 8 without clearing the synthetic routine created in the old app. M2 remote integration and GitHub publication are now in progress.
- [2026-10-04 17:39Z] Refetched `origin`: `origin/master` remained at the release base and is an ancestor of the candidate; `v1.1.6` remained unused. Fast-forward pushed commit `1471083` to `origin/master` and pushed annotated tag `v1.1.6`. GitHub Actions run `37221689409` was observed in progress for that tag and exact commit.
- [2026-10-04] The first tag workflow finished with 138 passing and 8 failing tests; all failures were `DataScreen` font asset lookups caused by a Windows-only Flutter SDK path in the test fixture. The release had not reached signing/build/upload. M1 was reopened for a portable fixture fix and new patch version.
- [2026-10-04] Replaced the platform-specific mock with project-tracked font loading. Focused DataScreen tests passed 8/8; full suite passed 146/146; analysis exited 0 with 12 informational findings and no warnings/errors. Release build and in-place update validation for 1.1.7+9 remain.
- [2026-10-04 17:51Z] M1 completed for 1.1.7+9: signed release build passed (65,353,182 bytes; SHA-256 `A3860051FB228CA5F3C01494039EF9F84C73DF05F5C72D0089EFB06E5F085CEA`); package/version/code, permissions, absence of bundled data, and established certificate verified. `adb install -r` upgraded 1.1.6+8 on the isolated emulator and preserved the synthetic `Upgrade QA` routine. M2 is now the only open milestone.

## Surprises & Discoveries

- Observation: the existing README explicitly labels its screenshots an earlier visual baseline, and the displayed Data Management capture advertises an import that overwrites all device data. The current 1.1.5 implementation merges missing records instead. Evidence: `README.md` screenshot introduction, `docs/images/screens/data-management.png`, and `docs/data-stability-review.md`.
- Observation: the release pipeline already listens for `v*` tags, runs the full test suite, checks Android signing secrets, and uploads the signed APK. Evidence: `.github/workflows/release.yml`.
- Observation: at initial inspection, `origin/master` was the actual default branch, `origin/HEAD` pointed there, and the feature worktree was 29 commits ahead of its base. The completed M2 progress below records the subsequent fast-forward to `origin/master`. Evidence: `git remote -v`, `git branch -avv`, `git merge-base origin/master HEAD`, and `git rev-list --left-right --count origin/master...HEAD`.
- Observation: the primary local `master` checkout contains unrelated dirty user changes, including overlapping active-workout paths. Evidence: `git -C <local path omitted> status --porcelain=v1 --branch`.
- Observation: before integration, the GitHub release workflow listened for configured `v*` tags and non-mutating push dry-runs to `master` and `v1.1.6` succeeded. Subsequent real publication and workflow evidence are recorded in Progress and the release report.
- Observation: current navigation has three tabs (Routines, History, Performance) and no separate Home route; the legacy `home-dashboard.png` is not linked from README. Evidence: `lib/src/navigation/main_scaffold.dart` and the current emulator UI.
- Observation: current emulator captures show a single `Export & Share Backup` action with system sharing and an additive `Import Backup` action; active session keeps the exercise name, prescribed reps, RIR, and tempo visible while completed/upcoming sets compact. Evidence: current `data-management.png` and `active-workout-session.png` captures from the dedicated synthetic-data emulator.
- Observation: the signed `1.1.6+8` APK updates the actual signed `1.1.5+7` artifact in place on the isolated API 34 emulator, and its synthetic `Upgrade QA` routine remains after a cold launch. Evidence: `adb install -r` reported `Success`; package version code queried as 8; routine visible in the Routines tree.
- Observation: final release candidate APK is signed with the established certificate, has no `INTERNET` permission, and contains no database or spreadsheet fixture entries. Evidence: `apksigner verify --print-certs`, `aapt dump permissions`, and APK ZIP entry inspection.
- Observation: workflow `37221689409` failed only eight DataScreen tests because its mock searched for `C:\src\flutter\...\roboto-bold.ttf`, absent on Ubuntu; the repository has all required font files in `assets/fonts/`. The failure preceded signing/build/upload. Evidence: job `111493144744` log and portable test fixture.
- Observation: the 1.1.7 signed APK retains the established signer and updates 1.1.6 in place without clearing the QA routine. Evidence: `apksigner verify --print-certs`, `adb install -r` success, package manager version code 9, and the post-install routines screenshot.

## Decision Log

- Decision: document the Routines Library as the app entry screen and leave the unlinked legacy Home image out of the README gallery.
  Rationale: the current `MainScaffold` contains three tabs and no Home screen; a stale Home screenshot would misrepresent the shipped navigation.
  Date: 2026-10-04
- Decision: use `master` as the origin branch and `v1.1.6+8` / `v1.1.6` as version and release tag.
  Rationale: this was the initial release decision based on the 1.1.5+7 source and unused tag. Superseded only for the follow-up after the published v1.1.6 workflow failed; keep this entry as decision history.
  Date: 2026-10-04
- Decision: run sequentially inside the clean feature worktree; render screenshots only from a fresh `main_demo.dart` store.
  Rationale: all release changes share one history, tag-triggered pipeline, and screenshot source. The primary checkout has dirty user changes; demo entrypoint contains an existing idempotent synthetic fixture.
  Date: 2026-10-04
- Decision: keep the unlinked legacy `home-dashboard.png` file untouched while replacing all README-linked captures and adding current History and warm-up screenshots.
  Rationale: there is no separate Home route in the current app; the file is unused by README and does not represent current navigation.
  Date: 2026-10-04
- Decision: verify the update using the existing signed 1.1.5+7 APK and a synthetic routine created in-app before `adb install -r`.
  Rationale: this tests the same package/signing/update path and proves app data remains after installation without touching personal data or clearing storage.
  Date: 2026-10-04
- Decision: preserve tag `v1.1.6` and publish the test fix as `1.1.7+9` / `v1.1.7`.
  Rationale: `v1.1.6` already exists on the remote and its run failed before producing an APK; rewriting a published release tag would make history and release state ambiguous.
  Date: 2026-10-04

## Outcomes & Retrospective

Feature/docs integration is on `origin/master`; the initial `v1.1.6` release workflow failed before artifact creation. The portable test fix, complete local validation, signed 1.1.7 APK, and in-place update verification are complete. Only the new `v1.1.7` tag-triggered workflow and GitHub asset verification remain.

## Revision Log

- [2026-10-04] Initial plan created from current branch, release workflow, screenshots, and repository state.
- [2026-10-04] M0 clarified that current navigation has no Home tab; captures document the existing root Routines tab instead.
- [2026-10-04] M0 completed with ten current README screenshot links; M1 release versioning and validation started.
- [2026-10-04] M1 completed with 146 passing tests, clean static analysis apart from twelve existing infos, a signed version 1.1.6+8 APK, and a successful data-preserving in-place update test. M2 is underway.
- [2026-10-04] Revision: retained the failed, already-published `v1.1.6` tag; reopened M1 for a cross-platform test fixture correction and advanced the release candidate monotonically to `1.1.7+9` / `v1.1.7`.
- [2026-10-04] M1 revalidated with the `1.1.7+9` signed APK and the synthetic-data-preserving in-place upgrade. M2 now publishes the new tag to the already-up-to-date `origin/master`.
