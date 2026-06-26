# Contract: Token Catalog

The token catalog is the source of truth for Wealth Map's cross-platform visual decisions.

## Required Coverage

| Category | Required intent |
|----------|-----------------|
| Brand color | Wealth Map identity and primary emphasis |
| Semantic color | Text, surface, border, accent, success, warning, danger, neutral |
| Typography | Display, title, headline, body, caption, amount, and compact labels |
| Spacing | Screen, section, card, row, control, and inline spacing |
| Shape | Card, control, pill, and compact element radius |
| Elevation | Card and floating surface depth |
| Icon sizing | Navigation, row, action, status, and widget icon sizes |
| Chart/status color | Asset, liability, net worth, stale, unavailable, success, warning, danger |
| Motion intent | Standard, reduced, and disabled motion guidance |

## Required Token Fields

- Stable token name
- Category
- Description
- Shared value or platform values
- iOS mapping
- Android mapping
- Web mapping
- Accessibility notes when applicable

## Invariants

- Tokens must be purpose-based, not tied to one screen unless the token represents a reusable surface role.
- Tokens must not contain secrets, credentials, personal financial data, user-entered financial labels, provider keys, endpoint URLs, or local environment values.
- Tokens must not introduce server, sync, backup, notification, widget payload, or analytics data changes.
- User-facing state meanings must not depend on color alone.
