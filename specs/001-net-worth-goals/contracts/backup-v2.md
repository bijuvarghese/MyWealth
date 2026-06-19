# Contract: Wealth Map Backup Version 2

## Compatibility

- `version` is `2` for new exports.
- The importer accepts version `1` and `2`.
- `netWorthGoal` is optional. Its absence means the backup carries no goal instruction.
- Existing arrays and their additive duplicate rules are unchanged.
- Versions greater than `2` remain unsupported.

## Goal Payload

```json
{
  "netWorthGoal": {
    "stableIdentifier": "opaque-stable-id",
    "targetAmount": 100000,
    "currencyCode": "USD",
    "targetDate": "2027-12-31T00:00:00Z",
    "createdAt": "2026-06-19T12:00:00Z",
    "updatedAt": "2026-06-19T12:00:00Z"
  }
}
```

Dates use the backup envelope's existing ISO-8601 encoding. Invalid amounts, unsupported currencies, empty identifiers, or missing dates cause the goal portion to be rejected with a typed import error before any goal replacement.

## Import Preview and Apply

`previewImport` reports one of these goal dispositions without mutating the store:

- `none`: backup has no goal.
- `insert`: backup has a valid goal and the store has none.
- `same`: imported and canonical goals are materially identical; no replacement is needed.
- `conflict`: a different canonical goal exists and a user decision is required.

`applyImport` accepts a goal conflict resolution:

- `keepExisting`: import all ordinary additive records and leave the current goal untouched.
- `replaceExisting`: after explicit confirmation, remove goal duplicates and insert/update the imported goal as canonical.

Cancelling before apply performs no import. A validation failure before apply performs no mutation. The implementation saves the applied import once after all selected inserts and goal resolution are staged.
