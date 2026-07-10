# Wealth Map Agent Guide

Wealth Map is a SwiftUI personal net-worth app with a WidgetKit extension and
Firebase proxy functions. Read `README.md`, `requirements.md`, and
`.specify/memory/constitution.md` before planning product changes. Use
`.specify/memory/requirements-context.md` to map requirement IDs to code areas.

## Requirements Discipline

- Treat `FR1.1`-`FR15.9` and `NFR1.1`-`NFR6.9` in `requirements.md` as the
  shipped baseline.
- Treat Current Scope Notes as present limitations and Planned Enhancements as
  candidates, not shipped commitments.
- Every feature spec and plan must cite affected requirement IDs, state what is
  preserved or changed, and define regression evidence.
- Update `requirements.md` when implementation changes shipped behavior or
  removes a documented limitation.

## Stable Technical Contracts

- Keep the `MyWealth` Xcode target, scheme, module, source paths, bundle IDs,
  App Group, Firebase project, and persisted identifiers stable unless a spec
  includes a migration.
- Use Wealth Map for user-facing product copy.
- Keep financial data local unless a user explicitly enables iCloud sync or
  invokes an export or analysis action.
- Never add provider keys or personal financial data to source control.

## Verification

Run the narrow tests for the changed behavior, then use this full app gate:

```sh
xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

For Firebase changes, run the scripts defined by `functions/package.json`.
Always run `git diff --check` before delivery.

## Tagging and Publishing

- Follow the existing release naming convention: use the plain app version as
  the Git tag and GitHub release title, for example `5.0.2`.
- Do not prefix release tags with `v` unless the repository history changes to
  that convention.
- Publish releases from the commit that contains the matching app and widget
  version bump.
- When correcting a mistakenly named release, remove the incorrect release/tag
  and republish using the plain-version convention.

<!-- SPECKIT START -->
For feature work, use the project-local `$speckit-*` skills. Read the current
feature plan at `specs/005-weekly-monthly-highlights/plan.md` and
`.specify/memory/requirements-context.md` for additional
technology, structure, scope, and traceability context.
<!-- SPECKIT END -->
