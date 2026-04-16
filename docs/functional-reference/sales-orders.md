# Sales Orders

## Overview

Sales Orders represent confirmed customer commitments to purchase goods. They are the central entity in the quote-to-cash flow, linking upstream quotes to downstream production (jobs), fulfillment (shipments), and billing (invoices). A sales order captures what a customer has ordered, at what price, and tracks fulfillment progress at the line-item level.

**Quote-to-cash flow:**
Quote (accepted) --> Sales Order (confirmed) --> Job (production) --> Shipment (fulfillment) --> Invoice (billing) --> Payment (collection)

Sales orders can be created directly or converted from an accepted quote. Each sales order contains one or more line items, each tied to a part in the catalog. Line items track shipped vs. remaining quantities to support partial delivery workflows.

---

## Routes & Navigation

| Route | Component | Description |
|-------|-----------|-------------|
| `/sales-orders` | `SalesOrdersComponent` | Sales order list page |

The feature is lazy-loaded via `loadChildren` in `app.routes.ts`. The route configuration is a single flat route (no sub-routes or tab segments).

**Detail view:** Sales order details open as a `MatDialog` via `DetailDialogService`, not as a separate route. The URL updates to `?detail=sales-order:{id}` when a detail dialog is open. On page load, if this query parameter is present, the detail dialog auto-opens for the specified order.

**Sidebar navigation:** Sales Orders appears in the main application sidebar under the order management group.

---

## Access & Permissions

Sales Orders requires one of the following roles:

| Role | Access |
|------|--------|
| Admin | Full CRUD, confirm, cancel, delete |
| Manager | Full CRUD, confirm, cancel, delete |
| PM | Full CRUD, confirm, cancel, delete |
| Office Manager | Full CRUD, confirm, cancel, delete |

The route is protected by `roleGuard('Admin', 'Manager', 'PM', 'OfficeManager')` on the client side and `[Authorize(Roles = "Admin,Manager,OfficeManager,PM")]` on the API controller.

Users with Engineer or Production Worker roles cannot access sales orders.

---

## Sales Order List

The list page displays all sales orders in a `DataTableComponent` with `tableId="sales-orders"`. Column preferences (visibility, order, width) are persisted per user.

### Columns

| Field | Header | Sortable | Filterable | Type | Width | Align | Custom Cell |
|-------|--------|----------|------------|------|-------|-------|-------------|
| `orderNumber` | Order # | Yes | No | text | 120px | left | Monospace, bold (`so-number` class) |
| `customerName` | Customer | Yes | No | text | auto | left | Plain text |
| `customerPO` | Cust. PO | Yes | No | text | 100px | left | Muted text, dash when null |
| `status` | Status | Yes | Yes | enum | 140px | left | Colored chip (see Status Chips) |
| `lineCount` | Lines | Yes | No | text | 70px | center | Plain number |
| `total` | Total | Yes | No | text | 100px | right | Currency formatted |
| `requestedDeliveryDate` | Delivery | Yes | No | date | 110px | left | `MM/dd/yyyy`, dash when null |
| `createdAt` | Created | Yes | No | date | 110px | left | `MM/dd/yyyy` |

### Status Chips

| Status | Chip Class | Color |
|--------|-----------|-------|
| Draft | `chip--muted` | Gray |
| Confirmed | `chip--primary` | Primary blue |
| InProduction | `chip--info` | Info blue |
| PartiallyShipped | `chip--warning` | Warning yellow |
| Shipped | `chip--success` | Success green |
| Completed | `chip--success` | Success green |
| Cancelled | `chip--error` | Error red |

### Filters

Three filter controls appear in a horizontal bar above the data table:

| Filter | Control | Type | Behavior |
|--------|---------|------|----------|
| Search | `<app-input>` | Text | Filters by search term. Applied on Enter keypress. Passed as `search` query param to API. |
| Customer | `<app-select>` | Dropdown | Options: "All Customers" (null) + all active customers loaded from `CustomerService`. Passed as `customerId` query param. |
| Status | `<app-select>` | Dropdown | Options: "All Statuses" (null), Draft, Confirmed, In Production, Partially Shipped, Shipped, Completed, Cancelled. Passed as `status` query param. |

Filter changes do not auto-apply. The search field triggers `applyFilters()` on Enter. The customer and status dropdowns require the user to press Enter in the search field or otherwise trigger a reload.

### Empty State

When no sales orders match the current filters, the DataTable displays an empty state with the `receipt_long` icon and a "No orders found" message.

### Row Interaction

Rows are clickable (`[clickableRows]="true"`). Clicking a row opens the sales order detail dialog.

---

## Sales Order Detail

The detail view is rendered inside a `MatDialog` via `SalesOrderDetailDialogComponent`, which wraps `SalesOrderDetailPanelComponent`. The dialog uses the `DetailDialogService` pattern, syncing `?detail=sales-order:{id}` to the URL.

### Header

- **Icon:** `receipt_long` (Material Icons Outlined), muted color
- **Order number:** Bold, primary text
- **Customer name:** Below the order number, muted text, rendered as an `<app-entity-link>` navigating to the customer detail
- **Close button:** Icon button (`close` icon) in the top-right corner

### Info Grid -- Status & Details

A 2-column grid displaying the following fields (conditionally rendered):

| Field | Label | Always Shown | Notes |
|-------|-------|-------------|-------|
| Status | Status | Yes | Colored chip matching the list view |
| Customer PO | Customer PO | Only if present | Plain text |
| Quote | Quote | Only if `quoteNumber` present | Rendered as `<app-entity-link>` to the originating quote |
| Credit Terms | Credit Terms | Only if present | String value (e.g., "Net30") |
| Requested Delivery | Requested Delivery | Only if present | `MM/dd/yyyy` format |
| Confirmed Date | Confirmed | Only if present | `MM/dd/yyyy` format. Set when the order transitions from Draft to Confirmed. |

### Barcode Section

A `<app-barcode-info>` component displays a barcode for the sales order, using `entityType="SalesOrder"`, compact mode. The barcode is auto-generated on order creation via `IBarcodeService`.

### Totals Grid

A 2-column grid showing financial summary:

| Field | Label | Format |
|-------|-------|--------|
| Subtotal | Subtotal | Currency |
| Tax | Tax ({taxRate}%) | Currency. Shows the tax rate percentage in the label. |
| Total | Total | Currency, bold |

### Notes

Displayed only when `notes` is non-null. Rendered with `white-space: pre-wrap` to preserve line breaks.

### Line Items Table

Displays all line items with fulfillment tracking columns. Table has `aria-label="Sales order line items"`.

| Column | Header | Align | Format |
|--------|--------|-------|--------|
| Part # | Part # | left | Monospace. Dash when null (non-catalog line). |
| Description | Description | left | Plain text |
| Qty | Qty | right | Integer |
| Shipped | Shipped | right | Integer. Green text when fully shipped. Warning/yellow text when partially shipped. |
| Remaining | Remaining | right | Integer. Computed: `quantity - shippedQuantity`. |
| Unit Price | Unit Price | right | Currency |
| Total | Total | right | Currency. Computed: `quantity * unitPrice`. |

### Timestamps

A 2-column grid at the bottom shows:

| Field | Format |
|-------|--------|
| Created | `MM/dd/yyyy` |
| Updated | `MM/dd/yyyy` |

### Activity Section

An `<app-entity-activity-section>` component renders the chronological activity log for the sales order (`entityType="SalesOrder"`).

---

## Create Sales Order

The create dialog is rendered by `SoDialogComponent` as an `<app-dialog>` with `width="1100px"` and `[splitLayout]="true"`. The dialog uses a two-panel layout: line items on the left (main area), order details on the right (sidebar).

### Draft Support

The dialog supports form draft auto-save via `DraftConfig`:
- **Entity type:** `sales-order`
- **Entity ID:** `new`
- **Route:** `/sales-orders`
- **Snapshot includes:** All form fields plus the `lines` array

### Form Fields (Sidebar -- Order Details)

| Field | Label | Control | Type | Required | Validation | data-testid |
|-------|-------|---------|------|----------|-----------|-------------|
| Customer | Customer | `<app-select>` | Dropdown | Yes | `Validators.required`. Options loaded from `CustomerService.getCustomers()`. First option is "Select Customer" (null). | `so-customer` |
| Customer PO | Customer PO | `<app-input>` | Text | No | None | `so-customer-po` |
| Credit Terms | Credit Terms | `<app-select>` | Dropdown | No | None. Options from `CREDIT_TERMS_OPTIONS`: None, Due on Receipt, Net 15, Net 30, Net 45, Net 60, Net 90. | `so-credit-terms` |
| Requested Delivery Date | Requested Delivery Date | `<app-datepicker>` | Date | No | None | `so-delivery-date` |
| Tax Rate | Tax Rate | `<app-input>` | Number | Yes | `Validators.required`, `Validators.min(0)`. Displayed with `%` suffix. | `so-tax-rate` |

### Notes Section (Sidebar)

| Field | Label | Control | Rows | data-testid |
|-------|-------|---------|------|-------------|
| Notes | (section title only) | `<app-textarea>` | 3 | `so-notes` |

### Summary Section (Sidebar)

Three computed read-only rows:

| Row | Computation |
|-----|-------------|
| Subtotal | Sum of all line totals (`quantity * unitPrice` per line) |
| Tax ({rate}%) | `taxRate / 100 * subtotal`. The rate value updates reactively from the tax rate form control. |
| **Total** | `subtotal + taxAmount`. Displayed with bold styling. |

### Line Items Section (Main Area)

#### Existing Lines Table

When one or more lines have been added, they appear in a table with these columns:

| Column | Align | Format |
|--------|-------|--------|
| Part # | left | Monospace |
| Description | left | Plain text |
| Qty | right | Integer |
| Unit Price | right | Currency |
| Total | right | Currency (`quantity * unitPrice`) |
| Actions | -- | Remove button (red `close` icon, tooltip "Remove") |

When no lines exist, a "No lines yet" empty message is displayed.

#### Add Line Form

A 4-column inline form below the lines table:

| Field | Label | Control | Required | Validation | data-testid |
|-------|-------|---------|----------|-----------|-------------|
| Part | Part | `<app-autocomplete>` | Yes | `Validators.required`. Options: active parts from `PartsService.getParts('Active')`. Display format: `{partNumber} -- {description}`. | `so-line-part` |
| Qty | Qty | `<app-input>` | Yes | `Validators.required`, `Validators.min(1)`. Default: 1. | `so-line-qty` |
| Unit Price | Price | `<app-input>` | Yes | `Validators.required`, `Validators.min(0)`. Default: 0. | `so-line-price` |

The "Add" button (`so-add-line-btn`) is disabled when the line form is invalid. On click, the part is resolved from the parts list, a new `LineEntry` is appended to the lines signal, and the line form resets to defaults.

### Footer Buttons

| Button | Style | Icon | Disabled When | Action |
|--------|-------|------|---------------|--------|
| Cancel | `action-btn` | -- | Never | Emits `closed` output, closes the dialog |
| Create Order | `action-btn--primary` | `save` | Form invalid, no lines, or saving in progress | Submits the sales order. Shows validation popover on hover when disabled. |

### Validation Popover

The save button uses `[appValidationPopover]="violations"` which combines:
- Standard form field violations (Customer is required, Tax Rate >= 0)
- Custom violation: "At least one line item is required" when the lines array is empty

### On Save

1. Constructs `CreateSalesOrderRequest` with form values and line items
2. Dates converted via `toIsoDate()`
3. Calls `SalesOrderService.createSalesOrder()`
4. On success: clears the draft, shows success snackbar, emits `saved` output
5. The parent component closes the dialog and reloads the list

---

## Edit Sales Order

The current UI does not expose an inline edit dialog. The `UpdateSalesOrder` API endpoint exists and accepts changes to header-level fields (shipping/billing address, credit terms, delivery date, customer PO, notes, tax rate). The detail panel emits an `editRequested` output with the full `SalesOrderDetail`, but no edit dialog component is currently implemented in the UI.

**API constraint:** Updates are only allowed on orders with `Draft` or `Confirmed` status. Attempting to update an order in any other status returns an `InvalidOperationException`.

---

## Line Items

### Data Model

Each `SalesOrderLine` has:

| Field | Type | Description |
|-------|------|-------------|
| `id` | int | Primary key |
| `partId` | int? | FK to Part. Null for non-catalog (custom description) lines. |
| `partNumber` | string? | Denormalized from Part for display. |
| `description` | string | Line item description. Required. |
| `quantity` | int | Ordered quantity. Must be > 0. |
| `unitPrice` | decimal | Price per unit. Must be >= 0. |
| `lineTotal` | decimal | Computed: `quantity * unitPrice`. |
| `lineNumber` | int | Sequential position within the order. Auto-assigned on creation. |
| `shippedQuantity` | int | Total units shipped across all linked shipment lines. |
| `remainingQuantity` | int | Computed: `quantity - shippedQuantity`. |
| `isFullyShipped` | bool | Computed: `shippedQuantity >= quantity`. |
| `notes` | string? | Optional per-line notes. |
| `uomId` | int? | FK to UnitOfMeasure. |

### Adding Lines (Create Dialog)

Lines are added client-side during order creation. The autocomplete searches active parts. On add, the part number and description are copied from the selected part. The line form resets for the next entry.

Lines cannot be added to an existing order through the current UI.

### Removing Lines (Create Dialog)

Each line has a remove button (red `close` icon) that removes it from the local array by index. This is only available during creation; lines cannot be removed from an existing order through the current UI.

---

## Fulfillment Tracking

Sales order lines track fulfillment through the `shippedQuantity` field, which is updated when shipment lines reference the sales order line.

### How Shipments Link to SO Lines

`ShipmentLine` entities have a FK relationship to `SalesOrderLine` via the `ShipmentLines` navigation property on `SalesOrderLine`. When a shipment is created against a sales order, each shipment line references the specific SO line being fulfilled and specifies the quantity shipped.

### Partial Delivery

- A single SO line can be fulfilled by multiple shipment lines across multiple shipments.
- `shippedQuantity` accumulates across all linked shipment lines.
- `remainingQuantity` = `quantity - shippedQuantity` shows what is still outstanding.
- The SO status progresses: `Confirmed` --> `PartiallyShipped` (some lines partially shipped) --> `Shipped` (all lines fully shipped).

### Visual Indicators

In the detail panel line items table:
- **Fully shipped:** The shipped quantity displays in green text (`text-success` class).
- **Partially shipped:** The shipped quantity displays in yellow/warning text (`text-warning` class).
- **Not shipped:** The shipped quantity displays in default text color (value is 0).

---

## Job Linking

Sales order lines can be linked to production jobs. The `SalesOrderLine` entity has a `Jobs` navigation property (`ICollection<Job>`). When a job is created from a sales order line, the job's `SalesOrderLineId` FK references the SO line.

This linkage enables:
- Tracking which jobs are in production for a given order
- Moving a job to the "Shipped" kanban stage can update SO fulfillment status
- Cross-entity navigation via `<app-entity-link>`

---

## Invoice Generation

Sales orders have a `Invoices` navigation property (`ICollection<Invoice>`). Invoices can be generated from sales orders, referencing the SO for billing context. Invoice generation is handled through the Invoices feature, not directly from the Sales Orders UI.

**Accounting boundary note:** Invoice CRUD is an accounting-bounded feature (standalone mode only). When a QuickBooks or other accounting provider is connected, invoices are managed in the external system.

---

## Entity Links

The detail panel uses `<app-entity-link>` for cross-entity navigation:

| Link | Type | Location | Behavior |
|------|------|----------|----------|
| Customer name | `customer` | Detail header | Navigates to customer detail page at `/customers/{id}/overview` |
| Quote number | `quote` | Info grid | Opens quote detail dialog via `?detail=quote:{id}`. Only shown when the SO originated from a quote. |

---

## Every Button & Action

### List Page

| Button | Location | Style | Icon | Behavior |
|--------|----------|-------|------|----------|
| New Order | Page header | `action-btn--primary` | `add` | Opens the create sales order dialog |

### Create Dialog

| Button | Location | Style | Icon | Disabled When | Behavior |
|--------|----------|-------|------|---------------|----------|
| Add (line) | Add line form | `action-btn--sm` | `add` | Line form invalid | Adds the line entry to the local array |
| Remove (line) | Per-line row | `icon-btn--danger` | `close` | Never | Removes the line from the array by index |
| Cancel | Dialog footer | `action-btn` | -- | Never | Closes the dialog without saving |
| Create Order | Dialog footer | `action-btn--primary` | `save` | Form invalid, no lines, or saving | Creates the sales order via API |

### Detail Dialog

| Button | Location | Style | Icon | Shown When | Confirmation | Behavior |
|--------|----------|-------|------|-----------|--------------|----------|
| Close | Header | `icon-btn` | `close` | Always | No | Closes the dialog |
| Confirm | Actions area | `action-btn--primary` | `check_circle` | Status = Draft | No | Transitions order to Confirmed status. Sets `confirmedDate`. |
| Cancel | Actions area | `action-btn` | `block` | Status = Draft or Confirmed | Yes (ConfirmDialog, severity: warn) | Transitions order to Cancelled status. |
| Delete | Actions area | `action-btn--danger` | `delete` | Status = Draft | Yes (ConfirmDialog, severity: danger) | Soft-deletes the order (`DeletedAt` timestamp). Closes dialog. |

### Action State Rules

| Current Status | Confirm | Cancel | Delete |
|---------------|---------|--------|--------|
| Draft | Enabled | Enabled | Enabled |
| Confirmed | Hidden | Enabled | Hidden |
| InProduction | Hidden | Hidden | Hidden |
| PartiallyShipped | Hidden | Hidden | Hidden |
| Shipped | Hidden | Hidden | Hidden |
| Completed | Hidden | Hidden | Hidden |
| Cancelled | Hidden | Hidden | Hidden |

---

## API Endpoints

All endpoints are under `/api/v1/orders` and require authentication with one of the authorized roles.

### GET /api/v1/orders

List all sales orders with optional filters.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `customerId` | int | No | Filter by customer ID |
| `status` | string (SalesOrderStatus) | No | Filter by status |

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "orderNumber": "SO-0001",
    "customerId": 5,
    "customerName": "Acme Corp",
    "status": "Confirmed",
    "customerPO": "PO-12345",
    "lineCount": 3,
    "total": 15750.00,
    "requestedDeliveryDate": "2026-05-15T00:00:00Z",
    "createdAt": "2026-04-01T14:30:00Z"
  }
]
```

### GET /api/v1/orders/{id}

Get full details for a single sales order including line items.

**Response:** `200 OK`

```json
{
  "id": 1,
  "orderNumber": "SO-0001",
  "customerId": 5,
  "customerName": "Acme Corp",
  "quoteId": 12,
  "quoteNumber": "Q-0012",
  "shippingAddressId": 3,
  "billingAddressId": 4,
  "status": "Confirmed",
  "creditTerms": "Net30",
  "confirmedDate": "2026-04-02T10:00:00Z",
  "requestedDeliveryDate": "2026-05-15T00:00:00Z",
  "customerPO": "PO-12345",
  "notes": "Rush order -- expedite production",
  "taxRate": 0.075,
  "subtotal": 14651.16,
  "taxAmount": 1098.84,
  "total": 15750.00,
  "lines": [
    {
      "id": 1,
      "partId": 42,
      "partNumber": "CNC-HSG-001",
      "description": "CNC Housing Assembly",
      "quantity": 100,
      "unitPrice": 125.00,
      "lineTotal": 12500.00,
      "lineNumber": 1,
      "shippedQuantity": 50,
      "remainingQuantity": 50,
      "isFullyShipped": false,
      "notes": null
    }
  ],
  "createdAt": "2026-04-01T14:30:00Z",
  "updatedAt": "2026-04-10T09:15:00Z"
}
```

**Error:** `404 Not Found` if the order does not exist or is soft-deleted.

### POST /api/v1/orders

Create a new sales order.

**Request Body:**

```json
{
  "customerId": 5,
  "quoteId": null,
  "shippingAddressId": null,
  "billingAddressId": null,
  "creditTerms": "Net30",
  "requestedDeliveryDate": "2026-05-15T00:00:00Z",
  "customerPO": "PO-12345",
  "notes": "Rush order",
  "taxRate": 0.075,
  "lines": [
    {
      "partId": 42,
      "description": "CNC Housing Assembly",
      "quantity": 100,
      "unitPrice": 125.00,
      "notes": null
    }
  ]
}
```

**Validation Rules (FluentValidation):**

| Field | Rule |
|-------|------|
| `customerId` | Must be > 0 |
| `lines` | Must not be empty ("At least one line item is required") |
| `taxRate` | Must be >= 0 and < 1 (decimal, e.g., 0.075 for 7.5%) |
| `lines[].description` | Must not be empty |
| `lines[].quantity` | Must be > 0 |
| `lines[].unitPrice` | Must be >= 0 |

**Response:** `201 Created` with `Location` header pointing to the new order.

```json
{
  "id": 1,
  "orderNumber": "SO-0001",
  "customerId": 5,
  "customerName": "Acme Corp",
  "status": "Draft",
  "customerPO": "PO-12345",
  "lineCount": 1,
  "total": 12500.00,
  "requestedDeliveryDate": "2026-05-15T00:00:00Z",
  "createdAt": "2026-04-16T12:00:00Z"
}
```

**Side effects:**
- Order number auto-generated via `ISalesOrderRepository.GenerateNextOrderNumberAsync()` (format: `SO-XXXX`)
- Initial status is `Draft`
- Line numbers are auto-assigned sequentially starting at 1
- A barcode is auto-created via `IBarcodeService` for the new order

### PUT /api/v1/orders/{id}

Update header-level fields on an existing sales order.

**Constraint:** Only `Draft` or `Confirmed` orders can be updated. Returns `InvalidOperationException` (409) otherwise.

**Request Body:**

```json
{
  "shippingAddressId": 3,
  "billingAddressId": 4,
  "creditTerms": "Net45",
  "requestedDeliveryDate": "2026-06-01T00:00:00Z",
  "customerPO": "PO-12345-REV",
  "notes": "Updated notes",
  "taxRate": 0.08
}
```

All fields are optional. Only provided fields are updated (null/missing fields are not cleared).

**Validation Rules (FluentValidation):**

| Field | Rule |
|-------|------|
| `shippingAddressId` | Must be > 0 when provided |
| `billingAddressId` | Must be > 0 when provided |
| `creditTerms` | Max 50 characters when provided |
| `customerPO` | Max 100 characters when provided |
| `notes` | Max 2000 characters when provided |
| `taxRate` | Must be between 0 and 1 (inclusive) when provided |

**Response:** `204 No Content`

### POST /api/v1/orders/{id}/confirm

Transition a sales order from Draft to Confirmed.

**Constraint:** Only `Draft` orders can be confirmed. Returns `InvalidOperationException` (409) otherwise.

**Side effects:**
- Status set to `Confirmed`
- `ConfirmedDate` set to `DateTimeOffset.UtcNow`

**Response:** `204 No Content`

### POST /api/v1/orders/{id}/cancel

Cancel a sales order.

**Constraint:** Cannot cancel `Shipped` or `Completed` orders. Returns `InvalidOperationException` (409) otherwise. `Draft`, `Confirmed`, `InProduction`, and `PartiallyShipped` orders can be cancelled.

**Side effects:**
- Status set to `Cancelled`

**Response:** `204 No Content`

### DELETE /api/v1/orders/{id}

Soft-delete a sales order.

**Constraint:** Only `Draft` orders can be deleted. Returns `InvalidOperationException` (409) otherwise.

**Side effects:**
- `DeletedAt` set to `DateTimeOffset.UtcNow` (soft delete)
- Order excluded from future queries by the global `DeletedAt == null` query filter

**Response:** `204 No Content`

---

## Status Lifecycle

```
Draft -----> Confirmed -----> InProduction -----> PartiallyShipped -----> Shipped -----> Completed
  |              |                  |                    |
  |              |                  |                    |
  v              v                  v                    v
Cancelled    Cancelled          (cannot cancel)     (cannot cancel)
```

### Status Definitions

| Status | Description | Allowed Transitions |
|--------|-------------|---------------------|
| **Draft** | Initial status on creation. Order is editable, can be confirmed, cancelled, or deleted. | Confirmed, Cancelled |
| **Confirmed** | Order has been reviewed and committed. `ConfirmedDate` is set. Still editable (header fields only). | InProduction, PartiallyShipped, Shipped, Cancelled |
| **InProduction** | At least one job linked to the order is in production. Set automatically by the system. | PartiallyShipped, Shipped |
| **PartiallyShipped** | Some but not all line items have been fully shipped. Updated as shipments are created. | Shipped |
| **Shipped** | All line items are fully shipped (`isFullyShipped` = true for all lines). | Completed |
| **Completed** | Order is fully fulfilled and closed. Terminal state. | (none) |
| **Cancelled** | Order was cancelled before completion. Terminal state. | (none) |

### Transition Rules (Backend Enforcement)

| Action | Allowed From | Backend Method |
|--------|-------------|----------------|
| Confirm | Draft only | `ConfirmSalesOrderHandler` |
| Cancel | Draft, Confirmed (backend also allows InProduction, PartiallyShipped) | `CancelSalesOrderHandler` |
| Delete (soft) | Draft only | `DeleteSalesOrderHandler` |
| Update fields | Draft, Confirmed only | `UpdateSalesOrderHandler` |

**Note on UI vs. backend:** The UI `canCancel()` method only enables the Cancel button for `Draft` and `Confirmed` statuses. The backend handler is more permissive, blocking only `Shipped` and `Completed`. This means the API technically allows cancellation of `InProduction` and `PartiallyShipped` orders, but the UI does not expose this action for those statuses.

### Tax Rate Convention

The tax rate is stored as a decimal fraction in the database (e.g., `0.075` for 7.5%). The UI input field displays and accepts the percentage value (e.g., `7.5`) with a `%` suffix, and divides by 100 before sending to the API. The backend validation enforces `0 <= taxRate < 1`.

---

## Known Limitations

1. **No inline edit dialog.** The `UpdateSalesOrder` API endpoint exists but the UI does not expose an edit dialog. The detail panel emits an `editRequested` output, but no edit component consumes it.

2. **No line item editing on existing orders.** Once created, line items cannot be added, removed, or modified through either the UI or API. The only line-level mutation is `shippedQuantity`, which is updated indirectly through shipment creation.

3. **Customer and status filters are not auto-applied.** Changing the customer or status dropdown does not automatically refresh the list. The user must press Enter in the search field to trigger `applyFilters()`.

4. **No shipping/billing address selection in the create dialog.** The `CreateSalesOrderRequest` model supports `shippingAddressId` and `billingAddressId`, but the create dialog does not expose address selection controls. Addresses can only be set via the `UpdateSalesOrder` API endpoint.

5. **No quote selection in the create dialog.** The `CreateSalesOrderRequest` supports a `quoteId` field for linking to a source quote, but the create dialog does not include a quote picker. Quote-to-SO conversion is handled from the Quotes feature.

6. **Tax rate input/API mismatch.** The UI tax rate field accepts percentage values (e.g., `7.5`) but the API expects a decimal fraction (e.g., `0.075`). The UI divides by 100 when computing the displayed tax amount, but the raw form value is sent directly to the API. This can cause confusion if the user enters `7.5` expecting 7.5% -- the API validation (`< 1`) will reject values >= 1, effectively preventing percentage-format input at the API level.

7. **Status transitions beyond Draft/Confirmed are system-driven.** The `InProduction`, `PartiallyShipped`, `Shipped`, and `Completed` status transitions are not exposed as user actions in the UI. They are expected to be updated automatically as related entities (jobs, shipments) progress.

8. **Drop-ship and back-to-back order operations** exist as backend handlers but are exposed on separate controllers (`DropShipsController`, `BackToBacksController`), not on the `SalesOrdersController`. These are not surfaced in the Sales Orders UI.
