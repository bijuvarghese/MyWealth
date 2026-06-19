# Data Model: Net Worth Goals

## Persisted Entity

### NetWorthGoal

Represents the user's one active net worth objective. The store may briefly observe duplicates after sync or import, but only the canonical record is exposed and successful reconciliation restores the singleton invariant.

| Field | Type | Rules |
|-------|------|-------|
| `stableIdentifier` | String, optional/defaulted for CloudKit | New records use a UUID string; non-empty values participate in deterministic tie-breaking. |
| `targetAmount` | Double, optional/defaulted for CloudKit | Must be finite and greater than zero before the record is treated as valid. |
| `currencyCode` | String, optional/defaulted for CloudKit | Must map to a supported `Asset.CurrencyType` other than `.none`. |
| `targetDate` | Date, optional/defaulted for CloudKit | Create/save requires the user's current calendar day or later. Existing records remain readable after the date passes. |
| `createdAt` | Date, optional/defaulted for CloudKit | Set once on creation; fallback is `.distantPast` for malformed records. |
| `updatedAt` | Date, optional/defaulted for CloudKit | Updated on every save and used first for canonical selection. |

## Invariants and Lifecycle

1. No record is the normal legacy and deleted state.
2. Create validates all fields, inserts one record, and reconciles any stale duplicates.
3. Edit updates the canonical record in place, preserving its stable identifier and creation time.
4. Delete removes only goal records after user confirmation; portfolio records are unrelated and have no cascade.
5. Reconciliation filters invalid rows, sorts by `updatedAt` descending, then `createdAt` descending, then stable identifier, exposes the first record, and removes extras only during an explicit successful store operation.
6. An achieved or overdue goal remains active until edited or deleted.

## Derived Value Objects

### GoalProgress

| Field | Meaning |
|-------|---------|
| `currentAmount` | Complete current portfolio net worth expressed in the goal currency, or unavailable. |
| `rawFraction` | `currentAmount / targetAmount` when both are valid. |
| `visualFraction` | Raw fraction clamped to `0...1`. |
| `isAchieved` | Current amount is greater than or equal to the target. |
| `rateState` | Available, stale-but-usable, or unavailable with missing currency codes. |

### GoalOutlook

An enum-like result with mutually exclusive states:

- `achieved`: goal is already met; no projection needed.
- `projected(date, pace)`: positive eligible history yields a date; pace is on-track or behind.
- `needsHistory`: fewer than three distinct dates or less than 30 elapsed days.
- `nonGrowing`: oldest-to-newest average daily change is zero or negative.
- `conversionUnavailable`: one or more snapshot currencies cannot be normalized.
- `currentValueUnavailable`: complete current portfolio net worth is unavailable.

## Projection Rules

1. Discard malformed/non-finite snapshots and snapshots with unsupported currency codes.
2. Sort chronologically and collapse multiple observations on one user-calendar day to the latest observation that day.
3. Keep the most recent 365 eligible daily observations.
4. Normalize each retained amount to goal currency through the current cached USD-base rate set; USD is always rate 1.
5. Require at least three observations and at least 30 full elapsed days between oldest and newest.
6. Calculate average daily change as `(newestAmount - oldestAmount) / elapsedDays`.
7. If current goal progress is achieved, return `achieved`. If average daily change is not positive, return `nonGrowing`.
8. Calculate remaining amount as `max(targetAmount - currentAmount, 0)` and projected elapsed days as `remaining / averageDailyChange`; round up to the next whole day.
9. A projected date on or before the target date is on-track; a later date is behind.

## Backup Transfer Shape

`NetWorthGoalExport` contains non-optional validated values: stable identifier, target amount, currency code, target date, created timestamp, and updated timestamp. `ExportPayload.netWorthGoal` is optional so version 1 and no-goal version 2 payloads decode safely.

## Migration

- Existing SwiftData stores add the model with zero rows; no existing entity or property changes.
- Backup decoder accepts versions 1 and 2. Version 1 behaves as a missing optional goal.
- Importing a goal into a store with no canonical goal inserts it.
- Importing a materially different goal into a store with a canonical goal returns a conflict preview. Apply requires `keepExisting` or explicit `replaceExisting`.
