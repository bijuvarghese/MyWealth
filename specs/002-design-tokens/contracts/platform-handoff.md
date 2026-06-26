# Contract: Platform Handoff

Platform owners can adopt the shared Wealth Map token catalog without changing shipped product behavior.

## iOS

- Consume tokens through app-owned presentation helpers.
- Preserve native navigation, Dynamic Type, VoiceOver, reduced motion, and standard control behavior.
- Keep token usage out of financial logic, persistence, networking, widget data stores, portability, notifications, and analytics.
- Verify touched screens and widgets against existing requirements before delivery.

## Android

- Map every shared token to native Android equivalents when an Android codebase is available.
- Document any visual equivalent that differs from the shared value because of platform conventions.
- Preserve the same state meanings and non-color-only cues.

## Web

- Map every shared token to web equivalents when a web codebase is available.
- Document responsive behavior for compact layouts, long labels, and large monetary values.
- Preserve the same state meanings and non-color-only cues.

## Review Evidence

Each platform adoption should include:

- Token categories adopted.
- Surfaces changed.
- Accessibility states reviewed.
- Screenshots or previews when practical.
- Confirmation that financial behavior, persisted data, sync, export, server, notification, widget payload, and telemetry behavior are unchanged.
