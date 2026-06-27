# Contract: Localization Coverage

This contract defines the minimum coverage for the Localization MVP. It is intentionally a user-facing display contract, not a persistence or server API contract.

## Supported Locales

| Locale | Requirement |
|--------|-------------|
| `en` | Source and fallback language |
| `hi` | MVP supported locale |
| `es` | MVP supported locale |
| `pt-BR` | MVP supported locale |
| `fr` | MVP supported locale |
| `de` | MVP supported locale |
| `zh-Hans` | MVP supported locale |
| `ar` | MVP supported locale and RTL validation locale |

## Required App Coverage

Every supported locale must include user-facing copy for:

- Onboarding
- Main tabs and iPad navigation
- Dashboard
- Assets and liabilities
- Add/edit forms
- Currency selection
- Net Worth and goals
- Rates and metal prices
- Briefing and FIRE
- Settings
- Reminders
- iCloud sync copy
- Backup/import/export copy
- Alerts, confirmations, destructive actions, validation, empty/loading/error/stale/unavailable states
- Share-prefill text initiated by the user
- Accessibility labels and state text when they differ from visible text

## Required Widget Coverage

Every supported locale must include user-facing copy for:

- Home and lock screen placeholder states
- Net worth labels
- Secondary currency labels
- Transfer-rate labels
- Unavailable state
- Last-updated context

Widget snapshot payloads are outside this display contract and must remain unchanged.

## Required Notification Coverage

Every supported locale must include copy for:

- Wealth Map reminder title/body text
- Reminder type labels
- Reminder frequency and cadence labels
- Weekday/month-day guidance

Notification identifiers and saved reminder preferences are outside this display contract and must remain unchanged.

## Compatibility Guarantees

- Currency codes are never localized.
- Stored enum raw values are never localized.
- Backup/import field names and category values are never localized in MVP.
- User-entered names, labels, and notes are never translated or rewritten.
- Analytics event names and parameters are never localized.
- Firebase request/response fields are never localized.

## Acceptance Evidence

- Locale coverage audit confirms no required surface is missing English fallback.
- Representative screens are checked in every MVP locale.
- Arabic is checked for RTL layout in app and widget surfaces.
- Tests confirm stable identifiers remain unchanged after display-label localization.
