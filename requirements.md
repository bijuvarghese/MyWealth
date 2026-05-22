# My Wealth - Requirements

Last updated: May 22, 2026

This document defines the current product requirements for the My Wealth iOS app and its exchange-rate proxy. It reflects the current app state: onboarding, local asset and liability tracking, multi-currency net worth, exchange-rate caching, portfolio history, reminders, and the Firebase rate proxy.

## Product Overview

My Wealth is a SwiftUI iOS app for tracking personal net worth across currencies. Users can configure preferred currencies, add and maintain assets and liabilities, view converted portfolio totals, monitor transfer rates, review portfolio insights and history, and rely on cached exchange-rate data fetched through a Firebase proxy.

User financial data is currently local to the device. The app does not provide cloud sync, account aggregation, bank connections, or remote user accounts.

## Current App Structure

- First-time users complete onboarding before reaching the main app.
- Returning users open into a tab-based app experience.
- The main tabs are Dashboard, Assets, Net Worth, Rates, and Settings.
- Assets, liabilities, asset value snapshots, and net worth snapshots are stored with SwiftData.
- Onboarding state, currency settings, exchange-rate cache data, and reminder preferences are stored with UserDefaults.
- Exchange rates are fetched through a Firebase HTTPS Cloud Function, not directly from the external provider.

## Functional Requirements

### 1. Onboarding and Settings

- **FR1.1**: First-time users must complete onboarding before reaching the main app experience.
- **FR1.2**: Onboarding must allow users to choose a default/base currency.
- **FR1.3**: Onboarding must allow users to choose one or more display currencies for net worth totals.
- **FR1.4**: The selected base currency must always be included in the display currency set.
- **FR1.5**: Onboarding completion, base currency, display currency selections, and reminder choice state must persist locally.
- **FR1.6**: Returning users who have completed onboarding must open directly to the main tab interface.
- **FR1.7**: Users must be able to update currency preferences from the Settings tab.
- **FR1.8**: Currency settings must prevent users from removing the final remaining display currency.
- **FR1.9**: Onboarding must include a step for configuring or explicitly skipping reminder preferences.
- **FR1.10**: Users must be able to update reminder preferences from the Settings tab after onboarding.
- **FR1.11**: Settings must allow users to toggle compact formatting for large currency totals.
- **FR1.12**: Settings must display app version information.

### 2. Currency Selection

- **FR2.1**: Users must be able to select from the supported currency catalog, excluding the internal empty currency value.
- **FR2.2**: Currency pickers must show common currencies first when no search is active.
- **FR2.3**: Currency pickers must support searching by currency code and currency name.
- **FR2.4**: Currency pickers must group non-common currencies alphabetically by currency code.
- **FR2.5**: Selected currencies must display both the ISO-style code and human-readable currency name.
- **FR2.6**: Currency preference changes must trigger exchange-rate refresh checks when selected currencies require unavailable rates.

### 3. Asset Management

- **FR3.1**: Users must be able to add assets with name, amount, currency, and category.
- **FR3.2**: Asset names must be non-empty before saving.
- **FR3.3**: Asset amounts must be numeric before saving.
- **FR3.4**: New assets must default to USD currency and Others category until the user changes them.
- **FR3.5**: Users must be able to edit an existing asset from the Assets tab.
- **FR3.6**: Asset edit forms must be pre-populated with the selected asset's current values.
- **FR3.7**: Users must be able to delete assets from the Assets tab list.
- **FR3.8**: Users must be able to delete an asset from the edit form.
- **FR3.9**: Assets must record a last-updated timestamp when created or changed.
- **FR3.10**: Supported asset categories must include Stocks, Real Estate, Crypto, Bank Deposits, Mutual Funds, Gold, Cars, and Others.
- **FR3.11**: Assets must maintain a stable history identifier so asset value snapshots can remain associated with the asset across edits.

### 4. Liability Management

- **FR4.1**: Users must be able to add liabilities with name, amount, currency, and category.
- **FR4.2**: Liability names must be non-empty before saving.
- **FR4.3**: Liability amounts must be numeric before saving.
- **FR4.4**: New liabilities must default to USD currency and Mortgage category until the user changes them.
- **FR4.5**: Users must be able to edit an existing liability from the Assets tab.
- **FR4.6**: Liability edit forms must be pre-populated with the selected liability's current values.
- **FR4.7**: Users must be able to delete liabilities from the Assets tab list.
- **FR4.8**: Users must be able to delete a liability from the edit form.
- **FR4.9**: Liabilities must record a last-updated timestamp when created or changed.
- **FR4.10**: Supported liability categories must include Mortgage, Auto Loan, Personal Loan, Student Loan, Credit Card, Line of Credit, and Other Debt.

### 5. Navigation and Tabs

- **FR5.1**: After onboarding, the app root must be a tab-based interface.
- **FR5.2**: The tab interface must include Dashboard, Assets, Net Worth, Rates, and Settings tabs.
- **FR5.3**: The Dashboard tab must summarize assets, liabilities, net worth, allocation, insights, selected converted totals, transfer rates, trend, and recent history.
- **FR5.4**: The Assets tab must display full asset and liability lists and provide add, edit, and delete workflows.
- **FR5.5**: The Net Worth tab must display converted net worth totals, exchange-rate status, net worth trend, and recent asset history.
- **FR5.6**: The Rates tab must display exchange-rate information between the base currency and selected display currencies, with refresh support and rate status messaging.
- **FR5.7**: The Settings tab must allow users to update currency preferences, reminder preferences, compact total formatting, and view app version information.

### 6. Dashboard, Assets, and Net Worth Views

- **FR6.1**: The Dashboard and Assets tabs must show an empty state when no assets or liabilities exist.
- **FR6.2**: Empty states must tell users how to add their first asset or liability.
- **FR6.3**: The Assets tab must display assets and liabilities in separate sections when both types exist.
- **FR6.4**: Each asset row must show the category icon, asset name, amount, currency code, and category name.
- **FR6.5**: Each liability row must show the category icon, liability name, amount, currency code, and category name.
- **FR6.6**: Portfolio totals must calculate net worth as converted assets minus converted liabilities.
- **FR6.7**: Converted totals must be shown for the configured base currency and selected display currencies when exchange-rate data is available.
- **FR6.8**: The Dashboard tab may show a limited preview of converted totals and transfer rates to keep the summary scannable.
- **FR6.9**: The Net Worth tab must show the fuller configured converted-total view.
- **FR6.10**: Asset and liability data must update automatically after records are added, edited, or deleted.
- **FR6.11**: Dashboard insights must summarize useful portfolio signals, including largest allocation, debt-to-asset ratio when liabilities exist, and recent net worth movement when history exists.
- **FR6.12**: Allocation charts must group assets by category and use the configured base currency for converted category totals.
- **FR6.13**: Net worth trend charts must use recorded `NetWorthSnapshot` data for the active base currency.
- **FR6.14**: Recent history must use recorded `AssetValueSnapshot` data and display the most recent asset value changes first.

### 7. Exchange Rates and Conversion

- **FR7.1**: The app must fetch latest exchange rates through a Firebase HTTPS Cloud Function.
- **FR7.2**: The iOS app must read the Firebase proxy URL from `Info.plist`.
- **FR7.3**: The iOS app must not call the external exchange-rate provider directly.
- **FR7.4**: The iOS app must not ship the external provider API key.
- **FR7.5**: A scheduled Firebase function must call the Apilayer exchange-rate API using USD as the base currency, request the app-supported symbol set explicitly, and refresh the shared server cache three times per day.
- **FR7.6**: The Firebase function must accept only GET requests and return 405 for other methods.
- **FR7.7**: The public Firebase HTTPS function must return the cached server copy from Datastore and avoid calling the external provider during normal user requests.
- **FR7.8**: The app must cache exchange rates locally after a successful fetch.
- **FR7.9**: The app must refresh exchange rates at most once per calendar day during normal app use when all required rates are present.
- **FR7.10**: The app must refresh rates sooner when required currencies are missing from the local cache.
- **FR7.11**: Cached rates must be reused when the app starts before a new refresh is needed.
- **FR7.12**: USD must always be available as a conversion rate with value 1.
- **FR7.13**: Conversion must return no total when a required source or target currency rate is unavailable.
- **FR7.14**: Network and decoding failures must not crash the app.
- **FR7.15**: Rate status messaging must distinguish loading, missing refresh, stale cache, missing required rates, and refresh failure states.
- **FR7.16**: If the server cache is empty, the public Firebase HTTPS function may populate it once from Apilayer and must return an error if that fallback fails.

### 8. Reminders and Notifications

- **FR8.1**: Users must be able to enable or disable portfolio reminders.
- **FR8.2**: Users must be able to configure reminder frequency as daily, weekly, or monthly.
- **FR8.3**: Users must be able to configure the time of day for reminders.
- **FR8.4**: For weekly reminders, users must be able to select which day of the week the alert fires.
- **FR8.5**: For monthly reminders, users must be able to select which day of the month the alert fires.
- **FR8.6**: Monthly reminder day selection must be limited to days 1-28 to avoid issues with February, leap years, and shorter months; the app must display in-app guidance explaining this constraint.
- **FR8.7**: Reminder preferences must persist locally across launches.
- **FR8.8**: Reminder status in Settings must display the currently configured reminder state.
- **FR8.9**: Tapping a reminder notification must clear the app badge count.
- **FR8.10**: Notification delegate setup must handle notification taps reliably, including when the app is launched cold from a notification.
- **FR8.11**: Smart reminder logic must avoid duplicate reminder pressure when the user has recently updated assets or when a reminder was recently sent.
- **FR8.12**: Reminder preference decoding must remain backward-compatible with legacy saved reminder preferences.

### 9. Portfolio History

- **FR9.1**: The app must record asset value snapshots using SwiftData when asset values change by at least 0.01.
- **FR9.2**: Asset value snapshot recording must ignore metadata-only edits that do not change the asset amount.
- **FR9.3**: Asset value snapshots must include asset identifier, asset name, amount, currency code, category name, and recorded timestamp.
- **FR9.4**: The app must record net worth snapshots using SwiftData when net worth changes by at least 0.01 in the active base currency.
- **FR9.5**: Net worth snapshots must include amount, currency code, and recorded timestamp.
- **FR9.6**: Net worth snapshot calculations must subtract liabilities from assets.
- **FR9.7**: Snapshot recording must run when dashboard/net worth data loads and when assets, liabilities, selected currencies, or exchange rates change.
- **FR9.8**: Snapshot display helpers must filter net worth trend rows by base currency, sort chronologically, and limit displayed rows.
- **FR9.9**: Recent asset history must sort snapshots newest first and limit displayed rows.

### 10. Data Persistence

- **FR10.1**: Asset data must persist locally using SwiftData.
- **FR10.2**: Liability data must persist locally using SwiftData.
- **FR10.3**: Asset value snapshots must persist locally using SwiftData.
- **FR10.4**: Net worth snapshots must persist locally using SwiftData.
- **FR10.5**: Currency settings and onboarding state must persist locally using UserDefaults.
- **FR10.6**: Exchange-rate cache data and its last-refresh timestamp must persist locally using UserDefaults.
- **FR10.7**: Reminder preferences must persist locally using UserDefaults.
- **FR10.8**: Compact total formatting preference must persist locally using UserDefaults.
- **FR10.9**: The app must restore persisted assets, liabilities, snapshots, settings, and reminder preferences across launches.

## Non-Functional Requirements

### 1. Platform and Tooling

- **NFR1.1**: The app must target iOS 17.0 or later.
- **NFR1.2**: The app must be built with SwiftUI, SwiftData, Observation, Charts, UserNotifications, and async/await.
- **NFR1.3**: The project must remain compatible with Swift 5.10 or later.
- **NFR1.4**: The project must remain compatible with Xcode 26.1 or later.

### 2. Usability

- **NFR2.1**: The app must use standard iOS navigation patterns such as TabView, NavigationStack, sheets, forms, lists, toolbar actions, searchable lists, and menus.
- **NFR2.2**: Forms must prevent invalid save actions instead of allowing invalid records to be created.
- **NFR2.3**: Searchable currency lists must remain usable for a large currency catalog.
- **NFR2.4**: Empty, loading, and error-tolerant states must avoid blocking core asset and liability management workflows.
- **NFR2.5**: Amount formatting must support compact notation for large net worth totals to remain readable.
- **NFR2.6**: Dashboard and settings layouts must remain readable with configured display currencies, long currency names, and large amounts.
- **NFR2.7**: Destructive actions such as deleting assets or liabilities must be clearly labeled.

### 3. Performance

- **NFR3.1**: Exchange-rate requests must run asynchronously and must not block the UI.
- **NFR3.2**: Portfolio total calculations must be efficient enough for interactive tab updates.
- **NFR3.3**: Local persistence reads and writes must not introduce noticeable delays for normal asset, liability, and snapshot counts.
- **NFR3.4**: Dashboard snapshot queries and chart helpers must limit displayed history to avoid rendering excessive rows.

### 4. Reliability

- **NFR4.1**: The app must tolerate missing, stale, or partially unavailable exchange-rate data.
- **NFR4.2**: Bad HTTP status codes, request failures, and decode failures must be surfaced through typed errors internally.
- **NFR4.3**: The app must avoid force-unwrapping optional asset, liability, and snapshot fields in UI and calculation paths.
- **NFR4.4**: SwiftData container initialization failures may terminate launch with a clear fatal error.
- **NFR4.5**: Notification scheduling must not produce concurrency warnings or data races.
- **NFR4.6**: Conversion and insight calculations must handle empty asset and liability collections without crashing.
- **NFR4.7**: Snapshot recording must avoid duplicate rows for insignificant value changes.

### 5. Security and Privacy

- **NFR5.1**: Third-party API keys must be stored in Firebase Secret Manager, not in iOS source code or app bundles.
- **NFR5.2**: The Firebase function must avoid returning provider secrets to the client.
- **NFR5.3**: User asset, liability, and snapshot data must stay local to the device unless a future sync feature explicitly changes that requirement.
- **NFR5.4**: Public privacy content must accurately describe data handling for the deployed app.
- **NFR5.5**: The app must not expose exchange-rate provider credentials through logs, UI, source control, or app configuration.

### 6. Architecture

- **NFR6.1**: Tab and dashboard business logic must remain separated from SwiftUI views through observable view-model types.
- **NFR6.2**: Asset, liability, net worth, and conversion calculations must remain testable through protocol-based operations.
- **NFR6.3**: Networking must remain centralized behind reusable request helpers.
- **NFR6.4**: The exchange-rate provider must remain replaceable without changing tab UI code.
- **NFR6.5**: UserDefaults-backed settings must be injectable or otherwise testable without polluting real user defaults.
- **NFR6.6**: Reminder scheduling should remain isolated behind reminder manager, scheduler, and preference store types.

## Current Scope Notes

- The app currently supports manual asset and liability tracking only; it does not connect to banks, brokerages, or crypto wallets.
- The Dashboard tab is the primary summary surface and includes asset/liability summary, insights, allocation, converted totals, transfer-rate preview, trend, and recent history.
- The Assets tab is the primary record-management surface for both assets and liabilities.
- The Net Worth tab provides a focused converted net worth and trend view.
- The Rates tab displays transfer-rate rows for configured display currencies relative to the selected base currency.
- The app records portfolio history but does not yet prune old snapshot records. Snapshot retention is documented separately as a planned enhancement in `docs/snapshot-retention-enhancement.md`.
- Trend charts currently use recent snapshots; user-selectable time ranges are future scope.
- Asset-specific detail/history screens are future scope; tapping a record currently opens its edit form.
- CSV export/import, iCloud sync, biometric app lock, rate alerts, and allocation targets are future scope.
