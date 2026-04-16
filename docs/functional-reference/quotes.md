# Quotes

## Overview

Quotes are binding, line-itemized price commitments sent to customers. Each quote contains one or more line items (part + quantity + unit price), a tax rate, and computed totals. Quotes follow a defined status lifecycle: Draft, Sent, Accepted, Declined, Expired, or ConvertedToOrder. An accepted quote can be converted into a Sales Order, which flows into the production and fulfillment pipeline.

Quotes share the `quotes` database table with Estimates, discriminated by `QuoteType.Quote`. A quote may optionally originate from an estimate conversion, tracked by the `source_estimate_id` FK.

Quotes have their own dedicated list page at `/quotes` and are also visible in the Customer detail Quotes tab.

## Routes

| Path | Component | Lazy-loaded |
|------|-----------|-------------|
| `/quotes` | `QuotesComponent` | Yes |

**Access roles:** Admin, Manager, OfficeManager, PM (inherited from `QuotesController` authorization).

**URL state:**
- `?detail=quote:{id}` -- opens the quote detail dialog for the specified quote. Set automatically when a row is clicked, cleared on dialog close.

## Page Layout

The page is a full-height flex column with three zones:

1. **Page header** (`PageHeaderComponent`) -- title "Quotes" with subtitle, and "New Quote" button.
2. **Filters bar** -- inline search and status filter controls.
3. **Content area** -- a `DataTableComponent` with the full quote list, wrapped in `LoadingBlockDirective`.
4. **Create dialog** (conditional) -- the `QuoteDialogComponent` rendered when creating a new quote.

### Toolbar Controls

| Control | Type | Purpose |
|---------|------|---------|
| Search | `InputComponent` | Free-text filter (triggers on Enter) |
| Status | `SelectComponent` | Filter by quote status |
| New Quote | Button | Opens the quote creation dialog |

## Filters

### Search

Free-text input. Applied on Enter keypress by calling `applyFilters()` which reloads the full list from the API.

### Status

Dropdown with options:
- All Statuses (value: `null`)
- Draft
- Sent
- Accepted
- Declined
- Expired
- Converted to Order

Selecting a status triggers a server-side filtered request via the `status` query parameter.

## List View

Renders a `DataTableComponent` with `tableId="quotes"`.

### Columns

| Field | Header | Sortable | Filterable | Type | Width | Align |
|-------|--------|----------|------------|------|-------|-------|
| `quoteNumber` | Quote # | Yes | No | text | 120px | left |
| `customerName` | Customer | Yes | No | text | auto | left |
| `status` | Status | Yes | Yes (enum) | enum | 140px | left |
| `lineCount` | Lines | Yes | No | number | 70px | center |
| `total` | Total | Yes | No | number | 100px | right |
| `expirationDate` | Expires | Yes | No | date | 110px | left |
| `createdAt` | Created | Yes | No | date | 110px | left |

### Custom Cell Rendering

- **Quote Number:** Rendered in a `qt-number` CSS class (monospace-style emphasis).
- **Status:** Colored chip with status-specific class:
  - Draft: `chip--muted` (gray)
  - Sent: `chip--info` (blue)
  - Accepted: `chip--success` (green)
  - Declined: `chip--error` (red)
  - Expired: `chip--warning` (yellow/orange)
  - ConvertedToOrder: `chip--primary` (primary brand color)
- **Total:** Formatted with `CurrencyPipe`.
- **Expires / Created:** Formatted as `MM/dd/yyyy`. Shows `---` if expiration date is null.

### Row Interaction

Rows are clickable (`[clickableRows]="true"`). Clicking a row opens the quote detail dialog via `DetailDialogService` with `?detail=quote:{id}` URL sync.

### Empty State

Icon: `request_quote`. Message: "No quotes found".

### URL-Driven Detail Open

On page load, after quotes are fetched, the component checks for a `?detail=quote:{id}` URL parameter and auto-opens the detail dialog if present.

## Create Dialog (`QuoteDialogComponent`)

A split-layout dialog for creating new quotes with line items on the left and metadata on the right.

**Dialog width:** 1100px (large).

**Draft support:** Configured with `DraftConfig` for auto-save to IndexedDB. Entity type: `quote`, entity ID: `new`, route: `/quotes`.

### Layout

The dialog uses `[splitLayout]="true"` to create a two-panel layout:

- **Left panel (main):** Line items table and add-line form.
- **Right panel (sidebar):** Customer, expiration, tax rate, notes, and computed summary.

### Sidebar Form Fields

| Field | Label | Component | FormControl | Required | Validation | Notes |
|-------|-------|-----------|-------------|----------|------------|-------|
| Customer | Customer | `<app-select>` | `customerId` | Yes | Must select a customer | Options loaded from `CustomerService.getCustomers()` (active only) |
| Expiration Date | Expiration Date | `<app-datepicker>` | `expirationDate` | No | -- | When the quote offer expires |
| Tax Rate | Tax Rate | `<app-input>` | `taxRate` | Yes | >= 0 | `type="number"`, `suffix="%"`. Entered as a percentage (e.g., 7.25), converted to decimal on submit |
| Notes | (none) | `<app-textarea>` | `notes` | No | -- | 3 rows; internal notes |

### Tax Rate Auto-Fill

When a customer is selected, the system calls `AdminService.getTaxRateForCustomer()` to fetch the applicable sales tax rate based on the customer's state. If a rate is found:

- The tax rate field is auto-populated with the percentage value.
- A badge appears next to the field showing the source (e.g., "CA 7.25%").
- A tooltip reads "Auto-filled from customer state. Edit to override."

The auto-fill indicator clears if the user manually edits the tax rate.

### Line Items Section

**Line items table** (shown when at least one line exists):

| Column | Header | Align |
|--------|--------|-------|
| Part # | Part # | left (monospace) |
| Description | Description | left |
| Qty | Qty | right |
| Unit Price | Unit Price | right (currency) |
| Total | Total | right (currency, computed) |
| Actions | (sr-only) | -- (remove button) |

Each line has a remove button (X icon, danger style) that deletes the line from the in-memory array.

**Empty state:** "No line items yet" message when no lines have been added.

### Add Line Form

A 4-column inline form below the line items table:

| Field | Label | Component | FormControl | Required | Validation | Notes |
|-------|-------|-----------|-------------|----------|------------|-------|
| Part | Part | `<app-autocomplete>` | `partId` | Yes | Must select a part | Options from `PartsService.getParts()`, displayed as `{partNumber} -- {description}`. `minChars=0` shows all on focus. |
| Qty | Qty | `<app-input>` | `quantity` | Yes | >= 1 | `type="number"`, defaults to 1 |
| Price | Price | `<app-input>` | `unitPrice` | Yes | >= 0 | `type="number"`. Auto-fills from part's `defaultPrice` when part is selected. |
| (button) | Add | Button | -- | -- | -- | `action-btn--sm`, disabled when line form is invalid |

**Price auto-fill:** When a part is selected, if the part has a `defaultPrice`, the unit price field is auto-populated and a "LIST" badge appears next to the field with tooltip "List price -- edit to override". The badge clears if the user manually changes the price.

After clicking Add, the line is appended to the `lines` signal array and the line form resets to defaults (`partId: null, quantity: 1, unitPrice: 0`).

### Summary Section (Sidebar)

Three computed rows displayed in the sidebar:

| Row | Value |
|-----|-------|
| Subtotal | Sum of all line totals (`quantity * unitPrice`) |
| Tax (X%) | Subtotal * tax rate percentage |
| **Total** | Subtotal + tax amount (bold, emphasized) |

All values update reactively as lines are added/removed or tax rate changes.

### Save Behavior

- **Disabled when:** Form is invalid, no lines added, or save is in progress.
- **Validation popover:** Shows on hover when disabled. Combines form field violations with a custom "At least one line item is required" message.
- **On submit:**
  1. Tax rate is converted from percentage to decimal (divided by 100) before sending to the API.
  2. `QuoteService.createQuote()` is called with the assembled `CreateQuoteRequest`.
  3. On success: draft is cleared, snackbar "Quote created" appears, `saved` event emits (parent reloads list).
  4. On error: saving state clears, global error interceptor handles the response.

## Detail Dialog (`QuoteDetailDialogComponent` / `QuoteDetailPanelComponent`)

The detail dialog opens via `DetailDialogService` as a full `MatDialog`. The dialog component is a thin wrapper that renders `QuoteDetailPanelComponent` and relays close/changed events.

### Header

- `request_quote` icon
- Quote number as the primary title
- Customer name as subtitle (clickable `EntityLinkComponent` navigating to customer detail)
- Close button (X icon)

### Info Grid

| Field | Label | Condition |
|-------|-------|-----------|
| Status | Status | Always shown; colored chip |
| Customer | Customer | Always shown; clickable entity link |
| Expiration | Expiration | Shown if `expirationDate` is set |
| Sent | Sent | Shown if `sentDate` is set |
| Accepted | Accepted | Shown if `acceptedDate` is set |
| Linked Order | Linked Order | Shown if `salesOrderId` is set; clickable entity link to the sales order |

### Notes Section

Shown only if `notes` is non-empty. Displays the full notes text.

### Line Items Table

| Column | Header | Align |
|--------|--------|-------|
| Part # | Part # | left (monospace). Shows `---` if `partNumber` is null |
| Description | Description | left |
| Qty | Qty | right |
| Unit Price | Unit Price | right (currency) |
| Total | Total | right (currency) |

### Totals Section

| Row | Value | Style |
|-----|-------|-------|
| Subtotal | Computed from lines | Normal |
| Tax (X%) | Subtotal * tax rate | Normal |
| **Total** | Subtotal + tax | Bold/emphasized |

### Metadata

| Field | Label |
|-------|-------|
| Created | `createdAt` formatted as `MM/dd/yyyy` |
| Updated | `updatedAt` formatted as `MM/dd/yyyy` |

### Action Buttons

Action buttons are conditionally rendered based on the current status:

| Action | Button Style | Icon | Visible When | Behavior |
|--------|-------------|------|--------------|----------|
| Send | `action-btn--primary` | `send` | `status === 'Draft'` | Calls `sendQuote()` |
| Accept | `action-btn--primary` | `thumb_up` | `status === 'Sent'` | Calls `acceptQuote()` |
| Reject | `action-btn` (secondary) | `thumb_down` | `status === 'Sent'` | Confirmation dialog, then calls `rejectQuote()` |
| Convert to Order | `action-btn--primary` | `shopping_cart` | `status === 'Accepted'` | Calls `convertToOrder()` |
| Delete | `action-btn--danger` | `delete` | `status === 'Draft'` | Confirmation dialog, then calls `deleteQuote()` |

**Confirmation dialogs:**
- **Reject:** Title "Reject Quote?", message includes quote number, severity `warn`, confirm label "Reject".
- **Delete:** Title "Delete Quote?", message includes quote number, severity `danger`, confirm label "Delete".

### Activity Section

An `EntityActivitySectionComponent` is rendered at the bottom of the detail panel with `entityType="Quote"` and `entityId` bound to the current quote ID. This shows the chronological activity log for the quote.

## Status Lifecycle

Quotes follow a strict server-enforced status lifecycle.

### Status Values

| Status | Meaning |
|--------|---------|
| `Draft` | Quote is being prepared; can be edited, sent, or deleted |
| `Sent` | Quote has been sent to the customer; awaiting response |
| `Accepted` | Customer has accepted the quote; eligible for conversion to Sales Order |
| `Declined` | Customer declined the quote |
| `Expired` | Quote validity period has passed |
| `ConvertedToOrder` | Quote was converted to a Sales Order |

### Transition Rules (Server-Enforced)

```
Draft ──────> Sent ──────> Accepted ──────> ConvertedToOrder
                 │                              (terminal)
                 └──────> Declined
                            (terminal)
```

| Transition | Endpoint | Precondition | Side Effects |
|------------|----------|--------------|--------------|
| Draft -> Sent | `POST /{id}/send` | Status must be `Draft` | Sets `SentDate` to current UTC |
| Sent -> Accepted | `POST /{id}/accept` | Status must be `Sent` | Sets `AcceptedDate` to current UTC |
| Sent -> Declined | `POST /{id}/reject` | Status must be `Sent` | None |
| Accepted -> ConvertedToOrder | `POST /{id}/convert` | Status must be `Accepted`, no existing sales order | Creates Sales Order, updates status |

**Invalid transitions** return 409 (InvalidOperationException) with a descriptive error message.

### Editable States

Only `Draft` quotes can be edited (`PUT /{id}`) or deleted (`DELETE /{id}`). Attempting to update or delete a non-Draft quote returns 409.

### Terminal States

- `Declined` -- no further transitions available.
- `ConvertedToOrder` -- no further transitions; quote is linked to a Sales Order.
- `Expired` -- note: there is no server endpoint to set this status; it must be set via another mechanism or manual DB update.

## Line Items

Each quote has one or more line items stored in the `quote_lines` table.

### Data Model (`QuoteLine`)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | int | No | Auto-increment PK |
| `quote_id` | int (FK) | No | Parent quote |
| `part_id` | int (FK) | Yes | Link to `parts` table (optional) |
| `description` | string | No | Line item description |
| `quantity` | int | No | Number of units |
| `unit_price` | decimal | No | Price per unit |
| `line_number` | int | No | Display order (1-based) |
| `notes` | string | Yes | Per-line notes |

**Computed:** `LineTotal = Quantity * UnitPrice` (calculated property, not stored).

### Line Item Validation (Server)

Validated via `CreateQuoteValidator`:

- At least one line item is required.
- Tax rate must be >= 0 and < 1 (stored as decimal, e.g., 0.0725 for 7.25%).
- Per line:
  - `Description` must be non-empty.
  - `Quantity` must be > 0.
  - `UnitPrice` must be >= 0.

### Line Items on Creation Only

Line items are set during quote creation and cannot be modified after the quote is created. There is no endpoint to add, update, or remove individual lines on an existing quote.

## Conversion Workflow: Quote to Sales Order

Converting an accepted quote creates a Sales Order with matching line items.

### User Flow

1. User views a quote in `Accepted` status in the detail dialog.
2. User clicks "Convert to Order" button.
3. `POST /api/v1/quotes/{id}/convert` is called directly (no confirmation dialog).
4. The detail reloads showing `ConvertedToOrder` status with a linked Sales Order. Snackbar confirms "Converted to order SO-XXXX".

### Server-Side Behavior (`ConvertQuoteToOrderHandler`)

1. Loads the quote with full details (lines, customer, existing sales order).
2. Validates: status must be `Accepted`.
3. Validates: `SalesOrder` navigation must be null (prevents double conversion).
4. Generates a new sequential order number via `ISalesOrderRepository.GenerateNextOrderNumberAsync()`.
5. Creates a new `SalesOrder` record:
   - `OrderNumber` = generated number
   - `CustomerId` = same as quote
   - `QuoteId` = quote's ID
   - `ShippingAddressId` = same as quote
   - `TaxRate` = same as quote
6. Copies all quote lines to sales order lines:
   - `PartId`, `Description`, `Quantity`, `UnitPrice`, `Notes` all copied
   - `LineNumber` re-assigned sequentially (1-based)
7. Sets the quote's `Status = ConvertedToOrder`.
8. Saves both records in a single transaction.

### What Carries Over

| Quote Field | Sales Order Field |
|-------------|-------------------|
| `CustomerId` | `CustomerId` |
| `Id` | `QuoteId` (FK back to quote) |
| `ShippingAddressId` | `ShippingAddressId` |
| `TaxRate` | `TaxRate` |
| All `QuoteLines` | All `SalesOrderLines` (same fields) |

### What Does NOT Carry Over

- `Notes` -- not copied to the sales order.
- `ExpirationDate` -- not applicable to orders.
- `SentDate` / `AcceptedDate` -- historical data stays on the quote.

## API Endpoints

All endpoints are under `/api/v1/quotes`. Authorization requires one of: Admin, Manager, OfficeManager, PM.

### List Quotes

```
GET /api/v1/quotes?customerId={int}&status={QuoteStatus}
```

**Query parameters (all optional):**

| Param | Type | Description |
|-------|------|-------------|
| `customerId` | int | Filter to a specific customer |
| `status` | QuoteStatus | Filter by status |

**Response:** `QuoteListItemModel[]`

```json
[
  {
    "id": 5,
    "quoteNumber": "Q-0005",
    "customerId": 10,
    "customerName": "Acme Corp",
    "status": "Draft",
    "lineCount": 3,
    "total": 12500.00,
    "expirationDate": "2026-06-15T00:00:00Z",
    "createdAt": "2026-04-12T09:00:00Z"
  }
]
```

Delegates to `IQuoteRepository.GetAllAsync()` which filters to `Type = Quote` only.

### Get Quote Detail

```
GET /api/v1/quotes/{id}
```

**Response:** `QuoteDetailResponseModel`

```json
{
  "id": 5,
  "quoteNumber": "Q-0005",
  "customerId": 10,
  "customerName": "Acme Corp",
  "shippingAddressId": 3,
  "status": "Sent",
  "sentDate": "2026-04-13T10:00:00Z",
  "expirationDate": "2026-06-15T00:00:00Z",
  "acceptedDate": null,
  "notes": "Priority customer -- expedite review.",
  "taxRate": 0.0725,
  "subtotal": 11628.00,
  "taxAmount": 843.03,
  "total": 12471.03,
  "salesOrderId": null,
  "salesOrderNumber": null,
  "sourceEstimateId": 2,
  "lines": [
    {
      "id": 10,
      "partId": 42,
      "partNumber": "BRK-001",
      "description": "Aluminum Bracket Assembly",
      "quantity": 100,
      "unitPrice": 45.00,
      "lineTotal": 4500.00,
      "lineNumber": 1,
      "notes": null
    }
  ],
  "createdAt": "2026-04-12T09:00:00Z",
  "updatedAt": "2026-04-13T10:00:00Z"
}
```

Loads via `IQuoteRepository.FindWithDetailsAsync()` which includes Lines (with Part navigation), Customer, and SalesOrder. Totals are computed server-side from lines.

### Create Quote

```
POST /api/v1/quotes
```

**Request body:** `CreateQuoteRequestModel`

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `customerId` | int | Yes | Must be > 0; customer must exist |
| `shippingAddressId` | int | No | Customer address ID |
| `expirationDate` | DateTimeOffset | No | ISO 8601 with UTC |
| `notes` | string | No | Free-text |
| `taxRate` | decimal | Yes | >= 0 and < 1 (decimal, e.g., 0.0725) |
| `lines` | CreateQuoteLineModel[] | Yes | At least one line required |

**Line item fields (`CreateQuoteLineModel`):**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `partId` | int | No | Link to parts table |
| `description` | string | Yes | Non-empty |
| `quantity` | int | Yes | Must be > 0 |
| `unitPrice` | decimal | Yes | Must be >= 0 |
| `notes` | string | No | Per-line notes |

**Response:** 201 Created with `QuoteListItemModel` body and `Location` header.

The created record has `Type = Quote`, `Status = Draft`, and an auto-generated `QuoteNumber`.

### Update Quote

```
PUT /api/v1/quotes/{id}
```

**Precondition:** Quote must be in `Draft` status. Returns 409 otherwise.

**Request body:** `UpdateQuoteRequestModel`

All fields are optional (partial update):

| Field | Type | Validation |
|-------|------|------------|
| `shippingAddressId` | int | Must be > 0 |
| `expirationDate` | DateTimeOffset | ISO 8601 with UTC |
| `notes` | string | Max 2000 characters |
| `taxRate` | decimal | 0 to 1 inclusive |

**Response:** 204 No Content.

Note: Line items cannot be modified after creation via this endpoint.

### Send Quote

```
POST /api/v1/quotes/{id}/send
```

**Precondition:** Status must be `Draft`. Returns 409 otherwise.

**Side effects:** Sets `SentDate` to current UTC, changes status to `Sent`.

**Response:** 204 No Content.

### Accept Quote

```
POST /api/v1/quotes/{id}/accept
```

**Precondition:** Status must be `Sent`. Returns 409 otherwise.

**Side effects:** Sets `AcceptedDate` to current UTC, changes status to `Accepted`.

**Response:** 204 No Content.

### Reject Quote

```
POST /api/v1/quotes/{id}/reject
```

**Precondition:** Status must be `Sent`. Returns 409 otherwise.

**Side effects:** Changes status to `Declined`.

**Response:** 204 No Content.

### Convert to Sales Order

```
POST /api/v1/quotes/{id}/convert
```

**Precondition:** Status must be `Accepted` and no existing sales order linked. Returns 409 otherwise.

**Side effects:** Creates a Sales Order with all line items copied, sets status to `ConvertedToOrder`.

**Response:** 201 Created with `SalesOrderListItemModel` body and `Location` header pointing to the new Sales Order.

### Delete Quote

```
DELETE /api/v1/quotes/{id}
```

**Precondition:** Status must be `Draft`. Returns 409 otherwise.

Soft-deletes the quote by setting `DeletedAt`.

**Response:** 204 No Content.

## Data Model

Quotes use the `Quote` entity with `Type = Quote`.

### Quote Entity (Quote-specific fields)

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | int | No | Auto-increment PK |
| `type` | QuoteType | No | Always `Quote` for quotes |
| `customer_id` | int (FK) | No | Link to `customers` table |
| `status` | QuoteStatus | No | Current lifecycle status |
| `quote_number` | string | Yes | Auto-generated (e.g., Q-0001) |
| `shipping_address_id` | int (FK) | Yes | Customer shipping address |
| `sent_date` | timestamptz | Yes | When quote was sent |
| `accepted_date` | timestamptz | Yes | When quote was accepted |
| `expiration_date` | timestamptz | Yes | Validity expiration |
| `notes` | string | Yes | Internal notes |
| `tax_rate` | decimal | No | Tax rate as decimal (0.0725 = 7.25%) |
| `source_estimate_id` | int (FK) | Yes | Self-FK to originating estimate |
| `converted_at` | timestamptz | Yes | When converted from estimate |
| `external_id` | string | Yes | Accounting provider ID |
| `external_ref` | string | Yes | Accounting provider reference |
| `provider` | string | Yes | Accounting provider name |
| `created_at` | timestamptz | No | Auto-set on insert |
| `updated_at` | timestamptz | No | Auto-set on insert/update |
| `deleted_at` | timestamptz | Yes | Soft-delete timestamp |

**Unused fields** (always null/default for quotes): `title`, `description`, `estimated_amount`, `assigned_to_id`.

### Navigations

- `Customer` -- the associated customer (required).
- `ShippingAddress` -- optional `CustomerAddress` for shipping.
- `Lines` -- collection of `QuoteLine` entities.
- `SourceEstimate` -- the `Estimate`-type record this quote was created from (optional).
- `GeneratedQuote` -- inverse navigation; the quote generated from this record if it is an estimate.
- `SalesOrder` -- the Sales Order created from this quote (optional).

### Computed Properties

- `Subtotal` = sum of all `Lines.LineTotal`
- `TaxAmount` = `Subtotal * TaxRate`
- `Total` = `Subtotal + TaxAmount`

## Permissions

| Action | Roles |
|--------|-------|
| View quotes | Admin, Manager, OfficeManager, PM |
| Create quote | Admin, Manager, OfficeManager, PM |
| Edit quote (Draft only) | Admin, Manager, OfficeManager, PM |
| Send quote | Admin, Manager, OfficeManager, PM |
| Accept quote | Admin, Manager, OfficeManager, PM |
| Reject quote | Admin, Manager, OfficeManager, PM |
| Convert to order | Admin, Manager, OfficeManager, PM |
| Delete quote (Draft only) | Admin, Manager, OfficeManager, PM |

Engineers and Production Workers do not have access to the quotes API.

## Relationship to Estimates

Quotes and Estimates share the same database table (`quotes`) and entity class (`Quote`), differentiated by the `type` column (`QuoteType` enum).

### Conversion Flow

```
Estimate (Estimate type)
    │
    ├── POST /api/v1/estimates/{id}/convert
    │
    v
Quote (Quote type, status=Draft)
    │
    ├── POST /api/v1/quotes/{id}/send    -> Sent
    ├── POST /api/v1/quotes/{id}/accept  -> Accepted
    ├── POST /api/v1/quotes/{id}/convert -> ConvertedToOrder
    │
    v
Sales Order
```

The `source_estimate_id` FK on the Quote links back to the originating Estimate. The `sourceEstimateId` field is included in the `QuoteDetailResponseModel` for traceability.

## Known Limitations

1. **Line items are immutable after creation.** There is no API endpoint to add, update, or remove line items on an existing quote. To change lines, the quote must be deleted and recreated.
2. **No edit UI in the detail dialog.** The detail panel is read-only. The update endpoint exists but the UI does not expose an edit form for quote metadata (shipping address, expiration, notes, tax rate).
3. **No Expired status transition endpoint.** There is no `POST /{id}/expire` endpoint. Quotes cannot be programmatically set to Expired status. There is no scheduled job to auto-expire quotes past their `expirationDate`.
4. **No pagination.** The list endpoint returns all quotes. For high-volume shops this could become a performance concern.
5. **Tax rate display discrepancy.** The create dialog accepts tax rate as a percentage (e.g., 7.25) and converts to decimal (0.0725) on submit. The detail panel displays the stored decimal value directly in the "Tax (X%)" label, which shows as "Tax (0.0725%)" instead of "Tax (7.25%)".
6. **No PDF generation.** Unlike invoices and work orders, there is no `GET /quotes/{id}/pdf` endpoint for generating a printable quote document.
7. **No customer tab integration.** While quotes can be filtered by `customerId` via the API, there is no dedicated Quotes tab in the Customer detail page (unlike Estimates which have their own tab).
8. **Convert to Order has no confirmation dialog.** Unlike Reject and Delete which prompt for confirmation, the Convert to Order action fires immediately on click.
9. **Part description from catalog only.** Line item descriptions are populated from the part catalog at creation time. There is no way to enter a custom description for a line item that differs from the part's catalog description.
10. **No discount support.** Line items have no discount field (percentage or flat). All pricing is unit-price-only.
