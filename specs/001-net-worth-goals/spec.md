# Feature Specification: Net Worth Goals

**Feature Branch**: `001-net-worth-goals`
**Created**: 2026-06-19
**Status**: Draft
**Input**: User description: "Net Worth Goals"
**Baseline**: `requirements.md` and `.specify/memory/requirements-context.md`

## Baseline Impact *(mandatory)*

**Change Type**: Additive feature

| Requirement ID | Disposition | Impact and regression expectation |
|----------------|-------------|-----------------------------------|
| FR2.1-FR2.5 | Preserve | Goal currency selection reuses the supported catalog behavior; regression evidence covers catalog exclusions, prioritization, search, grouping, and labels. |
| FR5.3 | Extend | Dashboard summary adds active-goal progress without removing existing summaries. |
| FR5.5 | Extend | Net Worth adds goal details and management without removing totals, rate status, trend, or history. |
| FR6.6 | Preserve | Goal calculations consume, but do not redefine, assets-minus-liabilities net worth. |
| FR6.7 | Extend | Current net worth may be converted to the goal currency only when required rates are available. |
| FR6.10 | Extend | Goal progress refreshes when portfolio records or rates change. |
| FR6.13 | Extend | Existing net worth history may support a clearly labeled goal projection; chart behavior remains unchanged. |
| FR7.8-FR7.15 | Preserve | Goal conversion uses the existing cache, refresh policy, missing-rate behavior, and status messaging; no new provider flow is introduced. |
| FR9.4-FR9.8 | Preserve | Projection reads existing net worth snapshots without changing recording, currency filtering, ordering, or display limits. |
| FR10.1-FR10.4 | Extend | The local financial data store also persists the active goal while existing records remain unchanged. |
| FR10.9 | Extend | The active goal restores across launches with existing financial data. |
| FR10.10-FR10.11 | Extend | New backups include the active goal; older backups remain importable and backups without a goal leave the current goal unchanged. |
| FR10.12 | Extend | The active goal follows the existing user-controlled iCloud data-store choice. |
| FR11.1-FR11.6 | Preserve | Widget payloads and presentation remain unchanged. |
| NFR2.1-NFR2.7 | Preserve | Goal management uses familiar navigation, blocks invalid saves, handles empty/error states, formats large amounts, supports long labels, and clearly labels deletion. |
| NFR3.2-NFR3.4 | Extend | Goal progress and projection remain responsive and operate on a bounded set of relevant history. |
| NFR4.1, NFR4.3, NFR4.6 | Extend | Missing rates, optional persisted fields, empty portfolios, negative net worth, and insufficient history produce safe states rather than fabricated estimates. |
| NFR5.3-NFR5.4 | Extend | Goal data follows the same local-by-default and user-enabled iCloud disclosures as other financial data. |
| NFR6.1-NFR6.2, NFR6.8 | Extend | Goal business rules and portability remain independently testable and outside presentation code. |

**Scope Source**: Promotes the `Net Worth Goals` candidate under `Planned Enhancements` in `requirements.md` into a concrete feature.

**Out of Scope**:

- Multiple simultaneous or archived goals.
- Goal contributions, linked accounts, automatic transfers, or investment recommendations.
- Goal-specific reminders, notifications, widgets, sharing, or server-side analysis.
- Historical exchange-rate reconstruction or guarantees that a projection will be achieved.
- Changes to portfolio snapshot recording, trend range selection, or existing net worth calculations.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a Goal and See Progress (Priority: P1)

A user creates one net worth goal with a target amount, currency, and date, then sees current progress on Dashboard and Net Worth.

**Why this priority**: A visible target turns the existing net worth total into a measurable personal objective.

**Independent Test**: Create a valid goal for a portfolio with a convertible current net worth and verify that both primary surfaces show the same target, current value, percentage, and target date.

**Acceptance Scenarios**:

1. **Given** no active goal and a current net worth of USD 50,000, **When** the user opens the goal form and selects USD, **Then** the form shows USD 50,000 as current net worth; after saving a USD 100,000 goal for a future date, Dashboard and Net Worth show 50% progress and the saved date.
2. **Given** no active goal, **When** the user enters a zero, negative, non-finite, or missing amount or a past date, **Then** save remains unavailable and the form identifies the invalid field.
3. **Given** a goal currency different from the portfolio base currency, **When** all required rates are available, **Then** current net worth and progress are shown in the goal currency.
4. **Given** a goal that is already met, **When** progress is displayed, **Then** the goal is labeled achieved, the visual indicator is complete, and the numeric result may communicate progress above 100%.

---

### User Story 2 - Understand Goal Outlook (Priority: P2)

A user with sufficient net worth history sees an indicative projected achievement date and whether the current pace is on track for the target date.

**Why this priority**: Progress becomes more useful when the user can compare historical direction with the desired deadline.

**Independent Test**: Supply at least three eligible snapshots spanning 30 days with positive growth and verify the displayed projection and on-track status against the defined calculation rules.

**Acceptance Scenarios**:

1. **Given** at least three eligible snapshots on distinct dates spanning at least 30 days and positive average daily net worth growth, **When** the goal is not yet achieved, **Then** Wealth Map shows an indicative projected date and labels the pace on track when that date is no later than the target date.
2. **Given** fewer than three eligible snapshots or less than 30 days of history, **When** the goal is viewed, **Then** the app says that more history is needed and does not show a projected date.
3. **Given** flat or negative average growth, **When** the goal is viewed, **Then** the app explains that the current trend cannot produce an achievement estimate and does not show a projected date.
4. **Given** required conversion rates are unavailable, **When** history cannot be expressed in the goal currency, **Then** the projection is unavailable and the app does not substitute zero or a fabricated value.

---

### User Story 3 - Maintain or Remove the Goal (Priority: P3)

A user edits the active goal as priorities change or removes it when it is no longer relevant.

**Why this priority**: Long-lived financial targets must remain correct and under the user's control.

**Independent Test**: Edit every goal field, relaunch to verify persistence, then confirm deletion and verify the no-goal state without affecting portfolio data.

**Acceptance Scenarios**:

1. **Given** an active goal, **When** the user changes its amount, currency, or date and saves, **Then** all goal surfaces update to the new values.
2. **Given** an active goal, **When** the user chooses delete, **Then** Wealth Map asks for confirmation before removing it.
3. **Given** a deleted goal, **When** the user returns to Dashboard or Net Worth, **Then** portfolio totals and history remain intact and a non-intrusive create-goal action is available.
4. **Given** iCloud sync is enabled, **When** the goal changes on one device and sync completes, **Then** the same single active goal is available on the user's other eligible devices.

---

### User Story 4 - Preserve the Goal in Backups (Priority: P4)

A user can preserve the active goal with a full Wealth Map backup and restore it later.

**Why this priority**: Goal data is part of the user's financial record and should follow existing portability expectations.

**Independent Test**: Export a backup containing a goal, import it into an empty data store, and verify the goal and existing portfolio records are restored; also import a legacy backup successfully.

**Acceptance Scenarios**:

1. **Given** an active goal, **When** the user exports and later imports a current-format backup into a store without a goal, **Then** the goal is restored with its original values.
2. **Given** an older valid backup with no goal field, **When** it is imported, **Then** existing supported data imports successfully and no placeholder goal is created.
3. **Given** an active goal already exists, **When** a backup containing another goal is imported, **Then** the user must explicitly confirm replacement before the imported goal becomes active.

### Edge Cases

- A negative current net worth shows 0% visual progress while retaining the actual signed current value; a zero target is never valid.
- Progress calculations support very large finite amounts and the currency's standard display precision without changing the stored target amount.
- A target date may be today or later when editing on that calendar day; dates before the user's current calendar day are invalid.
- Projection uses eligible snapshots converted consistently to the goal currency. It requires at least three distinct snapshot dates spanning at least 30 days and positive average daily change from the oldest to newest eligible value.
- When the goal has already been achieved, achievement status takes precedence over deadline or projection status.
- Missing or stale rates are surfaced using existing rate semantics; stale cached rates may calculate progress but remain visibly labeled stale.
- No portfolio data produces an unavailable current value and 0% progress, without blocking goal editing or core asset and liability workflows.
- On iCloud account changes or unavailability, local goal access follows existing store behavior and the app must not create duplicate active goals.
- Dashboard cards remain readable on iPhone and iPad with large amounts, long currency names, Dynamic Type, VoiceOver, and reduced motion. Progress is not communicated by color or animation alone.
- Cold launch, widgets, notifications, background behavior, and public indexing do not expose goal data.

## Requirements *(mandatory)*

### Feature Requirements

- **SFR-001**: Users must be able to create, edit, and remove at most one active net worth goal.
- **SFR-002**: A goal must contain a finite target amount greater than zero, a supported non-empty currency, and a target date that is not before the user's current calendar day.
- **SFR-003**: Invalid goal fields must prevent saving and must provide field-specific guidance.
- **SFR-004**: The goal form must show current net worth in its selected currency, and Dashboard and Net Worth must show a consistent active-goal summary including target amount, target date, current net worth, and progress percentage when conversion is available.
- **SFR-005**: Goal progress must be current net worth divided by target amount; the visual indicator must be bounded from 0% to 100%, while text may show achievement beyond 100%.
- **SFR-006**: A goal must be marked achieved whenever current net worth in the goal currency is greater than or equal to its target amount.
- **SFR-007**: Goal progress must refresh after the active goal, assets, liabilities, relevant exchange rates, or base/display currency settings change.
- **SFR-008**: Goal currency selection must use the supported currency catalog and its established search, grouping, and labeling behavior.
- **SFR-009**: When a required conversion rate is unavailable, Wealth Map must show goal progress as unavailable and must not treat a missing rate or converted amount as zero.
- **SFR-010**: Wealth Map must offer a projection only when at least three eligible net worth snapshots on distinct dates span at least 30 days and show positive average daily change from the oldest to newest eligible value.
- **SFR-011**: The indicative projected date must be based on the remaining target amount and the observed average daily net worth change; it must be labeled on track when no later than the target date and behind pace when later.
- **SFR-012**: Insufficient history, flat or negative change, unavailable conversion, and already-achieved goals must each produce a distinct, non-misleading outlook state.
- **SFR-013**: Removing a goal must require confirmation and must not delete or alter assets, liabilities, settings, or history.
- **SFR-014**: Goal data must persist across launches, remain local by default, and sync only through the existing user-enabled iCloud data store.
- **SFR-015**: Current-format backups must include the active goal, legacy backups must remain importable, and importing a conflicting goal must require explicit replacement confirmation.
- **SFR-016**: Goal views must support iPhone and iPad layouts, Dynamic Type, VoiceOver, reduced motion, long localized labels, and large formatted values without relying on color or animation alone.
- **SFR-017**: Goal calculations must not change existing net worth, conversion, snapshot, dashboard, history, widget, or reminder results.

### Key Entities *(include when data changes)*

- **Net Worth Goal**: The user's single active objective, with a stable identity, positive target amount, supported target currency, target date, creation time, and last-updated time. It is owned by the user and exists until explicitly removed or replaced during an approved import.
- **Goal Progress**: A derived, non-persisted view of current net worth in the goal currency, raw progress percentage, bounded visual progress, and achieved state.
- **Goal Outlook**: A derived, non-persisted result containing projection availability, indicative projected date when available, pace status, and a reason when no estimate is available.

## Privacy and Data Handling *(mandatory)*

- **On-device data**: The goal's amount, currency, date, and timestamps are stored with the user's local financial data. Derived progress and outlook are calculated locally.
- **iCloud data**: The goal syncs only when the user enables the existing personal iCloud data-store option; no new cloud provider is added.
- **Server-bound data**: N/A. Goal values and derived results are not sent to Firebase or analysis services by this feature.
- **Exports and sharing**: Full backups include goal data at the user's explicit request. No new shareable report or public sharing surface is added.
- **Widgets/notifications/indexing**: N/A. Goal data is excluded from widgets, notifications, Spotlight, and other public previews in this feature.
- **Secrets/logging**: No new secrets are required. Goal values and projections must not be added to diagnostic logs.

## Compatibility and Migration *(mandatory)*

- **SwiftData/schema**: Additive storage for zero or one goal must migrate existing stores without modifying existing model records. An empty goal collection is the valid legacy state.
- **UserDefaults/settings**: N/A. No new preference key is required and existing keys remain unchanged.
- **Backup/import format**: The backup format gains an optional goal payload under a new supported version. Older backups remain decodable; backups without a goal do not create one or silently replace an existing goal.
- **Stable identifiers**: The MyWealth target, scheme, module and source paths, bundle IDs, App Group, widget kinds, notification identifiers, Firebase project, endpoint names, and persisted identifiers remain unchanged.
- **Rollback**: Existing app behavior remains valid when no goal exists. Removing the feature UI leaves existing portfolio data untouched; older app versions may ignore the additive goal record, subject to the existing store's platform migration behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a valid goal and see matching progress on Dashboard and Net Worth in under 60 seconds.
- **SC-002**: Across acceptance fixtures for achieved, negative-net-worth, insufficient-history, flat-growth, negative-growth, missing-rate, stale-rate, and very-large-value cases, 100% show the defined state without a fabricated projection or crash.
- **SC-003**: Existing automated evidence for FR2.1-FR2.5, FR6.6-FR6.7, FR7.8-FR7.15, FR9.4-FR9.8, FR10.9-FR10.12, and FR11.1-FR11.6 continues to pass unchanged.
- **SC-004**: Goal progress and outlook become visible within one second after opening a populated Dashboard or Net Worth view under normal local portfolio and history volumes.
- **SC-005**: Current and legacy backup fixtures import successfully, and a conflicting imported goal is never activated without explicit user confirmation.
- **SC-006**: Every goal field, progress state, pace state, management action, and validation error is operable and understandable with VoiceOver at supported Dynamic Type sizes on iPhone and iPad.

## Assumptions and Dependencies

- Only one active goal is needed for this release; completing a goal does not archive or automatically delete it.
- The goal currency may differ from the base currency and uses the existing supported currency catalog and cached conversion data.
- Projection is educational and indicative. It assumes the observed net worth pace continues and does not model investment returns, contributions, inflation, taxes, or historical exchange rates.
- Eligible history consists of valid persisted net worth observations that can be expressed consistently in the goal currency; current cached rates may be used for cross-currency normalization and the estimate must be labeled accordingly.
- Existing portfolio calculation, history, iCloud, and backup capabilities remain available and are dependencies of this feature.
