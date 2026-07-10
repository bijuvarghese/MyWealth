# Tasks: Weekly and Monthly Highlights

**Input**: Design documents from `/specs/005-weekly-monthly-highlights/`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`,
`contracts/highlights-ui.md`, and `quickstart.md`

**Tests**: Automated tests are required for period eligibility, UserDefaults
compatibility, financial calculations, history baseline selection, and missing
rate behavior. Manual UI/accessibility evidence follows `quickstart.md`.

## Phase 1: Scope and Safety

**Purpose**: Lock requirement coverage and compatibility before code changes.

- [X] T001 [FR1.6,FR5.3,FR6.6,FR6.11,FR7.13-FR7.15,FR9.4-FR9.10,FR10.5,FR10.9,FR13.4-FR13.6,FR14.1-FR14.8,NFR2.1,NFR2.4-NFR2.6,NFR3.2-NFR3.4,NFR4.1,NFR4.3,NFR4.6-NFR4.7,NFR5.3,NFR5.6,NFR6.1,NFR6.2,NFR6.5] Confirm full baseline disposition and regression evidence in `specs/005-weekly-monthly-highlights/spec.md` and `specs/005-weekly-monthly-highlights/plan.md`
- [X] T002 [P] [NFR5.3,NFR5.6,SFR-006] Confirm local-only data flow and exclusions in `specs/005-weekly-monthly-highlights/contracts/highlights-ui.md`
- [X] T003 [P] [FR10.5,FR10.9,NFR6.5,SFR-006] Confirm defaults compatibility, identifier, rollback, and no-schema decisions in `specs/005-weekly-monthly-highlights/data-model.md`

---

## Phase 2: Foundational Work

**Purpose**: Build and verify the shared period, presentation, and summary
boundaries that all three stories consume.

- [X] T004 [SFR-001-SFR-006,NFR6.5] Add date-controlled and isolated-UserDefaults presentation tests in `MyWealthTests/MyWealthTests.swift`
- [X] T005 [SFR-007-SFR-012,FR6.6,FR7.13,FR9.4-FR9.10,NFR4.1,NFR4.3,NFR4.6] Add financial summary, baseline, missing-rate, scope, and bounded-insight tests in `MyWealthTests/MyWealthTests.swift`
- [X] T006 [SFR-001-SFR-006,NFR6.5] Implement calendar periods and automatic presentation state in `MyWealth/Core/Highlights/HighlightPresentationStore.swift`
- [X] T007 [SFR-007-SFR-012,FR6.6,FR6.11,FR7.13-FR7.15,FR9.4-FR9.10,NFR3.2-NFR3.4,NFR4.1,NFR4.3,NFR4.6] Implement highlight summary models, baseline selection, progress math, and insights in `MyWealth/Core/Highlights/WealthHighlightCalculator.swift`
- [X] T008 [SFR-001-SFR-012] Run the focused highlights tests from `MyWealthTests/MyWealthTests.swift`

**Checkpoint**: Scheduling and calculations pass without SwiftUI or real user defaults.

---

## Phase 3: User Story 1 - See a Timely Recap at Launch (Priority: P1)

**Goal**: Present the correct eligible recap after onboarding until the user dismisses it.
**Independent Test**: A fixed first-of-month or Saturday launch keeps returning
an undismissed recap, overlap presents monthly then weekly, and dismissal suppresses repeats.

### Verification for User Story 1

- [X] T009 [US1] [FR1.6,SFR-002-SFR-006,SFR-015] Extend launch-state tests for onboarding, foreground re-entry, overlap ordering, dismissal persistence, and repeat activation in `MyWealthTests/MyWealthTests.swift`

### Implementation for User Story 1

- [X] T010 [US1] [FR1.6,SFR-002-SFR-006,SFR-015] Integrate post-onboarding automatic highlight routing and presentation in `MyWealth/MyWealthApp.swift`
- [X] T011 [US1] [FR1.6,SFR-002-SFR-006,SFR-015] Run focused presentation tests and execute the automatic-entry scenarios in `specs/005-weekly-monthly-highlights/quickstart.md`

**Checkpoint**: Eligible launch behavior works independently on iPhone and iPad roots.

---

## Phase 4: User Story 2 - Understand Wealth Progress (Priority: P1)

**Goal**: Show clear current totals, period progress, liability movement, and
deterministic insights with honest unavailable states.
**Independent Test**: Known current and baseline fixtures produce the expected
amounts, percentages, insight order, and rate/history context.

### Verification for User Story 2

- [X] T012 [US2] [SFR-007-SFR-012,SFR-014,FR6.6,FR6.11,FR7.13-FR7.15] Extend display-model tests for positive, negative, zero, stale, missing-rate, empty, and insufficient-history states in `MyWealthTests/MyWealthTests.swift`

### Implementation for User Story 2

- [X] T013 [US2] [SFR-001,SFR-007-SFR-012,SFR-014,NFR2.4-NFR2.6] Implement the reusable weekly/monthly recap page and accessible metric/insight states in `MyWealth/Features/Highlights/WealthHighlightsView.swift`
- [X] T014 [US2] [FR14.1-FR14.8,SFR-014] Add English and seven supported-locale highlight copy in `MyWealth/Resources/Localizable.xcstrings`
- [X] T015 [US2] [SFR-007-SFR-012,SFR-014] Run focused summary tests and execute the state/accessibility scenarios in `specs/005-weekly-monthly-highlights/quickstart.md`

**Checkpoint**: Both recap modes explain progress without partial or fabricated values.

---

## Phase 5: User Story 3 - Review Highlights On Demand (Priority: P2)

**Goal**: Open current weekly or monthly recaps from Dashboard without consuming
automatic eligibility.
**Independent Test**: Each Dashboard action opens the selected current period in
two interactions and leaves automatic presentation state unchanged.

### Verification for User Story 3

- [X] T016 [US3] [FR5.3,SFR-005,SFR-013] Add manual-entry non-consumption coverage in `MyWealthTests/MyWealthTests.swift`

### Implementation for User Story 3

- [X] T017 [US3] [FR5.3,SFR-005,SFR-013,NFR2.1] Add weekly and monthly highlight actions and reusable sheet routing in `MyWealth/Features/Dashboard/DashboardView.swift`
- [X] T018 [US3] [FR5.3,SFR-005,SFR-013,SFR-014] Execute manual Dashboard entry on iPhone/iPad and confirm accessibility behavior from `specs/005-weekly-monthly-highlights/quickstart.md`

**Checkpoint**: On-demand access works independently of automatic scheduling.

---

## Phase 6: Regression and Documentation

- [X] T019 [P] [FR1.6,FR5.3,FR6.11,FR10.5,FR10.9] Promote shipped highlights behavior and map new requirement IDs in `requirements.md` and `.specify/memory/requirements-context.md`
- [X] T020 [P] [FR5.3,SFR-001-SFR-015] Add weekly/monthly highlights to current product behavior in `README.md`
- [X] T021 [FR10.5,FR10.9,FR13.4-FR13.6,NFR5.3,NFR5.6] Audit defaults, backups, iCloud, widgets, notifications, analytics, logs, and rollback against `specs/005-weekly-monthly-highlights/plan.md`
- [X] T022 [FR14.1-FR14.8,SFR-014,NFR2.4-NFR2.6] Validate localization catalog structure and iPhone/iPad accessibility states from `specs/005-weekly-monthly-highlights/quickstart.md`
- [X] T023 [SFR-001-SFR-015] Run all focused `MyWealthTests` highlights tests with `xcodebuild test -only-testing:MyWealthTests`
- [X] T024 [FR1.6,FR5.3,FR6.6,FR6.11,FR7.13-FR7.15,FR9.4-FR9.10,FR10.5,FR10.9,FR13.4-FR13.6,FR14.1-FR14.8] Run `git diff --check` from `/Users/bijuvarghese/Projects/MyWealth-101/iOS/MyWealth`
- [X] T025 [NFR1.1-NFR1.4,NFR2.1,NFR3.2-NFR3.4,NFR4.1,NFR4.3,NFR4.6-NFR4.7,NFR5.3,NFR5.6,NFR6.1,NFR6.2,NFR6.5] Run the full `xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth -destination 'platform=iOS Simulator,name=iPhone 17'` gate
- [X] T026 [FR1.6,FR5.3,FR6.6,FR6.11,FR7.13-FR7.15,FR9.4-FR9.10,FR10.5,FR10.9,FR13.4-FR13.6,FR14.1-FR14.8,SFR-001-SFR-015] Confirm implementation and verification evidence for every affected requirement in `specs/005-weekly-monthly-highlights/tasks.md`
- [X] T027 [FR15.2-FR15.4,SFR-002-SFR-004] Update automatic scheduling so monthly recaps summarize the prior completed month and weekly/monthly due periods catch up until dismissed in `MyWealth/Core/Highlights/HighlightPresentationStore.swift`
- [X] T028 [FR15.4,SFR-004] Preserve an overlapping first-of-month Saturday weekly recap when monthly is presented first and dismissed later in `MyWealth/Core/Highlights/HighlightPresentationStore.swift`
- [X] T029 [SFR-011,SFR-012,SFR-014] Remove duplicate insufficient-history insight copy while keeping the visible progress-card explanation in `MyWealth/Core/Highlights/WealthHighlightCalculator.swift`
- [X] T030 [FR15.2-FR15.4,SFR-002-SFR-004,SFR-012] Add date-controlled regression tests for monthly catch-up, weekly catch-up, late overlap dismissal, and no duplicate context insight in `MyWealthTests/MyWealthTests.swift`
- [X] T031 [FR15.2-FR15.5,SFR-001-SFR-006] Align the feature spec, data model, UI contract, quickstart, shipped requirements, and implementation plan with catch-up/retrospective behavior
- [X] T032 [FR15.1-FR15.9,SFR-001-SFR-015] Re-run focused highlights tests, localization validation, `git diff --check`, and the full iOS test gate after remediation

## Verification Evidence

- Date-controlled dismissal, overlap ordering, repeat-eligibility, manual
  non-consumption, scoped baseline, progress math, missing-rate, zero, negative,
  bounded-insight, and localization tests passed in `MyWealthTests`.
- Remediation added coverage for completed-month monthly recaps, post-schedule
  catch-up, first-of-month Saturday dismissal on a later day, and duplicate
  insufficient-history copy removal.
- The iPhone 17 simulator rendered Dashboard and the weekly empty highlight
  state with the native sheet, date range, Done action, localized copy, and
  scrollable card layout. iPad uses the same Dashboard entry and width-bounded
  reusable highlight view.
- Privacy/source audit found pending-period and dismissal keys only in the
  dedicated local store; no financial highlight data was added to backup,
  iCloud KVS, widgets, notifications, analytics, logs, exports, AI, or server
  payloads.
- `jq empty MyWealth/Resources/Localizable.xcstrings` passed and localization
  completeness/format-argument tests passed for all eight supported languages.
- The full required iPhone 17 `xcodebuild test` gate passed all 84 tests after
  isolating the existing conversion test from shared cached exchange rates.
- `git diff --check` passed.

## Dependencies and Execution

- Phase 1 documentation is complete before implementation.
- T004-T005 create correctness-sensitive tests before T006-T007 implementation.
- T006 and T007 block automatic routing, the UI, and manual entry.
- User Story 1 and User Story 2 can be verified independently after foundation;
  the reusable page from User Story 2 completes the visible automatic flow.
- User Story 3 depends on the reusable page but not automatic presentation.
- T019 and T020 may run in parallel after shipped behavior is stable.
- Full regression and requirement evidence follow focused tests and manual checks.

## Parallel Opportunities

- T002 and T003 inspect separate feature documents.
- T019 and T020 update separate baseline/product documents.
- Visual/manual checks can run while independent documentation is reviewed, but
  files shared by tests, app root, and Dashboard remain sequential.

## Implementation Strategy

1. Deliver the pure date/persistence and financial summary foundation.
2. Wire automatic monthly/weekly entry.
3. Render the shared recap page with all unavailable/accessibility states.
4. Add Dashboard manual access.
5. Promote baseline requirements and run focused, hygiene, and full gates.

The MVP is User Stories 1 and 2 together: automatic presentation plus a
financially correct recap. User Story 3 adds durable on-demand review.

## Notes

- Preserve every baseline requirement not explicitly extended.
- Never place secrets, real financial data, or user labels in tests, logs,
  telemetry, specs, or fixtures.
- Existing user-owned Android feature changes remain out of scope.
- All 26 tasks follow the required checklist format with IDs, requirement
  labels, story labels in story phases, and exact repository paths.
