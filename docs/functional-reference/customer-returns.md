# Customer Returns (RMA)

## Overview

Customer Returns tracks product returns from customers through a structured lifecycle: receive, inspect, optionally rework, resolve, and close. Each return is assigned a sequential RMA number (`RMA-00001`, `RMA-00002`, etc.) and linked to the original job that produced the returned product. When a rework is needed, the system can automatically create a new job linked to the original.

**Current status:** Backend-only. Full CRUD and lifecycle management via API. No dedicated UI page exists yet -- returns are consumed by the Report Builder (entity source `CustomerReturns`) and can be managed via API calls.

## Return Lifecycle

```
Received --> UnderInspection --> ReworkOrdered --> Resolved --> Closed
                            \                 /
                             --> Resolved ----/
```

### Status Enum (`CustomerReturnStatus`)

| Status | Description |
|--------|-------------|
| `Received` | Default status when a return is created. |
| `UnderInspection` | Return is being evaluated for defect/damage. |
| `ReworkOrdered` | A rework job has been created to fix the issue. Set automatically when `CreateReworkJob = true` during creation. |
| `Resolved` | Root cause addressed; any rework is complete. Transition from any non-Closed status. |
| `Closed` | Final state. Can only transition from `Resolved`. Immutable after this point. |

### Lifecycle Rules

- A return starts in `Received` status (or `ReworkOrdered` if `CreateReworkJob` is true).
- Resolving a return is allowed from any status except `Closed`.
- Closing a return is only allowed from `Resolved` status. Attempting to close from any other status returns a `409 Conflict`.
- Returns use soft-delete (`DeletedAt` on `BaseAuditableEntity`), so they are never hard-deleted.

## Entity: `CustomerReturn`

Extends `BaseAuditableEntity` (includes `Id`, `CreatedAt`, `UpdatedAt`, `DeletedAt`, `DeletedBy`, `CreatedBy`).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ReturnNumber` | `string` | Yes (auto-generated) | Sequential RMA number in format `RMA-XXXXX` (zero-padded 5 digits). |
| `CustomerId` | `int` | Yes | FK to `Customer`. The customer returning the product. |
| `OriginalJobId` | `int` | Yes | FK to `Job`. The original production job that created the returned product. |
| `ReworkJobId` | `int?` | No | FK to `Job`. The rework job created to fix the returned product. Null if no rework was requested. |
| `Reason` | `string` | Yes | Free-text reason for the return. Max 1000 characters. |
| `Notes` | `string?` | No | Additional notes. Max 2000 characters. |
| `Status` | `CustomerReturnStatus` | Yes | Current lifecycle status. Default: `Received`. |
| `ReturnDate` | `DateTimeOffset` | Yes | Date the return was received. |
| `InspectedById` | `int?` | No | FK to `ApplicationUser`. The user who inspected the return. |
| `InspectedAt` | `DateTimeOffset?` | No | Timestamp of inspection. |
| `InspectionNotes` | `string?` | No | Notes from the inspection. Max 2000 characters. |

### Navigation Properties

| Property | Type | Description |
|----------|------|-------------|
| `Customer` | `Customer` | The customer who initiated the return. |
| `OriginalJob` | `Job` | The original production job. |
| `ReworkJob` | `Job?` | The rework job (if created). |

## Rework Job Creation

When `CreateReworkJob = true` is passed during creation:

1. A new `Job` is created in the same track type as the original job.
2. The new job starts at the first stage (by sort order) of that track type.
3. The job title is prefixed with `[Rework]` (e.g., `[Rework] Widget Assembly`).
4. The description references the RMA number and reason.
5. Priority is set to `High`.
6. Assignee is copied from the original job.
7. A `JobLink` (type `RelatedTo`) is created between the original and rework jobs.
8. The return status is set to `ReworkOrdered` instead of `Received`.

## Authorization

All endpoints require one of: `Admin`, `Manager`, or `OfficeManager` roles.

## API Endpoints

Base path: `/api/v1/customer-returns`

### List Returns

```
GET /api/v1/customer-returns
```

**Query parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `customerId` | `int?` | Filter by customer. |
| `status` | `CustomerReturnStatus?` | Filter by status (e.g., `Received`, `Resolved`). |

**Response:** `200 OK` with `CustomerReturnListItemModel[]`

| Field | Type |
|-------|------|
| `id` | `int` |
| `returnNumber` | `string` |
| `customerId` | `int` |
| `customerName` | `string` |
| `originalJobId` | `int` |
| `originalJobNumber` | `string` |
| `reworkJobId` | `int?` |
| `reworkJobNumber` | `string?` |
| `status` | `string` |
| `reason` | `string` |
| `returnDate` | `DateTimeOffset` |
| `createdAt` | `DateTimeOffset` |

### Get Return Detail

```
GET /api/v1/customer-returns/{id}
```

**Response:** `200 OK` with `CustomerReturnDetailResponseModel`

Includes all list fields plus: `originalJobTitle`, `notes`, `inspectedById`, `inspectedByName`, `inspectedAt`, `inspectionNotes`, `updatedAt`.

### Create Return

```
POST /api/v1/customer-returns
```

**Request body (`CreateCustomerReturnRequestModel`):**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `customerId` | `int` | Yes | Must be > 0. |
| `originalJobId` | `int` | Yes | Must be > 0. |
| `reason` | `string` | Yes | Not empty, max 1000 chars. |
| `notes` | `string?` | No | Max 2000 chars. |
| `returnDate` | `DateTimeOffset` | Yes | Date the return was received. |
| `createReworkJob` | `bool` | Yes | Whether to auto-create a linked rework job. |

**Response:** `201 Created` with `CustomerReturnListItemModel` and `Location` header.

### Update Return

```
PUT /api/v1/customer-returns/{id}
```

**Request body (`UpdateCustomerReturnRequestModel`):**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `reason` | `string?` | No | Max 1000 chars. Only updates if non-null. |
| `notes` | `string?` | No | Max 2000 chars. Only updates if non-null. |
| `inspectionNotes` | `string?` | No | Max 2000 chars. Only updates if non-null. |

**Response:** `204 No Content`

### Resolve Return

```
POST /api/v1/customer-returns/{id}/resolve
```

Transitions the return to `Resolved` status. Fails with `409` if the return is already `Closed`.

**Response:** `204 No Content`

### Close Return

```
POST /api/v1/customer-returns/{id}/close
```

Transitions the return to `Closed` status. Only allowed from `Resolved` status. Fails with `409` if the return is not in `Resolved` status.

**Response:** `204 No Content`

## Report Builder Integration

Customer Returns are available as an entity source (`CustomerReturns`) in the dynamic Report Builder. The query includes `Customer`, `OriginalJob`, and `ReworkJob` navigation properties, so fields like `Customer.Name`, `OriginalJob.JobNumber`, and `ReworkJob.JobNumber` are available for columns, filters, and grouping.

## Known Limitations

1. **No dedicated UI page.** Returns are API-only. A future UI would likely be a list page with DataTable (similar to other entity list pages) and a detail dialog.
2. **No inspection workflow automation.** The `InspectedById` and `InspectedAt` fields exist but are not automatically set by any endpoint -- they must be set manually via `UpdateReturn` or direct database update.
3. **Status transitions are not fully enforced.** While `Resolve` and `Close` have guards, there is no endpoint to transition to `UnderInspection`. Status changes beyond create/resolve/close require direct entity updates.
4. **No file attachments.** Unlike jobs and other entities, there is no file upload endpoint for attaching photos or documents to a return (e.g., photos of the defect).
5. **No activity log integration.** Changes to returns are not recorded in the `ActivityLog` system.
6. **No SignalR real-time updates.** Changes are not broadcast to connected clients.
7. **No pagination.** The list endpoint returns all matching returns without pagination. This is acceptable for low-volume returns but may need pagination for high-volume shops.
