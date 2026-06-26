# Tasks: Cross-Platform Design Tokens

**Input**: Design documents from `/specs/002-design-tokens/`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, and `quickstart.md`

**Tests**: This is presentation-only work. Automated validation is required for token catalog shape and hygiene; focused UI/widget checks and repository hygiene are required for adopted surfaces.

## Format: `[ID] [P?] [Story] [Reqs] Description`

- **[P]**: Can run in parallel because files and dependencies do not overlap.
- **[Story]**: User story such as `[US1]`; omit only for shared setup/foundation.
- **[Reqs]**: Baseline or feature IDs.
- Every task names exact repository paths.

## Phase 1: Scope and Safety

**Purpose**: Lock requirement coverage and compatibility before code changes.

- [x] T001 [FR1.1-FR13.9,NFR1.1-NFR6.9,SFR-001-SFR-012] Confirm affected baseline and feature requirements in `specs/002-design-tokens/spec.md` and `specs/002-design-tokens/plan.md`
- [x] T002 [P] [NFR5.1-NFR5.7,SFR-010] Record privacy, secret, logging, and external data-flow constraints in `specs/002-design-tokens/plan.md`
- [x] T003 [P] [NFR4.1-NFR4.8,NFR6.1-NFR6.9] Record persistence, identifier, migration, rollback, and architecture decisions in `specs/002-design-tokens/plan.md`

---

## Phase 2: Foundational Work

**Purpose**: Shared token catalog, platform contracts, and validation that block all adoption stories.

- [x] T004 [SFR-001-SFR-004,SFR-009] Create the shared token catalog in `tokens/wealth-map.tokens.json`
- [x] T005 [SFR-001-SFR-004,NFR6.1-NFR6.9] Add iOS presentation token accessors in `MyWealth/Core/Design/WealthMapDesignTokens.swift`
- [x] T006 [P] [SFR-001-SFR-004,SFR-009-SFR-012,NFR5.1-NFR5.7] Add token catalog validation coverage in `MyWealthTests/MyWealthTests.swift`

**Checkpoint**: Token catalog is validated before component adoption.

---

## Phase 3: User Story 1 - Keep Wealth Map Visually Consistent (Priority: P1)

**Goal**: Reuse tokens in shared visual primitives so core app surfaces stay coherent without workflow changes.
**Independent Test**: Review tokenized components in representative app states and confirm content, actions, calculations, and labels are unchanged.

### Implementation for User Story 1

- [x] T007 [US1] [FR5.1-FR5.8,FR6.1-FR6.16,NFR2.1-NFR2.7,SFR-005-SFR-008] Adopt tokens in `MyWealth/Components/AppListCard.swift`
- [x] T008 [US1] [FR6.1-FR6.16,FR12.14,NFR2.1-NFR2.7,SFR-005-SFR-008] Adopt semantic status tokens in `MyWealth/Components/PillLabel.swift`
- [x] T009 [US1] [FR11.1-FR11.6,NFR2.1-NFR2.7,SFR-005-SFR-008] Align widget accent styling with token values in `MyWealthWidget/MyWealthWidgetViews.swift`
- [x] T010 [US1] [FR5.1-FR5.8,FR6.1-FR6.16,FR11.1-FR11.6,FR12.14,NFR2.1-NFR2.7] Complete focused UI/widget inspection using `specs/002-design-tokens/quickstart.md`

**Checkpoint**: User Story 1 works independently without regressing cited baseline requirements.

---

## Phase 4: User Story 2 - Share Visual Decisions Across Platforms (Priority: P2)

**Goal**: Make token decisions understandable for iOS, Android, and web owners.
**Independent Test**: Compare the shared token catalog with platform handoff contracts and confirm each required category has mappings or documented equivalents.

### Implementation for User Story 2

- [x] T011 [US2] [SFR-001-SFR-004,SFR-009,SFR-012] Confirm token catalog coverage against `specs/002-design-tokens/contracts/token-catalog.md`
- [x] T012 [US2] [SFR-002,SFR-009,SFR-012] Confirm platform mapping guidance against `specs/002-design-tokens/contracts/platform-handoff.md`

**Checkpoint**: Android and web adoption can proceed from the catalog without changing iOS behavior.

---

## Phase 5: User Story 3 - Safely Evolve the Visual System (Priority: P3)

**Goal**: Make future token changes reviewable and reversible.
**Independent Test**: Change review can identify affected token adoption surfaces and rollback path without data migration.

### Implementation for User Story 3

- [x] T013 [US3] [SFR-011,SFR-012,NFR6.1-NFR6.9] Document token ownership, update process, and rollback expectations in `specs/002-design-tokens/quickstart.md`
- [x] T014 [US3] [SFR-011,SFR-012,NFR6.1-NFR6.9] Confirm affected adoption surfaces are listed in `specs/002-design-tokens/plan.md`

---

## Final Phase: Regression and Documentation

- [x] T015 [P] [FR1.1-FR13.9,NFR1.1-NFR6.9] Confirm `requirements.md` does not need an update because shipped behavior is preserved
- [x] T016 [P] [SFR-001-SFR-012,NFR5.1-NFR5.7] Inspect token artifacts for secrets, credentials, personal financial data, and environment-specific values
- [x] T017 [NFR1.1-NFR6.9] Run `git diff --check`
- [x] T018 [NFR1.1-NFR6.9] Run focused Swift tests for token validation in `MyWealthTests/MyWealthTests.swift`
- [x] T019 [NFR1.1-NFR6.9] Run the full `xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth -destination 'platform=iOS Simulator,name=iPhone 17'` gate or record why it could not run
- [x] T020 [FR1.1-FR13.9,NFR1.1-NFR6.9,SFR-001-SFR-012] Confirm every affected requirement has implementation and verification evidence in `specs/002-design-tokens/tasks.md`

## Dependencies and Execution

- Phase 1 is complete and precedes implementation.
- Phase 2 blocks all adoption stories.
- User Story 1 is the MVP because it proves tokens inside the iOS app and widget.
- User Story 2 can run after the token catalog exists.
- User Story 3 can run after adoption surfaces are known.
- T006 can run in parallel with token accessor implementation after the catalog shape is defined.

## Parallel Execution Examples

- After T004, T005 and T006 can proceed in parallel.
- After T005, T007 and T008 can proceed in parallel because they touch separate components.
- T011 and T012 can proceed in parallel once the catalog is created.
- T015 and T016 can proceed in parallel during final review.

## Implementation Strategy

1. Deliver the MVP: T004-T010.
2. Confirm cross-platform handoff: T011-T012.
3. Confirm future-change safety: T013-T014.
4. Finish regression and repository hygiene: T015-T020.

## Notes

- Preserve behavior for every baseline requirement not explicitly changed.
- Never place secrets or real financial data in specs, tests, logs, or fixtures.
- Keep token usage presentation-only and out of financial, persistence, networking, notification, widget payload, portability, and analytics boundaries.
