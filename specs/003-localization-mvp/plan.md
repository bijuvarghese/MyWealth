# Implementation Plan: Localization MVP

**Branch**: `003-localization-mvp` | **Date**: June 26, 2026 | **Spec**: [spec.md](spec.md)
**Input**: `/specs/003-localization-mvp/spec.md`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`

## Summary

Deliver automatic local-language display for Wealth Map when the app or widget opens under the MVP locales: English fallback, Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, and Arabic. The implementation localizes static app, widget, reminder, share, validation, status, and display-label copy while preserving financial calculations, persisted raw values, exchange-rate behavior, backup/import formats, widget payloads, notification identifiers, Firebase flows, and analytics payload rules.

## Requirements Traceability

| Requirement | Planned change | Design surface | Verification |
|-------------|----------------|----------------|--------------|
| FR1.1-FR1.15, SFR-001, SFR-002, SFR-009, SFR-012 | Extend onboarding and settings copy for supported locales while preserving completion, currency, reminder, iCloud, backup/import, compact formatting, and version behavior. | `MyWealth/Features/Onboarding/`, `MyWealth/Features/Settings/`, `MyWealth/Components/ReminderStatusCard.swift`, app string resources | Locale smoke tests for onboarding/settings; existing persistence checks continue to pass. |
| FR2.1-FR2.8, SFR-004, SFR-005 | Extend currency picker display names and search-visible names without changing ISO codes, selection rules, base-currency requirements, ordering, or refresh triggers. | `MyWealth/Core/AssetCurrencyMetadata.swift`, `MyWealth/Features/CurrencySelection/`, onboarding/settings currency pickers, `CurrencyRowView` | Currency lookup tests in English, Hindi, Arabic, and unsupported locale; selection/order regression tests. |
| FR3.1-FR3.11, FR4.1-FR4.10, SFR-004, SFR-010 | Extend asset/liability forms, categories, rows, validation, empty states, and destructive copy while raw enum values and stored records remain stable. | `MyWealth/Core/Asset.swift`, `MyWealth/Features/AddOrEdit/`, `MyWealth/Features/Assets/`, row components | Add/edit/delete smoke checks; tests confirm raw values and backup identifiers unchanged. |
| FR5.1-FR5.8, SFR-001, SFR-002, SFR-008 | Extend tab labels, navigation titles, iPad section titles, and Briefing navigation copy for supported locales. | `MyWealth/MyWealthApp.swift`, `MyWealth/Features/IPad/IPadRootView.swift`, feature navigation titles | iPhone and iPad navigation pass in English, Arabic, and one additional MVP locale. |
| FR6.1-FR6.16, SFR-002, SFR-006, SFR-007, SFR-009 | Extend dashboard, net worth, insights, allocation, history, rate status, share text, empty/loading/error states, numbers, dates, percents, and plurals while calculations and display-currency order remain unchanged. | `MyWealth/Features/Dashboard/`, `CurrencyTotalsView`, `TransferRateWidgetView`, `RateStatusBannerView`, `DataPortability.PortfolioShareSummaryBuilder` | Populated/empty/stale/unavailable checks; conversion and share gating tests. |
| FR7.1-FR7.16 | Preserve exchange-rate proxy, cache, conversion, missing-rate, stale-rate, and failure behavior. | `FirebaseExchangeRateService`, `DashboardViewModel`, `functions/` unchanged unless copy-only errors are touched | Existing exchange-rate and conversion tests; no Firebase function changes expected. |
| FR8.1-FR8.12, SFR-002, SFR-004, SFR-007, SFR-010 | Extend reminder settings and notification title/body copy while preserving stored preference decoding, scheduling identifiers, smart reminder rules, badge clearing, and concurrency behavior. | `MyWealth/Core/Notifications/ReminderModels.swift`, `NotificationScheduler.swift`, `ReminderSettingsView`, onboarding reminder step | Reminder model display tests; notification request tests confirm stable identifier and localized body selection. |
| FR9.1-FR9.10 | Preserve snapshot recording, history-scope behavior, and stored snapshot values. Display-only labels may localize but snapshot category names remain compatible. | `DashboardViewModel`, `PortfolioHistoryCoordinator`, `AssetValueSnapshot`, `NetWorthSnapshot` | Existing snapshot tests plus review that no stored category-name rewrite occurs. |
| FR10.1-FR10.13, SFR-010 | Preserve SwiftData, UserDefaults, iCloud settings sync, backup/import format, restore semantics, and settings keys. | `DataPortability.swift`, `ICloudSettingsSync.swift`, SwiftData models, settings stores | Backup/import compatibility tests with existing fixture or generated sample; no key/schema diff. |
| FR11.1-FR11.6, SFR-003, SFR-006, SFR-008, SFR-009 | Extend widget visible labels, placeholders, unavailable states, and last-updated context while preserving snapshot schema, App Group suite, order, and timeline reload behavior. | `MyWealthWidget/MyWealthWidgetViews.swift`, `MyWealthWidgetProvider.swift`, `MyWealth/Core/Widget/` | Widget placeholder/populated inspection in English, Arabic, and Simplified Chinese; payload model unchanged. |
| FR12.1-FR12.16, SFR-002, SFR-004, SFR-006, SFR-007, SFR-012 | Extend goal form, summaries, validation, outlook states, timing text, and accessibility labels while preserving goal data and calculations. | `MyWealth/Core/NetWorthGoal.swift`, `MyWealth/Features/Goals/`, dashboard/net worth goal cards | Goal create/edit/delete tests; Dynamic Type and long-label checks. |
| FR13.1-FR13.9, SFR-010, SFR-011 | Preserve analytics and crash payload rules; do not add locale or localized/user-entered strings to telemetry. | `AnalyticsService.swift`, Firebase delegate, call sites | Analytics catalog/code review confirms no new disallowed parameters. |
| FR14.1-FR14.8, SFR-001-SFR-012 | Add automatic supported-language display, English fallback, locale-aware formatting, stable raw values, and Arabic right-to-left behavior across app and widget surfaces. | Localization catalogs, `MyWealth/Core/Localization/`, app and widget display boundaries | Supported-locale, fallback, compatibility, formatting, and RTL checks. |
| NFR1.1-NFR1.4 | Preserve platform/tooling baseline. | Xcode project, targets, build settings | Full iOS test gate when implementation begins. |
| NFR2.1-NFR2.7, SFR-008, SFR-012 | Extend native usability with localized copy, long labels, right-to-left layout, VoiceOver, Dynamic Type, and destructive-action clarity. | All user-facing SwiftUI views and widgets | Locale UI/accessibility matrix including Arabic RTL and Dynamic Type. |
| NFR3.1-NFR3.4 | Preserve interactive performance; localization must be bundle/local lookup only, not network or persistence work during render. | Display helpers and resources | Code review; no async/network/storage added for translation lookup. |
| NFR4.1-NFR4.8 | Preserve reliability for stale/missing data, optionals, notification scheduling, snapshots, and widget writes. | Existing services/stores plus localized status strings | Existing reliability tests plus localized stale/missing state checks. |
| NFR5.1-NFR5.7, SFR-011 | Preserve privacy and secret handling; localization resources must not contain secrets or personal financial data. | Translation resources, tests, logs | Source/resource review for secrets and personal data. |
| NFR6.1-NFR6.9 | Extend architecture with display helpers only; keep business, networking, reminder, widget, portability, and analytics boundaries intact. | `Core/Localization` or equivalent display helpers, existing view/service boundaries | Code review confirms localization does not move business logic into views. |

## Technical Context

**Language/Version**: Swift 6.0 for the app, widget, and tests. No Firebase or Node.js changes are planned.

**Primary Dependencies**: SwiftUI, Foundation locale/formatting support, UserNotifications, WidgetKit, SwiftData, Observation, Charts, CloudKit, async/await. No new third-party dependency is planned.

**Storage**: Bundled app/widget localization resources only. No SwiftData, UserDefaults, App Group UserDefaults, CloudKit, backup, or server storage changes.

**Testing**: Swift Testing in `MyWealthTests/`; focused display-helper, compatibility, backup/import, reminder, and widget payload tests; manual or automated locale launch checks; full iOS gate.

**Target Platform**: iOS/iPadOS 26.1+, Xcode 26.1+

**Project Type**: Existing iOS app and WidgetKit extension with Firebase backend unchanged.

**Performance Goals**: Localized labels and formatting must be immediate in normal view rendering, must not trigger network calls, and must not add noticeable latency to tab navigation, dashboard rendering, widget rendering, or form interaction.

**Constraints**: Local-first privacy; stable persisted identifiers; no in-app language setting for MVP; English fallback; graceful missing-translation behavior; RTL support for Arabic; no server translation; no translation of user-entered financial data.

**Scale/Scope**: User-facing copy across onboarding, tabs, dashboard, assets, liabilities, net worth/goals, rates, briefing/FIRE, settings, backup/import, reminders, widgets, share text, alerts, confirmations, statuses, validation, enum display labels, plurals, and locale-sensitive formatting.

## Constitution Check

*GATE: Must pass before research and be re-checked after design.*

- **Privacy by Default**: PASS. Localization resources are bundled and introduce no new server-bound data, financial payloads, telemetry parameters, or secrets.
- **Financial Correctness**: PASS. Calculations, exchange rates, snapshots, imports, exports, and reminder schedules are preserved; only presentation copy changes.
- **Compatibility**: PASS. No SwiftData schema, UserDefaults key, backup field, enum raw value, App Group payload, widget kind, notification identifier, bundle ID, or endpoint rename is planned.
- **Native Product Quality**: PASS. The plan requires locale checks across iPhone, iPad, widgets, Dynamic Type, VoiceOver, long labels, and Arabic RTL.
- **Architecture**: PASS. Localization stays in resource/display-helper boundaries and existing views consume localized display values without moving business logic.
- **Verification**: PASS. The plan includes focused tests, UI/accessibility checks, `git diff --check`, and the full iOS test gate for implementation.
- **Scope Discipline**: PASS. The MVP explicitly excludes an in-app language picker, runtime/server translation, data migration, Firebase changes, and translation of user-entered values.

## Project Structure

### Documentation (this feature)

```text
specs/003-localization-mvp/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── contracts/
    └── localization-coverage.md
```

### Source Code (select and narrow to real affected paths)

```text
MyWealth/
├── Resources/
│   └── Localizable.xcstrings
├── Components/
├── Core/
│   ├── Localization/
│   ├── Notifications/
│   ├── Widget/
│   ├── Asset.swift
│   ├── AssetCurrencyMetadata.swift
│   └── DataPortability.swift
├── Features/
│   ├── AddOrEdit/
│   ├── Assets/
│   ├── Briefing/
│   ├── CurrencySelection/
│   ├── Dashboard/
│   ├── FIRE/
│   ├── Goals/
│   ├── IPad/
│   ├── Onboarding/
│   ├── Reminders/
│   ├── Settings/
│   └── TransferRates/
└── MyWealthApp.swift

MyWealthWidget/
├── Resources/
│   └── Localizable.xcstrings
├── MyWealthWidgetViews.swift
└── MyWealthWidgetProvider.swift

MyWealthTests/
└── localization-focused tests
```

**Structure Decision**: Add localization resources to both the app and widget targets because widgets render in a separate extension. Add display helpers under `MyWealth/Core/Localization/` or an equivalent core display boundary for enum labels, currency names, plurals, and formatting wrappers that need tests. Keep existing feature views in their current folders and convert copy in place. Keep notification scheduling in `Core/Notifications`, widget payload boundaries in `Core/Widget`, and backup/share behavior in `DataPortability`.

## Data and Migration Design

- **Models/schema**: N/A. No SwiftData model or migration changes.
- **Settings/identifiers**: N/A. No in-app language preference, UserDefaults key, notification identifier, widget kind, App Group name, bundle ID, or endpoint changes.
- **Backup/import**: Backup field names, enum raw values, category names, and restore behavior stay unchanged. Localized display labels must not be exported in place of stable values.
- **iCloud/widget/server propagation**: iCloud and server behavior are unchanged. Widget visible labels localize, but widget snapshot payload fields and values remain unchanged.
- **Rollback/recovery**: Reverting resources/display helpers returns the app to English fallback with no migration. Existing data remains readable because stable raw values are preserved.

## Verification Plan

- **Focused tests**: Cover localized category/reminder/FIRE/goal/status labels, currency-name fallback, plural/count strings, English fallback for unsupported locales, notification body lookup, backup/import raw-value compatibility, widget payload stability, and share text formatting (`SFR-001`-`SFR-012`).
- **Regression tests**: Existing conversion, exchange-rate, settings persistence, snapshots, goals, reminders, backup/import, widget snapshot, and analytics catalog behavior (`FR1.1`-`FR13.9`, `NFR1.1`-`NFR6.9`).
- **UI/accessibility checks**: iPhone 17 and iPad where practical; English, Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, Arabic, and one unsupported locale; light/dark, Dynamic Type, VoiceOver labels, RTL layout, widgets, long currency names, large values, empty, loading, stale, missing-rate, destructive, and confirmation states.
- **Backend checks**: N/A. No Firebase, Node, cache, HTTP, provider, secret, or deployed endpoint change is planned.
- **Repository hygiene**: Run `git diff --check`; review localization resources for secrets, credentials, personal financial data, generated local artifacts, or user-entered financial labels.
- **Full iOS gate**:

  ```sh
  xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
    -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

## Complexity Tracking

> Fill only for constitution violations or new dependencies/abstractions.

| Violation or addition | Why needed | Simpler alternative rejected because | Approval/migration |
|-----------------------|------------|--------------------------------------|--------------------|
| N/A | No constitution violation or new dependency is planned. | N/A | N/A |
