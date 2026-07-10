# Implementation Plan: Weekly and Monthly Highlights

**Branch**: `005-weekly-monthly-highlights` | **Date**: July 5, 2026 | **Spec**: [spec.md](spec.md)
**Input**: `/specs/005-weekly-monthly-highlights/spec.md`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`

## Summary

Add locally calculated weekly and monthly portfolio recaps that can be opened
from Dashboard and remain due after their schedule date until explicitly dismissed. Automatic
monthly recaps summarize the prior completed month, while manual Dashboard
entry opens the current calendar month. A pure highlights calculator will derive current totals, a scoped historical baseline, growth,
liability movement, and bounded insights. A UserDefaults-backed presentation
store will evaluate first-of-month and Saturday eligibility with injected
calendar/date dependencies. SwiftUI pages will reuse the existing Dashboard
card, type, color, navigation, rate, and history patterns without changing
SwiftData, backup, widget, notification, iCloud, Firebase, or telemetry
contracts.

## Requirements Traceability

| Requirement | Planned change | Design surface | Verification |
|-------------|----------------|----------------|--------------|
| FR1.6, SFR-002-SFR-006, SFR-015 | Extend returning-user launch with post-onboarding recap eligibility, dismissal-only completion, catch-up due periods, and monthly-first overlap ordering. | `MyWealth/MyWealthApp.swift`, `MyWealth/Core/Highlights/HighlightPresentationStore.swift` | Date/calendar-controlled store tests plus launch-state inspection. |
| FR5.3, SFR-001, SFR-013 | Add Dashboard access to distinct current weekly and monthly pages while preserving existing sections. | `MyWealth/Features/Dashboard/DashboardView.swift`, `MyWealth/Features/Highlights/WealthHighlightsView.swift` | Manual navigation check on iPhone and iPad. |
| FR6.6, FR6.11, SFR-007-SFR-012 | Reuse complete current conversions and add deterministic period calculations and insights. | `MyWealth/Core/Highlights/WealthHighlightCalculator.swift`, `MyWealth/Features/Highlights/WealthHighlightsView.swift` | Pure calculation fixtures for growth, assets, liabilities, ratios, allocation, zero, negative, and unavailable values. |
| FR7.13-FR7.15, SFR-011 | Preserve complete-rate gating and expose missing/stale context in highlights. | `DashboardViewModel`, highlights calculator/view | Missing-rate and stale-rate tests; no partial totals. |
| FR9.4-FR9.10, SFR-009-SFR-010 | Read bounded `PortfolioSnapshot` history for the active currency and current scope without changing recording. | `WealthHighlightCalculator`, `DashboardView` history coordination | Baseline selection, scope boundary, ordering, and no-write tests. |
| FR10.5, FR10.9, SFR-006 | Persist only stable last-dismissed period identifiers in isolated local defaults. | `HighlightPresentationStore` | Isolated UserDefaults restore and downgrade-compatible missing-key tests. |
| FR13.4-FR13.6 | Preserve telemetry privacy and allowlist; add no highlight financial event. | Existing `AnalyticsService` boundary | Source audit and existing telemetry tests. |
| FR14.1-FR14.8, SFR-014 | Localize highlight copy while keeping period identifiers and financial raw values stable. | `MyWealth/Resources/Localizable.xcstrings`, highlights views/calculator display boundary | Catalog completeness, fallback, locale formatting, and Arabic RTL inspection. |
| FR15.1-FR15.9, SFR-001-SFR-015 | Promote the completed highlights contract into the shipped baseline without changing its approved scope. | Highlight core/view/root/Dashboard surfaces plus `requirements.md` | Focused highlight tests, source audit, manual state matrix, and full iOS gate. |
| NFR2.1, NFR2.4-NFR2.6, SFR-014 | Use native sheets/navigation, scrollable cards, explicit unavailable states, and scalable amount layouts. | `WealthHighlightsView`, existing design-system components | iPhone/iPad, Dynamic Type, VoiceOver, RTL, long-label, and large-value checks. |
| NFR3.2-NFR3.4 | Keep calculations synchronous and bounded over at most the supplied history slice; no new network or persistence query loop. | Calculator and SwiftData query predicate/sort use | Calculation unit tests and source inspection. |
| NFR4.1, NFR4.3, NFR4.6-NFR4.7 | Handle missing optional snapshot fields, empty collections, zero denominators, missing rates, and duplicates safely. | Calculator, presentation store, highlights view | Edge-case fixtures and existing history tests. |
| NFR5.3, NFR5.6 | Keep recap values local and out of logs, analytics, notifications, widgets, and server payloads. | Entire feature | Data-flow/source audit and telemetry regression tests. |
| NFR6.1, NFR6.2, NFR6.5 | Keep calculation and scheduling policy outside SwiftUI with injected settings/calendar dependencies. | `MyWealth/Core/Highlights/` | Direct unit tests without views or real user defaults. |

## Technical Context

**Language/Version**: Swift 6.0

**Primary Dependencies**: SwiftUI, SwiftData, Observation, Foundation; existing
DesignSystem package and Dashboard view-model conversion behavior

**Storage**: Existing SwiftData assets, liabilities, and `PortfolioSnapshot`
history are read only; namespaced standard UserDefaults keys record pending
non-financial period metadata and dismissed identifiers

**Testing**: Swift Testing in `MyWealthTests/` with isolated UserDefaults,
injected Calendar/Date, and in-memory model fixtures

**Target Platform**: iOS/iPadOS 26.1+, Xcode 26.1+

**Project Type**: Existing iOS app; no WidgetKit or Firebase change

**Performance Goals**: Eligible-launch evaluation completes in constant time;
summary calculation stays imperceptible for 10,000 history rows by using one
filtered pass and a bounded insight result; UI remains interactive without
network blocking

**Constraints**: Local-first privacy; complete-rate gating; scoped history;
Swift 6 concurrency safety; stable identifiers; no schema or backup change;
match existing Dashboard visual language

**Scale/Scope**: One launch coordinator, one pure calculator/model group, one
UserDefaults store, one reusable highlight view with weekly/monthly modes, two
Dashboard menu actions, localization entries, and focused tests

## Constitution Check

*GATE: Passed before research and re-checked after design.*

- **Privacy by Default**: PASS. Existing local records and cached rates are read
  only. Only non-financial period identifiers are newly persisted, and no new
  data leaves the device.
- **Financial Correctness**: PASS. Current values reuse complete conversion
  behavior; baseline selection, scoped history, zero/negative values, change
  signs, percentage denominator, and liability direction have direct tests.
- **Compatibility**: PASS. No model schema, backup field, synchronized setting,
  bundle ID, App Group, widget kind, notification identifier, endpoint, or raw
  financial value changes. Missing defaults are a safe migration.
- **Native Product Quality**: PASS. A standard sheet and NavigationStack-hosted
  scroll view reuse existing cards, tokens, and SF Symbols. Copy, state, large
  text, VoiceOver, reduced motion, RTL, iPhone, and iPad behavior are included.
- **Architecture**: PASS. Views render a derived summary; date policy,
  persistence, baseline selection, and financial math stay in focused,
  dependency-injected core types.
- **Verification**: PASS. Store/calculator tests cover SFR-002-SFR-012, focused
  app tests cover regressions, and the full iOS gate follows narrow tests.
- **Scope Discipline**: PASS. No planned enhancement is implicitly promoted.
  Notifications, widgets, sharing, exports, AI, server work, and new history
  storage remain out of scope.

## Project Structure

### Documentation (this feature)

```text
specs/005-weekly-monthly-highlights/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
├── contracts/
│   └── highlights-ui.md
└── tasks.md
```

### Source Code

```text
MyWealth/
├── Core/
│   └── Highlights/
│       ├── HighlightPresentationStore.swift
│       └── WealthHighlightCalculator.swift
├── Features/
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   └── Highlights/
│       └── WealthHighlightsView.swift
├── Resources/
│   └── Localizable.xcstrings
└── MyWealthApp.swift

MyWealthTests/
└── MyWealthTests.swift
```

**Structure Decision**: Calendar eligibility and local presentation state live
in `Core/Highlights` because app launch and Dashboard both consume the policy.
Financial recap derivation lives beside it as a pure calculator. The SwiftUI
page has its own feature folder and reuses Dashboard models/components rather
than expanding `DashboardView`. App root owns automatic sheet routing;
Dashboard owns manual routing. Existing file-system-synchronized Xcode groups
include the new Swift files without project-file edits.

## Data and Migration Design

- **Models/schema**: No SwiftData change. `PortfolioSnapshot` supplies baseline
  asset/liability/net-worth observations; current values come from existing
  asset/liability conversion paths.
- **Settings/identifiers**: Add
  `highlights.pendingWeeklyPeriod`,
  `highlights.pendingMonthlyPeriod`,
  `highlights.lastDismissedWeeklyPeriod` and
  `highlights.lastDismissedMonthlyPeriod`. Identifiers encode period kind plus
  calendar era/year/week or era/year/month. Pending values encode only the
  period kind, identifier, interval, and reference date so an undismissed sheet
  survives later launches. The store accepts injected UserDefaults and Calendar.
- **Backup/import**: No change. Presentation keys are device experience state,
  not portfolio data, and remain excluded.
- **iCloud/widget/server propagation**: No new propagation. The keys are not
  added to iCloud KVS; no highlight fields enter widget snapshots, Firebase,
  notifications, analytics, or AI payloads.
- **Rollback/recovery**: Older builds ignore the keys. A defaults write failure
  can only cause the recap to reappear; it cannot modify portfolio data. An
  invalid identifier is treated as not dismissed.

## Verification Plan

- **Focused tests**: Weekly/monthly intervals and identifiers; Saturday and
  first-day eligibility; overlap ordering; dismissal persistence; repeated activation; onboarding
  gate; manual non-consumption; persisted restoration; baseline selection;
  active scope/currency filtering; absolute and percentage growth; zero and
  negative baselines; asset/liability changes; debt ratio; allocation insight;
  bounded insight count; empty/missing-rate states.
- **Regression tests**: Existing Dashboard total, insight, portfolio history,
  snapshot scope, AppSettings isolation, analytics allowlist, and localization
  tests.
- **UI/accessibility checks**: iPhone 17 and iPad simulator; light/dark mode;
  smallest width; accessibility Dynamic Type; VoiceOver reading order and
  labels; reduced motion; Arabic RTL; empty, missing-rate, stale-rate,
  insufficient-history, negative, and large-value states.
- **Backend checks**: N/A; no Firebase/function change.
- **Repository hygiene**: Run `git diff --check`.
- **Full iOS gate**:

  ```sh
  xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
    -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

## Complexity Tracking

No constitution violations, migrations, or new dependencies.
