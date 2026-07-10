# Research: Android Wealth Map Parity

## Decision 1: Use Google Drive `appDataFolder` as the iCloud analogue

**Decision**: Store the opt-in Android sync envelope in the Google Drive
`appDataFolder` authorized with the narrow `drive.appdata` scope.

**Rationale**:

- Google documents `appDataFolder` as a hidden, application-specific folder
  accessible only by the creating app and hidden from users and other Drive
  apps.
- The scope is classified as non-sensitive and can be requested only when the
  user enables sync.
- Data remains in the user's Google account and no developer-operated
  portfolio database is required.
- The Drive API supports create, list, download, and update operations needed
  for a versioned sync envelope.

**Alternatives considered**:

- **Cloud Firestore**: Strong automatic offline/realtime synchronization, but it
  places portfolio data in a developer-controlled Firebase project and changes
  the iOS privacy boundary. Rejected for this feature.
- **Visible user-selected Drive files**: Good for manual backup/export but poor
  for automatic reconciliation and easier for users to modify accidentally.
- **OneDrive/Dropbox**: Not the native default on Android and would add another
  provider/account dependency.

**Sources**:

- [Google Drive application data folder](https://developers.google.com/workspace/drive/api/guides/appdata)
- [Android authorization guidance](https://developer.android.com/identity/authorization)

## Decision 2: Do not use Android Auto Backup as multi-device sync

**Decision**: Exclude Wealth Map financial stores from Android Auto Backup.
Rely on explicit Drive sync and explicit `.backup` export for recovery.

**Rationale**:

- Auto Backup normally runs only after at least 24 hours under device/network
  conditions and may never run.
- It stores only the latest backup, has a 25 MB quota, and is designed for
  restore rather than deterministic concurrent multi-device reconciliation.
- It can upload Room and preference files without an in-app Wealth Map opt-in,
  conflicting with the local-first privacy contract.

**Alternatives considered**:

- **Auto Backup plus Drive sync**: Creates two independent restore paths and can
  reintroduce stale database state. Rejected for financial stores.
- **Auto Backup only**: Does not meet cross-device freshness or conflict
  requirements.

**Source**:

- [Android Auto Backup](https://developer.android.com/identity/data/autobackup)

## Decision 3: Keep Room as the offline source of truth

**Decision**: Expand the existing Room database with explicit migrations and
observe it through Flow. Drive and Firebase clients update Room through
repositories; Compose never reads remote state directly.

**Rationale**:

- Room provides compile-time SQL validation, migration support, transactions,
  and offline access.
- Local CRUD remains instant and independent of network/account state.
- A single source of truth avoids split-brain UI between remote and local data.

**Alternatives considered**:

- **Replace Room with Firestore cache**: Violates the chosen privacy boundary
  and makes optional sync foundational.
- **Rewrite the prototype database**: Risks losing existing Android data.

**Source**:

- [Save data locally with Room](https://developer.android.com/training/data-storage/room)

## Decision 4: Keep small settings in DataStore

**Decision**: Preserve the existing Preferences DataStore keys and expand them
for settings, reminder, cache, and sync status metadata. Complex financial
records remain in Room.

**Rationale**:

- DataStore provides asynchronous, transactional settings updates with Flow.
- Preserving current keys avoids losing prototype onboarding/currency state.
- Device-only and syncable settings can be classified explicitly.

**Alternatives considered**:

- **Proto DataStore migration now**: Adds schema and migration work without
  improving the core parity outcome. Revisit after parity.
- **SharedPreferences**: Inferior consistency and coroutine integration.

**Source**:

- [Jetpack DataStore](https://developer.android.com/topic/libraries/architecture/datastore)

## Decision 5: Use WorkManager for durable sync and reminders

**Decision**: Use unique one-time WorkManager jobs after local changes and on
manual requests, plus constrained periodic reconciliation. Use device-local
work for reminders with platform-appropriate timing expectations.

**Rationale**:

- WorkManager persists across app restarts and device reboots, supports network
  constraints, unique work, retry, and backoff.
- Android does not guarantee exact periodic execution, so foreground and
  post-write sync remain the primary freshness triggers.
- Coroutines remain appropriate for in-process work but are insufficient after
  process death.

**Alternatives considered**:

- **Only app-scope coroutines**: Lose pending work on process death.
- **AlarmManager for all work**: Unnecessarily exact and power-expensive;
  reserve exact alarms for a future requirement that truly needs them.

**Sources**:

- [Android persistent work](https://developer.android.com/develop/background-work/background-tasks/persistent)
- [WorkManager getting started](https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started)

## Decision 6: Use versioned record merge, not whole-file last-write-wins

**Decision**: Sync one versioned Drive file but merge its records individually
by stable ID with modification metadata, tombstones, deterministic tie-breaks,
and conditional remote updates.

**Rationale**:

- Whole-file last-write-wins can silently discard unrelated edits from another
  device.
- Stable record identities already exist in the product/backup contracts.
- Tombstones prevent deleted records from being recreated by an offline device.
- A versioned envelope permits additive schema evolution and safe rejection of
  unsupported future formats.

**Alternatives considered**:

- **One file per record**: More Drive operations, complicated compaction and
  change tracking, and harder atomic portfolio validation.
- **Whole-file newest timestamp wins**: Simpler but unacceptable data-loss risk.
- **Custom sync backend**: Better realtime control but violates the requested
  personal-cloud boundary.

## Decision 7: Use adaptive Material 3 navigation and Glance

**Decision**: Use Material 3 adaptive navigation for compact/expanded primary
destinations and Glance for responsive home-screen widgets.

**Rationale**:

- Adaptive navigation naturally maps phone bottom navigation to larger-screen
  rails without duplicating destination logic.
- Glance is the supported Kotlin/Compose-style framework for Android widgets.
- Apple lock-screen widget families have no universal Android equivalent, so
  the plan preserves information parity through responsive home widgets.

**Alternatives considered**:

- **Fixed bottom navigation**: Poor tablet/foldable experience.
- **Custom RemoteViews widgets**: More imperative duplication without a product
  benefit.

**Sources**:

- [Build adaptive navigation](https://developer.android.com/develop/adaptive-apps/guides/build-adaptive-navigation)
- [Jetpack Glance](https://developer.android.com/develop/ui/compose/glance)

## Decision 8: Preserve locale set with Android resources

**Decision**: Use default English resources plus `values-hi`, `values-es`,
`values-pt-rBR`, `values-fr`, `values-de`, `values-zh-rCN`, and `values-ar`;
keep raw currencies/categories outside localized storage.

**Rationale**:

- Android resource selection provides locale fallback and RTL layout behavior.
- Separating display strings from persisted raw values preserves backup, sync,
  calculation, and analytics compatibility.
- Arabic previews and device tests can validate RTL before release.

**Alternatives considered**:

- **Runtime/server translation**: Adds privacy, latency, and consistency risk.
- **In-app language picker in V1**: Not required by the iOS baseline.

**Source**:

- [Localize Android apps](https://developer.android.com/guide/topics/resources/localization)

## Decision 9: Preserve the existing Android package and migrate incrementally

**Decision**: Keep `com.bxvdev.mywealth`, Room database
`mywealth_database`, and existing DataStore keys. Add migrations and stable
contracts before expanding features.

**Rationale**:

- These identifiers already exist in the Android prototype and may be present
  on test devices.
- OAuth Android client IDs and future Play releases depend on stable package
  and signing identities.
- Incremental migration provides evidence that the prototype is not silently
  discarded.

**Alternatives considered**:

- **Rename to match the iOS bundle**: Creates no user value and complicates
  OAuth, app identity, and upgrades.
- **Delete and regenerate the project**: Loses the current implementation and
  any local prototype data.
