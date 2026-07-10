# Data Model: Weekly and Monthly Highlights

## HighlightPeriod

A value type describing the selected reporting window.

| Field | Type | Rules |
|-------|------|-------|
| kind | weekly or monthly | Required and stable |
| interval | start/end dates | Derived from injected local calendar |
| identifier | string | Weekly uses calendar era/year-for-week/week; monthly uses era/year/month |
| referenceDate | date | Date used to derive the interval |

State transitions:

- Any date can derive one manual current weekly and one manual current monthly period.
- Automatic weekly derives the calendar week containing the most recent Saturday
  due date; automatic monthly derives the prior completed calendar month.
- A period is immutable after derivation.
- Manual opening does not transition presentation state.

## HighlightPresentationState

Device-local launch experience state persisted outside portfolio data.

| Field | Type | Rules |
|-------|------|-------|
| pendingWeeklyPeriod | optional period payload | Written when a scheduled weekly page is offered; cleared only by dismissal |
| pendingMonthlyPeriod | optional period payload | Written when a scheduled monthly page is offered; cleared only by dismissal |
| lastDismissedWeeklyPeriod | optional string | Written only after the user dismisses an automatically presented weekly page |
| lastDismissedMonthlyPeriod | optional string | Written only after the user dismisses an automatically presented monthly page |

State transitions:

- Missing or different identifier → eligible if the most recent monthly or
  weekly due period has not been dismissed.
- Matching dismissed identifier → completed and not eligible.
- Presentation writes pending non-financial period metadata but does not write dismissal state.
- A pending recap is restored on later launches regardless of date and remains pending until dismissed.
- First-of-month Saturday → emit completed-month monthly first and persist the
  overlapping weekly pending period; after monthly dismissal, emit weekly if its
  dismissal identifier is still missing.
- Incomplete onboarding → write nothing and emit nothing.

## WealthHighlightSummary

A non-persisted derived value rendered by either highlight page.

| Field | Type | Rules |
|-------|------|-------|
| period | HighlightPeriod | Required |
| currencyCode | string | Active base currency raw value |
| currentAssetTotal | optional decimal value | Available only with complete conversion |
| currentLiabilityTotal | optional decimal value | Available only with complete conversion |
| currentNetWorth | optional decimal value | Assets minus liabilities |
| baseline | optional HighlightBaseline | Selected from current scope/currency |
| assetChange | optional decimal value | Current assets minus baseline assets |
| liabilityChange | optional decimal value | Current liabilities minus baseline liabilities |
| netWorthChange | optional decimal value | Current net worth minus baseline net worth |
| netWorthChangeFraction | optional decimal fraction | Net-worth change divided by absolute nonzero baseline |
| insights | ordered list | Maximum four deterministic rows |
| ratesAreStale | boolean | Displays context; does not invalidate complete values |
| availability | available/current-only/unavailable | Drives empty and error-safe copy |

## HighlightBaseline

An immutable projection of one existing valid `PortfolioSnapshot`.

| Field | Type | Rules |
|-------|------|-------|
| recordedAt | date | Within active history scope |
| assetTotal | decimal value | Finite |
| liabilityTotal | decimal value | Finite |
| netWorth | decimal value | Asset total minus liability total |
| currencyCode | string | Must match active base currency |

Selection:

1. Filter to active currency, active scope, valid finite values, and no future
   observations beyond the reference date.
2. Prefer the newest observation at or before period start.
3. Otherwise choose the earliest observation within the period.
4. If no observation matches, comparison is unavailable.

## HighlightInsight

| Field | Type | Rules |
|-------|------|-------|
| kind | progress/liability/debt-ratio/allocation/context | Stable enum |
| systemImage | string | Existing SF Symbol only |
| message | localized string | Deterministic and non-prescriptive |
| sentiment | positive/neutral/warning | Supplemental; meaning must remain in text |

Insights are computed in priority order and truncated to four rows.

## Relationships and Ownership

- `WealthHighlightSummary` reads existing `Asset`, `Liability`, and
  `PortfolioSnapshot` values but owns none of them.
- `HighlightPresentationState` is device-local and is not part of SwiftData,
  iCloud KVS, backups, widgets, notifications, telemetry, or server payloads.
- No new financial entity or migration is introduced.
