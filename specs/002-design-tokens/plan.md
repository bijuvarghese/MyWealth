# Implementation Plan: Cross-Platform Design Tokens

**Branch**: `002-design-tokens` | **Date**: 2026-06-25 | **Spec**: [spec.md](spec.md)
**Input**: `/specs/002-design-tokens/spec.md`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`

## Summary

Create a shared Wealth Map design token foundation for iOS, Android, and web while preserving all shipped financial behavior. The current implementation defines reusable token decisions, documents platform mappings, adds a local Swift package with generic token/component names, and keeps app-facing compatibility facades so existing screens and widgets can align without changing calculations, persistence, sync, export, server, widget payload, notification, or telemetry behavior.

## Requirements Traceability

| Requirement | Planned change | Design surface | Verification |
|-------------|----------------|----------------|--------------|
| FR1.1-FR13.9, SFR-006 | Preserve shipped app behavior while visual values become token-driven. | `MyWealth/Components/`, selected `MyWealth/Features/`, `MyWealthWidget/` | Focused UI inspection plus `git diff --check`; run available tests for touched app/widget behavior. |
| FR5.1-FR5.8 | Preserve iPhone tabs and iPad navigation while shared visual primitives gain tokens. | `MyWealth/MyWealthApp.swift`, `MyWealth/Features/IPad/IPadRootView.swift` if adopted | Manual navigation pass through Dashboard, Assets, Net Worth, Rates, Settings, and iPad root. |
| FR6.1-FR6.16 | Preserve dashboard, asset, liability, net worth, share, allocation, and history data while tokenizing common presentation styles. | `MyWealth/Features/Dashboard/`, `MyWealth/Components/` | Empty/populated dashboard, large-value, long-currency, stale/unavailable-rate, and share-available checks. |
| FR11.1-FR11.6 | Preserve widget data contract and timeline behavior while aligning visible widget accent/status treatment. | `MyWealthWidget/MyWealthWidgetViews.swift`, `MyWealth/Core/Widget/` unchanged unless needed | Placeholder and populated widget preview/inspection; confirm no widget snapshot model changes. |
| FR12.14, SFR-007, SFR-008 | Preserve goal accessibility and non-color-only communication under tokenized color/type/spacing. | `MyWealth/Features/Goals/NetWorthGoalCard.swift`, `MyWealth/Features/Goals/NetWorthGoalFormView.swift` if adopted | Dynamic Type, VoiceOver labels, long currency labels, large values, and reduced-motion checks. |
| NFR1.1-NFR1.4 | Preserve platform and tooling baseline. | Xcode project and existing targets unchanged | Build/test with existing project settings when app code changes. |
| NFR2.1-NFR2.7, SFR-001-SFR-005, SFR-009, SFR-011, SFR-012 | Extend product quality with a reusable visual language and clear review process. | `tokens/`, `MyWealth/Core/Design/`, shared components, token contracts | Token catalog review; first-surface visual review; accessibility and rollback checklist. |
| NFR3.1-NFR3.4 | Preserve interactive performance by keeping tokens static and presentation-only. | `MyWealth/Core/Design/`, shared components | Inspect for no network, persistence, or heavy runtime parsing in tokenized UI paths. |
| NFR4.1-NFR4.8 | Preserve reliable empty/error/stale/unavailable states and keep status cues semantic. | `RateStatusBannerView`, dashboard status surfaces, goal states if adopted | State inspection for stale, unavailable, warning, success, and destructive treatments. |
| NFR5.1-NFR5.7, SFR-010 | Preserve privacy and secret handling. | `tokens/`, generated artifacts, source review | Inspect token files for no secrets, credentials, personal financial data, user-entered labels, or payload values. |
| NFR6.1-NFR6.9 | Extend architecture with presentation-only visual tokens while preserving business/service boundaries. | `https://github.com/bijuvarghese/wealth-map-design-system`, `MyWealth/Core/Design/`, `MyWealth/Components/`, `MyWealthWidget/` | Code review confirms financial logic, persistence, networking, widgets, portability, and analytics boundaries stay isolated. |

## Technical Context

**Language/Version**: Swift 6.0 for the current iOS app and widget; platform-neutral token documentation for Android and web handoff

**Primary Dependencies**: SwiftUI and WidgetKit for the current implementation slice; the remote `DesignSystem` Swift package at `https://github.com/bijuvarghese/wealth-map-design-system.git` pinned to version `0.1.0`; no Firebase, persistence, or server dependency changes

**Storage**: Source-controlled token catalog and documentation only; no SwiftData, UserDefaults, App Group UserDefaults, CloudKit, backup, or server storage changes

**Testing**: Static token/catalog inspection, focused component/widget review, existing Swift Testing where touched behavior has coverage, and the full iOS gate when app code changes

**Target Platform**: iOS/iPadOS 26.1+, Xcode 26.1+

**Project Type**: Existing iOS app and WidgetKit extension with cross-platform token handoff for future Android and web apps

**Performance Goals**: Token access must be immediate in rendered views, must not trigger network or persistence work, and must not add noticeable latency to tab, dashboard, chart, or widget rendering

**Constraints**: Local-first privacy; no secrets or financial data in tokens; graceful stale/missing status treatment; stable identifiers and persisted-data compatibility; native iOS/iPadOS and widget behavior

**Scale/Scope**: Shared token catalog, platform mapping docs, remote `DesignSystem` Swift package, generic reusable SwiftUI components, app compatibility facades, `AppListCard`, `PillLabel`, selected status/card accents, and widget accent alignment; full-screen migration remains incremental

## Constitution Check

*GATE: Must pass before research and be re-checked after design.*

- **Privacy by Default**: PASS. Tokens are presentation metadata only, contain no financial values or secrets, and introduce no new data flow.
- **Financial Correctness**: PASS. Calculations, rates, snapshots, imports, exports, and reminders are out of scope and remain unchanged.
- **Compatibility**: PASS. No persisted schema, settings key, backup format, bundle ID, App Group, widget kind, notification identifier, or endpoint changes.
- **Native Product Quality**: PASS. Tokens must preserve native controls, Dynamic Type, VoiceOver, reduced motion, long labels, large values, and non-color-only state communication.
- **Architecture**: PASS. Token accessors live in presentation boundaries and do not move business logic into views or shared styling code.
- **Verification**: PASS. Plan includes token inspection, focused UI/widget checks, existing tests where relevant, `git diff --check`, and full iOS gate when app code changes.
- **Scope Discipline**: PASS. This is a new internal design-system request; rebrand, full redesign, platform app creation, and financial behavior changes are excluded.

## Project Structure

### Documentation (this feature)

```text
specs/002-design-tokens/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
├── contracts/
│   ├── token-catalog.md
│   └── platform-handoff.md
└── tasks.md                 # generated in the next Spec Kit phase, if requested
```

### Source Code (select and narrow to real affected paths)

```text
tokens/
└── wealth-map.tokens.json

MyWealth/
├── Components/
│   ├── AppListCard.swift
│   └── PillLabel.swift
├── Core/
│   └── Design/
│       ├── WealthMapDesignTokens.swift
│       └── WealthMapTokenValidation.swift
├── Features/                # incremental adoption only where touched
├── Assets.xcassets/
└── MyWealthApp.swift

MyWealthWidget/
└── MyWealthWidgetViews.swift

MyWealthTests/
└── MyWealthTests.swift      # token validation tests if code generation is not added
```

**External Package Repository**: `https://github.com/bijuvarghese/wealth-map-design-system` owns the reusable SwiftUI token and component APIs under generic names such as `DesignTokens`, `Card`, `StatusBadge`, `MetricRow`, `MetricCard`, `AmountText`, `SectionHeader`, and `EmptyState`. The app currently consumes the published `0.1.0` package tag.

**Structure Decision**: A root `tokens/` directory keeps the shared cross-platform source visible in the app repo for Android/web handoff. The app consumes the `DesignSystem` Swift package from GitHub instead of vendoring the package source. `MyWealth/Core/Design/` keeps Wealth Map compatibility facades so existing screens can migrate incrementally. Widget styling imports the package directly with no payload-model changes. Android and web receive documented mappings until their codebases are available in this workspace.

## Data and Migration Design

- **Models/schema**: N/A. No SwiftData or persisted financial model changes.
- **Settings/identifiers**: N/A. No UserDefaults keys or stable identifier changes.
- **Backup/import**: N/A. Backup and import formats remain unchanged.
- **iCloud/widget/server propagation**: Widgets may consume equivalent visual values, but widget snapshots, App Group data, iCloud, Firebase, and server flows remain unchanged.
- **Rollback/recovery**: Roll back by restoring previous token values or reverting component token consumption. No user-data migration is required.

## Verification Plan

- **Focused tests**: Validate token catalog shape, required categories, stable names, platform mappings, and secret/data hygiene (`SFR-001`-`SFR-004`, `SFR-009`-`SFR-012`, `NFR5.1`-`NFR5.7`).
- **Regression tests**: Inspect touched components and widget views for unchanged content, actions, financial values, payload models, and navigation behavior (`FR1.1`-`FR13.9`, `FR11.1`-`FR11.6`).
- **UI/accessibility checks**: iPhone 17 and a supported iPad where practical; light/dark, high contrast, Dynamic Type, VoiceOver labels, reduced motion, long currency labels, large values, empty, stale, unavailable, warning, success, and destructive states (`NFR2.1`-`NFR2.7`, `FR12.14`).
- **Backend checks**: N/A. No Firebase, Node, cache, HTTP, provider, secret, or deployed endpoint change.
- **Repository hygiene**: Run `git diff --check`; inspect token files for secrets, credentials, personal financial data, generated local artifacts, or environment-specific values.
- **Full iOS gate**:

  ```sh
  xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
    -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

## Complexity Tracking

> Fill only for constitution violations or new dependencies/abstractions.

| Violation or addition | Why needed | Simpler alternative rejected because | Approval/migration |
|-----------------------|------------|--------------------------------------|--------------------|
| Remote `DesignSystem` Swift package | Needed to separate reusable UI tokens/components from the app target and support generic names in a standalone GitHub repo. | App-only helpers or vendored package source would keep UI infrastructure coupled to the app repo. | No user-data migration; Xcode project links the remote package into the app and widget targets. |
