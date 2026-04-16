# Estimates

## Overview

Estimates are non-binding ballpark figures provided to customers before a formal quote is created. They capture a single dollar amount with a title and description -- not line-itemized like quotes. Estimates live in the `quotes` table and share the `Quote` entity, discriminated by `QuoteType.Estimate`. This design allows a clean conversion path from estimate to formal quote while keeping a single source of truth.

Estimates are accessed exclusively through the Customer detail page (Estimates tab), not from a standalone list page. Each estimate belongs to a single customer.

## Route

Estimates have no dedicated route. They are rendered as a tab within the Customer detail page:

| Path | Component | Context |
|------|-----------|---------|
| `/customers/:id/estimates` | `CustomerEstimatesTabComponent` | Customer detail, Estimates tab |

**Access roles:** Admin, Manager, OfficeManager, PM (inherited from `EstimatesController` authorization).

## API Endpoints

All endpoints are under `/api/v1/estimates`. Authorization requires one of: Admin, Manager, OfficeManager, PM.

### List Estimates

```
GET /api/v1/estimates?customerId={int}&status={QuoteStatus}
```

**Query parameters (all optional):**

| Param | Type | Description |
|-------|------|-------------|
| `customerId` | int | Filter to a specific customer |
| `status` | QuoteStatus | Filter by status (Draft, Sent, Accepted, etc.) |

**Response:** `EstimateListItemModel[]`

```json
[
  {
    "id": 1,
    "customerId": 10,
    "customerName": "Acme Corp",
    "title": "Prototype Bracket Assembly",
    "estimatedAmount": 4500.00,
    "status": "Draft",
    "validUntil": "2026-06-01T00:00:00Z",
    "generatedQuoteId": null,
    "assignedToName": "Hartman, Daniel J",
    "createdAt": "2026-04-10T14:30:00Z"
  }
]
```

Results are ordered by `CreatedAt` descending. Uses `AsNoTracking()` for read performance.

### Get Estimate Detail

```
GET /api/v1/estimates/{id}
```

**Response:** `EstimateDetailResponseModel`

```json
{
  "id": 1,
  "customerId": 10,
  "customerName": "Acme Corp",
  "title": "Prototype Bracket Assembly",
  "description": "Rough estimate for 50-unit run of aluminum brackets with anodize finish.",
  "estimatedAmount": 4500.00,
  "status": "Draft",
  "validUntil": "2026-06-01T00:00:00Z",
  "notes": "Customer requested by end of Q2.",
  "assignedToId": 5,
  "assignedToName": "Hartman, Daniel J",
  "generatedQuoteId": null,
  "convertedAt": null,
  "createdAt": "2026-04-10T14:30:00Z",
  "updatedAt": "2026-04-10T14:30:00Z"
}
```

Returns 404 if not found, deleted, or if the record is not of type `Estimate`.

### Create Estimate

```
POST /api/v1/estimates
```

**Request body:** `CreateEstimateRequestModel`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `customerId` | int | Yes | Must be > 0; customer must exist |
| `title` | string | Yes | Non-empty, max 300 characters |
| `description` | string | No | Max 2000 characters |
| `estimatedAmount` | decimal | Yes | Must be >= 0 |
| `validUntil` | DateTimeOffset | No | ISO 8601 with UTC timezone |
| `notes` | string | No | Max 2000 characters |
| `assignedToId` | int | No | User ID to assign |

**Response:** 201 Created with `EstimateListItemModel` body and `Location` header pointing to the new resource.

The created record has `Type = Estimate` and `Status = Draft`.

### Update Estimate

```
PUT /api/v1/estimates/{id}
```

**Request body:** `UpdateEstimateRequestModel`

All fields are optional (partial update pattern -- only provided fields are applied):

| Field | Type | Validation |
|-------|------|------------|
| `title` | string | Max 300 characters |
| `description` | string | Max 2000 characters |
| `estimatedAmount` | decimal | Must be >= 0 |
| `status` | QuoteStatus | Valid enum value |
| `validUntil` | DateTimeOffset | ISO 8601 with UTC timezone |
| `notes` | string | Max 2000 characters |
| `assignedToId` | int | User ID (always applied, even if null -- clears assignment) |

**Response:** 204 No Content.

Returns 404 if not found, deleted, or not of type `Estimate`.

### Delete Estimate

```
DELETE /api/v1/estimates/{id}
```

Soft-deletes the estimate by setting `DeletedAt` to the current UTC time. Returns 404 if not found or already deleted.

**Response:** 204 No Content.

### Convert Estimate to Quote

```
POST /api/v1/estimates/{id}/convert
```

Converts the estimate into a formal `Quote`-type record. See the Conversion Workflow section below for details.

**Response:** 200 OK with `QuoteListItemModel` body representing the newly created quote.

**Error conditions:**
- 404 if estimate not found, deleted, or not of type `Estimate`
- 409 (InvalidOperationException) if estimate has already been converted (a `GeneratedQuote` navigation already exists)

## List View (Customer Estimates Tab)

The estimates tab within Customer detail displays a `DataTableComponent` with `tableId="customer-estimates"`.

### Columns

| Field | Header | Sortable | Filterable | Type | Width | Align |
|-------|--------|----------|------------|------|-------|-------|
| `title` | Title | Yes | No | text | auto | left |
| `estimatedAmount` | Amount | Yes | No | number | 120px | right |
| `status` | Status | Yes | Yes (enum) | enum | 110px | left |
| `validUntil` | Valid Until | Yes | No | date | 110px | left |
| `createdAt` | Created | Yes | No | date | 100px | left |
| `actions` | (none) | No | No | -- | 100px | left |

### Custom Cell Rendering

- **Amount:** Formatted with `CurrencyPipe` (`$X,XXX.XX`).
- **Status:** Rendered as a colored chip. Color mapping:
  - Draft: `chip--muted` (gray)
  - Sent: `chip--info` (blue)
  - Accepted: `chip--success` (green)
  - Declined: `chip--error` (red)
  - Expired: `chip--warning` (yellow/orange)
  - ConvertedToQuote: `chip--primary` (primary brand color)
- **Valid Until / Created:** Formatted as `MM/dd/yyyy`.
- **Actions:** Two icon buttons per row:
  - **Convert to Quote** (`forward` icon) -- visible only when `generatedQuoteId` is null (not yet converted). Opens a confirmation dialog before converting.
  - **Delete** (`delete` icon, danger style) -- opens a confirmation dialog before soft-deleting.

### Row Interaction

Rows are clickable (`[clickableRows]="true"`). Clicking a row opens the edit dialog pre-populated with the estimate's data.

### Empty State

Icon: `request_quote`. Message: "No estimates yet".

### Toolbar

The tab has a right-aligned toolbar containing a single "New Estimate" button (`action-btn--primary` with `add` icon).

## Create / Edit Dialog

Both create and edit use the same `<app-dialog>` instance toggled by the `showDialog` signal. The dialog title changes dynamically: "New Estimate" for create, "Edit Estimate" for edit.

**Dialog width:** 520px (medium).

### Form Fields

| Field | Label | Component | FormControl | Required | Validation | Notes |
|-------|-------|-----------|-------------|----------|------------|-------|
| Title | Title | `<app-input>` | `title` | Yes | Non-empty, max 300 chars | Free-text title for the estimate |
| Description | Description | `<app-textarea>` | `description` | No | -- | 2 rows; longer description of scope |
| Estimated Amount | Estimated Amount | `<app-input>` | `estimatedAmount` | Yes | >= 0 | `mask="currency"`, `prefix="$"` |
| Valid Until | Valid Until | `<app-datepicker>` | `validUntil` | No | -- | Expiration date for the estimate |
| Status | Status | `<app-select>` | `status` | No | -- | Only shown in edit mode; options: Draft, Sent, Accepted, Declined, Expired |
| Notes | Notes | `<app-textarea>` | `notes` | No | -- | 2 rows; internal notes |

**Layout:** Title and Description are full-width. Estimated Amount and Valid Until are side-by-side in a `dialog-row`. Status (edit only) is full-width. Notes is full-width at the bottom.

### Form Behavior

- **Create mode:** Form resets to defaults (`estimatedAmount: 0`, `status: Draft`). `customerId` is automatically set from the parent customer context.
- **Edit mode:** Form patches with the selected estimate's current values. `Status` select appears only in edit mode, allowing manual status changes.
- **Validation popover:** Submit button shows a popover on hover listing violations (Title required, Estimated Amount required).
- **Submit button:** Disabled when form is invalid or save is in progress.
- **On successful save:** Dialog closes, estimate list reloads, snackbar confirmation ("Estimate created" or "Estimate updated").

## Status Lifecycle

Estimates share the `QuoteStatus` enum with Quotes, but only use a subset of the values.

### Status Values Used by Estimates

| Status | Meaning | Transition From |
|--------|---------|-----------------|
| `Draft` | Initial state; estimate is being prepared | (creation) |
| `Sent` | Estimate has been communicated to the customer | Draft (manual) |
| `Accepted` | Customer has indicated interest | Sent (manual) |
| `Declined` | Customer declined the estimate | Sent (manual) |
| `Expired` | Estimate validity period has passed | Any (manual) |
| `ConvertedToQuote` | Estimate was converted to a formal Quote | Any non-converted (via convert action) |

### Transition Rules

Status transitions on estimates are **not server-enforced** -- the update endpoint accepts any `QuoteStatus` value. Transitions are managed through the UI:

- The **edit dialog** exposes a Status dropdown with options: Draft, Sent, Accepted, Declined, Expired.
- The **Convert to Quote** action (via the row action button) sets the status to `ConvertedToQuote` automatically and cannot be manually selected.

### Terminal States

- `ConvertedToQuote` -- estimate has been converted; the `generatedQuoteId` field links to the resulting Quote. The convert button is hidden once this is set.

## Conversion Workflow: Estimate to Quote

Converting an estimate creates a new `Quote`-type record linked back to the original estimate.

### User Flow

1. User clicks the **forward** icon button on an estimate row (visible only if `generatedQuoteId` is null).
2. A confirmation dialog appears: "Convert to Quote? Convert '[title]' to a formal quote? The estimate will be marked as Accepted."
3. On confirmation, `POST /api/v1/estimates/{id}/convert` is called.
4. The estimate list reloads. A snackbar shows "Created quote Q-XXXX".

### Server-Side Behavior (`ConvertEstimateToQuoteHandler`)

1. Loads the estimate with `Customer` and `GeneratedQuote` includes.
2. Validates: must exist, must be of type `Estimate`, must not be deleted.
3. Validates: `GeneratedQuote` must be null (prevents double conversion).
4. Generates a new sequential quote number via `IQuoteRepository.GenerateNextQuoteNumberAsync()`.
5. Creates a new `Quote` record:
   - `Type = Quote`
   - `QuoteNumber` = generated number
   - `CustomerId` = same as estimate
   - `Status = Draft`
   - `Notes` = estimate's `Description` (falls back to `Notes` if description is null)
   - `ExpirationDate` = same as estimate
   - `TaxRate = 0`
   - `SourceEstimateId` = estimate's ID
6. Sets the estimate's `Status = ConvertedToQuote` and `ConvertedAt` = current UTC time.
7. Saves both records in a single transaction.

### What Carries Over

| Estimate Field | Quote Field | Notes |
|----------------|-------------|-------|
| `CustomerId` | `CustomerId` | Same customer |
| `Description` or `Notes` | `Notes` | Description preferred; falls back to Notes |
| `ExpirationDate` | `ExpirationDate` | Copied as-is |
| `Id` | `SourceEstimateId` | Bidirectional FK link |

### What Does NOT Carry Over

- `EstimatedAmount` -- the quote starts with zero line items; the user must add them manually.
- `Title` -- quotes use `QuoteNumber` instead of a free-text title.
- `AssignedToId` -- not copied to the new quote.
- `Status` -- the new quote always starts as `Draft`.

## Data Model

Estimates use the `Quote` entity with `Type = Estimate`. Estimate-specific fields:

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | int | No | Auto-increment PK |
| `type` | QuoteType | No | Always `Estimate` for estimates |
| `customer_id` | int (FK) | No | Link to `customers` table |
| `status` | QuoteStatus | No | Current lifecycle status |
| `title` | string | Yes | Human-readable title (estimate-specific) |
| `description` | string | Yes | Scope description (estimate-specific) |
| `estimated_amount` | decimal | Yes | Single ballpark dollar amount (estimate-specific) |
| `expiration_date` | timestamptz | Yes | Validity expiration |
| `notes` | string | Yes | Internal notes |
| `assigned_to_id` | int (FK) | Yes | Assigned user |
| `converted_at` | timestamptz | Yes | When converted to quote |
| `created_at` | timestamptz | No | Auto-set on insert |
| `updated_at` | timestamptz | No | Auto-set on insert/update |
| `deleted_at` | timestamptz | Yes | Soft-delete timestamp |

**Unused fields** (always null/default for estimates): `quote_number`, `shipping_address_id`, `sent_date`, `accepted_date`, `tax_rate`, `external_id`, `external_ref`, `provider`.

### Navigations

- `Customer` -- the associated customer (required).
- `GeneratedQuote` -- the `Quote`-type record created from this estimate (via `SourceEstimateId` self-FK, inverse navigation).

## Permissions

| Action | Roles |
|--------|-------|
| View estimates | Admin, Manager, OfficeManager, PM |
| Create estimate | Admin, Manager, OfficeManager, PM |
| Edit estimate | Admin, Manager, OfficeManager, PM |
| Delete estimate | Admin, Manager, OfficeManager, PM |
| Convert to quote | Admin, Manager, OfficeManager, PM |

Engineers and Production Workers do not have access to the estimates API.

## Known Limitations

1. **No standalone list page.** Estimates are only accessible through the Customer detail Estimates tab. There is no cross-customer estimate listing or global search for estimates.
2. **No server-side status transition enforcement.** The API accepts any valid `QuoteStatus` value on update without validating the transition (e.g., Draft to ConvertedToQuote via PUT is technically possible).
3. **No pagination.** The list endpoint returns all estimates for a customer. Acceptable for typical volumes but could become an issue for customers with hundreds of estimates.
4. **No assignee in the customer tab.** The `assignedToId` / `assignedToName` fields exist in the API response model but the Customer Estimates tab UI does not display or set the assignee.
5. **Conversion is one-way.** Once an estimate is converted to a quote, the conversion cannot be undone. The estimate is permanently marked `ConvertedToQuote`.
6. **No amount carried to quote lines.** The `estimatedAmount` is not pre-populated on the generated quote -- the user must manually add line items after conversion.
7. **No expiration automation.** Estimates are not automatically marked `Expired` when their `validUntil` date passes. Expiration must be set manually via the status dropdown.
8. **Description field not loaded in edit mode.** The edit dialog patches from the `Estimate` list model (which lacks `description`), not the detail model. This means description edits require the user to re-enter the full text.
