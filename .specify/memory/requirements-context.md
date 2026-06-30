# Wealth Map Requirements Context

This file is a routing guide for Spec Kit. `requirements.md` remains the
authoritative product baseline; do not copy its full contents into feature
artifacts or allow this summary to override it.

## Source Hierarchy

1. `.specify/memory/constitution.md` defines non-negotiable engineering and
   governance rules.
2. `requirements.md` defines shipped behavior, non-functional constraints,
   current scope, and candidate enhancements.
3. A feature's `spec.md` defines an approved change to that baseline.
4. `plan.md` and `tasks.md` define how the approved change will be delivered.

Conflicts between a feature request and the constitution or baseline MUST be
called out explicitly. Silence never implies permission to change existing
behavior.

## Baseline Requirement Map

| Area | Requirement IDs | Primary implementation surfaces |
|------|-----------------|---------------------------------|
| Onboarding and settings | FR1.1-FR1.15 | `MyWealth/Features/Onboarding/`, `MyWealth/Features/Settings/` |
| Currency selection | FR2.1-FR2.8 | `MyWealth/Features/CurrencySelection/`, settings and conversion helpers |
| Asset management | FR3.1-FR3.11 | `MyWealth/Features/AddOrEdit/`, `MyWealth/Features/Assets/`, `MyWealth/Core/Asset.swift` |
| Liability management | FR4.1-FR4.10 | `MyWealth/Features/AddOrEdit/`, `MyWealth/Features/Assets/` |
| Navigation and tabs | FR5.1-FR5.8 | `MyWealth/MyWealthApp.swift`, `MyWealth/Features/IPad/` |
| Dashboard and net worth | FR6.1-FR6.16 | `MyWealth/Features/Dashboard/`, shared components |
| Exchange rates | FR7.1-FR7.16 | iOS networking services, `functions/`, Firebase configuration |
| Reminders | FR8.1-FR8.12 | `MyWealth/Core/Notifications/`, reminder feature views |
| Portfolio history | FR9.1-FR9.10 | snapshot models, dashboard coordinators and sanitizers |
| Persistence and portability | FR10.1-FR10.13 | SwiftData container, settings stores, `DataPortability.swift`, iCloud helpers |
| Widgets | FR11.1-FR11.6 | `MyWealth/Core/Widget/`, `MyWealthWidget/` |
| Net worth goals | FR12.1-FR12.16 | `MyWealth/Core/NetWorthGoal.swift`, `MyWealth/Core/NetWorthGoalStore.swift`, `MyWealth/Features/Goals/`, Dashboard and Net Worth surfaces |
| Localization | FR14.1-FR14.8 | `MyWealth/Resources/Localizable.xcstrings`, `MyWealth/Core/Localization/`, localized feature display boundaries, `MyWealthWidget/Resources/Localizable.xcstrings` |
| Platform and tooling | NFR1.1-NFR1.4 | Xcode project and all Swift targets |
| Usability | NFR2.1-NFR2.7 | all user-facing SwiftUI flows |
| Performance | NFR3.1-NFR3.4 | networking, calculations, persistence, dashboard rendering |
| Reliability | NFR4.1-NFR4.8 | error paths, concurrency, persistence, widgets |
| Security and privacy | NFR5.1-NFR5.5 | client data flows, Firebase functions, logs and configuration |
| Architecture | NFR6.1-NFR6.8 | view models, services, stores, schedulers and portability helpers |

## Scope Interpretation

- Statements under Functional and Non-Functional Requirements are shipped
  baseline contracts unless a feature spec explicitly changes them.
- Current Scope Notes describe present limitations. A feature may remove a
  limitation only when it says so explicitly and supplies acceptance criteria.
- Planned Enhancements and Snapshot Retention are candidates, not shipped
  promises. Promote the selected candidate into a feature spec with concrete,
  testable requirements before implementation.
- Features not named in `requirements.md` still require impact analysis across
  every baseline area they touch.

## Required Feature Impact Record

Every generated `spec.md` MUST contain:

- change type: additive feature, behavioral change, defect correction, or
  internal-only change;
- affected baseline IDs and the exact effect on each;
- baseline IDs that are especially at risk of regression;
- current-scope or planned-enhancement text being changed or promoted;
- explicit out-of-scope behavior;
- local, iCloud, export, widget, notification, and server data-flow impact;
- compatibility or migration impact for persisted data and stable identifiers;
- measurable acceptance and regression criteria.

Use `N/A` with a reason instead of omitting an impact category.
