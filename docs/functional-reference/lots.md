# Production Lots

## Overview

Production Lots provide material traceability by assigning lot numbers to batches of parts. Each `LotRecord` ties a quantity of a specific part to its origin (job, production run, or purchase order line) and optionally tracks supplier lot numbers and expiration dates. The traceability query endpoint allows looking up the full chain of a lot -- what jobs used it, where it is stored, what inspections it passed, and where it was purchased from.

This system supports FDA/medical-grade traceability requirements when needed, while remaining low-friction for shops that do not require lot tracking.

**Current status:** Backend-only. Full CRUD and traceability query via API. No dedicated UI page exists yet, though lots are surfaced in the Quality module UI and the Report Builder (entity source `LotRecords`).

## Lot Number Generation

Lot numbers can be provided manually or auto-generated.

### Auto-Generation Format

When no `LotNumber` is provided (or it is blank), the system generates one using the pattern:

```
LOT-{YYYYMMDD}-{NNN}
```

Where:
- `YYYYMMDD` is the current UTC date.
- `NNN` is a zero-padded 3-digit daily sequence counter (counts all lots created with the same date prefix).

Examples: `LOT-20260416-001`, `LOT-20260416-002`, `LOT-20260417-001`

### Manual Lot Numbers

When provided, manual lot numbers are trimmed of whitespace. Max length: 100 characters.

## Entity: `LotRecord`

Extends `BaseAuditableEntity` (includes `Id`, `CreatedAt`, `UpdatedAt`, `DeletedAt`, `DeletedBy`, `CreatedBy`).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `LotNumber` | `string` | Yes (auto-generated if blank) | Unique lot identifier. Max 100 chars. |
| `PartId` | `int` | Yes | FK to `Part`. The part this lot contains. |
| `JobId` | `int?` | No | FK to `Job`. The production job that produced this lot. |
| `ProductionRunId` | `int?` | No | FK to `ProductionRun`. The specific production run within a job. |
| `PurchaseOrderLineId` | `int?` | No | FK to `PurchaseOrderLine`. The PO line this lot was received against (for purchased materials). |
| `Quantity` | `int` | Yes | Number of units in this lot. Must be > 0. |
| `ExpirationDate` | `DateTimeOffset?` | No | Expiration date for perishable or time-sensitive materials. |
| `SupplierLotNumber` | `string?` | No | The supplier's own lot number (for incoming materials). Max 100 chars. |
| `Notes` | `string?` | No | Free-text notes. Max 2000 chars. |

### Navigation Properties

| Property | Type | Description |
|----------|------|-------------|
| `Part` | `Part` | The part this lot contains. |
| `Job` | `Job?` | The producing job (if manufactured in-house). |
| `ProductionRun` | `ProductionRun?` | The production run (if tracked at run level). |
| `PurchaseOrderLine` | `PurchaseOrderLine?` | The PO line (if received from a supplier). |

## Origin Tracking

Each lot can be linked to one or more origins, enabling both "made here" and "bought from supplier" traceability:

| Origin Type | Fields Used | Scenario |
|-------------|-------------|----------|
| In-house production | `JobId`, `ProductionRunId` | Parts manufactured on the shop floor. |
| Purchased material | `PurchaseOrderLineId`, `SupplierLotNumber` | Raw materials or components received from vendors. |
| Mixed | Any combination | A lot may be linked to both a PO line (where material was sourced) and a job (where it was consumed/transformed). |

## Traceability Query

The traceability endpoint provides a complete chain of information for a given lot number:

### Response Structure (`LotTraceabilityResponseModel`)

| Field | Type | Description |
|-------|------|-------------|
| `lotNumber` | `string` | The queried lot number. |
| `partNumber` | `string` | The part number. |
| `partDescription` | `string?` | The part description. |
| `jobs` | `LotTraceJobModel[]` | All jobs linked to this lot number. |
| `productionRuns` | `LotTraceProductionRunModel[]` | All production runs linked to this lot. |
| `purchaseOrders` | `LotTracePurchaseOrderModel[]` | All purchase orders where this lot was received. |
| `binLocations` | `LotTraceBinLocationModel[]` | Current inventory locations (bins) containing this lot. |
| `inspections` | `LotTraceInspectionModel[]` | All QC inspections performed on this lot. |

### Sub-Models

**`LotTraceJobModel`:** `id`, `jobNumber`, `title`

**`LotTraceProductionRunModel`:** `id`, `runNumber`, `status`

**`LotTracePurchaseOrderModel`:** `id`, `poNumber`, `vendorName`

**`LotTraceBinLocationModel`:** `locationId`, `locationName`, `quantity`

**`LotTraceInspectionModel`:** `id`, `status`, `inspectorName`, `createdAt`

### How Traceability Links Are Resolved

1. **Jobs:** All `LotRecord` rows with the same `LotNumber` that have a non-null `JobId`.
2. **Production Runs:** All `LotRecord` rows with the same `LotNumber` that have a non-null `ProductionRunId`.
3. **Purchase Orders:** All `LotRecord` rows with the same `LotNumber` that have a non-null `PurchaseOrderLineId`, resolved through `PurchaseOrderLine` -> `PurchaseOrder` -> `Vendor`.
4. **Bin Locations:** `BinContent` rows where `EntityType = "part"`, `EntityId` matches the lot's `PartId`, and `LotNumber` matches.
5. **QC Inspections:** `QcInspection` rows where `LotNumber` matches.

## Authorization

All endpoints require one of: `Admin`, `Manager`, `Engineer`, or `ProductionWorker` roles.

## API Endpoints

Base path: `/api/v1/lots`

### List Lot Records

```
GET /api/v1/lots
```

**Query parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `partId` | `int?` | Filter by part. |
| `jobId` | `int?` | Filter by producing job. |
| `search` | `string?` | Search across lot number, supplier lot number, and part number. |

**Response:** `200 OK` with `LotRecordResponseModel[]`, ordered by `CreatedAt` descending.

**`LotRecordResponseModel` fields:**

| Field | Type |
|-------|------|
| `id` | `int` |
| `lotNumber` | `string` |
| `partId` | `int` |
| `partNumber` | `string` |
| `partDescription` | `string?` |
| `jobId` | `int?` |
| `jobNumber` | `string?` |
| `productionRunId` | `int?` |
| `purchaseOrderLineId` | `int?` |
| `quantity` | `int` |
| `expirationDate` | `DateTimeOffset?` |
| `supplierLotNumber` | `string?` |
| `notes` | `string?` |
| `createdAt` | `DateTimeOffset` |

### Create Lot Record

```
POST /api/v1/lots
```

**Request body (`CreateLotRecordRequestModel`):**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `lotNumber` | `string?` | No | Auto-generated if blank. Max 100 chars. |
| `partId` | `int` | Yes | Must be > 0. |
| `jobId` | `int?` | No | Link to producing job. |
| `productionRunId` | `int?` | No | Link to production run. |
| `purchaseOrderLineId` | `int?` | No | Link to PO line (for purchased materials). |
| `quantity` | `int` | Yes | Must be > 0. |
| `expirationDate` | `DateTimeOffset?` | No | Expiration date for time-sensitive materials. |
| `supplierLotNumber` | `string?` | No | Supplier's lot number. Max 100 chars. |
| `notes` | `string?` | No | Free-text notes. Max 2000 chars. |

**Response:** `201 Created` with `LotRecordResponseModel`.

### Get Traceability

```
GET /api/v1/lots/{lotNumber}/trace
```

**Path parameter:** `lotNumber` (string) -- the lot number to trace.

**Response:** `200 OK` with `LotTraceabilityResponseModel`.

**Error:** `404 Not Found` if no lot with that number exists.

## Report Builder Integration

Lot Records are available as an entity source (`LotRecords`) in the dynamic Report Builder. The query includes `Part`, `Job`, and `ProductionRun` navigation properties, so fields like `Part.PartNumber`, `Job.JobNumber`, and `ProductionRun.RunNumber` are available.

## Known Limitations

1. **No dedicated UI page.** Lots are API-only with surface-level integration in the Quality module. A future Lots tab or page would provide list/search/trace UI.
2. **No update or delete endpoints.** Once created, lot records are immutable via the API. Changes require direct database modification.
3. **Lot number uniqueness is not enforced.** Multiple `LotRecord` rows can share the same `LotNumber` (this is by design -- a lot can span multiple origins). However, the auto-generation logic uses a daily counter that could produce duplicates under high concurrency (no database-level unique constraint with retry).
4. **No serial number tracking.** Individual unit-level serial numbers within a lot are not tracked. The system operates at the lot/batch level.
5. **No expiration alerts.** Lots with expiration dates do not trigger notifications or scheduled checks when approaching expiry.
6. **No pagination.** The list endpoint returns all matching records. This may need pagination for shops with high lot volume.
7. **No file attachments.** Cannot attach certificates of conformance, material test reports, or other documents to a lot record.
8. **No activity log integration.** Lot creation and traceability queries are not logged in the `ActivityLog` system.
