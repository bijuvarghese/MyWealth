# UI Contract: Net Worth Goal

## Surfaces

| Surface | No goal | Active goal | Action |
|---------|---------|-------------|--------|
| Dashboard Plan section | Compact `Set a Net Worth Goal` row | Compact progress card with target, date, progress, and short outlook | Opens create or edit flow. FIRE Calculator remains available. |
| Net Worth list | Goal invitation below current totals | Full goal card with current/target values, accessible progress, deadline, and outlook explanation | Opens create or edit flow. |
| Goal form | Create title and empty defaults | Edit title and prefilled canonical goal | Save; edit also exposes destructive Delete. |

## Display States

1. **Available**: Show current amount, target, percentage, deadline, and outlook.
2. **Achieved**: Show completed visual progress and an explicit `Goal achieved` label; do not show a future projection.
3. **Needs history**: Show progress plus `More history is needed for a projection`.
4. **Not growing**: Show progress plus `Current history does not support an achievement estimate`.
5. **Behind pace**: Show indicative projected date and an explicit behind-pace label.
6. **On track**: Show indicative projected date and an explicit on-track label.
7. **Missing rate/current value**: Show target and deadline, replace current/progress with `Unavailable`, and name the existing rate issue without substituting zero.
8. **Stale rates**: Permit calculation from cached values while retaining the existing stale-rate warning semantics.

## Form Contract

- Target amount uses numeric financial entry and rejects empty, non-finite, zero, and negative values.
- Currency uses the existing searchable supported-currency presentation and excludes `.none`.
- Date picker limits new selections to the user's current calendar day or later.
- Save is disabled until all fields are valid; field-specific accessibility guidance remains visible.
- Delete is available only while editing and requires a destructive confirmation naming only the goal.
- Dismissing an unsaved form does not alter the canonical goal.

## Accessibility Contract

- The progress indicator exposes one combined label containing current, target, percentage or unavailable state, and achieved status.
- On-track, behind, achieved, and unavailable states include text and symbols; color is supplemental.
- Progress animation is omitted or disabled when Reduce Motion is active.
- Layout supports accessibility Dynamic Type without truncating the amount, date, state, or primary action.
- Dashboard and Net Worth expose the same semantic values and edit action.
