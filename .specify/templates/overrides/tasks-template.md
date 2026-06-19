---
description: "Wealth Map feature implementation task template"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`
**Prerequisites**: `spec.md` and `plan.md`; research, data model, contracts, and
quickstart when produced

**Tests**: Tests are required for financial calculations, persistence and
migrations, settings compatibility, networking, notifications, widgets, import
or export, and defect corrections. Other UI-only work still requires the
verification defined in the plan.

## Format: `[ID] [P?] [Story] [Reqs] Description`

- **[P]**: Can run in parallel because files and dependencies do not overlap.
- **[Story]**: User story such as `[US1]`; omit only for shared setup/foundation.
- **[Reqs]**: Baseline or feature IDs, for example `[FR7.13,SFR-002]`.
- Every task MUST name exact repository paths.

## Wealth Map Paths

- App code: `MyWealth/Components/`, `MyWealth/Core/`, `MyWealth/Features/`
- Widget code: `MyWealthWidget/` and shared `MyWealth/Core/Widget/`
- App tests: `MyWealthTests/MyWealthTests.swift`
- Firebase backend: `functions/`
- Operations: `scripts/`, `cloud-run/`, `.github/workflows/`
- Product documentation: `README.md`, `requirements.md`, feature artifacts

<!-- Replace every example below with feature-specific tasks. Do not create new
project scaffolding for this established repository unless the plan requires it. -->

## Phase 1: Scope and Safety

**Purpose**: Lock requirement coverage and compatibility before code changes.

- [ ] T001 [FRx.x,NFRx.x] Confirm affected baseline and feature requirements in `spec.md` and `plan.md`
- [ ] T002 [P] [NFR5.x] Record privacy, secret, logging, and external data-flow constraints in `plan.md`
- [ ] T003 [P] [NFR4.x,NFR6.x] Record persistence, identifier, migration, rollback, and architecture decisions in `plan.md`

---

## Phase 2: Foundational Work

**Purpose**: Shared models, protocols, migrations, fixtures, or service contracts
that block all user stories. Remove this phase when the feature needs none.

- [ ] T004 [Req IDs] Add or update focused tests in `MyWealthTests/MyWealthTests.swift`
- [ ] T005 [Req IDs] Implement shared model/service contract in `[exact path]`
- [ ] T006 [Req IDs] Add migration or backward-compatible decoding in `[exact path]`

**Checkpoint**: Foundation builds and focused tests pass before story work.

---

## Phase 3: User Story 1 - [Title] (Priority: P1)

**Goal**: [User value]
**Independent Test**: [Observable test]

### Verification for User Story 1

- [ ] T007 [P] [US1] [Req IDs] Add failing calculation/service tests in `MyWealthTests/MyWealthTests.swift`
- [ ] T008 [P] [US1] [Req IDs] Define iPhone/iPad, accessibility, empty, error, and stale-data checks in `quickstart.md`

### Implementation for User Story 1

- [ ] T009 [US1] [Req IDs] Implement domain or service behavior in `[exact MyWealth/Core or Features path]`
- [ ] T010 [US1] [Req IDs] Implement SwiftUI behavior in `[exact MyWealth/Features or Components path]`
- [ ] T011 [US1] [Req IDs] Propagate widget, iCloud, notification, export, or backend changes in `[exact path]`
- [ ] T012 [US1] [Req IDs] Run focused tests and complete the independent story check

**Checkpoint**: User Story 1 works independently without regressing cited baseline requirements.

---

## Phase 4+: Additional User Stories

Repeat the User Story 1 structure for each prioritized story. Keep tests and
implementation mapped to requirement IDs and avoid cross-story file conflicts.

---

## Final Phase: Regression and Documentation

- [ ] TXXX [P] [Req IDs] Update `requirements.md` when shipped baseline or current scope changes
- [ ] TXXX [P] [Req IDs] Update `README.md` or operational documentation when setup or behavior changes
- [ ] TXXX [Req IDs] Validate migrations, backups, settings, identifiers, and rollback behavior
- [ ] TXXX [Req IDs] Validate iPhone/iPad layouts and applicable accessibility states
- [ ] TXXX [Req IDs] Run Firebase/package checks when `functions/` or operations code changed
- [ ] TXXX [Req IDs] Run `git diff --check`
- [ ] TXXX [Req IDs] Run the full `xcodebuild test` gate from `plan.md`
- [ ] TXXX [Req IDs] Confirm every affected requirement has implementation and verification evidence

## Dependencies and Execution

- Scope and Safety precedes implementation.
- Foundational work blocks all dependent stories.
- Tests for correctness-sensitive behavior are written before implementation.
- Models and protocols precede services; services precede views and integrations.
- App/widget, local/iCloud, and client/server changes are verified together.
- `[P]` is valid only for separate files with no unresolved dependency.

## Notes

- Preserve behavior for every baseline requirement not explicitly changed.
- Never place secrets or real financial data in specs, tests, logs, or fixtures.
- Prefer established project boundaries and avoid unrelated refactoring.
- Complete a story's independent test before moving to the next priority.
