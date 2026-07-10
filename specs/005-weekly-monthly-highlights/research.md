# Research: Weekly and Monthly Highlights

## Decision 1: Reuse portfolio snapshots as the comparison source

**Decision**: Compare current converted totals with the most recent valid
`PortfolioSnapshot` at or before the period start, falling back to the earliest
valid in-period snapshot.

**Rationale**: `PortfolioSnapshot` records both assets and liabilities in the
base currency, so all requested progress measures share one timestamp and
currency. The fallback gives new users partial-period context without inventing
an earlier value.

**Alternatives considered**:

- Use only `NetWorthSnapshot`: rejected because it cannot explain separate asset
  and liability movement.
- Reconstruct historical totals from asset value snapshots: rejected because
  liability history is unavailable and would fabricate debt movement.
- Persist a new weekly/monthly summary model: rejected because existing history
  is sufficient and a new sync/backup migration adds risk.

## Decision 2: Keep current totals complete-rate gated

**Decision**: Reuse Dashboard conversion operations for current asset,
liability, and net-worth values. If any required rate is missing, the current
summary is unavailable rather than partially totaled.

**Rationale**: This preserves `FR7.13` and keeps highlight numbers identical to
Dashboard. Stale complete rates remain usable with explicit stale context.

**Alternatives considered**:

- Sum only convertible records: rejected because the resulting progress could
  look precise while omitting part of the portfolio.
- Use snapshot current values when rates are missing: rejected because a prior
  observation is not the user's current portfolio.

## Decision 3: Use signed absolute change and an absolute percentage denominator

**Decision**: Absolute change is `current - baseline`. Percentage change is
`(current - baseline) / abs(baseline)` when the baseline is finite and nonzero;
otherwise percentage is unavailable.

**Rationale**: The absolute denominator keeps improvement direction intuitive
for negative starting net worth while avoiding division by zero. The page
always labels the result as change, not return.

**Alternatives considered**:

- Divide by the signed baseline: rejected because improving from a negative
  value would display as a negative percentage.
- Hide all change when the baseline is negative: rejected because debt-heavy
  users still benefit from measurable progress.

## Decision 4: Device-calendar periods with stable component identifiers

**Decision**: Use an injected local `Calendar` for date eligibility and period
intervals. Weekly identifiers use era, year-for-week-of-year, and week number;
monthly identifiers use era, year, and month.

**Rationale**: This follows the user's current calendar/time zone while avoiding
locale-formatted strings as persistence keys. Foundation weekday 7 identifies
Saturday independently of the configured first weekday.

**Alternatives considered**:

- Store raw start-date timestamps: rejected because time-zone shifts can move a
  timestamp across a local day boundary.
- Force UTC/ISO weeks: rejected because automatic presentation is a local
  calendar experience.

## Decision 5: Dismissal completes a recap and monthly leads overlap

**Decision**: Eligibility checks do not persist completion. The app records a
period only when the user dismisses its page. When day one is Saturday, present
monthly first, then present weekly after monthly is dismissed if weekly remains
undismissed.

**Rationale**: A displayed page is not necessarily read if the process ends.
Dismissal is the explicit completion signal requested by the user. Monthly
still receives clear precedence without silently consuming the weekly recap.

**Alternatives considered**:

- Mark a recap complete when presentation begins: rejected because an app exit
  could permanently consume an unread recap.
- Suppress weekly during overlap: rejected because the user requires every
  undismissed weekly recap to remain due.

## Decision 6: Root-owned automatic routing and Dashboard-owned manual routing

**Decision**: App root evaluates automatic eligibility after onboarding and
presents a highlights sheet. Dashboard exposes weekly/monthly menu actions that
present the same reusable view without writing presentation state.

**Rationale**: Launch behavior applies equally to iPhone tabs and iPad split
navigation, while manual actions remain discoverable on the primary summary
surface. Reusing one view prevents data and visual divergence.

**Alternatives considered**:

- Put all launch logic in Dashboard: rejected because navigation timing and
  future root variants could bypass it.
- Add two new primary tabs: rejected because `FR5.2` fixes the five primary
  destinations and highlights are periodic secondary surfaces.

## Decision 7: Deterministic, bounded insights

**Decision**: Produce at most four prioritized insights from period progress,
liability direction/debt ratio, and largest allocation, using only local
calculations and neutral educational language.

**Rationale**: A small ordered set remains scannable and testable. It reuses
signals already familiar from Dashboard without adding AI, advice, or network
work.

**Alternatives considered**:

- Reuse every Dashboard insight: rejected because stale-asset and milestone
  messages can overwhelm a short period recap.
- Generate prose with AI: rejected because it adds a sensitive server-bound
  data flow and nondeterministic output.
