# Tasks: Localization MVP

**Input**: Design documents from `/specs/003-localization-mvp/`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`,
`contracts/localization-coverage.md`, and `quickstart.md`

## Phase 1: Scope and Safety

- [X] T001 [FR1.1-FR14.8,NFR1.1-NFR6.9,SFR-001-SFR-012] Confirm localization scope, traceability, and regression evidence in `specs/003-localization-mvp/spec.md` and `specs/003-localization-mvp/plan.md`
- [X] T002 [P] [NFR5.1-NFR5.7,SFR-010,SFR-011] Confirm privacy, stable identifiers, persistence compatibility, and rollback boundaries in `specs/003-localization-mvp/contracts/localization-coverage.md`
- [X] T003 [P] [NFR2.1-NFR2.7,SFR-001,SFR-008,SFR-009] Confirm locale, RTL, fallback, Dynamic Type, and manual smoke coverage in `specs/003-localization-mvp/quickstart.md`

---

## Phase 2: Foundational Work

- [X] T004 [SFR-001,SFR-004-SFR-007,SFR-009,SFR-010] Add localization lookup, formatting, enum display-label, and fallback tests in `MyWealthTests/MyWealthTests.swift`
- [X] T005 [SFR-001,SFR-004-SFR-007,SFR-009] Implement locale-aware display helpers without changing raw values in `MyWealth/Core/Localization/Localization.swift`
- [X] T006 [SFR-001,SFR-002,SFR-009,SFR-011] Add English source and Hindi, Spanish, Portuguese Brazil, French, German, Simplified Chinese, and Arabic translations in `MyWealth/Resources/Localizable.xcstrings`
- [X] T007 [SFR-001,SFR-003,SFR-009,SFR-011] Add widget English source and MVP translations in `MyWealthWidget/Resources/Localizable.xcstrings`

**Checkpoint**: Localization resources compile and helper tests pass before surface conversion.

---

## Phase 3: User Story 1 - Open Wealth Map in a Supported Language (Priority: P1)

**Goal**: Show the core app experience in the active supported language.
**Independent Test**: Launch each MVP locale and complete onboarding, navigate all tabs, and trigger representative validation and empty states without raw keys.

- [X] T008 [P] [US1] [FR1.1-FR1.15,FR2.1-FR2.8,FR5.1-FR5.8,SFR-002,SFR-005,SFR-012] Localize onboarding, currency selection, main tabs, and iPad navigation in `MyWealth/Features/Onboarding/`, `MyWealth/Features/CurrencySelection/`, `MyWealth/MyWealthApp.swift`, and `MyWealth/Features/IPad/IPadRootView.swift`
- [X] T009 [P] [US1] [FR3.1-FR6.16,SFR-002,SFR-004,SFR-006,SFR-012] Localize asset, liability, dashboard, history, allocation, and net-worth surfaces in `MyWealth/Features/AddOrEdit/`, `MyWealth/Features/Assets/`, `MyWealth/Features/Dashboard/`, and `MyWealth/Components/`
- [X] T010 [P] [US1] [FR7.15,FR12.1-FR12.16,SFR-002,SFR-004,SFR-006,SFR-007,SFR-012] Localize rates, briefing, FIRE, goal, and status surfaces in `MyWealth/Features/TransferRates/`, `MyWealth/Features/Briefing/`, `MyWealth/Features/FIRE/`, and `MyWealth/Features/Goals/`
- [X] T011 [P] [US1] [FR1.7-FR1.15,FR8.1-FR8.12,SFR-002,SFR-004,SFR-007,SFR-012] Localize settings, reminder, iCloud, backup, alert, and validation surfaces in `MyWealth/Features/Settings/`, `MyWealth/Features/Reminders/`, and `MyWealth/Components/ReminderStatusCard.swift`
- [X] T012 [US1] [SFR-001,SFR-002,SFR-008,SFR-012] Build the app and complete supported-locale source coverage and RTL layout audits across `MyWealth/` and `MyWealth/Resources/Localizable.xcstrings`

---

## Phase 4: User Story 2 - Preserve Financial Records Across Locale Changes (Priority: P1)

**Goal**: Localize display labels while preserving records and compatibility-sensitive values.
**Independent Test**: Create records in English, switch locale, and confirm labels change while stored values, calculations, backup JSON, reminder IDs, and widget snapshots do not.

- [X] T013 [US2] [FR3.10,FR4.10,FR8.12,FR9.3,FR10.10-FR10.13,SFR-004,SFR-010] Route category, reminder, goal, FIRE, and status presentation through localized display labels while preserving raw values in `MyWealth/Core/Asset.swift`, `MyWealth/Core/Notifications/ReminderModels.swift`, and related feature helpers
- [X] T014 [US2] [FR2.3,FR2.5,SFR-005,SFR-006,SFR-010] Localize currency names with safe custom-code fallback in `MyWealth/Core/AssetCurrencyMetadata.swift`
- [X] T015 [US2] [FR6.16,FR10.10-FR10.11,SFR-002,SFR-007,SFR-010] Localize share and import/export summaries without changing backup fields in `MyWealth/Core/DataPortability.swift`
- [X] T016 [US2] [FR3.1-FR4.10,FR8.1-FR8.12,FR10.1-FR11.6,SFR-010] Run focused compatibility tests for raw values, backup/import, reminders, widget payloads, and calculations in `MyWealthTests/MyWealthTests.swift`

---

## Phase 5: User Story 3 - Unsupported Locale Falls Back Gracefully (Priority: P2)

**Goal**: Keep the full app usable in English under unsupported or incomplete locales.
**Independent Test**: Launch using an unsupported locale and verify English copy appears with no raw localization keys.

- [X] T017 [US3] [SFR-001,SFR-006,SFR-009] Add unsupported-locale and missing-key fallback coverage in `MyWealthTests/MyWealthTests.swift`
- [X] T018 [US3] [SFR-002,SFR-009] Audit programmatic strings, interpolations, accessibility text, and fallback values across `MyWealth/`

---

## Phase 6: User Story 4 - Localized Widgets and Notifications (Priority: P2)

**Goal**: Match widget and reminder copy to the active locale without changing payloads or identifiers.
**Independent Test**: Render placeholder/populated widgets and schedule reminders in English, Arabic, and one additional locale.

- [X] T019 [P] [US4] [FR11.1-FR11.6,SFR-003,SFR-008,SFR-010,SFR-012] Localize widget placeholder and populated labels in `MyWealthWidget/MyWealthWidgetViews.swift`
- [X] T020 [P] [US4] [FR8.1-FR8.12,SFR-002,SFR-004,SFR-010] Localize newly scheduled reminder title/body copy while preserving identifiers in `MyWealth/Core/Notifications/NotificationScheduler.swift`
- [X] T021 [US4] [FR8.1-FR8.12,FR11.1-FR11.6,SFR-003,SFR-008,SFR-010] Run widget and notification focused tests and verify identifiers/payloads in `MyWealthTests/MyWealthTests.swift`

---

## Final Phase: Regression and Documentation

- [X] T022 [P] [SFR-001-SFR-012] Document supported locales and automatic locale behavior in `README.md`
- [X] T023 [FR1.1-FR14.8,NFR1.1-NFR6.9,SFR-001-SFR-012] Run localization-focused and existing regression tests from `specs/003-localization-mvp/quickstart.md`
- [X] T024 [SFR-011] Run `git diff --check` and audit localization resources for secrets or personal financial data
- [X] T025 [FR1.1-FR14.8,NFR1.1-NFR6.9,SFR-001-SFR-012] Run the full iPhone 17 `xcodebuild test` gate and confirm requirement evidence in `specs/003-localization-mvp/plan.md`

## Dependencies and Execution

- Phase 1 precedes all code changes.
- Phase 2 blocks all user stories.
- User Stories 1 and 2 are the MVP core and precede fallback and extension acceptance.
- User Story 3 depends on the app catalog and display helper.
- User Story 4 depends on widget resources and the shared display contract.
- Tasks marked `[P]` touch independent file groups and may proceed together after their phase prerequisites.

## Implementation Strategy

Implement the native localization foundation first, then localize the in-app experience and compatibility-sensitive display labels. Finish with fallback, widget, and notification coverage, followed by the focused and full regression gates. Do not add a language preference, change persistence, or modify server data flow.
