# Research: Net Worth Goals

## Decision 1: Persist the Goal with Financial Records

**Decision**: Store an additive `NetWorthGoal` record in the existing SwiftData schema and include it in the user's current local/optional CloudKit store.

**Rationale**: The goal contains sensitive financial data, belongs with portfolio records, benefits from the existing opt-in sync boundary, and needs typed date/amount persistence. An empty collection naturally represents all existing installs.

**Alternatives considered**:

- UserDefaults: simple, but poorly aligned with financial-record ownership, backup behavior, and CloudKit model sync.
- A separate store: adds migration, lifecycle, and sync complexity without isolation value.
- Server storage: violates local-first scope and creates unnecessary identity/security work.

## Decision 2: Enforce One Goal Through a Deterministic Store Policy

**Decision**: Give records a stable identifier and timestamps, then have `NetWorthGoalStore` select the newest valid record and reconcile duplicates after sync/import/write.

**Rationale**: CloudKit merges can temporarily create more than one record, while uniqueness constraints are not a suitable cross-store assumption. Centralizing canonical selection protects every UI and portability path.

**Alternatives considered**:

- Rely only on UI to prevent a second record: does not cover sync or imports.
- Unique schema constraint: risks CloudKit compatibility and still needs conflict handling.
- Preserve multiple records as an archive: expands product scope beyond one active goal.

## Decision 3: Use Complete Current-Rate Normalization

**Decision**: Compute current progress in the goal currency only when every participating portfolio currency and the goal currency has a valid cached rate. Normalize historical snapshots to the goal currency using the same current cached USD-base rate convention and label projections indicative.

**Rationale**: The app has current cached rates but no historical FX series. Complete coverage prevents a partial portfolio from masquerading as the user's full net worth. Using one rate convention makes mixed historical currencies comparable without new networking.

**Alternatives considered**:

- Silently skip records with missing rates: produces misleading partial progress.
- Restrict goals to the base currency: contradicts the promoted candidate and multi-currency product.
- Fetch historical exchange rates: adds server/provider scope, privacy/operations work, and a new financial-data dependency.

## Decision 4: Use a Conservative, Explainable Projection

**Decision**: Require at least three valid observations on distinct calendar dates spanning 30 days. Use the oldest-to-newest average daily net worth change, and project only when that change is positive. Cap calculator input at the most recent 365 eligible rows.

**Rationale**: The rule is deterministic, testable, understandable to users, and resistant to producing an estimate from a few days of noise. A bounded input protects rendering and calculation cost.

**Alternatives considered**:

- Two observations: technically sufficient but too sensitive to one change.
- Compound growth or regression: appears more precise than the available irregular manual history supports.
- Machine learning or AI: unnecessary, opaque, server-bound, and outside educational goal tracking.

## Decision 5: Share One Card Across Both Summary Surfaces

**Decision**: Place a compact shared goal card in the Dashboard Plan section and the focused Net Worth list, with a shared create/edit form reached through native navigation or a sheet.

**Rationale**: Dashboard provides discovery and quick progress; Net Worth provides contextual detail. A shared component keeps states and accessibility consistent without adding navigation.

**Alternatives considered**:

- Dashboard only: lower implementation cost but weak management/detail discoverability.
- Net Worth only: misses the primary summary surface named in the candidate.
- New Goals tab: disproportionate for one active goal and disrupts stable navigation.

## Decision 6: Version Backups and Preview Goal Conflicts

**Decision**: Add an optional goal payload in backup version 2, continue decoding version 1, and separate import preview from apply so replacement needs explicit confirmation.

**Rationale**: Goal data should be portable, but the existing additive importer cannot safely decide between two singleton goals. Preview/apply preserves all existing additive record behavior while making the one destructive choice visible.

**Alternatives considered**:

- Exclude goals from backup: breaks user expectations for a full backup.
- Always keep the local goal: prevents intentional restore.
- Always replace it: destructive and violates explicit-action expectations.
