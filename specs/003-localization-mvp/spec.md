# Feature Specification: Localization MVP

**Feature Branch**: `003-localization-mvp`
**Created**: June 26, 2026
**Status**: Draft
**Input**: User description: "MVP multi-language support. When Wealth Map is opened in a supported locale, the app should show the local language. MVP languages: English fallback, Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, and Arabic."
**Baseline**: `requirements.md` and `.specify/memory/requirements-context.md`

## Baseline Impact *(mandatory)*

**Change Type**: Additive feature

| Requirement ID | Disposition | Impact and regression expectation |
|----------------|-------------|-----------------------------------|
| FR1.1-FR1.15 | Extend | Onboarding and Settings copy must appear in the active supported locale while onboarding completion, currency preferences, reminders, iCloud sync, backup/import actions, and app version behavior remain unchanged. Regression evidence: localized onboarding/settings smoke checks plus existing settings persistence tests. |
| FR2.1-FR2.8 | Extend | Currency picker labels and search-visible currency names may localize, but currency codes, selection rules, ordering, required base currency, and exchange-rate refresh behavior must remain unchanged. Regression evidence: currency selection tests under English and one non-English locale. |
| FR3.1-FR4.10 | Extend | Asset and liability forms, categories, validation messages, destructive actions, and empty states must localize. Stored names, amounts, currencies, category raw identifiers, and history identifiers remain unchanged. Regression evidence: add/edit/delete form checks and payload compatibility tests. |
| FR5.1-FR5.8 | Extend | Tab labels, navigation titles, and iPhone/iPad navigation copy must localize without changing tabs, destinations, or actions. Regression evidence: localized navigation pass on iPhone and iPad. |
| FR6.1-FR6.16 | Extend | Dashboard, Assets, Net Worth, insights, history, rate status, share-sheet prefill text, and large-value labels must localize while calculations, converted totals, share action gating, and display-currency order remain unchanged. Regression evidence: populated and empty dashboard checks with localized copy. |
| FR7.1-FR7.16 | Preserve | Exchange-rate fetching, cache semantics, conversion logic, server proxy behavior, and failure handling are not changed. Regression evidence: existing exchange-rate and conversion tests continue to pass. |
| FR8.1-FR8.12 | Extend | Reminder settings and notification title/body copy must localize while saved reminder preferences, scheduling identifiers, badge behavior, smart reminder logic, and backward compatibility remain unchanged. Regression evidence: notification scheduling tests confirm stable identifiers and localized body selection. |
| FR9.1-FR9.9 | Preserve | Snapshot recording, filtering, sorting, and stored snapshot values are unchanged. Display-only category labels may localize, but stored snapshot category names remain compatible. Regression evidence: existing snapshot tests continue to pass. |
| FR10.1-FR10.13 | Preserve | SwiftData, UserDefaults, iCloud settings sync, backup export/import formats, and restored data behavior remain unchanged. Regression evidence: backup/import compatibility tests confirm existing payloads remain importable. |
| FR11.1-FR11.6 | Extend | Widget visible labels must localize under supported widget locales while widget snapshot schema, App Group suite, timeline reload behavior, and selected-currency order remain unchanged. Regression evidence: placeholder and populated widget checks in English and one non-English locale. |
| FR12.1-FR12.16 | Extend | Goal form, summaries, validation messages, outlook states, and progress labels must localize while goal data, calculations, backup participation, privacy exclusions, and accessibility requirements remain unchanged. Regression evidence: localized goal create/edit/delete checks and existing goal tests. |
| FR13.1-FR13.9 | Preserve | Analytics event names, allowed parameters, Crashlytics behavior, and privacy restrictions are unchanged. Regression evidence: analytics catalog review confirms no locale, free text, user-entered financial data, or direct personal identifiers are added. |
| NFR1.1-NFR1.4 | Preserve | Platform, Swift, and Xcode baselines remain unchanged. Regression evidence: existing project build/test gate. |
| NFR2.1-NFR2.7 | Extend | Localized UI must remain native, readable, searchable, clear for destructive actions, and usable with long translated labels and large totals. Regression evidence: Dynamic Type, long-label, and destructive-action checks in supported locales. |
| NFR3.1-NFR3.4 | Preserve | Localization must not add blocking work to tab updates, calculations, persistence, or dashboard rendering. Regression evidence: code review confirms no network or heavy parsing during normal view rendering. |
| NFR4.1-NFR4.8 | Preserve | Existing stale, missing, error, optional-field, notification, snapshot, and widget reliability behavior remains unchanged. Regression evidence: existing reliability-focused tests plus localized stale/missing status checks. |
| NFR5.1-NFR5.7 | Preserve | No new server-bound financial data, secrets, provider keys, or telemetry payloads are introduced. Regression evidence: source review for translation files and logs. |
| NFR6.1-NFR6.9 | Extend | Display localization must stay in presentation/display-helper boundaries and must not move financial, networking, widget, reminder, portability, or analytics logic into views. Regression evidence: code review confirms stable boundaries. |

**Scope Source**: New request promoted into concrete MVP feature scope.

**Out of Scope**:

- In-app language picker independent from iOS app/system language.
- Machine translation at runtime or server-side translation.
- Translating user-entered asset names, liability names, notes, imported values, backup payload fields, or historical record identifiers.
- Changing base currency, display-currency defaults, exchange-rate provider symbols, or conversion behavior based on language.
- Adding new Firebase, CloudKit, App Group, backup, notification identifier, widget kind, analytics, or App Store release automation behavior.
- Completing every possible App Store metadata localization before app UI localization is accepted.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open Wealth Map in a Supported Language (Priority: P1)

A user whose device or app language is Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, or Arabic opens Wealth Map and sees primary navigation, onboarding, settings, dashboard, asset/liability, rates, briefing, and goal copy in that local language.

**Why this priority**: This is the core user promise: the app should feel local when opened in a supported locale.

**Independent Test**: Launch the app under each MVP locale and confirm primary tab labels, navigation titles, onboarding copy, settings copy, dashboard empty/populated states, and form validation copy appear localized.

**Acceptance Scenarios**:

1. **Given** the app language is set to Hindi and onboarding is incomplete, **When** the user opens Wealth Map, **Then** onboarding titles, buttons, helper copy, validation copy, and settings names appear in Hindi while persisted onboarding behavior remains unchanged.
2. **Given** the app language is set to Arabic, **When** the user opens the main app, **Then** visible copy appears in Arabic, layout respects right-to-left presentation, and financial values, currency codes, actions, and navigation remain understandable.

---

### User Story 2 - Preserve Financial Records Across Locale Changes (Priority: P1)

A user changes the device or app language after recording assets, liabilities, goals, reminders, and currency preferences. Wealth Map localizes display copy without altering stored financial data or compatibility-sensitive identifiers.

**Why this priority**: Localization must never corrupt financial data, backups, reminders, widgets, or sync state.

**Independent Test**: Create sample records in English, switch to another supported locale, relaunch, and confirm visible labels localize while stored records, settings, backup output, widget payloads, and calculations remain stable.

**Acceptance Scenarios**:

1. **Given** a user has assets in categories such as Stocks and Real Estate, **When** the app language changes to French, **Then** category display labels appear in French but stored category identifiers, exported backup values, and historical snapshot associations remain compatible.
2. **Given** a user has reminder preferences enabled, **When** the app language changes to Spanish, **Then** reminder settings and future notification copy appear in Spanish while existing scheduling identifiers and preference decoding remain backward-compatible.

---

### User Story 3 - Unsupported Locale Falls Back Gracefully (Priority: P2)

A user opens Wealth Map under a locale that is not part of the MVP language set. The app remains fully usable with English fallback strings and locale-appropriate numbers/dates where the platform provides them.

**Why this priority**: Partial localization must not create broken copy or block core portfolio workflows.

**Independent Test**: Launch under an unsupported locale and confirm no missing-key text appears in onboarding, tabs, dashboard, settings, reminders, widgets, or share text.

**Acceptance Scenarios**:

1. **Given** the app language is set to an unsupported locale, **When** the user opens Wealth Map, **Then** all app and widget copy falls back to English and all financial behavior remains available.
2. **Given** a supported locale lacks a translation for a newly added string, **When** that screen is opened during development, **Then** the app shows English fallback rather than a raw localization key.

---

### User Story 4 - Localized Widgets and Notifications (Priority: P2)

A user who relies on widgets and reminders sees concise localized copy outside the app while sensitive financial snapshot behavior remains unchanged.

**Why this priority**: Widgets and notifications are highly visible and must match the local-language promise without changing privacy boundaries.

**Independent Test**: Inspect placeholder and populated widgets plus scheduled reminder content under English, Arabic, and one additional MVP locale.

**Acceptance Scenarios**:

1. **Given** a widget snapshot exists and the widget locale is Simplified Chinese, **When** the widget renders, **Then** widget labels such as net worth, transfer rate, unavailable state, and last-updated context appear in Simplified Chinese while amounts and currency order match the snapshot.
2. **Given** reminders are enabled and the app locale is Portuguese Brazil, **When** a reminder is scheduled, **Then** notification body copy is Portuguese Brazil and the stable notification identifier remains unchanged.

### Edge Cases

- Unsupported locales must fall back to English with no visible raw localization keys.
- Arabic must support right-to-left layout without overlapping controls, clipped destructive labels, or reversed financial meaning.
- Long translations must remain readable in compact iPhone layouts, iPad split view, Dynamic Type, widgets, and forms with long currency names and large amounts.
- Currency codes must remain stable ISO-style values even when currency names are localized.
- User-entered names, notes, backup files, imported values, and historical snapshot identifiers must not be translated or rewritten.
- Plural/count text must handle zero, one, and many values correctly in every MVP locale.
- Reminder notifications scheduled before a locale change may remain delivered as previously scheduled, but new or refreshed reminders must use the current locale.
- AI analysis text returned from the server may remain in the language returned by the service; local static framing copy around the analysis must localize.

## Requirements *(mandatory)*

### Feature Requirements

- **SFR-001**: Wealth Map must support automatic app/system language localization for English fallback plus Hindi (`hi`), Spanish (`es`), Portuguese Brazil (`pt-BR`), French (`fr`), German (`de`), Simplified Chinese (`zh-Hans`), and Arabic (`ar`).
- **SFR-002**: All static user-facing app copy in onboarding, tabs, dashboard, assets, liabilities, net worth, rates, briefing, FIRE, goals, reminders, settings, backup/import, iCloud, errors, alerts, confirmations, share-prefill text, and empty/loading/stale/unavailable states must have localization entries for every MVP locale.
- **SFR-003**: All static widget labels, placeholder copy, unavailable-state copy, and last-updated context must have localization entries for every MVP locale.
- **SFR-004**: Asset category, liability category, reminder frequency, reminder type, weekday, FIRE level subtitle, goal outlook, rate status, import/export summary, and validation display labels must localize for presentation without changing persisted raw values or compatibility-sensitive identifiers.
- **SFR-005**: Currency pickers must continue to display ISO-style currency codes and should display localized currency names when available from the active locale, with existing English/custom fallback names for unsupported, crypto, metal, or provider-specific codes.
- **SFR-006**: Number, currency, percent, date, time, and compact amount presentation must use locale-appropriate formatting where the platform provides it while preserving the selected Wealth Map currency code and existing compact-format preference.
- **SFR-007**: Plural and count-based strings, including import summaries, history counts, goal timing, and reminder cadence text, must render grammatically for zero, one, and many counts in every MVP locale.
- **SFR-008**: Arabic localization must support right-to-left layout in app and widget surfaces without changing financial value meaning, currency ordering requirements, or navigation destinations.
- **SFR-009**: Unsupported locales and missing translations must fall back to English without displaying raw localization keys.
- **SFR-010**: Localization must not add or change SwiftData schemas, UserDefaults keys, iCloud key-value keys, backup/import field names, App Group payload fields, widget kinds, notification identifiers, Firebase endpoint names, analytics event names, or analytics parameter names.
- **SFR-011**: Localization resources and test fixtures must not contain secrets, provider keys, real personal financial data, user-entered account labels, or environment-specific credentials.
- **SFR-012**: Accessibility labels, button labels, alert titles, destructive action labels, and VoiceOver-relevant state text must localize consistently with visible copy in every MVP locale.

### Key Entities *(include when data changes)*

- **Localized UI Copy**: Static product text shown in app, widget, notification, share, alert, validation, and empty/error states. Owned by app resources and localized per MVP locale.
- **Localized Display Label**: Locale-specific presentation string for an existing stable enum, state, or helper output. It must be derived at display time and must not replace raw persisted values.
- **Stable Identifier**: Existing raw values, keys, payload fields, bundle identifiers, widget kinds, notification identifiers, endpoint names, and analytics names that localization must not rename.
- **Fallback Locale**: English copy used whenever the active locale or a specific translated string is unsupported or incomplete.

## Privacy and Data Handling *(mandatory)*

- **On-device data**: New localization resources are bundled with the app and widget. User financial data, settings, reminders, and records stay in their existing local stores.
- **iCloud data**: No new iCloud data. Existing settings and SwiftData sync behavior are unchanged.
- **Server-bound data**: N/A. Localization does not introduce server translation, new Firebase requests, or additional analytics payloads.
- **Exports and sharing**: Backup/export formats stay unchanged. Share-prefill text may localize only when the user explicitly opens the share action; no share data leaves the device unless the user chooses a destination.
- **Widgets/notifications/indexing**: Widget visible labels and notification copy localize. Widget payloads, notification identifiers, and privacy-sensitive snapshot behavior remain unchanged. No Spotlight or indexing changes.
- **Secrets/logging**: Localization resources must not contain provider keys, Firebase credentials, personal financial data, or user-entered labels. Logs must not add locale-specific financial payloads.

## Compatibility and Migration *(mandatory)*

- **SwiftData/schema**: N/A. No model, field, relationship, or migration changes.
- **UserDefaults/settings**: N/A. No setting key changes and no new language preference in MVP.
- **Backup/import format**: N/A. Backup JSON field names, enum raw values, category names, and restore semantics remain compatible with existing backups.
- **Stable identifiers**: Bundle IDs, App Group, widget kinds, notification identifiers, Firebase endpoints, analytics event names, and analytics parameter names remain unchanged.
- **Rollback**: Reverting localization resources or display helpers must return visible copy to English without data migration, data loss, or identifier changes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For each MVP locale, a first-time user can complete onboarding and reach the Dashboard with localized visible copy and without changing onboarding persistence behavior.
- **SC-002**: For each MVP locale, a returning user can view Dashboard, Assets, Net Worth, Rates, Briefing, Settings, widgets, and reminder settings with no visible raw localization keys.
- **SC-003**: Switching between English and at least three non-English MVP locales, including Arabic, does not change converted totals, display-currency order, stored asset/liability/goal data, backup/import compatibility, widget payload fields, or analytics payload rules.
- **SC-004**: Arabic right-to-left checks and Dynamic Type checks show no overlapping primary controls, clipped destructive action text, or unreadable widget labels on supported iPhone and iPad layouts.
- **SC-005**: Unsupported locales fall back to English across app and widget surfaces while retaining locale-appropriate platform formatting where available.
- **SC-006**: The full iOS test gate and targeted localization tests pass before delivery, or any inability to run them is documented with equivalent evidence.

## Assumptions and Dependencies

- The MVP uses the active iOS app/system language; an in-app language picker is deferred.
- English remains the source and fallback language.
- Professional or reviewed translations are required before release-quality acceptance; machine-generated text may be used only as a draft requiring review.
- Currency names can use platform locale data when available, with existing English/custom fallback names for unsupported codes, crypto, and metals.
- App Store metadata localization can follow the same language set, but app UI acceptance is not blocked on completing store metadata.
