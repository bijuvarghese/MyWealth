# Research: Cross-Platform Design Tokens

## Decision: Use a Shared Token Catalog With Platform Mappings

**Rationale**: The user wants the same design decisions available to iOS, Android, and web. A shared catalog with explicit platform mappings keeps the product language consistent while allowing each platform to express native equivalents.

**Alternatives considered**:

- **iOS-only theme first**: Faster for the current repository, but it would not satisfy the Android and web requirement.
- **Full design-system dependency immediately**: More automation up front, but unnecessary before the first token set and adoption surfaces are validated.

## Decision: Separate Primitive Values From Semantic Roles

**Rationale**: Primitive values describe raw choices, while semantic roles describe product intent such as primary action, warning, success, card surface, chart asset, or chart liability. This lets Wealth Map adjust appearance later without rewriting every screen.

**Alternatives considered**:

- **Screen-specific tokens**: Easy to start, but they duplicate decisions and do not travel well across platforms.
- **Only raw color and spacing values**: Portable, but not expressive enough for safe product-wide changes.

## Decision: Start With High-Reuse Presentation Primitives

**Rationale**: `AppListCard`, `PillLabel`, status treatments, and widget accent styling already centralize repeated visual choices. Tokenizing these first gives visible value with low behavioral risk.

**Alternatives considered**:

- **Migrate every screen at once**: Higher risk and review burden with little added learning.
- **Only document tokens without adoption**: Useful for handoff, but it would not prove the token system works in the iOS app.

## Decision: Keep Tokens Presentation-Only

**Rationale**: Wealth Map's constitution requires financial logic, persistence, networking, widgets, portability, and analytics to stay in their existing boundaries. Tokens should not affect calculations, stored data, server flows, or user privacy.

**Alternatives considered**:

- **Store tokens as runtime settings**: Adds migration and settings complexity without user value for the first rollout.
- **Fetch tokens remotely**: Creates a new data flow and reliability risk that is not needed.

## Decision: Validate Token Hygiene Locally

**Rationale**: Token files are source-controlled and could be copied across platforms, so they must be checked for required categories, mappings, and absence of secrets or personal financial data.

**Alternatives considered**:

- **Manual-only review**: Acceptable for early sketches, but weaker than repeatable checks once tokens enter the app.
- **Heavy generated pipeline immediately**: Useful later, but a lightweight local validation keeps the first rollout simple.
