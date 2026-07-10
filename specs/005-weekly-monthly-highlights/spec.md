# Feature Specification: Weekly and Monthly Highlights

**Feature Branch**: `005-weekly-monthly-highlights`
**Created**: July 5, 2026
**Status**: Approved
**Input**: User description: "Create weekly highlights page, monthly highlight page, which shows progress. Open monthly on the first of every month and weekly every Saturday, including insights, wealth growth, liabilities, and related portfolio progress."
**Baseline**: `requirements.md` and `.specify/memory/requirements-context.md`

## Baseline Impact *(mandatory)*

**Change Type**: Additive feature

| Requirement ID | Disposition | Impact and regression expectation |
|----------------|-------------|-----------------------------------|
| FR1.6 | Extend | Returning users still reach the main app, with an eligible highlight presented until explicitly dismissed for its period. Regression evidence covers normal launches and incomplete onboarding. |
| FR5.3 | Extend | Dashboard remains the primary summary and gains access to current weekly and monthly highlights. Existing summary sections remain unchanged. |
| FR6.6 | Preserve | Highlight totals and changes use net worth as converted assets minus converted liabilities. Focused calculation tests cover positive, negative, and unavailable values. |
| FR6.11 | Extend | Existing portfolio insights remain intact while highlights add period-specific growth, asset, liability, and debt observations. |
| FR7.13-FR7.15 | Preserve | Missing required rates make affected highlight values unavailable with visible context; no partial total is presented. |
| FR9.4-FR9.10 | Extend | Existing scoped portfolio history supplies highlight comparisons without changing snapshot recording, ordering, or scope-reset behavior. |
| FR10.5, FR10.9 | Extend | Local settings persist which weekly and monthly periods the user explicitly dismissed and restore that state across launches. |
| FR13.4-FR13.6 | Preserve | Highlights do not add financial values or labels to telemetry and do not expand the telemetry allowlist. |
| FR14.1-FR14.8 | Extend | Highlight titles, metrics, insights, empty states, dates, percentages, and accessibility copy join the localized app surface while persisted period identifiers stay stable. |
| FR15.1-FR15.9 | Add | Promote the approved highlight pages, dismissal-only completion, calculations, privacy boundaries, manual entry, and accessible localization into the shipped product baseline. |
| NFR2.1, NFR2.4-NFR2.6 | Extend | Highlights use native presentation and remain readable for empty data, large values, long labels, and compact layouts. |
| NFR3.2-NFR3.4 | Preserve | Highlight calculations remain interactive and use bounded local history. |
| NFR4.1, NFR4.3, NFR4.6-NFR4.7 | Preserve | Missing rates, empty collections, optional snapshot fields, and duplicate protection remain safe. |
| NFR5.3, NFR5.6 | Preserve | Highlight data remains local unless an existing explicit user-controlled data action is used; no financial highlight payload is transmitted. |
| NFR6.1, NFR6.2, NFR6.5 | Extend | Period calculation and presentation eligibility stay outside views and are independently testable with isolated local settings. |

**Scope Source**: New user request extending the shipped Dashboard, insights, history, and local-settings baseline.

**Out of Scope**:

- Notifications, widgets, emails, or push delivery of highlights.
- AI-generated, provider-generated, predictive, or prescriptive financial advice.
- New snapshot schemas, account aggregation, live account feeds, or new server calls.
- Editing portfolio records from a highlight.
- Backfilling older missed recaps beyond the most recent monthly or weekly due period.
- Sharing or exporting a highlight.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See a Timely Recap at Launch (Priority: P1)

As a returning user, I see a monthly highlight on the first day of a month or a weekly highlight on Saturday so that Wealth Map proactively summarizes my recent progress without repeatedly interrupting me.

**Why this priority**: Automatic, predictable presentation is the defining behavior of the requested feature.

**Independent Test**: Launch a completed-onboarding profile on an eligible date, leave without dismissing and verify the recap returns, then dismiss it and verify it does not automatically reappear during the same calendar period.

**Acceptance Scenarios**:

1. **Given** onboarding is complete and the current local date is the first day of a month or later in that month, **When** Wealth Map becomes active and the prior completed monthly recap has not been dismissed, **Then** it presents that monthly highlight and keeps it presented until the user dismisses it.
2. **Given** onboarding is complete and the current local date is Saturday or later before the next weekly recap supersedes it, **When** Wealth Map becomes active and the most recent Saturday-triggered weekly recap has not been dismissed, **Then** it presents the weekly highlight and keeps it presented until the user dismisses it.
3. **Given** an eligible highlight was displayed but not dismissed before the app ended, **When** Wealth Map next opens on any later date, **Then** it restores that pending highlight before evaluating newer scheduled recaps.
4. **Given** the user dismissed the eligible recap for the current period, **When** the app becomes active again, **Then** it does not automatically present that recap again.
5. **Given** the first day of a month is also Saturday, **When** Wealth Map becomes active, **Then** it presents the completed-month monthly recap first and preserves the overlapping weekly recap so it follows after monthly is dismissed, even if dismissal happens on a later day.
6. **Given** onboarding is incomplete, **When** the app opens on an eligible date, **Then** onboarding remains uninterrupted and no highlight is marked as dismissed.

---

### User Story 2 - Understand Wealth Progress (Priority: P1)

As a user, I can understand how net worth, assets, and liabilities changed during the selected week or month and see concise insights based on my recorded data.

**Why this priority**: A recap is useful only when it converts history into clear, financially correct progress.

**Independent Test**: Provide known beginning and current portfolio values and verify the highlight shows the correct absolute and percentage changes, liability direction, period dates, and insight wording.

**Acceptance Scenarios**:

1. **Given** valid current totals and a usable period baseline, **When** a highlight opens, **Then** it shows current net worth, absolute and percentage net-worth growth, asset change, liability change, and the covered date range in the base currency.
2. **Given** liabilities decreased during the period, **When** the highlight opens, **Then** it describes the decrease as positive debt progress without representing it as investment growth.
3. **Given** liabilities increased during the period, **When** the highlight opens, **Then** it clearly identifies the increase without judgmental or prescriptive language.
4. **Given** sufficient portfolio data, **When** insights are shown, **Then** they include a bounded selection of useful observations such as progress direction, debt-to-asset ratio, and largest asset allocation.
5. **Given** a missing required conversion rate, **When** the highlight opens, **Then** affected totals and progress are unavailable, the reason is visible, and no partial value is fabricated.
6. **Given** no usable historical baseline exists, **When** the highlight opens, **Then** current totals remain visible when calculable and the page explains that more recorded history is needed for period comparison.

---

### User Story 3 - Review Highlights On Demand (Priority: P2)

As a user, I can open the current weekly or monthly highlight from Dashboard even when no automatic recap is due.

**Why this priority**: On-demand access makes the two pages durable product surfaces rather than one-time launch interruptions.

**Independent Test**: Open each highlight from Dashboard on an ineligible date and verify the selected period appears without changing automatic presentation state.

**Acceptance Scenarios**:

1. **Given** Dashboard is available, **When** the user chooses Weekly Highlights, **Then** the current calendar-week highlight opens.
2. **Given** Dashboard is available, **When** the user chooses Monthly Highlights, **Then** the current calendar-month highlight opens.
3. **Given** a highlight is opened manually, **When** it is dismissed, **Then** automatic presentation eligibility for that period is unchanged.
4. **Given** an iPhone or iPad with large text, VoiceOver, right-to-left layout, or reduced motion enabled, **When** a highlight is reviewed, **Then** its content remains ordered, labeled, scrollable, and understandable without relying on color or animation.

### Edge Cases

- First-of-month and Saturday overlap presents monthly first, then the weekly recap if it has not been dismissed.
- A launch after the eligible date catches up only the most recent due monthly or weekly recap and never marks a missed period as dismissed without user action.
- Calendar calculations use the device's current calendar, locale, and time zone; a time-zone change must not produce duplicate presentation for the same local period identifier.
- A zero baseline avoids division by zero; absolute change may be shown while percentage change is unavailable.
- Negative net worth and movement through zero remain valid and clearly formatted.
- Empty assets and liabilities show a useful setup state without crashing.
- Missing, stale, partial, malformed, duplicate, or out-of-scope history never creates a fabricated baseline.
- Very large values, long translated labels, Dynamic Type, VoiceOver, reduced motion, and compact iPhone width remain readable.
- Automatic presentation waits until onboarding is complete and the main app is visible.

## Requirements *(mandatory)*

### Feature Requirements

- **SFR-001**: The app must provide distinct weekly and monthly highlight presentations that identify their period and covered date range.
- **SFR-002**: On or after the first local calendar day of a month, the app must automatically present the prior completed month's monthly highlight after onboarding is complete until the user dismisses it; only dismissal suppresses later automatic presentation for that monthly period.
- **SFR-003**: On or after Saturday, the app must automatically present the most recent Saturday-triggered weekly highlight after onboarding is complete until the user dismisses it or a newer weekly period becomes due; only dismissal suppresses later automatic presentation for that weekly period.
- **SFR-004**: When the first day of a month is Saturday, monthly presentation must take precedence and the overlapping still-undismissed weekly highlight must be preserved so it follows after monthly dismissal.
- **SFR-005**: Opening either highlight manually must not alter automatic presentation eligibility.
- **SFR-006**: Pending undismissed recap state and explicit dismissal history must persist locally using stable period identifiers and must not enter portfolio backups, widgets, notifications, analytics, or server payloads.
- **SFR-007**: Each highlight must show current assets, current liabilities, and current net worth in the active base currency when complete conversion data is available.
- **SFR-008**: When a valid period baseline exists, each highlight must show absolute net-worth change, percentage net-worth change when mathematically valid, asset change, and liability change.
- **SFR-009**: Comparisons must use history from the active base currency and current portfolio-history scope; data from older scopes must not be presented as current-period growth.
- **SFR-010**: The baseline must be the most recent valid portfolio observation at or before the period start, falling back to the earliest valid observation within the period; if neither exists, comparison values must be unavailable.
- **SFR-011**: Missing required rates must make affected current and comparison values unavailable rather than partial, stale rates may be used with visible stale context, and empty or insufficient history must receive an explanatory state.
- **SFR-012**: Highlights must provide a bounded set of deterministic, non-prescriptive insights covering available progress, liability direction or debt-to-asset ratio, and asset allocation signals.
- **SFR-013**: Dashboard must provide user-initiated access to the current weekly and monthly highlights.
- **SFR-014**: Highlight pages must support iPhone and iPad, localization, locale-aware dates/numbers/percentages, right-to-left layout, Dynamic Type, VoiceOver, reduced motion, long labels, large values, negative values, and scrollable content.
- **SFR-015**: Automatic highlighting must not interrupt onboarding, modify financial records, create extra history, or block normal navigation when data is unavailable.

### Key Entities *(include when data changes)*

- **Highlight Period**: A weekly or monthly calendar interval with a stable local identifier, start date, end date, title, and automatic-presentation eligibility. Automatic monthly periods summarize the prior completed month; manual monthly periods summarize the current month.
- **Highlight Summary**: A derived, non-persisted view of current assets, liabilities, net worth, baseline values, absolute and percentage progress, rate context, and deterministic insights.
- **Highlight Presentation State**: The locally persisted pending recap payload, plus identifiers for the most recently explicitly dismissed weekly and monthly periods.

## Privacy and Data Handling *(mandatory)*

- **On-device data**: Adds only local presentation-period identifiers; all highlight calculations use existing on-device portfolio, history, settings, and cached-rate data.
- **iCloud data**: Highlight financial content is already covered by existing opt-in portfolio sync. Presentation-period identifiers remain device-local and are not added to iCloud settings sync.
- **Server-bound data**: No new payload or request. Existing cached exchange-rate behavior is reused without sending portfolio values.
- **Exports and sharing**: Highlights are not added to backups, exports, or share actions.
- **Widgets/notifications/indexing**: No highlight content or presentation state is added to widgets, notifications, Spotlight, or other public previews.
- **Secrets/logging**: No new secret is introduced. Financial values, labels, insights, and presentation identifiers must not be logged or added to telemetry.

## Compatibility and Migration *(mandatory)*

- **SwiftData/schema**: No schema change; highlights derive from existing assets, liabilities, and portfolio history.
- **UserDefaults/settings**: Adds namespaced keys for pending weekly/monthly period metadata and last explicitly dismissed weekly/monthly identifiers. Missing keys mean no recap is pending or dismissed and require no migration.
- **Backup/import format**: Unchanged; presentation identifiers are intentionally excluded.
- **Stable identifiers**: Target, scheme, module, source paths, bundle IDs, App Group, widgets, notification identifiers, Firebase project, and endpoints remain unchanged.
- **Rollback**: Older versions ignore the new settings keys. Removing the feature leaves portfolio data and history unchanged.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In date-controlled tests, 100% of eligible first-of-month, post-first catch-up, Saturday, and post-Saturday catch-up launches keep returning the correct undismissed recap, while an explicit dismissal suppresses that recap for the rest of its period.
- **SC-002**: For representative positive, negative, zero, and cross-zero fixtures, displayed absolute changes match source totals within currency display precision and valid percentages match within 0.1 percentage point.
- **SC-003**: In missing-rate, empty-data, and insufficient-history scenarios, 100% of highlights avoid partial financial totals and provide an actionable explanation.
- **SC-004**: A user can open either current highlight from Dashboard in no more than two interactions and distinguish assets, liabilities, net worth, and progress without relying on color.
- **SC-005**: All affected baseline tests for totals, insights, history scope, launch routing, settings isolation, localization, and privacy continue to pass, followed by the full iOS test gate.

## Assumptions and Dependencies

- Manual "Weekly" means the device calendar week containing the current date; automatic weekly means the calendar week containing the most recent Saturday due date.
- Manual "Monthly" means the device calendar month containing the current date; automatic monthly means the prior completed calendar month, due from the first day of the following month until dismissed.
- On an overlapping first-of-month Saturday, monthly is shown first and weekly follows only after the user dismisses monthly.
- Existing portfolio snapshots, base-currency settings, local cached rates, and Dashboard calculations remain the source of financial truth.
- Recaps are educational summaries of user-entered data, not advice, predictions, guarantees, or provider analysis.
