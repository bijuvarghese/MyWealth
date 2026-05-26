[![Latest Release](https://img.shields.io/github/v/release/bijuvarghese/MyWealth?label=latest%20release)](https://github.com/bijuvarghese/MyWealth/releases/latest)
[![Platform](https://img.shields.io/badge/platform-iOS-blue)](https://github.com/bijuvarghese/MyWealth)
[![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift)](https://www.swift.org/)
[![License](https://img.shields.io/github/license/bijuvarghese/MyWealth)](https://github.com/bijuvarghese/MyWealth/blob/main/LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/bijuvarghese/MyWealth)](https://github.com/bijuvarghese/MyWealth/commits/main)
[![Repo Size](https://img.shields.io/github/repo-size/bijuvarghese/MyWealth)](https://github.com/bijuvarghese/MyWealth)
[![Stars](https://img.shields.io/github/stars/bijuvarghese/MyWealth?style=social)](https://github.com/bijuvarghese/MyWealth/stargazers)
[![Issues](https://img.shields.io/github/issues/bijuvarghese/MyWealth)](https://github.com/bijuvarghese/MyWealth/issues)
# My Wealth

My Wealth is a SwiftUI iOS app for tracking personal net worth across currencies. It supports manual asset and liability tracking, converted net worth totals, transfer-rate monitoring, portfolio insights, snapshot-based history, home and lock screen widgets, iCloud sync, backup import/export, and configurable portfolio reminders.

User financial data is stored locally by default, with optional iCloud backup and sync controlled by the user. Exchange rates are fetched through a Firebase HTTPS Cloud Function so the external provider API key is never shipped in the app bundle.

## Project Details

- Platform: iOS
- Deployment target: iOS 26.1, as currently configured in the Xcode project
- Xcode: 26.1+
- Swift: 6.0
- App version: 3.2
- Bundle identifier: `com.bv.MyWealth`

## Current Features

- Onboarding for base currency, display currencies, iCloud sync, and reminder preferences
- Tab-based app experience with Dashboard, Assets, Net Worth, Rates, and Settings
- Manual asset tracking with name, amount, currency, category, edit, and delete support
- Manual liability tracking with name, amount, currency, category, edit, and delete support
- Multi-currency net worth totals using cached exchange rates
- User-arranged display-currency ordering so priority currencies appear first
- Dashboard summary for assets, liabilities, net worth, allocation, insights, transfer-rate preview, trend, and recent history
- Dedicated Net Worth tab with converted totals, exchange-rate status, trend chart, and recent asset history
- Transfer Rates tab for configured display currencies relative to the selected base currency
- Home screen and lock screen widgets for net worth summaries
- Optional iCloud backup and sync through the user's personal iCloud account
- Backup export/import for local app data
- Configurable compact formatting for large currency totals
- Portfolio reminders with daily, weekly, and monthly schedules
- Smart reminder behavior to reduce duplicate reminder pressure after recent portfolio activity
- Local snapshot history for asset value changes and net worth changes
- Searchable currency selection with common currencies prioritized

## Architecture

- SwiftUI for app UI and navigation
- SwiftData for assets, liabilities, asset value snapshots, and net worth snapshots
- UserDefaults for onboarding state, currency settings, compact-format preference, reminder preferences, and exchange-rate cache metadata
- CloudKit/iCloud support for optional user-controlled backup and sync
- WidgetKit and App Group UserDefaults for home and lock screen widget snapshots
- Observation-powered view models for dashboard and conversion behavior
- Async/await networking through a reusable network helper
- Protocol-backed exchange-rate fetching for testability
- Firebase Cloud Functions as the exchange-rate proxy
- Swift Testing coverage for conversion, totals, reminders, onboarding, snapshots, settings, and exchange-rate behavior

## Data Model

The app currently persists these local SwiftData models:

- `Asset`
- `Liability`
- `AssetValueSnapshot`
- `NetWorthSnapshot`

Snapshot history powers the dashboard history list and net worth trend chart. Duplicate snapshot cleanup runs automatically for older data, but long-term snapshot retention is still planned.

## Widgets

The app includes a `MyWealthWidgetExtension` target with WidgetKit views for:

- Small home screen net worth summary
- Medium home screen net worth and secondary currency totals
- Lock screen circular net worth summary
- Lock screen rectangular net worth summary

The main app writes a lightweight `WidgetSnapshot` to the shared App Group `group.com.bv.MyWealth` after portfolio, currency, or exchange-rate changes. The widget extension reads that shared snapshot and refreshes its timelines through WidgetKit.

## Exchange Rate Proxy

The app fetches exchange rates through a Firebase HTTPS Cloud Function so the Apilayer API key is not shipped in the iOS app.

The iOS app reads `ExchangeRateProxyURL` from `MyWealth/Info.plist`, which is currently configured for the `mywealth-api-router` Firebase project. The HTTPS function returns the latest cached Datastore copy instead of calling Apilayer for every app user. A scheduled Firebase function refreshes that Datastore cache three times per day at `00:00`, `08:00`, and `16:00` UTC. Refreshes request the app-supported Apilayer symbol set explicitly, using USD as the base currency.

### Firebase Setup

1. Install and sign in to the Firebase CLI.

2. From this directory, select the Firebase project:

   ```sh
   firebase use mywealth-api-router
   ```

3. Confirm the project has a default Datastore database. The functions store the shared exchange-rate payload as `ExchangeRateCache/latest`.

4. Store the Apilayer key in Secret Manager:

   ```sh
   firebase functions:secrets:set EXCHANGE_RATES_API_KEY
   ```

5. Install function dependencies:

   ```sh
   cd functions
   npm install
   cd ..
   ```

6. Deploy the functions:

   ```sh
   firebase deploy --only functions
   ```

After deployment, `refreshExchangeRateCache` keeps the server cache warm automatically. If the cache entity does not exist yet, the public `latestExchangeRate` endpoint will fetch and create it once, then future user requests will read from Datastore.

### Cache Freshness Check

For automation or manual health checks, run:

```sh
./scripts/check-cache-freshness.sh
```

The script checks both the exchange-rate and metal-price Firebase endpoints by default, reads each `cacheTimestamp` from the JSON response, and exits non-zero if either cache is older than 8 hours. Use `--exchange-only` or `--metal-only` for a single-endpoint check, `--threshold-hours N` to change the freshness window, or `--url URL` together with a single-endpoint option to override the endpoint.
If the automation sets `SLACK_WEBHOOK_URL`, the script also posts the full run summary to Slack after every run.

### Cloud Run Trigger

If you want to trigger the cache check remotely from your phone, deploy the included Cloud Run service:

```sh
RUN_CHECK_TOKEN="choose-a-long-random-token" \
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..." \
./scripts/deploy-cache-check-cloud-run.sh
```

The deploy script builds and deploys `mywealth-cache-check` to Cloud Run in project `mywealth-api-router` and sets the token and Slack webhook as environment variables.

After deployment:

```sh
curl -X POST "https://YOUR_CLOUD_RUN_URL/run" \
  -H "Authorization: Bearer YOUR_RUN_CHECK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

The service exposes:

- `GET /healthz` for a simple health check
- `POST /run` to execute the cache check, return a JSON report, and optionally post to Slack

Optional `POST /run` JSON body fields:

- `thresholdHours`: override the default 8-hour staleness threshold
- `only`: `"exchange"` or `"metal"` to check a single endpoint
- `slack`: `false` to skip Slack delivery for that run

## Local Development

Open `MyWealth.xcodeproj` in Xcode, select the `MyWealth` scheme, and run the app on an iOS simulator or device.

To run the Firebase function locally or deploy it, use the Firebase CLI from the repository root after completing the setup above.

## Current Scope

- The app supports manual financial tracking only.
- Bank, brokerage, crypto wallet, and account aggregation integrations are not included.
- CSV import/export, biometric app lock, rate alerts, allocation targets, user-selectable trend ranges, and asset-specific detail/history screens are future scope.
