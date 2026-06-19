# Quickstart: Net Worth Goals

## Implementation Order

1. Add `NetWorthGoal` and register it in `CloudKitSyncManager` and test schemas.
2. Add `NetWorthGoalStore` with validation, canonical selection, upsert, delete, and duplicate reconciliation tests.
3. Add the pure progress/outlook calculator and complete its edge-case matrix before UI work.
4. Build the shared card and goal form, then compose them into both Dashboard and Net Worth surfaces.
5. Upgrade backup export/import to version 2 with preview/apply conflict resolution and Settings confirmation.
6. Run focused regressions, accessibility/layout checks, the full iOS gate, and `git diff --check`.

## Focused Verification

```sh
xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:MyWealthTests
```

Confirm manually on iPhone 17 and a supported iPad:

- Create/edit/delete and relaunch persistence.
- Same goal values on Dashboard and Net Worth.
- Negative, partial, achieved, insufficient-history, non-growing, on-track, behind, missing-rate, and stale-rate states.
- Maximum Dynamic Type, VoiceOver, reduced motion, long currency labels, and large values.
- Backup v1 import, v2 round trip, conflict keep, conflict replace, and cancellation.

## Release Gate

```sh
xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
  -destination 'platform=iOS Simulator,name=iPhone 17'

git diff --check
```

No Firebase or functions check is required because this feature adds no backend change.
