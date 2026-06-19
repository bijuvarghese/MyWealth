# Implementation Plan: Net Worth Goals

**Branch**: `001-net-worth-goals` | **Date**: 2026-06-19 | **Spec**: [spec.md](spec.md)
**Input**: `/specs/001-net-worth-goals/spec.md`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`

## Summary

Add one local-first net worth goal with create, edit, delete, Dashboard/Net Worth progress, and a history-based outlook. A new additive SwiftData model stores the singleton goal; a pure calculator derives progress and projection from the existing portfolio totals, cached rates, and snapshots; focused SwiftUI views present and manage it. Backup v2 adds an optional goal and requires explicit conflict resolution. Existing net worth, history, widget, reminder, server, and provider contracts remain unchanged.

## Requirements Traceability

| Requirement | Planned change | Design surface | Verification |
|-------------|----------------|----------------|--------------|
| FR2.1-FR2.5, SFR-002-SFR-003, SFR-008 | Preserve currency-catalog behavior and validate goal fields. | `Features/Goals/NetWorthGoalFormView.swift`, existing `CurrencySelectionView` patterns | Form and currency-selection tests; manual search/group/label check. |
| FR5.3, FR5.5, SFR-004 | Extend Dashboard and Net Worth with the same goal summary and management route; show current net worth in the form's selected currency. | `Features/Dashboard/DashboardView.swift`, `Features/Goals/NetWorthGoalCard.swift`, `Features/Goals/NetWorthGoalFormView.swift` | UI state matrix on iPhone and iPad plus selected-currency calculation test. |
| FR6.6-FR6.7, FR6.10, SFR-004-SFR-009, SFR-017 | Reuse assets-minus-liabilities totals, require complete rate coverage, and recompute on query/rate changes. | `Core/AssetOperations.swift`, `Features/Goals/NetWorthGoalCalculator.swift`, `DashboardView.swift` | Calculator tests for exact, cross-currency, negative, achieved, and missing-rate cases; existing total tests. |
| FR6.13, FR9.4-FR9.8, SFR-010-SFR-012 | Read existing snapshots for a bounded, indicative projection without changing recording or charts. | `NetWorthGoalCalculator.swift`, `DashboardViewModel.swift` history inputs | Projection tests for 3/30 threshold, ordering, duplicates, flat/negative growth, conversion, and target comparison; history regressions. |
| FR7.8-FR7.15, SFR-007, SFR-009 | Use the existing local rate cache and status semantics; introduce no network flow. | `DashboardViewModel.swift`, `NetWorthGoalCalculator.swift`, `NetWorthGoalCard.swift` | Fresh/stale/missing/failed-rate state tests; existing exchange-rate tests. |
| FR10.1-FR10.4, FR10.9, FR10.12, SFR-001, SFR-013-SFR-014 | Add an optional singleton goal to the current local/CloudKit-capable schema and reconcile duplicates deterministically. | `Core/NetWorthGoal.swift`, `Core/NetWorthGoalStore.swift`, `Core/CloudKitSyncManager.swift` | In-memory persistence, upsert, delete, duplicate reconciliation, and container-schema tests. |
| FR10.10-FR10.11, NFR6.8, SFR-015 | Add optional goal data to backup v2, preserve v1 imports, and preview goal conflicts before import. | `Core/DataPortability.swift`, `Features/Settings/SettingsView.swift` | v1/v2 decode, round-trip, no-goal, keep-existing, replace-confirmed, and cancellation tests. |
| FR11.1-FR11.6, SFR-017 | Preserve all widget contracts; goal data is not propagated. | `Core/Widget/`, `MyWealthWidget/` unchanged | Existing widget writer/reader tests and full gate. |
| NFR2.1-NFR2.7, SFR-003, SFR-013, SFR-016 | Use native form/navigation patterns, clear validation/deletion, compact values, and accessible non-color states. | `Features/Goals/`, Dashboard and Net Worth composition | VoiceOver, Dynamic Type, reduced motion, long-label, large-value, and destructive confirmation checks. |
| NFR3.2-NFR3.4, SFR-004, SFR-010-SFR-011 | Keep calculations synchronous and pure over one goal and a bounded snapshot input. | `NetWorthGoalCalculator.swift` | Normal-volume calculation under SC-004 and unit tests with oversized history input. |
| NFR4.1, NFR4.3, NFR4.6, SFR-005-SFR-012 | Model unavailable/insufficient/non-growing/achieved results explicitly and avoid force unwraps or fabricated values. | `NetWorthGoal.swift`, `NetWorthGoalCalculator.swift`, `NetWorthGoalCard.swift` | Edge-state table tests and empty portfolio UI check. |
| NFR5.3-NFR5.4, SFR-014 | Keep goal data local unless existing iCloud or export actions are enabled. | SwiftData container and `DataPortability.swift`; no Firebase changes | Data-flow inspection; privacy copy remains accurate. |
| NFR6.1-NFR6.2, SFR-004-SFR-012, SFR-017 | Keep calculation and persistence policy outside SwiftUI views with injectable pure inputs. | `NetWorthGoalCalculator.swift`, `NetWorthGoalStore.swift` | Direct Swift Testing coverage without rendering UI. |

## Technical Context

**Language/Version**: Swift 6.0

**Primary Dependencies**: SwiftUI, SwiftData, Observation, Charts, CloudKit, structured concurrency; no new package or Firebase dependency

**Storage**: Existing SwiftData store, optionally CloudKit-backed by the user's current setting; JSON `.backup` payload v2

**Testing**: Swift Testing in `MyWealthTests/`; focused goal calculator, persistence, and portability tests plus the full app gate

**Target Platform**: iOS/iPadOS 26.1+, Xcode 26.1+

**Project Type**: Existing iOS app with unchanged WidgetKit extension and Firebase backend

**Performance Goals**: Goal progress/outlook visible within one second for normal portfolios; calculator receives at most the most recent 365 eligible snapshots after filtering/sorting; no added network request

**Constraints**: Local-first privacy; complete-rate validation for goal values; deterministic date math; safe stale/missing data; Swift 6 concurrency; additive schema; stable target, bundle, App Group, widget, notification, and endpoint identifiers

**Scale/Scope**: One active goal, two app surfaces, one management form, one pure calculator, one small persistence store, existing local histories (bounded to 365 eligible rows), backup v1/v2 compatibility; no widget, notification, server, or provider changes

## Constitution Check

*GATE: PASS before research; PASS again after the data model and contracts below were completed.*

- **Privacy by Default**: PASS. Goal fields stay in the existing local store, enter personal iCloud only with opt-in sync, and enter a backup only on explicit export. No server-bound flow, new secret, public preview, or sensitive logging is added.
- **Financial Correctness**: PASS. Amount/date validation, complete rate coverage, progress bounds, snapshot eligibility, growth calculation, achieved precedence, and all unavailable states are explicit and testable. The estimate is labeled indicative.
- **Compatibility**: PASS. The schema change is additive and CloudKit-compatible, v1 backups remain decodable, v2 goal conflicts require a decision, and stable identifiers remain untouched.
- **Native Product Quality**: PASS. The plan uses standard navigation, form, card, confirmation, ProgressView, accessibility labels, Dynamic Type, reduced-motion-safe presentation, and matching iPhone/iPad routes.
- **Architecture**: PASS. Pure calculation and persistence reconciliation live outside views; existing conversion, query, model-container, and portability boundaries are reused. No external dependency is added.
- **Verification**: PASS. Focused cases map to every new rule, high-risk preserved totals/history/backup/widget behavior is included, and the required full iOS gate remains the release gate.
- **Scope Discipline**: PASS. Only the Net Worth Goals candidate is promoted. Multiple goals, reminders, widgets, sharing, advice, contributions, account links, and historical FX are excluded.

## Project Structure

### Documentation (this feature)

```text
specs/001-net-worth-goals/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── contracts/
    ├── backup-v2.md
    └── goal-ui.md
```

### Source Code

```text
MyWealth/
├── Core/
│   ├── NetWorthGoal.swift                 # additive SwiftData model and derived enums
│   ├── NetWorthGoalStore.swift            # singleton reconciliation/upsert/delete policy
│   ├── CloudKitSyncManager.swift           # register model in the existing schema
│   └── DataPortability.swift               # optional backup v2 goal and conflict preview/apply
├── Features/
│   ├── Dashboard/DashboardView.swift       # query and compose goal card on both surfaces
│   ├── Settings/SettingsView.swift         # imported-goal conflict confirmation
│   └── Goals/
│       ├── NetWorthGoalCalculator.swift    # pure progress/outlook rules
│       ├── NetWorthGoalCard.swift          # shared Dashboard/Net Worth states
│       └── NetWorthGoalFormView.swift      # create/edit/delete flow
└── MyWealthApp.swift                       # unchanged container injection

MyWealthTests/
└── MyWealthTests.swift                     # focused model/calculator/import regression tests
```

**Structure Decision**: Goal files form a focused feature folder while the model, singleton policy, container registration, and portability remain in Core beside equivalent app-wide boundaries. Dashboard owns both current summary surfaces, so it composes the shared card without adding a tab. The synchronized Xcode groups discover new files without project-file edits.

## Data and Migration Design

- **Models/schema**: Add `NetWorthGoal` with CloudKit-safe optional/defaulted fields: stable identifier, target amount, currency code, target date, created timestamp, and updated timestamp. Existing stores migrate additively to zero goals. `NetWorthGoalStore` selects the newest valid updated record as canonical, uses timestamp then stable identifier as a deterministic tie-break, and removes duplicate singleton records on a successful write/reconciliation.
- **Settings/identifiers**: No UserDefaults keys. The target, scheme, bundle IDs, App Group, widget kinds, notifications, endpoints, and existing persisted identifiers do not change.
- **Backup/import**: Raise `ExportPayload.currentVersion` to 2 and decode `netWorthGoal` with `decodeIfPresent` so v1 remains valid. Export only the canonical goal. Import is split into preview and apply: non-conflicting data remains additive; an imported goal is inserted when none exists; a different existing goal yields `keepExisting` or user-confirmed `replaceExisting`, never silent replacement.
- **iCloud/widget/server propagation**: Register `NetWorthGoal` in the same optionally CloudKit-backed schema. Duplicate reconciliation protects the one-goal invariant after sync merges. Widgets, App Group payloads, Firebase functions, ChatGPT analysis exports, notifications, and Spotlight receive no goal fields.
- **Rollback/recovery**: No goal is a fully valid state. Validation ignores malformed legacy/sync rows and preserves portfolio operation. A cancelled/failed conflicting import leaves the existing goal unchanged. Existing portfolio records are never cascaded from goal deletion. Full downgrade across a changed SwiftData schema requires pre-release migration testing; the feature itself writes no destructive migration.

## Verification Plan

- **Focused tests**: Validate model defaults and canonical selection; create/edit/delete/duplicate reconciliation; amount/date/currency validation; progress at negative, zero, partial, exact, and above-target values; cross-currency full coverage and missing-rate refusal; stale-rate labeling input; 3-snapshot/30-day threshold; unsorted and duplicate-day inputs; flat/negative growth; projected on-track/behind; achieved precedence; 365-row bound; backup v2 round trip; v1 decode; missing goal; conflict keep/replace/cancel.
- **Regression tests**: Re-run existing conversion and liabilities tests (FR6.6-FR6.7), rate-cache/error tests (FR7.8-FR7.15), snapshot recording/filter/order tests (FR9.4-FR9.8), data portability tests (FR10.9-FR10.11), CloudKit container construction (FR10.12), and widget data-store tests (FR11.1-FR11.6).
- **UI/accessibility checks**: iPhone 17 and a supported iPad in portrait/landscape; no-goal, unavailable total, missing rate, stale rate, insufficient history, non-growing, on-track, behind, and achieved states; very large amounts, long currency labels, maximum Dynamic Type, VoiceOver reading order/actions, reduced motion, form validation, deletion confirmation, and import replacement confirmation.
- **Backend checks**: N/A. No Firebase, Node, cache, HTTP, provider, secret, or deployed endpoint change.
- **Repository hygiene**: Run `git diff --check` after implementation and ensure no personal financial fixtures, backups, credentials, or generated secrets are tracked.
- **Full iOS gate**:

  ```sh
  xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
    -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

## Complexity Tracking

No constitution violations, new third-party dependencies, or exception approvals are required.
