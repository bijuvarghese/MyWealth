<!--
Sync Impact Report
- Version: 1.0.0 -> 1.1.0
- Adopted principles: Privacy by Default; Financial Correctness and Compatibility;
  Native, Accessible Product Quality; Clear Boundaries and Simple Design;
  Verification Before Delivery
- Added requirement-ID traceability, shipped-versus-planned scope rules, and
  mandatory regression coverage for affected baseline requirements
- Template overrides added: plan, spec, tasks, and checklist templates
-->
# Wealth Map Constitution

## Core Principles

### I. Privacy by Default
User financial data MUST remain on-device unless the user explicitly enables
iCloud sync or invokes an export or analysis action. Secrets MUST stay in
Firebase Secret Manager or approved deployment configuration and MUST NOT be
committed, logged, embedded in the app, or returned to clients. New data flows
MUST document what leaves the device, why it is required, and how the user
controls it.

### II. Financial Correctness and Compatibility
Calculations, currency conversions, snapshots, imports, exports, and reminder
schedules MUST define their edge cases and have focused automated tests.
Missing or stale rates MUST fail visibly and gracefully rather than fabricate a
value. Persisted schemas, backup formats, UserDefaults keys, bundle identifiers,
App Groups, notification identifiers, widget kinds, and deployed endpoint names
MUST remain backward-compatible unless a specification includes an explicit
migration and rollback plan.

Every feature specification MUST cite the affected `FR*` and `NFR*` identifiers
from `requirements.md`, state whether each requirement is preserved, extended,
or changed, and define regression evidence for preserved behavior. Planned
enhancements are not baseline requirements until promoted into an approved
feature specification.

### III. Native, Accessible Product Quality
Features MUST follow established SwiftUI and Apple platform patterns and remain
usable on supported iPhone and iPad layouts. Specifications MUST include empty,
loading, error, large-value, long-label, Dynamic Type, VoiceOver, reduced-motion,
and destructive-action behavior when applicable. User-facing copy MUST use the
Wealth Map brand while internal compatibility-sensitive MyWealth names remain
stable unless a migration requires otherwise.

### IV. Clear Boundaries and Simple Design
Views MUST remain focused on presentation and interaction. Financial logic,
persistence, networking, notification scheduling, widget exchange, and data
portability MUST stay in their existing model, service, coordinator, or helper
boundaries and remain independently testable. Prefer existing project patterns
and platform frameworks. New abstractions or dependencies require a concrete
reduction in complexity, duplication, or operational risk.

### V. Verification Before Delivery
Every change MUST be verified at the narrowest useful level and at all affected
integration boundaries. Swift behavior changes require Swift Testing coverage;
Firebase or Node changes require the relevant package checks; shared app/widget,
persistence, or user-workflow changes require broader integration verification.
The full iOS test command is the release gate for app changes unless the plan
documents why it cannot run and what equivalent evidence was collected.

## Platform and Operational Constraints

- The primary client stack is Swift 6, SwiftUI, SwiftData, Observation, Charts,
  UserNotifications, WidgetKit, CloudKit, and structured concurrency.
- The supported deployment baseline is recorded in the Xcode project and MUST
  not be lowered or raised accidentally.
- Firebase HTTPS functions protect third-party credentials and own shared cache
  refresh behavior; clients MUST NOT call protected providers directly.
- `com.bv.MyWealth`, `com.bv.MyWealth.MyWealthWidget`, and
  `group.com.bv.MyWealth` are stable compatibility contracts.
- Public product naming is Wealth Map. Technical target, scheme, source path,
  Firebase project, and repository names may retain MyWealth.
- Functional and non-functional requirements in `requirements.md` are shipped
  baseline contracts. Current Scope Notes are present limitations, while Planned
  Enhancements are candidates only. A feature specification MUST identify any
  baseline change or candidate it promotes and MUST preserve all unlisted
  baseline behavior.

## Development Workflow

1. Start meaningful product work with `$speckit-specify`; use
   `$speckit-clarify` when material behavior is unresolved. Read
   `.specify/memory/requirements-context.md` and `requirements.md` first.
2. Use `$speckit-plan` to record architecture, privacy, migration, platform,
   and test decisions before implementation.
3. Use `$speckit-tasks` to produce independently verifiable work ordered by
   user value and dependency; run `$speckit-analyze` before implementation for
   cross-cutting or high-risk changes.
4. Keep changes scoped. Do not rename compatibility-sensitive identifiers or
   refactor unrelated modules without an approved specification and migration.
5. Before delivery, run `git diff --check` and all tests named in the plan.
   For iOS changes, the default full gate is:

   ```sh
   xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
     -destination 'platform=iOS Simulator,name=iPhone 17'
   ```

6. Secrets, personal financial data, backups, local environment files, and
   generated credentials MUST never enter specifications, logs, fixtures, or
   source control.

## Governance

This constitution governs all Spec Kit artifacts and implementation work in this
repository. Plans MUST include a Constitution Check, and reviewers MUST reject
unexplained violations. Amendments require a documented rationale, an impact
review of templates and active specifications, and a semantic version update:
MAJOR for removed or incompatible principles, MINOR for new principles or
materially expanded obligations, and PATCH for clarifications. `README.md` and
`requirements.md` provide product context but do not override this constitution.

**Version**: 1.1.0 | **Ratified**: 2026-06-19 | **Last Amended**: 2026-06-19
