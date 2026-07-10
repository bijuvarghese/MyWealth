# Contract: Google Drive App-Data Sync

## Purpose

This contract defines the Android equivalent of optional iCloud backup and
sync. It is a client-to-user-Drive contract, not a Wealth Map backend API.

## Authorization

- Sync defaults to disabled.
- Authorization begins only from an explicit user action.
- Request only `https://www.googleapis.com/auth/drive.appdata`.
- The app remains fully usable if authorization is denied, revoked, or
  unavailable.
- Authorization tokens and account identity remain device-local and are never
  included in analytics or sync content.
- Disabling sync stops work but does not delete remote data or revoke access.
  A separate disconnect action may revoke access after confirmation.

## Remote Object

| Property | Contract |
|----------|----------|
| Space | `appDataFolder` |
| Filename | `wealth-map-sync-v1.json` |
| MIME type | `application/json` |
| Schema | `schemaVersion: 1` |
| Multiplicity | At most one canonical active file per authorized account |
| Update guard | Remote ETag/version conditional update |

Duplicate candidate files are resolved by selecting the valid file with the
highest remote version/modified time and reporting cleanup as maintenance;
invalid candidates are not applied.

## Envelope

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-06-30T18:00:00Z",
  "writerDeviceId": "opaque-device-id",
  "records": {
    "assets": [],
    "liabilities": [],
    "assetValueSnapshots": [],
    "netWorthSnapshots": [],
    "portfolioSnapshots": [],
    "netWorthGoals": []
  },
  "settings": {
    "baseCurrency": "USD",
    "displayCurrencies": ["USD", "EUR"],
    "usesCompactCurrencyTotals": false
  },
  "tombstones": [],
  "integrity": {
    "recordCount": 0,
    "contentDigest": "sha256-base64"
  }
}
```

Every record and tombstone contains:

- Stable record type and record ID
- UTC modification/deletion time
- Opaque mutation ID
- Opaque writer device ID

Persisted category, currency, unit, and other enum values use the same stable
raw values as backup version 2. Localized labels never enter the payload.

## Validation

Before applying a downloaded envelope:

1. Reject unsupported future `schemaVersion` values without modifying Room.
2. Verify JSON shape, size limits, record count, and content digest.
3. Reject non-finite/invalid decimals, invalid dates, empty stable IDs,
   unsupported required currency codes, and malformed tombstones.
4. Canonicalize duplicate remote entries by the merge ordering below.
5. Validate that the result contains at most one active goal.
6. Apply the complete merged result in one Room transaction.

## Deterministic Merge

For each `(recordType, recordId)`:

1. Compare mutation timestamp.
2. The higher timestamp wins.
3. If timestamps are equal, compare opaque mutation ID lexicographically.
4. If mutation IDs are also equal and one candidate is a tombstone, the
   tombstone wins.
5. Exact duplicate content is idempotent.

For the singleton goal:

- Merge by stable ID first.
- If multiple active valid goals remain, select the highest ordered mutation as
  canonical and retain non-canonical deletion tombstones.

For settings:

- Merge each syncable settings bundle by its bundle mutation metadata.
- Preserve display-currency order and ensure the base currency appears exactly
  once.
- Never merge onboarding, reminder, token, account, or device state.

## Reconciliation Algorithm

1. Snapshot dirty local records and local tombstones.
2. Download the canonical remote object and its ETag/version, or use an empty
   envelope when none exists.
3. Validate remote content.
4. Merge local and remote state deterministically.
5. Apply the merged state to Room transactionally.
6. Upload the merged envelope using the downloaded ETag/version condition.
7. If the remote precondition fails, repeat from download with exponential
   backoff.
8. Mark local mutations clean and advance the checkpoint only after successful
   upload.

If upload fails after local merge, local state remains valid and dirty/pending
metadata causes a later retry.

## Triggers

- Initial enable
- App foreground
- Explicit user refresh
- Debounced unique one-time work after a supported local mutation
- Constrained periodic WorkManager safety-net reconciliation

Work requires a network connection. Background execution is eventual and not
presented as exact or realtime.

## Account Isolation

- Associate every synced local profile with an opaque authorized-account ID.
- If the authorization account differs, pause before downloading or uploading.
- Offer explicit actions to keep current data local, switch to the existing
  account profile, or merge into the new account after a preview/confirmation.
- Never use email addresses in database filenames, logs, analytics, crash
  metadata, or notification text.

## Status Contract

The Settings UI exposes:

- Off
- Authorization required
- Initial sync
- Syncing
- Up to date with last successful time
- Pending while offline
- Paused after authorization/account change
- Retryable failure
- Incompatible remote data

Errors identify the action the user can take without exposing payload content.

## Privacy Contract

- No Drive payload passes through Wealth Map Firebase functions or another
  developer server.
- No payload, token, account ID, financial value, user-entered label, or Drive
  error body is logged or sent to analytics.
- Widgets and notifications are local consumers only.
- Disabling or uninstalling the app does not silently delete remote data.
