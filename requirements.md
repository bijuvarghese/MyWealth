# My Wealth - Requirements
 
Last updated: May 21, 2026
 
This document defines the current product requirements for the My Wealth iOS app and its exchange-rate proxy. It focuses on expected product behavior, data handling, platform constraints, and known future scope.
 
## Product Overview
 
My Wealth is a SwiftUI iOS app for tracking personal assets across currencies. Users can configure preferred currencies, add and maintain assets, view currency-adjusted portfolio totals, monitor transfer rates between currencies, and rely on cached exchange-rate data fetched through a Firebase proxy.
 
## Functional Requirements
 
### 1. Onboarding and Settings
 
- **FR1.1**: First-time users must complete onboarding before reaching the main app experience.
- **FR1.2**: Onboarding must allow users to choose a default/base currency.
- **FR1.3**: Onboarding must allow users to choose one or more display currencies.
- **FR1.4**: The selected base currency must always be included in the display currency set.
- **FR1.5**: Onboarding completion, base currency, and display currency selections must persist locally.
- **FR1.6**: Returning users who have completed onboarding must open directly to the main tab interface.
- **FR1.7**: Users must be able to update currency preferences from the Settings tab.
- **FR1.8**: Currency settings must prevent users from removing the final remaining display currency.
- **FR1.9**: Onboarding must include a step for configuring reminder preferences.
- **FR1.10**: Users must be able to update reminder preferences from the Settings tab after onboarding.
### 2. Currency Selection
 
- **FR2.1**: Users must be able to select from the supported currency catalog, excluding the internal empty currency value.
- **FR2.2**: Currency pickers must show common currencies first when no search is active.
- **FR2.3**: Currency pickers must support searching by currency code and currency name.
- **FR2.4**: Currency pickers must group non-common currencies alphabetically by currency code.
- **FR2.5**: Selected currencies must display both the ISO-style code and human-readable currency name.
### 3. Asset Management
 
- **FR3.1**: Users must be able to add assets with the following fields:
  * Name
  * Amount
  * Currency
  * Category
- **FR3.2**: Asset names must be non-empty before saving.
- **FR3.3**: Asset amounts must be numeric before saving.
- **FR3.4**: New assets must default to USD currency and Others category until the user changes them.
- **FR3.5**: Users must be able to edit an existing asset from the Assets tab.
- **FR3.6**: Asset edit forms must be pre-populated with the selected asset's current values.
- **FR3.7**: Users must be able to delete assets from the Assets tab list.
- **FR3.8**: Users must be able to delete an asset from the edit form.
- **FR3.9**: Assets must record a last-updated timestamp when created or changed.
- **FR3.10**: Supported asset categories must include Stocks, Real Estate, Crypto, Bank Deposits, Mutual Funds, Gold, Cars, and Others.
### 4. Navigation and Tabs
 
- **FR4.1**: After onboarding, the app root must be a tab-based interface.
- **FR4.2**: The tab interface must include dedicated tabs for Assets, Transfer Rates, and Settings.
- **FR4.3**: The Assets tab must display the full asset list and net worth totals.
- **FR4.4**: The Transfer Rates tab must display exchange rate information between the base currency and selected display currencies, with refresh support and rate status messaging.
- **FR4.5**: The Settings tab must allow users to update currency preferences and reminder preferences.
### 5. Assets Tab
 
- **FR5.1**: The Assets tab must show an empty state when no assets exist.
- **FR5.2**: The empty state must tell users how to add their first asset.
- **FR5.3**: When assets exist, the Assets tab must display a list of assets.
- **FR5.4**: Each asset row must show the category icon, asset name, amount, currency code, and category name.
- **FR5.5**: The Assets tab must show converted portfolio totals (net worth) for asset currencies that can be calculated from available exchange-rate data.
- **FR5.6**: Portfolio totals must be sorted by currency code.
- **FR5.7**: Asset data must update automatically after assets are added, edited, or deleted.
- **FR5.8**: The Assets tab must provide a toolbar action for adding an asset.
### 6. Exchange Rates and Conversion
 
- **FR6.1**: The app must fetch latest exchange rates through a Firebase HTTPS Cloud Function.
- **FR6.2**: The iOS app must read the Firebase proxy URL from `Info.plist`.
- **FR6.3**: The iOS app must not call the external exchange-rate provider directly.
- **FR6.4**: The iOS app must not ship the external provider API key.
- **FR6.5**: The Firebase function must call the Apilayer exchange-rate API using USD as the base currency.
- **FR6.6**: The Firebase function must accept only GET requests and return 405 for other methods.
- **FR6.7**: The Firebase function must return an error response when the provider request fails.
- **FR6.8**: The app must cache exchange rates locally after a successful fetch.
- **FR6.9**: The app must refresh exchange rates at most once per calendar day during normal app use.
- **FR6.10**: Cached rates must be reused when the app starts before a new refresh is needed.
- **FR6.11**: USD must always be available as a conversion rate with value 1.
- **FR6.12**: Conversion must return no total when a required source or target currency rate is unavailable.
- **FR6.13**: Network and decoding failures must not crash the app.
### 7. Reminders and Notifications
 
- **FR7.1**: Users must be able to enable or disable portfolio reminders.
- **FR7.2**: Users must be able to configure reminder frequency as daily, weekly, or monthly.
- **FR7.3**: Users must be able to configure the time of day for reminders.
- **FR7.4**: For weekly reminders, users must be able to select which day of the week the alert fires.
- **FR7.5**: For monthly reminders, users must be able to select which day of the month the alert fires.
- **FR7.6**: Monthly reminder day selection must be limited to days 1–28 to avoid issues with February, leap years, and shorter months; the app must display in-app guidance explaining this constraint.
- **FR7.7**: Reminder preferences must persist locally across launches.
- **FR7.8**: Reminder status in Settings must display the currently configured frequency and selected day.
- **FR7.9**: Tapping a reminder notification must clear the app badge count.
- **FR7.10**: Notification delegate setup must handle notification taps reliably, including when the app is launched cold from a notification.
### 8. Data Persistence
 
- **FR8.1**: Asset data must persist locally using SwiftData.
- **FR8.2**: Currency settings and onboarding state must persist locally using UserDefaults.
- **FR8.3**: Exchange-rate cache data and its last-refresh timestamp must persist locally using UserDefaults.
- **FR8.4**: Reminder preferences must persist locally using UserDefaults.
- **FR8.5**: The app must restore persisted assets, settings, and reminder preferences across launches.
## Non-Functional Requirements
 
### 1. Platform and Tooling
 
- **NFR1.1**: The app must target iOS 17.0 or later.
- **NFR1.2**: The app must be built with SwiftUI, SwiftData, Observation, and async/await.
- **NFR1.3**: The project must remain compatible with Swift 5.10 or later.
- **NFR1.4**: The project must remain compatible with Xcode 26.1 or later.
### 2. Usability
 
- **NFR2.1**: The app must use standard iOS navigation patterns such as TabView, NavigationStack, sheets, forms, lists, and toolbar actions.
- **NFR2.2**: Forms must prevent invalid save actions instead of allowing invalid records to be created.
- **NFR2.3**: Searchable currency lists must remain usable for a large currency catalog.
- **NFR2.4**: Empty, loading, and error-tolerant states must avoid blocking core asset-management workflows.
- **NFR2.5**: Amount formatting must use compact notation for large net worth totals to remain readable.
### 3. Performance
 
- **NFR3.1**: Exchange-rate requests must run asynchronously and must not block the UI.
- **NFR3.2**: Portfolio total calculations must be efficient enough for interactive tab updates.
- **NFR3.3**: Local persistence reads and writes must not introduce noticeable delays for normal asset counts.
### 4. Reliability
 
- **NFR4.1**: The app must tolerate missing, stale, or partially unavailable exchange-rate data.
- **NFR4.2**: Bad HTTP status codes, request failures, and decode failures must be surfaced through typed errors internally.
- **NFR4.3**: The app must avoid force-unwrapping optional asset fields in UI and calculation paths.
- **NFR4.4**: SwiftData container initialization failures may terminate launch with a clear fatal error.
- **NFR4.5**: Notification scheduling must not produce concurrency warnings or data races.
### 5. Security and Privacy
 
- **NFR5.1**: Third-party API keys must be stored in Firebase Secret Manager, not in iOS source code or app bundles.
- **NFR5.2**: The Firebase function must avoid returning provider secrets to the client.
- **NFR5.3**: User asset data must stay local to the device unless a future sync feature explicitly changes that requirement.
- **NFR5.4**: Public privacy content must accurately describe data handling for the deployed app.
### 6. Architecture
 
- **NFR6.1**: Tab and dashboard business logic must remain separated from SwiftUI views through observable view-model types.
- **NFR6.2**: Asset calculation behavior must remain testable through protocol-based operations.
- **NFR6.3**: Networking must remain centralized behind reusable request helpers.
- **NFR6.4**: The exchange-rate provider must remain replaceable without changing tab UI code.
## Current Scope Notes
 
- The app root after onboarding is a tab-based `HomeView` with Assets, Transfer Rates, and Settings tabs.
- `AssetChartsView` exists in the codebase but is not currently displayed in any active tab.
- Settings currently persist currency and reminder preferences; display currency filtering in the Assets tab should continue to evolve toward consistently honoring all selected display currencies.