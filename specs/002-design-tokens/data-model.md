# Data Model: Cross-Platform Design Tokens

## Design Token

Represents one reusable Wealth Map visual decision.

**Fields**:

- `name`: Stable purpose-based identifier.
- `category`: Color, typography, spacing, shape, elevation, motion, icon, chart, or status.
- `description`: Product intent and recommended usage.
- `value`: Shared value where a platform-neutral value exists.
- `platformValues`: iOS, Android, and web mappings when exact values differ.
- `accessibilityNotes`: Contrast, Dynamic Type, reduced motion, or non-color-only guidance.

**Validation**:

- Name must be stable, unique, and purpose-based.
- Category must be one of the required token categories.
- Each required platform must have a value or documented equivalent.
- Token content must not include secrets, credentials, personal financial data, user-entered labels, or environment-specific values.

## Token Category

Groups tokens by visual role.

**Required categories**:

- Brand color
- Semantic color
- Typography
- Spacing
- Shape
- Elevation
- Icon sizing
- Chart/status color
- Motion intent

**Validation**:

- Every required category must have at least one token.
- Semantic color and status categories must include non-color-only usage guidance where state meaning is user-facing.

## Platform Mapping

Describes how a shared token appears on a target platform.

**Fields**:

- `platform`: iOS, Android, or web.
- `representation`: Platform-appropriate value or reference.
- `rationale`: Required when the mapping is not an exact equivalent.

**Validation**:

- All tokens must include iOS, Android, and web mappings or an explicit reason a mapping is deferred.
- Mappings must preserve the same product intent even when platform expression differs.

## Token Adoption Surface

Tracks a product area or shared UI primitive that consumes tokens.

**Fields**:

- `surface`: Component, screen, widget family, or documentation handoff.
- `tokensUsed`: Token names adopted by the surface.
- `regressionEvidence`: Required checks for that surface.

**Validation**:

- Adoption must remain presentation-only.
- Adoption must identify any affected accessibility, light/dark, high-contrast, large-value, or long-label checks.
