# Data Model: Android Wealth Map Parity

## Storage Rules

- Room is the authoritative store for financial records, history, goals,
  tombstones, and structured caches.
- Canonical financial amounts are stored as decimal strings and exposed as
  `BigDecimal`; parsing rejects non-finite and malformed values.
- Times are stored as UTC epoch milliseconds and encoded as ISO-8601 in backup
  and sync payloads.
- Stable IDs are opaque UUID strings and never localized.
- DataStore holds small settings and device state only.
- Drive sync is a projection of validated local state, never a second live
  database read directly by the UI.

## Room Entities

### AssetEntity

| Field | Type | Rules |
|------|------|-------|
| `id` | String | Primary key; preserve prototype UUID |
| `historyIdentifier` | String | Unique stable association key; backfill when missing |
| `name` | String | Trimmed, non-empty |
| `amountDecimal` | String | Finite, non-negative canonical decimal |
| `currencyCode` | String | Supported code; precious metals use their stable code |
| `categoryRaw` | String | Stable iOS-compatible raw value |
| `lastUpdatedEpochMs` | Long | UTC mutation time |
| `weightUnitRaw` | String? | Stable unit for precious-metal entry |
| `isIncludedInPortfolio` | Boolean | Defaults true |

### LiabilityEntity

| Field | Type | Rules |
|------|------|-------|
| `id` | String | Primary key |
| `historyIdentifier` | String | Stable association key |
| `name` | String | Trimmed, non-empty |
| `amountDecimal` | String | Finite, non-negative canonical decimal |
| `currencyCode` | String | Supported code |
| `categoryRaw` | String | Stable liability raw value |
| `lastUpdatedEpochMs` | Long | UTC mutation time |

### AssetValueSnapshotEntity

| Field | Type | Rules |
|------|------|-------|
| `id` | String | Primary key |
| `assetIdentifier` | String | Index; references stable history ID |
| `assetName` | String | Historical display copy |
| `amountDecimal` | String | Canonical decimal |
| `currencyCode` | String | Stable code |
| `categoryRaw` | String | Historical stable category |
| `recordedAtEpochMs` | Long | Indexed UTC time |
| `isManual` | Boolean | Distinguishes user-authored history |

Insert only when the relevant value changes by at least `0.01`, except explicit
manual history entries.

### NetWorthSnapshotEntity

| Field | Type | Rules |
|------|------|-------|
| `id` | String | Primary key |
| `amountDecimal` | String | Assets minus liabilities |
| `currencyCode` | String | Indexed base currency |
| `recordedAtEpochMs` | Long | Indexed UTC time |
| `historyScopeId` | String | Prevents scope changes appearing as growth |

### PortfolioSnapshotEntity

| Field | Type | Rules |
|------|------|-------|
| `id` | String | Primary key |
| `assetTotalDecimal` | String | Canonical decimal |
| `liabilityTotalDecimal` | String | Canonical decimal |
| `currencyCode` | String | Base currency |
| `recordedAtEpochMs` | Long | UTC time |
| `historyScopeId` | String | Active calculation scope |

### NetWorthGoalEntity

| Field | Type | Rules |
|------|------|-------|
| `stableIdentifier` | String | Primary key; at most one active row |
| `targetAmountDecimal` | String | Finite and positive |
| `currencyCode` | String | Supported code |
| `targetDateEpochDay` | Long | Not before save-day when created/edited |
| `createdAtEpochMs` | Long | UTC time |
| `updatedAtEpochMs` | Long | UTC mutation time |

DAO mutations enforce a singleton transaction and canonicalize imported or
synced duplicates.

### ExchangeRateCacheEntity

| Field | Type | Rules |
|------|------|-------|
| `currencyCode` | String | Primary key; USD always present |
| `rateDecimal` | String | Finite and positive |
| `providerTimestampEpochMs` | Long? | Server/cache timestamp |
| `fetchedAtEpochMs` | Long | Local fetch time |

### MetalPriceCacheEntity

Stores the supported metal/currency quote, price decimal, provider timestamp,
and local fetch time using a composite stable key.

### SyncTombstoneEntity

| Field | Type | Rules |
|------|------|-------|
| `recordType` | String | Composite primary key component |
| `recordId` | String | Composite primary key component |
| `deletedAtEpochMs` | Long | Deletion mutation time |
| `mutationId` | String | Deterministic tie-break |
| `deviceId` | String | Opaque local installation ID |

Tombstones participate in merge and remain until a future retention policy has
proof every supported client checkpoint has observed them.

### SyncRecordMetadataEntity

Tracks record type/ID, last mutation time, mutation ID, device ID, dirty state,
and last confirmed remote generation without duplicating financial fields.

## DataStore Settings

### Synced after explicit opt-in

- Base currency code
- Ordered display currency codes
- Compact-total preference
- Include-ignored-assets preference only if promoted into the cross-device
  contract before implementation

### Always device-local

- Onboarding completion
- Reminder enabled/frequency/time/day
- Notification permission/status
- Sync enabled
- Opaque authorized account profile ID
- Device ID
- Last sync status/error category/checkpoint
- Exchange/metal local refresh metadata not already stored in Room
- Telemetry initialization state

## Sync Envelope Version 1

```text
SyncEnvelope
├── schemaVersion = 1
├── generatedAt
├── writerDeviceId
├── records
│   ├── assets[]
│   ├── liabilities[]
│   ├── assetValueSnapshots[]
│   ├── netWorthSnapshots[]
│   ├── portfolioSnapshots[]
│   └── netWorthGoals[]
├── settings
├── tombstones[]
└── integrity
    ├── recordCount
    └── contentDigest
```

Each record adds `modifiedAt`, `mutationId`, and `deviceId` sync metadata while
retaining its stable product fields.

## Merge State Transitions

```text
disabled
  -> authorizationRequired
  -> initialSync
  -> upToDate

upToDate
  -> pendingLocalChanges
  -> syncing
  -> upToDate

any enabled state
  -> pendingOffline
  -> syncing

any enabled state
  -> pausedAuthorization
  -> authorizationRequired

any enabled state
  -> pausedAccountChange
  -> explicit account decision

syncing
  -> retryableFailure
  -> syncing

syncing
  -> incompatibleRemoteSchema
  -> paused
```

## Prototype Migration

### Room v1 to parity schema

1. Export and test the actual Room v1 schema.
2. Create new canonical columns/tables without deleting the existing asset
   table.
3. Preserve `Asset.id`.
4. Copy valid `amount` REAL values into canonical decimal text.
5. Backfill `historyIdentifier` from the existing ID or a deterministic UUID.
6. Default `isIncludedInPortfolio` to true and `weightUnitRaw` to null.
7. Validate row counts and required fields before committing migration.
8. Enable Room schema export and add migration fixtures to source control.

### DataStore

Preserve `onboarding_completed`, `base_currency`, and `display_currencies`.
Normalize display order and ensure the base currency is present on first read
after upgrade; add new keys without resetting existing values.
