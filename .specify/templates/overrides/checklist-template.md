# [CHECKLIST TYPE] Checklist: [FEATURE NAME]

**Purpose**: Validate the feature against Wealth Map's product baseline
**Created**: [DATE]
**Feature**: [Link to spec.md]
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`

<!-- Keep applicable baseline checks and add feature-specific checks. Use N/A
only with a written reason. Checklist items validate requirement quality and
coverage, not merely whether implementation tasks were completed. -->

## Requirements and Scope

- [ ] CHK001 Every affected `FR*`, `NFR*`, and `SFR*` ID is traceable through spec, plan, tasks, and verification
- [ ] CHK002 Shipped baseline, current limitations, planned enhancements, and explicit out-of-scope behavior are distinguished
- [ ] CHK003 Acceptance scenarios cover success, empty, boundary, and failure behavior
- [ ] CHK004 Preserved baseline behavior at risk of regression has explicit evidence

## Privacy and Compatibility

- [ ] CHK005 Local, iCloud, server, export, widget, notification, and indexing data flows are addressed
- [ ] CHK006 Secrets, logs, and test fixtures cannot expose credentials or real financial data
- [ ] CHK007 SwiftData, UserDefaults, backup, identifier, endpoint, and rollback impacts are addressed

## Product Quality

- [ ] CHK008 iPhone and iPad behavior is specified where applicable
- [ ] CHK009 Dynamic Type, VoiceOver, reduced motion, long labels, large values, and destructive actions are addressed
- [ ] CHK010 Missing/stale rates, concurrency, offline behavior, and partial failures are addressed where relevant

## Verification

- [ ] CHK011 Correctness-sensitive behavior has automated test requirements
- [ ] CHK012 Cross-boundary app/widget, local/iCloud, or client/server checks are included where relevant
- [ ] CHK013 Full build/test and documentation gates are explicit and measurable

## Notes

- Check completed items with `[x]`.
- Add findings and requirement references inline.
- Unresolved items block implementation unless explicitly approved in the plan.
