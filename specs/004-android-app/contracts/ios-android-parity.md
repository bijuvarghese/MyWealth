# Contract: iOS-to-Android Parity

## Platform Mapping

| iOS contract/surface | Android implementation contract |
|----------------------|---------------------------------|
| SwiftUI | Jetpack Compose + Material 3 |
| TabView | Adaptive `NavigationSuiteScaffold` |
| iPad `NavigationSplitView` | Expanded navigation rail and adaptive list/detail layouts |
| SwiftData | Room with explicit migrations and Flow |
| UserDefaults | DataStore |
| CloudKit private sync | Opt-in Google Drive `appDataFolder` sync |
| iCloud key-value settings | Syncable settings inside the Drive envelope |
| WidgetKit/App Group snapshot | Glance widget backed by minimized local widget state |
| UserNotifications | Android notification channels + WorkManager scheduling |
| UIActivityViewController | Android Sharesheet |
| Document picker | Storage Access Framework |
| Info.plist proxy URLs | Non-secret BuildConfig/resource configuration |
| SF Symbols | Material/custom vector icons with accessibility labels |
| XCTest/Swift Testing | JVM, AndroidX instrumented, Compose, Room, WorkManager, and Glance tests |

## Requirement Adaptations

### Navigation

- Preserve five destinations: Dashboard, Assets, Net Worth, Rates, Briefing.
- Settings is reachable from Dashboard and Briefing.
- Compact windows use bottom navigation; expanded windows use a rail or
  equivalent adaptive presentation.

### Persistence and Sync

- Room replaces SwiftData but preserves user-observable record behavior.
- Drive replaces optional iCloud and remains off by default.
- Exact background timing is not promised on Android; foreground/post-write
  sync plus WorkManager provides eventual reconciliation.
- Google account changes require explicit local profile decisions.

### Widgets

- Preserve net worth, asset total, liability total, base currency, ordered
  secondary totals, empty state, and last update.
- Android home-screen sizes are supported responsively.
- Apple lock-screen widget family parity is not claimed where the Android
  launcher does not provide an equivalent host.

### Reminders

- Preserve daily/weekly/monthly configuration and smart suppression.
- Android notification permission denial is a first-class state.
- Inexact durable scheduling is acceptable; exact-alarm permission is not
  requested for portfolio reminders.

### Backup and Sharing

- `.backup` version 2 is the cross-platform portable data contract.
- Android uses the Storage Access Framework for import/export.
- Text progress summaries use Android Sharesheet and remain user initiated.

### Localization and Accessibility

- Preserve `en`, `hi`, `es`, `pt-BR`, `fr`, `de`, `zh-Hans`, and `ar`.
- Android resource qualifiers provide fallback and RTL.
- TalkBack replaces VoiceOver validation; font scaling replaces Dynamic Type.

## Calculation Parity Fixtures

Both platforms must share safe, synthetic fixtures for:

- Same-currency and cross-currency totals
- Missing source/target rates
- USD identity rate
- Assets minus liabilities
- Included and ignored assets
- Allocation by category
- Snapshot threshold `0.01`
- Goal progress, achieved state, insufficient history, non-growing history,
  unavailable conversion, due today, overdue, and remaining-gap rates
- FIRE calculation levels and edge cases

Expected results are stored as decimal strings with an explicitly documented
display rounding policy. Platform-local formatting may differ by locale while
the underlying numeric result remains equivalent.

## Backend Parity

- Android calls the same deployed Firebase HTTPS proxy contracts.
- Android never calls Apilayer, MetalpriceAPI, or OpenAI directly.
- Android does not receive or bundle provider API keys.
- HTTP method, status, decoding, cache timestamp, and missing-rate behavior
  match the iOS requirements.

## Privacy Parity

- Financial records stay local unless the user enables Drive sync, exports a
  backup, shares a summary, or explicitly invokes sanitized analysis.
- Telemetry is behavior-only and uses the iOS typed allowlist.
- Google account identity, Drive payloads, balances, labels, and free text are
  excluded from telemetry and crash metadata.
