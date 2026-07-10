# Tasks: Android Wealth Map Parity

**Input**: Design documents from `/specs/004-android-app/`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`,
`contracts/`, and `quickstart.md`

## Phase 1: Setup and Safety

- [ ] T001 Record the existing Android build/test baseline and prototype structure in `../../Android/MyWealth/README.md`
- [ ] T002 Update Android dependency versions and add required Compose adaptive, WorkManager, serialization, lifecycle, security, Glance, Google authorization, Drive, and test libraries in `../../Android/MyWealth/gradle/libs.versions.toml` and `../../Android/MyWealth/app/build.gradle.kts`
- [ ] T003 Harden repository ignores for Gradle, Android Studio, environment, signing, OAuth, Firebase, backup, and local financial artifacts in `../../Android/MyWealth/.gitignore`
- [ ] T004 Add non-secret Firebase proxy endpoint configuration and remove direct provider configuration from `../../Android/MyWealth/app/build.gradle.kts`
- [ ] T005 Disable unconsented financial-data Auto Backup and define explicit extraction exclusions in `../../Android/MyWealth/app/src/main/AndroidManifest.xml`, `../../Android/MyWealth/app/src/main/res/xml/backup_rules.xml`, and `../../Android/MyWealth/app/src/main/res/xml/data_extraction_rules.xml`
- [ ] T006 Create the application container and package boundaries in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/app/WealthMapApplication.kt` and `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/app/AppContainer.kt`

## Phase 2: Foundational Data and Domain Work

- [ ] T007 [P] Add Room v1 migration fixtures and schema tests in `../../Android/MyWealth/app/src/androidTest/java/com/bxvdev/mywealth/data/local/AppDatabaseMigrationTest.kt`
- [ ] T008 [P] Add calculation, currency, snapshot, goal, and formatting tests in `../../Android/MyWealth/app/src/test/java/com/bxvdev/mywealth/domain/PortfolioCalculatorTest.kt`
- [ ] T009 [P] Add backup v1/v2 codec and transactional import tests in `../../Android/MyWealth/app/src/test/java/com/bxvdev/mywealth/portability/BackupCodecTest.kt`
- [ ] T010 Implement canonical Room entities, converters, DAOs, database schema export, and explicit v1 migration in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/local/`
- [ ] T011 Implement compatible DataStore settings and prototype-key migration in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/preferences/UserPreferencesRepository.kt`
- [ ] T012 Implement stable currency/category/unit catalogs and locale-independent raw values in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/domain/model/`
- [ ] T013 Implement pure conversion, totals, allocation, snapshot, goal, and FIRE calculators in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/domain/calculation/`
- [ ] T014 Implement typed repository interfaces and Room-backed repositories in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/repository/`
- [ ] T015 Implement typed Firebase proxy clients and Room-backed rate/metal caches in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/remote/`
- [ ] T016 Implement backup v1/v2 codec, import preview/apply, and export services in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/portability/`

## Phase 3: User Story 1 — Track Net Worth on Android (P1)

**Goal**: Complete the local-first portfolio product without requiring network or Google authorization.
**Independent Test**: Complete onboarding, add/edit/delete mixed-currency assets and liabilities, relaunch, and verify totals, history, goals, settings, export, and import.

- [ ] T017 [P] [US1] Add onboarding, currency picker, CRUD, navigation, and empty-state Compose tests in `../../Android/MyWealth/app/src/androidTest/java/com/bxvdev/mywealth/ui/CoreJourneyTest.kt`
- [ ] T018 [P] [US1] Add repository integration tests for assets, liabilities, snapshots, goals, and settings in `../../Android/MyWealth/app/src/androidTest/java/com/bxvdev/mywealth/data/repository/PortfolioRepositoryTest.kt`
- [ ] T019 [US1] Implement lifecycle-safe root state and adaptive five-destination navigation in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/navigation/WealthMapNavHost.kt`
- [ ] T020 [US1] Implement complete onboarding including base/display currencies, reminder choice, optional sync choice, and validation in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/onboarding/`
- [ ] T021 [US1] Implement searchable and reorderable currency selection in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/currency/`
- [ ] T022 [US1] Implement asset/liability list, details, add/edit/delete, inclusion controls, and precious-metal entry in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/assets/`
- [ ] T023 [US1] Implement Dashboard totals, insights, allocation, history preview, goal summary, and share action in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/dashboard/`
- [ ] T024 [US1] Implement Net Worth totals, rate status, trend, history, and goal workflows in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/networth/`
- [ ] T025 [US1] Implement Rates transfer rows, refresh, status, and metal prices in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/rates/`
- [ ] T026 [US1] Implement deterministic Briefing and FIRE surfaces in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/briefing/`
- [ ] T027 [US1] Implement Settings for currency, compact totals, reminders, backup/import, sync, cleanup, and app version in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/settings/`
- [ ] T028 [US1] Wire view models and repositories for every primary destination in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/viewmodel/`
- [ ] T029 [US1] Replace the prototype activity/navigation wiring with the application container and root app in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/MainActivity.kt`

## Phase 4: User Story 2 — Remain Local and Useful Offline (P1)

**Goal**: Guarantee useful offline behavior and zero unintended financial-data uploads.
**Independent Test**: Disable network and cloud authorization, exercise all local workflows, and inspect outbound payloads and backup eligibility.

- [ ] T030 [P] [US2] Add offline, missing-rate, backup-exclusion, and log-redaction tests in `../../Android/MyWealth/app/src/test/java/com/bxvdev/mywealth/privacy/LocalFirstPrivacyTest.kt`
- [ ] T031 [US2] Implement typed app errors and redacted diagnostics without stack-trace or payload logging in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/app/AppError.kt`
- [ ] T032 [US2] Implement offline-first refresh/status orchestration and pending-work state in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/repository/RefreshCoordinator.kt`
- [ ] T033 [US2] Implement the typed telemetry allowlist and no-op/fake-safe initialization boundary in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/telemetry/AnalyticsService.kt`
- [ ] T034 [US2] Add privacy and offline status copy/actions to Settings and rate surfaces in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/settings/SettingsScreen.kt`

## Phase 5: User Story 3 — Opt In to Google Account Backup and Sync (P1)

**Goal**: Reconcile supported portfolio data through the user's Drive app-data folder after explicit authorization.
**Independent Test**: Enable sync on populated device A, restore on device B, edit different records offline, reconnect, and verify convergence.

- [ ] T035 [P] [US3] Add sync envelope validation, digest, merge, tombstone, retry, and schema-version tests in `../../Android/MyWealth/app/src/test/java/com/bxvdev/mywealth/data/sync/SyncMergeEngineTest.kt`
- [ ] T036 [P] [US3] Add fake Drive client and WorkManager orchestration tests in `../../Android/MyWealth/app/src/test/java/com/bxvdev/mywealth/data/sync/DriveSyncCoordinatorTest.kt`
- [ ] T037 [US3] Implement the versioned sync envelope, serializer, validation, and digest in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/SyncEnvelope.kt`
- [ ] T038 [US3] Implement deterministic record/settings/tombstone merge rules in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/SyncMergeEngine.kt`
- [ ] T039 [US3] Implement on-demand `drive.appdata` authorization and token/account state behind an interface in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/GoogleDriveAuthorization.kt`
- [ ] T040 [US3] Implement conditional app-data file create/list/download/update behavior behind a fakeable client in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/GoogleDriveAppDataClient.kt`
- [ ] T041 [US3] Implement transactional reconciliation and sync checkpoints in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/DriveSyncCoordinator.kt`
- [ ] T042 [US3] Implement unique post-write, foreground, manual, and periodic sync work in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/DriveSyncWorker.kt`

## Phase 6: User Story 4 — Recover Safely Across Accounts and Devices (P2)

**Goal**: Prevent silent account mixing and data loss during conflict, revocation, or interruption.
**Independent Test**: Switch accounts, interrupt sync/import, and create concurrent update/delete/goal conflicts.

- [ ] T043 [P] [US4] Add account isolation, profile switch, interrupted apply, and goal-conflict tests in `../../Android/MyWealth/app/src/test/java/com/bxvdev/mywealth/data/sync/AccountProfileManagerTest.kt`
- [ ] T044 [US4] Implement opaque account-scoped database profile selection and local-only fallback in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/AccountProfileManager.kt`
- [ ] T045 [US4] Implement sync status and account-change decision models in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/SyncStatus.kt`
- [ ] T046 [US4] Implement initial-sync, account-change, conflict, pause, retry, disconnect, and disable UX in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/screens/settings/SyncSettingsScreen.kt`
- [ ] T047 [US4] Add transactional recovery markers and stale-work cancellation to import and sync services in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/data/sync/DriveSyncCoordinator.kt`

## Phase 7: User Story 5 — Android-Native and Accessible Experience (P2)

**Goal**: Complete platform-native reminders, widgets, localization, adaptive layouts, and accessibility.
**Independent Test**: Exercise compact/expanded devices, TalkBack, 200% font, Arabic RTL, permission denial, and widget states.

- [ ] T048 [P] [US5] Add reminder scheduling and smart-suppression tests in `../../Android/MyWealth/app/src/test/java/com/bxvdev/mywealth/notifications/ReminderSchedulerTest.kt`
- [ ] T049 [P] [US5] Add widget projection and empty/populated state tests in `../../Android/MyWealth/app/src/test/java/com/bxvdev/mywealth/widget/WidgetSnapshotTest.kt`
- [ ] T050 [US5] Implement reminder models, DataStore persistence, notification channel/permission handling, and WorkManager scheduling in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/notifications/`
- [ ] T051 [US5] Implement responsive Glance widgets and local widget snapshot refreshes in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/widget/`
- [ ] T052 [US5] Add English, Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, and Arabic resources in `../../Android/MyWealth/app/src/main/res/values*/`
- [ ] T053 [US5] Replace hard-coded user copy and add locale-aware currency/date/percent formatting in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/`
- [ ] T054 [US5] Complete compact/expanded/foldable layouts, TalkBack semantics, 200% font resilience, reduced motion, contrast, and RTL behavior in `../../Android/MyWealth/app/src/main/java/com/bxvdev/mywealth/ui/`
- [ ] T055 [US5] Add locale, RTL, large-font, accessibility, adaptive navigation, reminder-permission, and widget UI tests in `../../Android/MyWealth/app/src/androidTest/java/com/bxvdev/mywealth/ui/AccessibilityLocaleTest.kt`

## Final Phase: Integration and Release Evidence

- [ ] T056 Run and fix JVM tests with `../../Android/MyWealth/gradlew testDebugUnitTest`
- [ ] T057 Run and fix Android lint with `../../Android/MyWealth/gradlew lintDebug`
- [ ] T058 Run and fix debug assembly and instrumented tests with `../../Android/MyWealth/gradlew assembleDebug connectedDebugAndroidTest`
- [ ] T059 Record FR/NFR parity evidence, platform adaptations, migration results, and sync/privacy results in `../../Android/MyWealth/README.md`
- [ ] T060 Run `git diff --check` in both repositories and mark all completed tasks in `specs/004-android-app/tasks.md`

## Dependencies

- Phase 1 precedes all implementation.
- Phase 2 blocks every user story.
- US1 delivers the local product and blocks widget/sync UI integration.
- US2 can proceed after Phase 2 and must pass before enabling any cloud work.
- US3 depends on US1 data/repositories and US2 privacy boundaries.
- US4 depends on US3 sync interfaces.
- US5 reminders can follow Phase 2; widgets and adaptive UI depend on US1.

## Parallel Opportunities

- T007-T009 can run independently before T010-T016.
- T017 and T018 can be prepared in parallel.
- T030 can run while local UI work is being completed.
- T035 and T036 cover independent sync layers.
- T048 and T049 cover independent Android platform features.

## Implementation Strategy

1. Establish a secure, migratable local foundation.
2. Ship a complete local-only Android product before cloud sync.
3. Add privacy verification before Drive authorization.
4. Add deterministic sync and account recovery behind fakeable interfaces.
5. Finish Android-native widgets, reminders, localization, accessibility, and release gates.
