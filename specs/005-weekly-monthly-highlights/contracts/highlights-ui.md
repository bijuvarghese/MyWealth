# UI Contract: Weekly and Monthly Highlights

## Entry Points

### Automatic

- Evaluate only when onboarding is complete and the app becomes active.
- First local day of month or later: present the prior completed Monthly
  Highlights if not dismissed.
- Saturday or later: present the most recent Saturday-triggered Weekly
  Highlights if not dismissed.
- First local day of month on Saturday: present Monthly Highlights first, then
  persist Weekly Highlights so it follows after monthly dismissal when weekly
  remains undismissed.
- Record completion only in the sheet dismissal callback. Presentation alone
  never consumes a recap; persist the non-financial pending period so an app
  exit before dismissal restores that exact recap on the next launch.

### Manual

- Dashboard actions are named `Weekly Highlights` and `Monthly Highlights`.
- Each action opens the current calendar period using the same page as automatic
  entry.
- Manual entry never reads or writes the last-dismissed decision.

## Page Contract

Each page must expose:

1. Period kind and locale-formatted date range.
2. A hero current-net-worth value or explicit unavailable state.
3. Current assets and liabilities.
4. Net-worth growth as signed amount and percentage when valid.
5. Asset and liability changes when a baseline exists.
6. Up to four deterministic insight rows.
7. Stale-rate or insufficient-history context when applicable.
8. A dismiss action when presented modally.

## State Matrix

| Current totals | Baseline | Result |
|----------------|----------|--------|
| Available | Available | Full progress, metrics, and insights |
| Available | Missing | Current totals plus history-needed context and current-state insights |
| Missing | Any | Unavailable financial state with rate guidance; no partial totals |
| Empty portfolio | Missing | Add-assets-or-liabilities setup state |
| Available from stale rates | Available or missing | Values shown with visible stale-rate context |

## Accessibility Contract

- Reading order follows title, period, hero, metrics, insights, context, dismiss.
- Positive/negative meaning is present in labels and text, never color alone.
- Currency values use locale-aware formatting and monospaced digits where
  consistent with Dashboard.
- Content scrolls at accessibility text sizes and does not require horizontal
  scrolling.
- SF Symbols receive adjacent text or explicit labels.
- The page introduces no required animation and therefore respects reduced
  motion by default.
- Layout direction follows the active locale.

## Privacy Contract

- No share, export, notification, widget, screenshot, indexing, logging,
  telemetry-value, AI, or server action is added.
- Manual or automatic opening does not mutate financial data or snapshot
  history.
