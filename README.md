# My Wealth

My Wealth is a SwiftUI iOS app for tracking personal net worth across currencies. It supports manual asset and liability tracking, converted net worth totals, transfer-rate monitoring, portfolio insights, snapshot-based history, and configurable portfolio reminders.

User financial data is stored locally on device. Exchange rates are fetched through a Firebase HTTPS Cloud Function so the external provider API key is never shipped in the app bundle.

## Project Details

- Platform: iOS
- Deployment target: iOS 26.1, as currently configured in the Xcode project
- Xcode: 26.1+
- Swift: 5.10+
- App version: 2.0
- Bundle identifier: `com.bv.MyWealth`

## Current Features

- Onboarding for base currency, display currencies, and reminder preferences
- Tab-based app experience with Dashboard, Assets, Net Worth, Rates, and Settings
- Manual asset tracking with name, amount, currency, category, edit, and delete support
- Manual liability tracking with name, amount, currency, category, edit, and delete support
- Multi-currency net worth totals using cached exchange rates
- Dashboard summary for assets, liabilities, net worth, allocation, insights, transfer-rate preview, trend, and recent history
- Dedicated Net Worth tab with converted totals, exchange-rate status, trend chart, and recent asset history
- Transfer Rates tab for configured display currencies relative to the selected base currency
- Configurable compact formatting for large currency totals
- Portfolio reminders with daily, weekly, and monthly schedules
- Smart reminder behavior to reduce duplicate reminder pressure after recent portfolio activity
- Local snapshot history for asset value changes and net worth changes
- Searchable currency selection with common currencies prioritized

## Architecture

- SwiftUI for app UI and navigation
- SwiftData for assets, liabilities, asset value snapshots, and net worth snapshots
- UserDefaults for onboarding state, currency settings, compact-format preference, reminder preferences, and exchange-rate cache metadata
- Observation-powered view models for dashboard and conversion behavior
- Async/await networking through a reusable network helper
- Protocol-backed exchange-rate fetching for testability
- Firebase Cloud Functions as the exchange-rate proxy
- Swift Testing coverage for conversion, totals, reminders, onboarding, snapshots, and exchange-rate behavior

## Data Model

The app currently persists these local SwiftData models:

- `Asset`
- `Liability`
- `AssetValueSnapshot`
- `NetWorthSnapshot`

Snapshot history powers the dashboard history list and net worth trend chart. Old snapshots are not pruned yet; planned retention work is documented in `docs/snapshot-retention-enhancement.md`.

## Exchange Rate Proxy

The app fetches exchange rates through a Firebase HTTPS Cloud Function so the Apilayer API key is not shipped in the iOS app.

The iOS app reads `ExchangeRateProxyURL` from `MyWealth/Info.plist`, which is currently configured for the `mywealth-api-router` Firebase project.

### Firebase Setup

1. Install and sign in to the Firebase CLI.

2. From this directory, select the Firebase project:

   ```sh
   firebase use mywealth-api-router
   ```

3. Store the Apilayer key in Secret Manager:

   ```sh
   firebase functions:secrets:set EXCHANGE_RATES_API_KEY
   ```

4. Install function dependencies:

   ```sh
   cd functions
   npm install
   cd ..
   ```

5. Deploy the function:

   ```sh
   firebase deploy --only functions
   ```

## Local Development

Open `MyWealth.xcodeproj` in Xcode, select the `MyWealth` scheme, and run the app on an iOS simulator or device.

To run the Firebase function locally or deploy it, use the Firebase CLI from the repository root after completing the setup above.

## Current Scope

- The app supports manual financial tracking only.
- Bank, brokerage, crypto wallet, and account aggregation integrations are not included.
- iCloud sync, CSV import/export, biometric app lock, rate alerts, allocation targets, user-selectable trend ranges, and asset-specific detail/history screens are future scope.
