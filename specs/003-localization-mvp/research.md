# Research: Localization MVP

## Decision: Use automatic app/system locale for MVP

**Rationale**: The user request is to show the local language when the app is opened in a different locale. Automatic locale behavior matches the platform expectation and avoids adding a new persisted language preference, settings UI, iCloud sync question, and migration surface.

**Alternatives considered**: An in-app language picker was deferred because it expands settings scope, persistence, testing, and support burden. Runtime/server translation was rejected because it would introduce privacy, reliability, review, and data-flow risk.

## Decision: MVP language set

**Rationale**: Support English fallback plus Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, and Arabic. This gives broad practical reach and tests the hardest layout/formatting cases early, including right-to-left layout through Arabic.

**Alternatives considered**: Adding all suggested second-wave Indian and Asia-Pacific languages now was rejected because it would multiply translation review and QA before the localization pipeline is proven.

## Decision: Preserve stable raw values and localize display labels only

**Rationale**: Asset categories, liability categories, reminder enum values, backup category names, widget payload fields, notification identifiers, analytics names, and persisted currency codes are compatibility-sensitive. Localized display labels can change by locale without mutating stored data.

**Alternatives considered**: Migrating stored enum raw values to language-neutral keys was rejected for MVP because it would require backup/import migration and offers limited user value compared with safe display localization.

## Decision: Use platform locale formatting with explicit Wealth Map currency codes

**Rationale**: Amounts, dates, times, percentages, and compact notation should follow the active locale where possible, while still using the user-selected Wealth Map currency code and preserving compact total settings.

**Alternatives considered**: Keeping all numeric/date formatting English-like was rejected because it weakens localization quality. Reformatting currency based on device region instead of selected Wealth Map currency was rejected because it would alter financial meaning.

## Decision: Localize widget and reminder copy in the first release

**Rationale**: Widgets and notifications are prominent user-facing surfaces. Localizing the app but leaving out-of-app copy in English would make the MVP feel incomplete.

**Alternatives considered**: Deferring widget/reminder localization was rejected because it risks mismatched language experiences and misses important accessibility/RTL validation surfaces.

## Decision: Keep AI-generated analysis language out of MVP control

**Rationale**: Static app framing copy around AI analysis can localize, but response text returned by the server may remain in the service output language. Changing server prompts or passing locale to analysis would be a separate privacy and behavior change.

**Alternatives considered**: Adding locale to server-bound AI payloads was rejected for MVP to avoid changing Firebase request shape, analysis expectations, and telemetry/privacy review.
