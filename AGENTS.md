# Wealth Map Agent Guide

Wealth Map is a SwiftUI personal net-worth app with a WidgetKit extension and
Firebase proxy functions. Read `README.md`, `requirements.md`, and
`.specify/memory/constitution.md` before planning product changes.

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

<!-- SPECKIT START -->
For feature work, use the project-local `$speckit-*` skills. Read the current
feature plan for additional technology, structure, and command context.
<!-- SPECKIT END -->
