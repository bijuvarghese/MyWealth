# Quickstart: Verify Weekly and Monthly Highlights

## Automated Focused Scenarios

1. Use an isolated UserDefaults suite and fixed Calendar/Date.
2. Verify:
   - first-of-month and later-in-month launches keep emitting the prior
     completed monthly recap until dismissal is recorded;
   - Saturday and later-in-week launches keep emitting the most recent weekly
     recap until dismissal is recorded;
   - first-of-month Saturday emits monthly first and preserves weekly after a
     later monthly dismissal;
   - dates with already dismissed due periods emit nothing;
   - incomplete onboarding writes nothing;
   - a recreated store restores prior handling.
3. Build fixed current/baseline totals and verify:
   - positive and negative net-worth movement;
   - liability decrease and increase wording;
   - zero and negative baselines;
   - latest pre-period and earliest in-period baseline selection;
   - currency, history-scope, future-row, optional-field, and duplicate filtering;
   - missing current totals and stale-rate context;
   - no more than four insights.

## Manual Product Scenarios

1. On Dashboard, open both actions from the overflow menu and confirm the
   current weekly and monthly date ranges.
2. Set the simulator date to Saturday, cold launch a completed profile, and
   confirm Weekly Highlights remains due until dismissed.
3. Set the simulator date to the first day of a month, cold launch, and confirm
   Monthly Highlights summarizes the prior completed month and remains due until
   dismissed.
4. Use a first-of-month Saturday, quit before dismissing, relaunch the next day,
   and confirm weekly follows only after monthly is dismissed.
5. End the app while a recap is visible and confirm it returns on the next
   eligible launch; then dismiss it and confirm it stays dismissed for the period.
6. Start with no assets/liabilities, incomplete rates, stale rates, insufficient
   history, negative net worth, and very large amounts.
7. Check iPhone and iPad, light/dark mode, accessibility Dynamic Type,
   VoiceOver, reduced motion, and Arabic layout.
8. Confirm Dashboard calculations and existing history do not change after
   opening or dismissing a highlight.

## Commands

```sh
xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
  -destination 'platform=iOS Simulator,name=iPhone 17'

git diff --check
```
