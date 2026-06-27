# Data Model: Localization MVP

No persisted financial or settings model changes are planned. The entities below describe display contracts and compatibility boundaries used by the implementation.

## Localized UI Copy

**Meaning**: Static product text shown in app, widget, notification, share, alert, validation, empty, loading, stale, unavailable, and confirmation states.

**Fields**

- `key`: Stable developer-facing identifier for a localized string.
- `englishValue`: English fallback text.
- `localizedValues`: Translations for Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, and Arabic.
- `comment`: Translator context for financial/product meaning and placeholders.
- `placeholders`: Typed values inserted at runtime, such as count, amount, currency code, date, time, or user-visible state.

**Validation Rules**

- Every key required by the MVP app or widget surfaces has an English fallback.
- Every MVP locale has reviewed values before release acceptance.
- Placeholders are preserved in every locale and retain financial meaning.
- No key or value contains secrets, credentials, real personal financial data, or user-entered financial labels.

## Localized Display Label

**Meaning**: Locale-specific presentation for an existing stable enum, helper state, or derived label.

**Examples**

- Asset category label
- Liability category label
- Reminder frequency, type, and weekday label
- FIRE level subtitle
- Goal outlook label
- Rate status label
- Import/export summary label

**Validation Rules**

- Display labels are derived at render/use time.
- Display labels never replace persisted raw values.
- Display labels never change backup/import field names or enum raw values.
- Display labels remain available to accessibility labels and VoiceOver state text.

## Stable Identifier

**Meaning**: Compatibility-sensitive value that must not be localized or renamed.

**Examples**

- SwiftData stored enum raw values
- Currency codes
- UserDefaults keys
- iCloud key-value keys
- Backup/import field names
- App Group keys and widget snapshot fields
- Widget kind identifiers
- Notification identifiers
- Firebase endpoint names
- Analytics event and parameter names

**Validation Rules**

- Stable identifiers remain byte-for-byte compatible unless a future spec includes a migration.
- Tests or review confirm localized display labels do not leak into persisted payloads.

## Fallback Locale

**Meaning**: English copy used when a locale or specific string is unsupported or incomplete.

**Validation Rules**

- Unsupported locales must show English product copy rather than raw keys.
- Missing translations during development must be discoverable by tests or review.
- Fallback behavior must keep all workflows usable.
