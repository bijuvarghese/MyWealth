# Wealth Map

[![Latest Release](https://img.shields.io/github/v/release/bijuvarghese/MyWealth?label=latest%20release)](https://github.com/bijuvarghese/MyWealth/releases/latest)
[![Platform](https://img.shields.io/badge/platform-iOS-blue)](https://github.com/bijuvarghese/MyWealth)
[![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift)](https://www.swift.org/)
[![iOS CI](https://github.com/bijuvarghese/MyWealth/actions/workflows/ios-ci.yml/badge.svg?branch=main)](https://github.com/bijuvarghese/MyWealth/actions/workflows/ios-ci.yml)
[![Functions CI](https://github.com/bijuvarghese/MyWealth/actions/workflows/functions-ci.yml/badge.svg?branch=main)](https://github.com/bijuvarghese/MyWealth/actions/workflows/functions-ci.yml)
[![Cache Monitor](https://github.com/bijuvarghese/MyWealth/actions/workflows/cache-monitor.yml/badge.svg?branch=main)](https://github.com/bijuvarghese/MyWealth/actions/workflows/cache-monitor.yml)

Wealth Map is a SwiftUI iOS app for tracking personal net worth across currencies. It supports manual asset and liability tracking, converted net worth totals, transfer-rate and precious-metal monitoring, net worth goals, portfolio insights, FIRE projections, AI-assisted portfolio briefings, user-controlled progress sharing, snapshot-based history, home and lock screen widgets, optional iCloud sync, backup import/export, and configurable portfolio reminders.

Financial data is stored locally by default. Users can opt in to iCloud backup and sync, and can export or import a `.backup` file for portability. Exchange rates, metal prices, and AI analysis are routed through Firebase HTTPS Cloud Functions so provider API keys are never shipped in the app bundle.

## Project Details

- Platform: iOS
- Deployment target: iOS 26.1
- Xcode: 26.1+
- Swift: 6.0
- App version: 4.5
- Bundle identifier: `com.bv.MyWealth`
- Widget bundle identifier: `com.bv.MyWealth.MyWealthWidget`
- Shared App Group: `group.com.bv.MyWealth`

## Current Features

- Onboarding for base currency, display currencies, iCloud sync, and reminder preferences
- iPhone tab experience for Dashboard, Assets, Net Worth, Rates, and Briefing
- iPad `NavigationSplitView` experience with the same primary sections
- Manual asset tracking with name, amount, currency, category, edit, delete, and portfolio-inclusion controls
- Manual liability tracking with name, amount, currency, category, edit, and delete support
- Precious-metal asset entry with weight-unit support for troy ounces, grams, kilograms, and ounces
- Multi-currency net worth totals using cached exchange rates
- User-arranged display-currency ordering for totals and widgets
- Dashboard summaries for assets, liabilities, net worth, allocation, insights, transfer-rate preview, trend, and recent history
- Weekly and monthly progress highlights with wealth growth, asset, liability, debt, and allocation insights; eligible recaps remain due until dismissed
- User-initiated Dashboard sharing for a text-only net worth progress summary
- Dedicated Net Worth view with converted totals, exchange-rate status, trend chart, and recent history
- One active net worth goal with multi-currency progress, target date, and history-based outlook
- Rates view for configured currency transfers and precious-metal prices
- Briefing view with portfolio health scoring, warnings, allocation notes, return attribution, scenario links, and optional AI analysis
- FIRE calculator for LeanFIRE, FIRE, and FatFIRE progress and projections
- Home screen and lock screen widgets for net worth summaries
- Optional iCloud backup and sync through the user's personal iCloud account
- Backup export/import for assets, liabilities, history, portfolio snapshots, and the active net worth goal
- ChatGPT-ready export plus in-app AI analysis through the Firebase proxy
- Configurable compact formatting for large currency totals
- Portfolio reminders with daily, weekly, and monthly schedules
- Smart reminder behavior to reduce duplicate reminders after recent portfolio activity
- Local snapshot history for asset value changes, portfolio totals, and net worth changes
- Searchable currency selection with common currencies prioritized

## Localization

Wealth Map follows the active iOS app or system language automatically. The
MVP supports English, Hindi, Spanish, Portuguese (Brazil), French, German,
Simplified Chinese, and Arabic. Unsupported languages fall back to English.

App, widget, reminder, validation, status, accessibility, and share copy is
localized. Currency codes, saved enum values, backup fields, widget payloads,
notification identifiers, analytics names, and user-entered financial labels
remain unchanged. Currency names use the active locale when Foundation
provides one, with the existing catalog as a fallback.

Translations in `Localizable.xcstrings` should receive native-speaker review
before a production release, especially financial guidance and compact widget
copy.

## Architecture

- SwiftUI for app UI and navigation
- SwiftData for assets, liabilities, asset value snapshots, net worth snapshots, portfolio snapshots, and the active net worth goal
- UserDefaults for onboarding state, currency settings, compact-format preference, reminder preferences, and exchange-rate cache metadata
- CloudKit/iCloud support for optional user-controlled backup and sync
- WidgetKit and App Group UserDefaults for home and lock screen widget snapshots
- Observation-powered view models for dashboard, conversion, metal-price, and briefing behavior
- Async/await networking through reusable service helpers
- Protocol-backed exchange-rate and metal-price fetching for testability
- Firebase Cloud Functions as provider-key-protecting proxies
- Swift Testing coverage for conversion, totals, reminders, onboarding, snapshots, settings, FIRE projections, and rate behavior

## Data Model

The app currently persists these local SwiftData models:

- `Asset`
- `Liability`
- `AssetValueSnapshot`
- `NetWorthSnapshot`
- `PortfolioSnapshot`

Snapshot history powers the dashboard history list, net worth trend chart, portfolio metrics, widget updates, and briefing calculations. Duplicate snapshot cleanup runs automatically for older data.

## Widgets

The app includes a `MyWealthWidgetExtension` target with WidgetKit views for:

- Small home screen net worth summary
- Medium home screen net worth and secondary currency totals
- Lock screen circular net worth summary
- Lock screen rectangular net worth summary

The main app writes a lightweight `WidgetSnapshot` to the shared App Group `group.com.bv.MyWealth` after portfolio, currency, or exchange-rate changes. The widget extension reads that shared snapshot and refreshes its timelines through WidgetKit.

## Firebase Proxies

The iOS app reads these endpoint URLs from `MyWealth/Info.plist`:

- `ExchangeRateProxyURL`: `latestExchangeRate`
- `MetalPriceProxyURL`: `latestMetalPrice`
- `ChatGPTAnalysisProxyURL`: `analyzeWealthMap`

The Firebase project is currently `mywealth-api-router` and the functions run in `us-central1`.

### Exchange Rates

The app fetches exchange rates through a Firebase HTTPS Cloud Function backed by Apilayer. The function caches the latest Datastore copy as `ExchangeRateCache/latest` and serves the cached payload to app clients. A scheduled function refreshes that cache three times per day at `00:00`, `08:00`, and `16:00` UTC using USD as the provider base currency.

### Metal Prices

The app fetches precious-metal prices through a Firebase HTTPS Cloud Function backed by MetalpriceAPI. The function caches supported metal and currency quotes as `MetalPriceCache/latest` and serves that cached payload to app clients. A scheduled function refreshes the cache on the same UTC cadence as exchange rates.

### AI Analysis

The app sends a sanitized portfolio snapshot to `analyzeWealthMap`, which calls the OpenAI Responses API from the server side. The function validates payload shape, applies request-size and per-client rate limits, and frames the response as educational planning analysis rather than financial, legal, tax, immigration, or investment advice.

## Firebase Setup

1. Install and sign in to the Firebase CLI.

2. From this directory, select the Firebase project:

   ```sh
   firebase use mywealth-api-router
   ```

3. Confirm the project has a default Datastore database. The functions store the shared exchange-rate payload as `ExchangeRateCache/latest` and the shared metal-price payload as `MetalPriceCache/latest`.

4. Store provider keys in Secret Manager:

   ```sh
   firebase functions:secrets:set EXCHANGE_RATES_API_KEY
   firebase functions:secrets:set METAL_PRICE_API_KEY
   firebase functions:secrets:set OPENAI_API_KEY
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

After deployment, `refreshExchangeRateCache` and `refreshMetalPriceCache` keep the server caches warm automatically. If a cache entity does not exist yet, the public endpoint fetches and creates it once, then future user requests read from Datastore.

## Firebase Analytics and Crashlytics

Wealth Map uses Firebase Analytics and Crashlytics for behavior-only usage,
retention, and crash diagnostics. Analytics calls must go through
`AnalyticsService`; views must not call Firebase directly. The allowed event
parameters are limited to source screen, asset type, liability type, goal type,
budget type, calculator mode, and app version. Never attach balances, amounts,
net worth, income, expense values, account names, institution names,
transaction names, notes, email, name, phone, or other user-entered financial
values.

To enable Firebase locally or for release:

1. In Firebase Console, register the iOS app with bundle ID `com.bv.MyWealth`.
2. Download `GoogleService-Info.plist` and add it locally to the `MyWealth`
   app target so it is bundled with `MyWealth.app`.
3. Keep the downloaded plist out of source control. The app skips Firebase
   configuration when the plist is absent, which keeps tests and fresh clones
   buildable.
4. Confirm Crashlytics dSYM upload succeeds from the `Upload Crashlytics dSYMs`
   Xcode build phase when archiving a release build.

## Cache Freshness Check

For automation or manual health checks, run:

```sh
./scripts/check-cache-freshness.sh
```

The script checks both the exchange-rate and metal-price Firebase endpoints by default, reads each `cacheTimestamp` from the JSON response, and exits non-zero if either cache is older than 8 hours. Use `--exchange-only` or `--metal-only` for a single-endpoint check, `--threshold-hours N` to change the freshness window, or `--url URL` together with a single-endpoint option to override the endpoint.

If the automation sets `SLACK_WEBHOOK_URL`, the script also posts the full run summary to Slack after every run.

## Cloud Run Trigger

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

## GitHub Actions

This repository includes three baseline workflows under `.github/workflows`:

- `ios-ci.yml` to build and test the iOS app on pull requests, pushes to `main`, and manual runs
- `functions-ci.yml` to validate the Firebase functions package when backend files change
- `cache-monitor.yml` to run the cache freshness check on a schedule or via manual dispatch

To enable Slack delivery from `cache-monitor.yml`, add a repository secret named `SLACK_WEBHOOK_URL`.

## Local Development

Open `MyWealth.xcodeproj` in Xcode, select the `MyWealth` scheme, and run the app on an iOS simulator or device.

To run tests from the command line:

```sh
xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth -destination 'platform=iOS Simulator,name=iPhone 17'
```

To work on Firebase functions locally or deploy them, use the Firebase CLI from the repository root after completing the setup above.

## Spec-Driven Development

This repository includes [GitHub Spec Kit](https://github.com/github/spec-kit)
configured for Codex skills. The project constitution is stored at
`.specify/memory/constitution.md`, the requirements routing guide is stored at
`.specify/memory/requirements-context.md`, Wealth Map template customizations
live under `.specify/templates/overrides/`, and Codex skills live under
`.agents/skills/`.

Start a feature with `$speckit-specify`, then use `$speckit-plan`,
`$speckit-tasks`, and `$speckit-implement`. Optional quality steps include
`$speckit-clarify`, `$speckit-checklist`, and `$speckit-analyze`. Generated
feature artifacts are stored under `specs/`.

Generated specs must trace affected `FR*` and `NFR*` identifiers from
`requirements.md`. Functional and non-functional requirements are treated as
the shipped baseline; planned enhancements remain candidates until promoted
into an approved feature spec.

The integration is pinned to Spec Kit `0.8.15`. To verify the installed CLI:

```sh
specify version
```

## Current Scope

- The app supports manual financial tracking only.
- Bank, brokerage, crypto wallet, and account aggregation integrations are not included.
- CSV import/export, biometric app lock, rate alerts, allocation targets, and user-selectable trend ranges are future scope.
