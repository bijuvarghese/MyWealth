# Feature Specification: Android Wealth Map Parity

**Feature Branch**: `004-android-app`
**Created**: June 30, 2026
**Status**: Draft
**Input**: User description: "Implement the Android app from the iOS requirements and provide an Android equivalent to optional iCloud sync."
**Baseline**: `requirements.md` and `.specify/memory/requirements-context.md`

## Baseline Impact *(mandatory)*

**Change Type**: Additive feature

| Requirement ID | Disposition | Impact and regression expectation |
|----------------|-------------|-----------------------------------|
| FR1.1-FR1.15 | Adapt | Deliver equivalent onboarding and settings behavior using Android-native navigation, preferences, backup, and opt-in sync controls. |
| FR2.1-FR2.8 | Preserve | Use the same currency catalog, search, ordering, base-currency, and refresh semantics. |
| FR3.1-FR4.10 | Preserve | Deliver equivalent asset and liability creation, validation, editing, deletion, category, and timestamp behavior with stable identifiers. |
| FR5.1-FR5.8 | Adapt | Deliver Dashboard, Assets, Net Worth, Rates, and Briefing destinations with adaptive Android navigation and accessible Settings entry points. |
| FR6.1-FR6.16 | Preserve | Match net-worth calculations, ordering, insights, history, empty states, and user-initiated text sharing. |
| FR7.1-FR7.16 | Preserve | Use the existing Firebase proxy and cache contract; remove direct external-provider access from the Android client. |
| FR8.1-FR8.12 | Adapt | Match reminder behavior with Android notification permission, scheduling, badge-safe handling, and device-local preferences. |
| FR9.1-FR9.10 | Preserve | Match snapshot thresholds, ordering, history scopes, and liability-aware net-worth history. |
| FR10.1-FR10.13 | Adapt | Use Android local persistence, preserve the portable backup format, and substitute opt-in Google-account app-data sync for iCloud. |
| FR11.1-FR11.6 | Adapt | Deliver Android home-screen widgets with equivalent snapshot content and update behavior; lock-screen widgets remain platform-dependent. |
| FR12.1-FR12.16 | Preserve | Match single-goal validation, progress, projection, persistence, backup, and privacy behavior. |
| FR13.1-FR13.9 | Adapt | Use an Android-owned telemetry wrapper with the same behavior-only allowlist and financial-data prohibitions. |
| FR14.1-FR14.8 | Preserve | Support the same languages, English fallback, locale-aware formatting, stable raw values, and Arabic right-to-left behavior. |
| NFR1.1-NFR1.4 | Adapt | Replace Apple-specific tooling with a supported Kotlin, Android SDK, Jetpack Compose, Room, and Gradle baseline. |
| NFR2.1-NFR2.7 | Adapt | Use native Android navigation, forms, search, adaptive layouts, destructive-action confirmation, and accessibility patterns. |
| NFR3.1-NFR3.4 | Preserve | Keep network, calculations, persistence, and bounded history work off the main thread and responsive. |
| NFR4.1-NFR4.8 | Adapt | Preserve graceful rate, persistence, scheduling, snapshot, and widget failure behavior with Android equivalents. |
| NFR5.1-NFR5.7 | Preserve | Keep provider secrets out of the client and keep financial data local unless the user explicitly enables Google Drive sync or exports data. |
| NFR6.1-NFR6.9 | Adapt | Preserve view-model, repository, networking, scheduling, widget, portability, and telemetry boundaries in the Android architecture. |

**Scope Source**: New Android implementation requested from the shipped iOS baseline.

**Out of Scope**:

- Bank, brokerage, crypto-wallet, or account aggregation.
- Shared or family portfolios.
- A developer-operated cloud database containing user portfolio data.
- Automatic migration of an iCloud container into Google Drive.
- Pixel-perfect copying of Apple-only controls, lock-screen widget families, or iOS navigation chrome.
- Changes to the shipped iOS app or Firebase provider contracts.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Track Net Worth on Android (Priority: P1)

An Android user completes onboarding, adds assets and liabilities, and sees accurate multi-currency net worth across the primary Wealth Map destinations.

**Why this priority**: Local portfolio tracking is the core product value and must work without cloud services.

**Independent Test**: Install offline, complete onboarding, add and edit mixed-currency assets and liabilities, and verify totals, validation, persistence, and relaunch behavior.

**Acceptance Scenarios**:

1. **Given** a new installation, **When** the user completes all required onboarding choices, **Then** the app opens the main experience and restores those choices on relaunch.
2. **Given** complete cached rates, **When** assets and liabilities are changed, **Then** converted net worth, history, insights, goals, and widgets update consistently.
3. **Given** missing or stale rates, **When** the user opens a calculation surface, **Then** the app identifies unavailable or stale results without fabricating values or blocking record management.

---

### User Story 2 - Remain Local and Useful Offline (Priority: P1)

A privacy-conscious user keeps cloud sync disabled and uses Wealth Map entirely on the device, including during network outages.

**Why this priority**: Local-first privacy is a non-negotiable product contract.

**Independent Test**: Deny network access and cloud authorization, then create, edit, delete, export, import, and review records without a crash or unintended cloud upload.

**Acceptance Scenarios**:

1. **Given** sync is disabled, **When** financial records change, **Then** no portfolio field is sent to Google Drive, Firebase telemetry, notifications, or another remote store.
2. **Given** the device is offline, **When** the user edits local records, **Then** all local workflows remain available and pending rate or optional sync work fails gracefully.

---

### User Story 3 - Opt In to Google Account Backup and Sync (Priority: P1)

A user explicitly connects a Google account and enables private Wealth Map synchronization so portfolio data can be recovered and reconciled on another Android device.

**Why this priority**: This is the Android equivalent of the iOS opt-in iCloud experience and protects users from device loss.

**Independent Test**: Enable sync on a populated device, authorize the minimum app-data permission, install on a second device with the same account, and verify a complete, conflict-tolerant restore.

**Acceptance Scenarios**:

1. **Given** local data and no remote snapshot, **When** the user enables sync, **Then** existing supported data is uploaded without deleting or blocking the local database.
2. **Given** an existing remote snapshot, **When** sync is enabled on another device, **Then** records merge by stable identity and deterministic newest-change rules without duplicate active records.
3. **Given** revoked authorization, no network, or a quota/service failure, **When** sync runs, **Then** local data remains usable, retryable work is retained, and a non-blocking paused/error status is shown.
4. **Given** the user disables sync, **When** local data changes, **Then** new remote writes stop while local records and the existing remote copy remain intact.

---

### User Story 4 - Recover Safely Across Accounts and Devices (Priority: P2)

A user can understand sync state, avoid mixing two Google accounts, and resolve first-sync or goal conflicts safely.

**Why this priority**: Account confusion is a high-risk failure mode for personal financial records.

**Independent Test**: Switch the authorized Google account, create conflicting edits on two devices, and verify account isolation, deterministic merges, visible status, and no silent loss.

**Acceptance Scenarios**:

1. **Given** sync is associated with one Google account, **When** another account is selected, **Then** synchronization pauses until the user explicitly chooses the new account context; records are not silently mixed.
2. **Given** concurrent changes to the same record, **When** devices reconcile, **Then** the newest valid update wins with a stable tie-break and deletions are not accidentally resurrected.
3. **Given** conflicting active goals, **When** data merges, **Then** exactly one valid active goal remains and the user can inspect the result.

---

### User Story 5 - Use an Android-Native, Accessible App (Priority: P2)

Users can navigate the app on phones, tablets, foldables, widgets, supported locales, and assistive configurations without losing financial meaning.

**Why this priority**: Platform parity means equivalent outcomes delivered through native Android behavior.

**Independent Test**: Exercise compact and expanded windows, large font scale, TalkBack, Arabic RTL, notification denial, and widget empty/populated states.

**Acceptance Scenarios**:

1. **Given** a compact or expanded window, **When** the user navigates primary destinations, **Then** navigation adapts without hiding actions or losing state.
2. **Given** Arabic or another supported locale, **When** the app and widget render, **Then** copy, direction, dates, numbers, and currencies are localized while stored identifiers remain unchanged.

### Edge Cases

- Empty portfolios, zero liabilities, negative or non-finite input, very large values, and unsupported currency codes.
- Partial, stale, malformed, or missing exchange-rate and metal-price payloads.
- Process death during import, database migration, sync merge, or remote upload.
- Two devices editing or deleting the same record before either receives the other change.
- Remote data newer than local data, local data newer than remote data, and equal timestamps from different devices.
- Google authorization revoked, account removed, Drive disabled, storage unavailable, rate-limited, or offline.
- App downgrade after a Room or sync-payload migration.
- Notification permission denied, exact timing unavailable, reboot, time-zone change, and monthly dates near February.
- Large font scale, TalkBack, reduced motion, long translations, Arabic RTL, and narrow widget sizes.

## Requirements *(mandatory)*

### Feature Requirements

- **SFR-001**: The Android app must provide user-observable parity for FR1.1-FR14.8 except where this specification explicitly defines an Android platform adaptation.
- **SFR-002**: Local Room data and device-local settings must remain the source of truth and fully usable while offline or signed out.
- **SFR-003**: Financial data must not enter Android Auto Backup or another cloud path without an explicit Wealth Map opt-in.
- **SFR-004**: The client must use the existing Firebase HTTPS proxies and must not call protected exchange-rate, metal-price, or AI providers directly.
- **SFR-005**: Android backup export and import must preserve the iOS versioned `.backup` field names, raw enum values, stable identifiers, and legacy-read behavior where representable.
- **SFR-006**: Cloud sync must default off and require an explicit Google account authorization for only application-data storage.
- **SFR-007**: Enabling sync must reconcile all supported portfolio records plus base currency, ordered display currencies, and compact-format preference.
- **SFR-008**: Onboarding completion, reminder preferences, notification state, authorization tokens, and device identifiers must remain device-local.
- **SFR-009**: Remote synchronization must use stable record identities, deletion tombstones, deterministic conflict rules, schema versioning, and retry-safe operations.
- **SFR-010**: Sync must run after relevant local changes, when the app returns to the foreground, on user-requested refresh, and periodically when Android permits; exact immediate background delivery is not guaranteed.
- **SFR-011**: Disabling sync must cancel future sync work without deleting local data or silently deleting the remote copy.
- **SFR-012**: Account changes must pause sync and require an explicit user choice before associating local data with a different Google account.
- **SFR-013**: Sync state must distinguish disabled, authorization required, initial sync, up to date, pending offline, paused, and failed states.
- **SFR-014**: Failed or interrupted imports, migrations, and sync merges must be transactional or recoverable without leaving partially applied portfolio state.
- **SFR-015**: Android home-screen widgets must expose the same core net-worth snapshot while omitting data when no valid local snapshot exists.
- **SFR-016**: Reminder delivery must remain device-local and tolerate permission denial, reboot, time-zone changes, and platform scheduling limits.
- **SFR-017**: The app must support the iOS MVP locales and preserve stable raw values across locale changes.
- **SFR-018**: Telemetry must use the same typed allowlist as iOS and must never include financial amounts, labels, free text, account identity, or Drive contents.
- **SFR-019**: The implementation must migrate the existing Android prototype database and preferences without losing valid asset or onboarding data.
- **SFR-020**: The current direct third-party exchange-rate URL and exception printing must be removed before production parity work proceeds.

### Key Entities

- **Portfolio records**: Assets, liabilities, value snapshots, net-worth snapshots, portfolio snapshots, and one active net-worth goal.
- **User settings**: Base currency, ordered display currencies, compact formatting, onboarding, reminder, and sync preferences with explicit device-local/cloud classifications.
- **Sync envelope**: A versioned representation of supported records, settings, tombstones, modification metadata, and integrity metadata.
- **Sync account context**: The locally held association between Wealth Map and the user-authorized Google account, without storing financial values or account identity in telemetry.
- **Exchange-rate cache**: Rates, server/cache timestamp, local refresh timestamp, status, and required-currency coverage.
- **Widget snapshot**: A minimized local projection of totals, selected currencies, and update time for Android widgets.

## Privacy and Data Handling *(mandatory)*

- **On-device data**: Room stores portfolio records, snapshots, goals, sync tombstones, and caches. DataStore stores app and device preferences. Local behavior remains complete without sync.
- **iCloud data**: N/A on Android. The equivalent optional user-controlled destination is the app-only data area of the user-authorized Google Drive account.
- **Server-bound data**: Firebase receives only rate/metal requests and explicitly invoked sanitized AI analysis. Google Drive receives the versioned sync envelope only after opt-in. No developer-operated portfolio database is introduced.
- **Exports and sharing**: Backup files and text summaries leave the device only through explicit user actions and Android system pickers/sharesheets.
- **Widgets/notifications/indexing**: Widgets use a minimized local snapshot. Reminders contain no balances or user-entered labels. No financial data is indexed for system search in this feature.
- **Secrets/logging**: Provider secrets remain server-side. OAuth tokens, financial payloads, account identifiers, and user-entered values must not be logged or committed.

## Compatibility and Migration *(mandatory)*

- **SwiftData/schema**: N/A for Android code; iOS schemas remain unchanged. Android Room migrations must be explicit and tested from the prototype schema.
- **UserDefaults/settings**: N/A for Android code; iOS keys remain unchanged. Android DataStore keys receive stable documented names and migration coverage.
- **Backup/import format**: Android reads and writes the compatible versioned Wealth Map `.backup` envelope and rejects unsupported future versions safely.
- **Stable identifiers**: The Android package, Firebase endpoint names, raw categories, notification work names, widget identity, Drive filename, sync schema, and record identifiers become compatibility contracts once released.
- **Rollback**: Local data remains authoritative. A failed or reverted sync release must continue opening the last valid Room database and leave remote data untouched until a compatible client resumes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every FR1.1-FR14.8 behavior has a passing Android parity test or a documented, accepted platform adaptation.
- **SC-002**: A user can complete onboarding and add, edit, delete, relaunch, export, and import a mixed asset/liability portfolio with no network or Google account.
- **SC-003**: With sync disabled, network inspection shows zero financial-record uploads.
- **SC-004**: A populated portfolio enabled for sync restores on a second authorized Android device with no duplicate active records and matching totals.
- **SC-005**: Simulated concurrent update/delete cases converge deterministically across two clients without resurrecting deleted data.
- **SC-006**: Rate, authorization, Drive, migration, and process-interruption failures do not crash the app or corrupt the last valid local state.
- **SC-007**: Core screens remain usable at 200% font scale, with TalkBack, in Arabic RTL, and across compact and expanded window classes.
- **SC-008**: Unit tests, instrumented persistence tests, Compose UI tests, lint, and debug assembly pass from a clean checkout.

## Assumptions and Dependencies

- The existing Android prototype is retained and migrated incrementally rather than discarded.
- The current iOS `requirements.md` is the behavioral source of truth; Apple-only implementation details are adapted to Android-native equivalents.
- The existing Firebase project and HTTPS proxy endpoints remain available to Android clients.
- Users who enable sync have a Google account and Google Drive service available.
- Google-controlled scheduling and network conditions mean background sync is eventual; foreground and post-write reconciliation provide the primary freshness path.
- Google Drive application-data storage is preferred over Firestore because it avoids a developer-operated portfolio store and most closely matches the personal-cloud boundary of iCloud.
