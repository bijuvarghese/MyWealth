# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: `/specs/[###-feature-name]/spec.md`
**Baseline**: `requirements.md`, `.specify/memory/requirements-context.md`

## Summary

[Primary user outcome, affected baseline IDs, and concise technical approach]

## Requirements Traceability

| Requirement | Planned change | Design surface | Verification |
|-------------|----------------|----------------|--------------|
| [FRx.x/NFRx.x/SFR-xxx] | [Preserve/extend/change] | [Real path/module] | [Test or inspection] |

All affected baseline IDs from the feature specification MUST appear here. Add
high-risk preserved requirements when regression is plausible.

## Technical Context

**Language/Version**: Swift 6.0; JavaScript/Node.js 22 when Firebase changes are included

**Primary Dependencies**: SwiftUI, SwiftData, Observation, Charts,
UserNotifications, WidgetKit, CloudKit, async/await; Firebase Functions and
Datastore for server proxy work

**Storage**: SwiftData, UserDefaults, App Group UserDefaults, optional CloudKit,
Firebase Datastore caches; narrow to the stores affected by this feature

**Testing**: Swift Testing in `MyWealthTests/`; package scripts in
`functions/package.json`; focused script or endpoint validation when applicable

**Target Platform**: iOS/iPadOS 26.1+, Xcode 26.1+

**Project Type**: Existing iOS app, WidgetKit extension, and Firebase backend

**Performance Goals**: [Interactive UI, bounded history queries, nonblocking
network/persistence work, or feature-specific measurable goal]

**Constraints**: Local-first privacy; graceful stale/missing data; Swift 6
concurrency safety; stable identifiers and persisted-data compatibility

**Scale/Scope**: [Affected screens, models, services, widget families, functions,
and realistic local record counts]

## Constitution Check

*GATE: Must pass before research and be re-checked after design.*

- **Privacy by Default**: [Data-flow and secret-handling result]
- **Financial Correctness**: [Precision, rate, calculation, and edge-case result]
- **Compatibility**: [Persistence, backup, settings, identifier, and migration result]
- **Native Product Quality**: [iPhone/iPad, accessibility, state, and copy result]
- **Architecture**: [Existing boundary reuse and dependency justification]
- **Verification**: [Tests and integration gates mapped to requirements]
- **Scope Discipline**: [Planned enhancement promotion and explicit exclusions]

Any failed gate MUST be resolved or recorded in Complexity Tracking with an
approved migration and rollback plan.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

### Source Code (select and narrow to real affected paths)

```text
MyWealth/
├── Components/
├── Core/
│   ├── Notifications/
│   └── Widget/
├── Features/
├── Assets.xcassets/
├── Info.plist
└── MyWealthApp.swift

MyWealthWidget/
MyWealthTests/
functions/
scripts/
cloud-run/
```

**Structure Decision**: [List exact files/modules to change and explain why each
belongs in its existing boundary]

## Data and Migration Design

- **Models/schema**: [Changes and migration, or N/A]
- **Settings/identifiers**: [Changes and compatibility, or N/A]
- **Backup/import**: [Changes and format versioning, or N/A]
- **iCloud/widget/server propagation**: [Cross-boundary consistency, or N/A]
- **Rollback/recovery**: [Safe behavior after partial failure or downgrade]

## Verification Plan

- **Focused tests**: [Requirement IDs and test cases]
- **Regression tests**: [Preserved baseline behaviors at risk]
- **UI/accessibility checks**: [Devices, layouts, states, assistive settings]
- **Backend checks**: [Functions tests, cache/HTTP behavior, secret validation]
- **Full iOS gate**:

  ```sh
  xcodebuild test -project MyWealth.xcodeproj -scheme MyWealth \
    -destination 'platform=iOS Simulator,name=iPhone 17'
  ```

## Complexity Tracking

> Fill only for constitution violations or new dependencies/abstractions.

| Violation or addition | Why needed | Simpler alternative rejected because | Approval/migration |
|-----------------------|------------|--------------------------------------|--------------------|
| [Item] | [Concrete need] | [Evidence] | [Decision] |
