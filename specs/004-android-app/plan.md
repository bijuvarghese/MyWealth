# Implementation Plan: Android Wealth Map Parity

**Branch**: `004-android-app` | **Date**: June 30, 2026 | **Spec**: [spec.md](spec.md)
**Input**: `/specs/004-android-app/spec.md`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`

## Summary

Deliver the Android Wealth Map app with user-observable parity to
`FR1.1`-`FR14.8` while preserving the existing Android package and prototype
data. Use Jetpack Compose with adaptive Material 3 navigation, Room as the
offline source of truth, DataStore for settings, WorkManager for persistent
work, Glance for home-screen widgets, and the existing Firebase HTTPS proxies.

Replace iCloud with an explicit opt-in Google Drive `appDataFolder` integration.
The app will synchronize a versioned, mergeable portfolio envelope stored in
the user's Google account; no developer-operated portfolio database is added.
Android Auto Backup will not contain financial data because it is neither an
explicit Wealth Map opt-in nor a continuous multi-device sync mechanism.

## Requirements Traceability

| Requirement | Planned change | Design surface | Verification |
|-------------|----------------|----------------|--------------|
| FR1.1-FR1.15, SFR-001, SFR-002, SFR-006-SFR-008, SFR-011-SFR-013 | Extend the prototype onboarding and add a real Settings flow, reminder choice, compact totals, backup/import, and opt-in Google Drive sync. | `ui/onboarding/`, `ui/settings/`, `data/preferences/`, `data/sync/` | Onboarding, persistence, settings, and sync opt-in UI tests. |
| FR2.1-FR2.8, SFR-001, SFR-007 | Port the full currency catalog, localized names, search, common ordering, required base currency, and user ordering. | `domain/currency/`, currency picker UI, settings repository | Catalog/search/order unit tests and Compose picker tests. |
| FR3.1-FR3.11, FR4.1-FR4.10, SFR-001, SFR-002, SFR-019 | Migrate the prototype asset table and add liabilities, stable history IDs, complete categories, inclusion state, validation, and CRUD. | Room entities/DAOs/migrations, asset/liability repositories and screens | Migration tests from Room v1 plus CRUD and validation tests. |
| FR5.1-FR5.8, SFR-001 | Add Dashboard, Assets, Net Worth, Rates, and Briefing destinations with Settings available from Dashboard and Briefing; adapt phone/tablet navigation. | `ui/navigation/`, destination screens, Material 3 adaptive scaffold | Compact/expanded navigation and state-restoration UI tests. |
| FR6.1-FR6.16, SFR-001, SFR-002 | Port totals, insights, allocation, rate status, trend, recent history, ordering, and explicit text sharing. | `domain/calculation/`, dashboard/net-worth view models and screens | Golden calculation fixtures, empty/stale UI tests, sharesheet intent test. |
| FR7.1-FR7.16, SFR-004, SFR-020 | Remove the direct third-party rate call; use configured Firebase endpoints, typed failures, local cache, missing-rate refresh, and USD=1. | `data/remote/`, `data/cache/`, `BuildConfig`, repositories | Mock HTTP contract tests, cache-day boundary tests, offline tests. |
| FR8.1-FR8.12, SFR-008, SFR-016 | Implement device-local reminders with Android permission handling, durable scheduling, smart suppression, and legacy preference migration. | `notifications/`, WorkManager, DataStore, reminder settings UI | WorkManager tests, permission-denial UI tests, reboot/time-zone checks. |
| FR9.1-FR9.10, SFR-007, SFR-009 | Add all snapshot entities and thresholds, portfolio scope metadata, deterministic ordering, and bounded queries. | Room snapshot tables/DAOs, history coordinator, calculation layer | Snapshot threshold, duplicate, scope-change, and query-limit tests. |
| FR10.1-FR10.13, SFR-002-SFR-014, SFR-019 | Use Room/DataStore, compatible `.backup` v2 import/export, account-isolated Drive sync profiles, and transactional recovery. | persistence, portability, sync envelope/engine, account profile manager | Room migration, backup fixtures, two-client merge, rollback, and privacy tests. |
| FR11.1-FR11.6, SFR-015 | Add responsive Android home-screen widgets backed by a minimized local snapshot and explicit refreshes. | `widget/` with Glance, widget snapshot repository | Empty/populated/multi-currency widget tests and update trigger checks. |
| FR12.1-FR12.16, SFR-001, SFR-005, SFR-007 | Port one-goal storage, validation, progress, projections, remaining-gap guidance, deletion, and backup/sync behavior. | Room goal entity/DAO, domain calculator, goal UI | Goal state matrix, projection edge cases, backup/sync conflict tests. |
| FR13.1-FR13.9, SFR-018 | Add an app-owned typed telemetry boundary; initialize Firebase optionally and preserve the behavior-only allowlist. | `telemetry/`, app initialization, call sites | Fake telemetry sink tests and payload allowlist audit. |
| FR14.1-FR14.8, SFR-017 | Move all copy to resources for the eight MVP locales; use locale-aware number/date formatting and Arabic RTL. | `res/values-*`, display adapters, widget/notification resources | Resource completeness, fallback, raw-value, formatting, and RTL tests. |
| NFR1.1-NFR1.4 | Establish the Android platform baseline without changing the iOS baseline. | Gradle version catalog, build files, CI | Clean Gradle build on the pinned JDK/SDK toolchain. |
| NFR2.1-NFR2.7 | Use native Compose, adaptive navigation, clear validation, accessible actions, and large-value formatting. | all Compose surfaces | TalkBack, 200% font, compact/expanded, destructive-action checks. |
| NFR3.1-NFR3.4 | Keep database/network/sync work off the main thread and bound history queries. | coroutines, Room, repositories, WorkManager | dispatcher tests, query limits, macrobenchmark baseline where practical. |
| NFR4.1-NFR4.8 | Preserve typed errors and safe empty, stale, scheduling, persistence, and widget behavior. | result/error types, repositories, workers | failure-injection tests across network, Room, Drive, widgets, and reminders. |
| NFR5.1-NFR5.7 | Preserve secrets and local-first privacy; disable unintended Android cloud backup of financial stores. | manifest/backup rules, Firebase config, Drive authorization, logging | APK/source secret scan, backup-rule test, network payload inspection. |
| NFR6.1-NFR6.9 | Introduce clear UI/domain/data boundaries and protocol-style interfaces for providers, sync, scheduling, portability, and telemetry. | package architecture and app container | dependency-direction tests/code review plus fake-driven unit tests. |

## Technical Context

**Language/Version**: Kotlin 2.2.10; Java 17 toolchain; AGP 9.2.1

**Primary Dependencies**: Jetpack Compose/Material 3, Material 3 Adaptive,
Navigation Compose, Lifecycle/ViewModel, Kotlin coroutines/Flow, Room 2.8.4,
DataStore, WorkManager, Retrofit/OkHttp, Kotlin serialization, Google Identity
Services `AuthorizationClient`, Google Drive API v3, Glance, AndroidX Security
where local token metadata requires protection, and optional Firebase
Analytics/Crashlytics

**Storage**: Room for portfolio records, history, goals, tombstones, and local
caches; DataStore for settings and sync state; a versioned file in the
authorized Google Drive `appDataFolder` for optional sync; no financial data in
uncontrolled Android Auto Backup

**Testing**: JVM unit tests, Room migration/in-memory tests, WorkManager tests,
fake Drive and HTTP clients, Android instrumented tests, Compose UI tests,
Glance tests, localization/RTL checks, and Gradle lint/build gates

**Target Platform**: Android API 24 minimum, target/compile SDK 36.1, phones,
tablets, and foldables

**Project Type**: Existing single-module Android application in the separate
`../../Android/MyWealth` Git repository; Spec Kit artifacts remain in the iOS
requirements repository because it owns the product baseline

**Performance Goals**: Cold launch reaches locally available content without
waiting for network or Drive; local CRUD visibly updates within one frame after
Room emits; calculations stay interactive for 1,000 active records and 10,000
history rows; list/history queries are bounded; sync and import never block the
main thread

**Constraints**: Local-first privacy, explicit cloud opt-in, no direct provider
keys/calls, eventual Android background scheduling, stable package and raw
identifiers, deterministic merge rules, transactional migrations, and no iOS
code or deployed endpoint changes

**Scale/Scope**: Five primary destinations, Settings and onboarding, six core
Room record families plus sync metadata, eight locales, one widget family with
responsive sizes, reminders, three Firebase proxy clients, backup/import, and
one Google Drive sync file per authorized account

## Constitution Check

*GATE: Passed before research and re-checked after design.*

- **Privacy by Default**: PASS. Room remains authoritative and cloud sync is
  off by default. Google Drive receives portfolio data only after a user grants
  the app-data scope. Auto Backup is excluded for financial stores. No
  developer-operated portfolio database is introduced.
- **Financial Correctness**: PASS. Decimal amounts use canonical decimal
  storage, rate completeness gates calculations, and migrations, merge rules,
  snapshots, goals, imports, and conflict cases receive focused tests.
- **Compatibility**: PASS. The Android package and existing prototype data are
  preserved through explicit migrations. iOS identifiers and backend endpoints
  do not change. Backup v2 and sync schema versions are documented.
- **Native Product Quality**: PASS. Compose, Material 3 adaptive navigation,
  Android Sharesheet, notification permission behavior, Glance, TalkBack,
  large fonts, RTL, and compact/expanded layouts replace Apple-specific UI.
- **Architecture**: PASS. UI, domain, local data, remote data, sync, scheduling,
  portability, widgets, and telemetry have testable boundaries. New libraries
  directly replace required Apple platform capabilities.
- **Verification**: PASS. Each baseline area maps to unit, persistence,
  worker/client, UI, accessibility, localization, or integration evidence.
- **Scope Discipline**: PASS. The plan targets shipped baseline parity and the
  requested cloud adaptation; aggregation, sharing, and iOS changes are
  explicitly excluded.

## Project Structure

### Documentation (this feature)

```text
specs/004-android-app/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── contracts/
    ├── google-drive-sync.md
    └── ios-android-parity.md
```

### Source Code

```text
../../Android/MyWealth/
├── app/
│   ├── schemas/                         # exported Room schemas
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── java/com/bxvdev/mywealth/
│       │   │   ├── app/                 # Application and AppContainer
│       │   │   ├── data/
│       │   │   │   ├── local/           # Room entities, DAOs, migrations
│       │   │   │   ├── preferences/     # DataStore
│       │   │   │   ├── remote/          # Firebase proxy clients/caches
│       │   │   │   ├── repository/
│       │   │   │   └── sync/            # Drive auth, envelope, merge, worker
│       │   │   ├── domain/
│       │   │   │   ├── calculation/
│       │   │   │   ├── currency/
│       │   │   │   └── model/
│       │   │   ├── notifications/
│       │   │   ├── portability/
│       │   │   ├── telemetry/
│       │   │   ├── ui/
│       │   │   │   ├── navigation/
│       │   │   │   ├── screens/
│       │   │   │   ├── components/
│       │   │   │   └── theme/
│       │   │   └── widget/
│       │   └── res/values*/
│       ├── test/
│       └── androidTest/
├── build.gradle.kts
├── gradle/libs.versions.toml
└── settings.gradle.kts
```

**Structure Decision**: Keep the existing single application module and
package ID. Use a small manual `AppContainer` rather than adding a dependency
injection framework during parity work. Split packages by responsibility so
Compose screens depend on view models/domain interfaces, while Room, Retrofit,
Drive, WorkManager, Glance, and Firebase implementations stay replaceable in
tests.

## Data and Migration Design

- **Models/schema**: Export the existing Room v1 schema before changes. Add
  explicit migrations for liabilities, snapshots, portfolio snapshots, one
  goal, decimal-safe amount columns, inclusion/metal metadata, sync tombstones,
  and cache tables. Preserve current asset UUIDs; backfill history identifiers
  and canonical decimal strings transactionally. Never use destructive
  migration in production.
- **Settings/identifiers**: Preserve existing onboarding, base currency, and
  display-currency keys. Add ordered currencies, compact formatting, history
  scope, reminders, sync enabled/account context/status, and cache metadata.
  Onboarding, reminders, authorization, and device identity never sync.
- **Backup/import**: Implement iOS-compatible backup envelope version 2 with
  ISO-8601 dates and stable raw values. Import versions 1 and 2 transactionally,
  preview goal conflicts, reject unsupported future versions, and use the
  Storage Access Framework for explicit file selection.
- **iCloud/widget/server propagation**: iCloud is unchanged. On Android, Drive
  sync includes supported Room records and selected lightweight settings.
  Widgets read only the local widget snapshot. Firebase continues to receive
  only rate/metal requests and explicitly invoked sanitized analysis payloads.
- **Rollback/recovery**: Write database migrations before feature code, retain
  the last valid local state, validate remote/import envelopes before mutation,
  use Room transactions, keep sync checkpoints only after successful remote
  writes, and preserve remote data when sync is disabled or a release is rolled
  back.

## Google Drive Sync Design

Google Drive `appDataFolder` is the Android iCloud analogue:

- Request the non-sensitive `drive.appdata` scope only when the user enables
  sync; do not make Google account connection a prerequisite for local use.
- Store one versioned `wealth-map-sync-v1.json` envelope per authorized account.
  The folder is hidden and only this app can access its contents.
- Associate local data with an opaque, locally protected account profile.
  A changed account pauses sync and opens an explicit keep-local, switch, or
  merge decision; no automatic cross-account merge occurs.
- Reconcile on initial enable, foreground entry, manual refresh, and debounced
  post-write one-time work. Add constrained periodic WorkManager reconciliation
  as a safety net, acknowledging Android does not guarantee exact execution.
- Merge records by type and stable ID. Highest modification timestamp wins;
  equal timestamps use a stable mutation ID tie-break; a deletion tombstone
  wins an exact tie. Goal reconciliation preserves one valid active goal.
- Use the remote file ETag/version for conditional update. On a precondition
  failure, download, merge, and retry with exponential backoff.
- Validate and merge into Room transactionally. A remote failure never rolls
  back a valid local user edit; it leaves sync pending.
- Never place Drive payloads, tokens, account identity, or financial values in
  logs, analytics, notifications, widgets, crash keys, or source control.

## Delivery Phases

### Phase 0 — Safety and Build Baseline

1. Capture the Room v1 schema and baseline tests before changing entities.
2. Remove the direct `open.er-api.com` endpoint and `printStackTrace`; introduce
   configured Firebase proxy interfaces and typed errors.
3. Exclude financial stores from Android Auto Backup and document the explicit
   Drive/manual-backup paths.
4. Add CI commands for unit tests, lint, debug assembly, and instrumented tests.

**Exit gate**: Existing prototype builds, valid prototype data migrates in a
test, no direct provider call remains, and no financial database is included in
unconsented cloud backup.

### Phase 1 — Persistence and Domain Foundation

1. Introduce the complete Room schema, DAOs, migrations, decimal converters,
   stable IDs, tombstones, and bounded history queries.
2. Expand DataStore settings while preserving prototype keys.
3. Add repository interfaces and pure calculators for conversion, totals,
   allocation, insights, snapshots, goals, and projections.
4. Implement compatible backup v1/v2 decode, v2 encode, preview, and
   transactional apply.

**Exit gate**: Persistence, migration, calculation, snapshot, goal, and backup
fixtures pass without Compose or network dependencies.

### Phase 2 — Core Local Product

1. Complete onboarding and searchable/ordered currency selection.
2. Add adaptive primary navigation and real Settings destinations.
3. Complete asset/liability CRUD, categories, inclusion behavior, metal entry,
   and destructive confirmations.
4. Build Dashboard, Assets, Net Worth, Rates, and base Briefing surfaces from
   local repositories.

**Exit gate**: A local-only user can complete all FR1-FR6 record and navigation
journeys offline after rates have been cached.

### Phase 3 — Rates, History, Goals, and Intelligence

1. Integrate Firebase exchange-rate and metal-price caches with completeness,
   daily refresh, stale status, and failure behavior.
2. Wire snapshot recording, trends, allocation, insights, history scope, and
   bounded charts.
3. Add goal forms, progress, projection states, remaining-gap guidance, and
   backup behavior.
4. Complete FIRE and deterministic Briefing calculations; add sanitized AI
   analysis only after its explicit action and payload tests are complete.

**Exit gate**: Golden iOS/Android calculation fixtures match within documented
display precision and all missing-rate cases remain unavailable rather than
partial.

### Phase 4 — Android Platform Features

1. Add reminders using WorkManager for durable inexact cadence, handling
   notification permission, reboot/time-zone changes, and smart suppression.
2. Add Glance widgets backed by the local widget snapshot and refresh triggers.
3. Add Storage Access Framework import/export and Android Sharesheet progress
   sharing.
4. Add typed Firebase telemetry/Crashlytics boundaries with the iOS allowlist.

**Exit gate**: Permission denial, process death, empty widget, reminder, share,
and telemetry privacy tests pass.

### Phase 5 — Google Drive Backup and Sync

1. Configure Drive API/OAuth branding and Android client IDs for debug/release
   package signatures; add on-demand app-data authorization.
2. Implement account context, sync envelope codec/validation, merge engine,
   conditional Drive client, and fake client test suite.
3. Add initial sync, account isolation, status UI, post-write/foreground/manual
   triggers, periodic safety-net work, cancellation, retry, and revocation
   behavior.
4. Run two-client conflict, delete, goal, account-switch, offline, interrupted
   upload, and schema-version scenarios.

**Exit gate**: Same-account devices converge without duplicate active records;
different accounts never mix without an explicit choice; disabling sync leaves
both local and remote copies intact.

### Phase 6 — Localization, Accessibility, and Release Hardening

1. Complete all eight locale resource sets, plural/formatting behavior, Arabic
   RTL, localized widgets, reminders, validation, statuses, and share text.
2. Audit TalkBack labels/actions, 200% font scale, reduced motion, contrast,
   compact/expanded/foldable layouts, long labels, and large values.
3. Run migration from the prototype, backup interoperability, clean-install,
   upgrade/downgrade safety, privacy, dependency, lint, and release-build gates.

**Exit gate**: Every baseline row has recorded Android evidence or an approved
platform adaptation, with no open P0/P1 correctness, privacy, migration, or
accessibility defect.

## Verification Plan

- **Focused tests**: Currency/catalog behavior; decimal conversion and totals;
  asset/liability validation; snapshot thresholds and scopes; goal states;
  reminder calculations; backup versions; sync merge/tombstone/account rules;
  Firebase response/cache behavior; telemetry allowlist.
- **Regression tests**: Room v1 migration, existing DataStore keys, local-only
  startup, offline CRUD, display order, USD=1, missing-rate behavior, no direct
  provider calls, raw enum/backup compatibility, no Auto Backup leakage.
- **UI/accessibility checks**: API 24 and API 36.1; phone, tablet, foldable
  emulation; light/dark; 200% font; TalkBack; reduced motion; all MVP locales;
  Arabic RTL; empty/loading/stale/missing/error/destructive states.
- **Backend checks**: Reuse the existing Firebase function package tests.
  Android adds HTTP contract tests against captured safe fixtures and a staging
  endpoint smoke test; no provider keys enter Android configuration.
- **Android gates**:

  ```sh
  cd ../../Android/MyWealth
  ./gradlew testDebugUnitTest
  ./gradlew lintDebug
  ./gradlew assembleDebug
  ./gradlew connectedDebugAndroidTest
  ```

- **Repository hygiene**:

  ```sh
  git -C ../../Android/MyWealth diff --check
  git diff --check
  ```

## Complexity Tracking

| Violation or addition | Why needed | Simpler alternative rejected because | Approval/migration |
|-----------------------|------------|--------------------------------------|--------------------|
| Google Drive API + Google Identity Services | Provides explicit, user-account-owned Android backup/sync without a developer portfolio backend. | Auto Backup is delayed and not app-controlled; Firestore changes the privacy boundary. | New sync schema and OAuth setup are isolated behind interfaces; local-only remains default. |
| WorkManager | Required for durable reminders and eventual sync after process death/reboot. | Coroutines stop with the process and cannot satisfy persistent work. | Workers use stable unique names and test helpers. |
| Material 3 Adaptive and Glance | Required native equivalents for iPad-style adaptive navigation and WidgetKit summaries. | Fixed phone navigation and custom RemoteViews would duplicate platform behavior. | Added only when the corresponding parity phase begins. |
| Sync merge metadata/tombstones | Prevents duplicate, lost, or resurrected records across devices. | Whole-file last-write-wins can silently discard concurrent financial edits. | Versioned envelope, deterministic merge contract, migrations, and rollback tests are mandatory. |
