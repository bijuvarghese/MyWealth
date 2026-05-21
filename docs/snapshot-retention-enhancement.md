# Snapshot Retention Enhancement

## Summary

The app currently records portfolio history using persistent SwiftData models for asset value snapshots and net worth snapshots. This gives the dashboard enough data to show recent asset history and net worth trends, but the stored snapshot data can grow indefinitely because old snapshots are never pruned.

This enhancement proposes adding a retention policy so snapshot history stays useful while keeping local storage predictable.

## Current Behavior

- `AssetValueSnapshot` is created when an asset's amount changes by at least `0.01`.
- `NetWorthSnapshot` is created when the portfolio total changes by at least `0.01` in the selected base currency.
- Snapshots are recorded when the dashboard loads and when assets, exchange rates, or the base currency change.
- The dashboard currently displays only a limited number of snapshots:
  - Net worth trend uses the latest 30 matching snapshots.
  - Asset history uses the latest 5 asset value snapshots.
- Older snapshots remain stored even when they are no longer displayed.

## Risk

For normal usage, snapshot data should stay relatively small. However, users who update asset values frequently over months or years could accumulate many unused snapshot records.

This may eventually increase:

- SwiftData store size.
- Dashboard query cost.
- Memory used when snapshot queries load.
- Backup size for local app data.

## Proposed Retention Policy

Add cleanup after recording portfolio history.

Recommended defaults:

- Keep the latest 30 `NetWorthSnapshot` records per currency.
- Keep the latest 100 `AssetValueSnapshot` records per asset.
- Delete older records after a new snapshot is inserted.

This keeps the existing dashboard behavior intact while providing extra history beyond what is currently shown.

## Implementation Notes

- Add snapshot pruning inside `DashboardViewModel.recordPortfolioHistory(...)` after snapshot insertion.
- Group `NetWorthSnapshot` records by `displayCurrencyCode`.
- Group `AssetValueSnapshot` records by `displayAssetIdentifier`.
- Sort each group by `displayRecordedAt` descending.
- Keep the newest records up to the configured limit.
- Delete the remaining records from `ModelContext`.
- Keep the retention limits as private constants so they can be adjusted later.

## Acceptance Criteria

- The dashboard continues to record asset and net worth history as it does today.
- Old net worth snapshots are pruned beyond the per-currency limit.
- Old asset value snapshots are pruned beyond the per-asset limit.
- Snapshot pruning does not delete current `Asset` records.
- Snapshot pruning does not delete recent history needed by the dashboard.
- Unit tests cover retention behavior for both snapshot models.

## Future Options

- Add a user-facing setting for history length.
- Use a time-based policy, such as keeping one year of snapshots.
- Compact history into daily, weekly, or monthly samples for long-term trend charts.
