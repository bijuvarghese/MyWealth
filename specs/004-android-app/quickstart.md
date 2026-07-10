# Quickstart: Android Wealth Map Parity

## Prerequisites

- Android Studio compatible with AGP 9.2.1
- JDK 17
- Android SDK 36.1 and an API 24+ emulator/device
- Access to the existing `mywealth-api-router` Firebase proxy endpoints
- For sync testing: a Google Cloud project with Drive API enabled and Android
  OAuth clients for the package/signing combinations under test

Do not place provider keys, OAuth client secrets, access tokens, personal
financial data, or real backup files in the repository.

## Repository Locations

```sh
cd /Users/bijuvarghese/Projects/MyWealth-101/Android/MyWealth
```

The product baseline and feature plan are in:

```text
../../iOS/MyWealth/requirements.md
../../iOS/MyWealth/specs/004-android-app/
```

## Initial Safety Checks

1. Preserve the existing package `com.bxvdev.mywealth`.
2. Export the Room v1 schema before increasing the database version.
3. Add a migration fixture containing one valid prototype asset and existing
   onboarding/currency preferences.
4. Confirm the production source no longer contains `open.er-api.com`,
   provider keys, or `printStackTrace`.
5. Confirm Android backup configuration excludes Room, DataStore financial
   settings, OAuth/token state, and sync files.

## Firebase Proxy Configuration

Expose non-secret endpoint URLs through a documented Gradle property or
BuildConfig field. Do not hardcode external provider endpoints.

Required logical endpoints:

- Exchange rates
- Metal prices
- Sanitized AI analysis

The debug build may use staging endpoints. Release values must point to the
approved Firebase HTTPS functions.

## Google Drive Setup

1. Enable Google Drive API in the selected Google Cloud project.
2. Complete OAuth branding, homepage, privacy-policy, and terms URLs.
3. Create Android OAuth clients for debug and release package/signing
   fingerprints.
4. Request only the `drive.appdata` scope when the user enables sync.
5. Do not request offline backend access or send Drive tokens to a server.

## Build and Test

```sh
./gradlew testDebugUnitTest
./gradlew lintDebug
./gradlew assembleDebug
./gradlew connectedDebugAndroidTest
```

Before delivery:

```sh
git diff --check
```

## Manual Local-Only Smoke Test

1. Install with no Google account authorization.
2. Complete onboarding.
3. Add mixed-currency assets and liabilities.
4. Edit and delete records.
5. Relaunch offline and confirm records/settings remain.
6. Confirm missing rates show unavailable status rather than partial totals.
7. Export a `.backup`, clear app data, import it, and compare totals/history.
8. Inspect network traffic and confirm no financial records leave the device.

## Two-Device Sync Smoke Test

Use synthetic data only.

1. Device A: create a portfolio, enable sync, grant `drive.appdata`, and wait
   for an up-to-date status.
2. Device B: authorize the same account and enable sync.
3. Confirm matching records, settings, goal, history, and totals.
4. Edit different records offline on both devices; reconnect and confirm both
   survive.
5. Edit the same record on both devices with controlled timestamps; confirm the
   deterministic winner.
6. Delete a record on A while B is offline; reconnect B and confirm the record
   is not resurrected.
7. Revoke Drive access and confirm local workflows remain available with a
   paused status.
8. Select a different account and confirm no sync occurs before explicit user
   choice.
9. Disable sync and confirm local data remains and no further upload occurs.

## Accessibility and Locale Matrix

Check a compact phone and expanded tablet/foldable layout with:

- English and every MVP locale
- Arabic RTL
- 200% font scale
- TalkBack
- Light and dark theme
- Empty, loading, stale, missing, failed, destructive, and confirmation states
- Small and large responsive widget sizes

## Release Evidence

Record:

- Requirement IDs covered by each automated suite
- Room migration start/end versions
- Backup fixtures and compatibility results
- Firebase proxy contract results
- Drive merge/account/offline test results
- Auto Backup exclusion evidence
- Dependency and secret scan results
- Known Android platform adaptations
