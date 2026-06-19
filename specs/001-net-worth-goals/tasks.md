# Tasks: Net Worth Goals

**Input**: Design documents from `/specs/001-net-worth-goals/`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`

## Phase 1: Scope and Safety

- [X] T001 [FR2.1-FR11.6,NFR2.1-NFR6.8] Confirm traceability and compatibility decisions in `specs/001-net-worth-goals/spec.md` and `specs/001-net-worth-goals/plan.md`
- [X] T002 [NFR5.3-NFR5.4,SFR-014] Verify local, iCloud, export, widget, notification, logging, and server boundaries in `specs/001-net-worth-goals/plan.md`
- [X] T003 [NFR4.1,NFR6.1-NFR6.8,SFR-015] Verify schema, backup, singleton reconciliation, and rollback contracts in `specs/001-net-worth-goals/data-model.md` and `specs/001-net-worth-goals/contracts/backup-v2.md`

## Phase 2: Foundational Work

- [X] T004 [SFR-001-SFR-003,SFR-013-SFR-014] Add failing goal model and store tests in `MyWealthTests/MyWealthTests.swift`
- [X] T005 [SFR-001-SFR-003,SFR-013-SFR-014] Implement the additive goal model in `MyWealth/Core/NetWorthGoal.swift`
- [X] T006 [SFR-001,SFR-013-SFR-014] Implement canonical singleton persistence operations in `MyWealth/Core/NetWorthGoalStore.swift`
- [X] T007 [FR10.1-FR10.4,FR10.9,FR10.12] Register the goal model in `MyWealth/Core/CloudKitSyncManager.swift` and test schema in `MyWealthTests/MyWealthTests.swift`
- [X] T008 [SFR-001-SFR-003,SFR-013-SFR-014] Run the focused goal model/store tests

## Phase 3: User Story 1 - Create a Goal and See Progress (Priority: P1)

**Goal**: Create one goal and see consistent progress on Dashboard and Net Worth.
**Independent Test**: Save a valid goal and verify matching target, current value, percentage, and date on both surfaces.

- [X] T009 [US1] [FR6.6-FR7.15,SFR-004-SFR-009] Add failing progress, validation, cross-currency, and missing-rate tests in `MyWealthTests/MyWealthTests.swift`
- [X] T010 [US1] [FR6.6-FR7.15,SFR-004-SFR-009] Implement complete-rate goal progress calculation in `MyWealth/Features/Goals/NetWorthGoalCalculator.swift`
- [X] T011 [US1] [FR2.1-FR2.5,NFR2.1-NFR2.7,SFR-002-SFR-003,SFR-008,SFR-016] Implement create/edit form validation and accessible currency selection in `MyWealth/Features/Goals/NetWorthGoalFormView.swift`
- [X] T012 [US1] [FR5.3,FR5.5,NFR2.5-NFR2.6,SFR-004-SFR-009,SFR-016] Implement shared accessible progress states in `MyWealth/Features/Goals/NetWorthGoalCard.swift`
- [X] T013 [US1] [FR5.3,FR5.5,FR6.10,SFR-004,SFR-007] Integrate goal query, card, and form routes into `MyWealth/Features/Dashboard/DashboardView.swift`
- [X] T014 [US1] [FR6.6-FR7.15,SFR-004-SFR-009] Run focused progress/calculation tests and build both app layouts

## Phase 4: User Story 2 - Understand Goal Outlook (Priority: P2)

**Goal**: Show an explainable projected date or a precise unavailable reason.
**Independent Test**: Evaluate fixtures for 3/30 eligibility, on-track, behind, insufficient, non-growing, conversion-unavailable, and achieved states.

- [X] T015 [US2] [FR6.13,FR9.4-FR9.8,SFR-010-SFR-012] Add failing projection eligibility, date, pace, currency, and bound tests in `MyWealthTests/MyWealthTests.swift`
- [X] T016 [US2] [FR6.13,FR9.4-FR9.8,NFR3.2-NFR4.6,SFR-010-SFR-012] Implement bounded snapshot normalization and outlook calculation in `MyWealth/Features/Goals/NetWorthGoalCalculator.swift`
- [X] T017 [US2] [NFR2.4-NFR2.6,SFR-010-SFR-012,SFR-016] Render outlook states and indicative labeling in `MyWealth/Features/Goals/NetWorthGoalCard.swift`
- [X] T018 [US2] [FR6.13,FR9.4-FR9.8,SFR-010-SFR-012] Run focused outlook tests and independently verify the state matrix

## Phase 5: User Story 3 - Maintain or Remove the Goal (Priority: P3)

**Goal**: Edit, persist, sync, and safely delete the active goal.
**Independent Test**: Edit every field, relaunch, then confirm deletion leaves all portfolio records intact.

- [X] T019 [US3] [SFR-001,SFR-013-SFR-014] Add edit, persistence, duplicate reconciliation, and delete-isolation tests in `MyWealthTests/MyWealthTests.swift`
- [X] T020 [US3] [NFR2.7,SFR-001,SFR-013] Complete edit/delete confirmation behavior in `MyWealth/Features/Goals/NetWorthGoalFormView.swift`
- [X] T021 [US3] [FR10.9,FR10.12,SFR-014] Verify container rebuild and canonical goal behavior in `MyWealth/Core/CloudKitSyncManager.swift` and `MyWealth/Core/NetWorthGoalStore.swift`
- [X] T022 [US3] [SFR-001,SFR-013-SFR-014] Run focused lifecycle tests and verify portfolio isolation

## Phase 6: User Story 4 - Preserve the Goal in Backups (Priority: P4)

**Goal**: Round-trip the goal while preserving legacy imports and requiring replacement confirmation.
**Independent Test**: Import v1, round-trip v2, then exercise keep, replace, and cancellation for a conflicting goal.

- [X] T023 [US4] [FR10.10-FR10.11,NFR6.8,SFR-015] Add failing v1/v2, round-trip, invalid-goal, and conflict-resolution tests in `MyWealthTests/MyWealthTests.swift`
- [X] T024 [US4] [FR10.10-FR10.11,NFR6.8,SFR-015] Implement backup v2 optional goal export, preview, and apply in `MyWealth/Core/DataPortability.swift`
- [X] T025 [US4] [NFR2.7,SFR-015] Implement imported-goal conflict confirmation in `MyWealth/Features/Settings/SettingsView.swift`
- [X] T026 [US4] [FR10.10-FR10.11,SFR-015] Run focused portability tests and verify the backup contract

## Final Phase: Regression and Documentation

- [X] T027 [FR5.3,FR5.5,FR10.1-FR10.12] Update shipped behavior and promoted enhancement status in `requirements.md` and feature summary in `README.md`
- [X] T028 [NFR2.1-NFR2.7,SFR-016] Validate iPhone/iPad layouts, Dynamic Type, VoiceOver labels, reduced motion, large amounts, and long currency names
- [X] T029 [FR6.6-FR11.6,SFR-017] Run focused conversion, rate, history, persistence, portability, and widget regression tests
- [X] T030 [NFR1.1-NFR6.8] Run `git diff --check`
- [X] T031 [NFR1.1-NFR6.8] Run the full `xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth -destination 'platform=iOS Simulator,name=iPhone 17'` gate
- [X] T032 [FR2.1-FR11.6,NFR2.1-NFR6.8,SFR-001-SFR-017] Confirm all tasks and requirement evidence in `specs/001-net-worth-goals/tasks.md`

## Dependencies and Execution

- Phase 1 confirms already-approved scope; Phase 2 blocks all stories.
- User Story 1 is the MVP and blocks the shared display portions of User Story 2 and lifecycle UI of User Story 3.
- User Story 2 depends on the calculator/card from User Story 1 but is independently testable with snapshot fixtures.
- User Story 3 depends on the foundational store and form, not on projection logic.
- User Story 4 depends on the foundational model/store and may proceed after their focused tests pass.
- Financial, persistence, and portability tests precede their production changes.

## Implementation Strategy

Deliver the P1 create/progress path first, add outlook states, complete edit/delete lifecycle, then version portability. Keep widget, notification, Firebase, analysis export, and stable identifier surfaces unchanged. Finish with requirement documentation and the full release gate.
