# Shipments

## Overview

The Shipments feature manages the physical fulfillment of sales orders -- from creating shipment records and adding line items, through packing, carrier rate shopping, label generation, shipping, tracking, and delivery confirmation. Shipments are the bridge between sales orders and invoices in the quote-to-cash flow.

Each shipment is linked to exactly one sales order and contains one or more shipment lines referencing either sales order lines (with fulfillment quantity tracking) or standalone parts. Shipments support partial delivery -- multiple shipments can fulfill a single sales order, and each shipment can contain a subset of the order's lines.

Carrier integration is provided via the `IShippingService` pluggable interface. In development/mock mode, three canned carrier rates (UPS Ground, FedEx Home Delivery, USPS Priority Mail) are returned. Direct carrier API integrations (UPS, FedEx, USPS, DHL) are planned but not yet implemented. Manual mode (user enters carrier and tracking number directly) is always available regardless of carrier integration status.

PDF generation is available for two document types: packing slips and bills of lading, both rendered server-side via QuestPDF.

---

## Routes & Navigation

| Route | Component | Description |
|-------|-----------|-------------|
| `/shipments` | `ShipmentsComponent` | Main shipment list page |

The shipments page is a single flat route with no sub-routes or tabs. Detail views are opened as full-screen `MatDialog` dialogs via `DetailDialogService`, synced to the URL as `?detail=shipment:{id}`.

**Sidebar navigation:** Shipments appears in the main sidebar navigation.

**Deep linking:** Opening `/shipments?detail=shipment:42` loads the list and immediately opens the detail dialog for shipment 42. The URL updates when a detail dialog opens and clears when it closes (`replaceUrl: true`).

---

## Access & Permissions

The `ShipmentsController` is restricted to three roles via `[Authorize(Roles = "Admin,Manager,OfficeManager")]`:

| Role | Access |
|------|--------|
| Admin | Full CRUD, all actions |
| Manager | Full CRUD, all actions |
| OfficeManager | Full CRUD, all actions |
| Engineer | No access |
| PM | No access |
| Production Worker | No access |

All endpoints require authentication. Unauthenticated requests receive a 401 response.

---

## Shipment List

### Page Layout

The shipment list page uses a `PageHeaderComponent` with a title ("Shipments"), subtitle, and a "New Shipment" action button (icon: `add`). Below the header is a filter bar followed by a `DataTableComponent`.

### Filters

| Filter | Control | Behavior |
|--------|---------|----------|
| Search | `app-input` with Enter key trigger | Free-text search (client-side filtering via DataTable built-in) |
| Status | `app-select` dropdown | Server-side filter; triggers `loadShipments()` on change |

**Status filter options:**

| Value | Label |
|-------|-------|
| `null` | All Statuses |
| `Pending` | Pending |
| `Packed` | Packed |
| `Shipped` | Shipped |
| `InTransit` | In Transit |
| `Delivered` | Delivered |
| `Cancelled` | Cancelled |

### Table Columns

Table ID: `shipments` (used for column preference persistence).

| Field | Header | Sortable | Filterable | Type | Width | Custom Cell |
|-------|--------|----------|------------|------|-------|-------------|
| `shipmentNumber` | Shipment # | Yes | No | text | 120px | Monospace font (`sh-number` class) |
| `salesOrderNumber` | SO # | Yes | No | text | 120px | Monospace font |
| `customerName` | Customer | Yes | No | text | auto | Plain text |
| `status` | Status | Yes | Yes | enum | 120px | Colored chip (see status chip mapping) |
| `carrier` | Carrier | Yes | No | text | 100px | Displays `---` when null |
| `trackingNumber` | Tracking # | Yes | No | text | 140px | Monospace font; displays `---` when null |
| `shippedDate` | Shipped Date | Yes | No | date | 110px | `MM/dd/yyyy` format; displays `---` when null |
| `createdAt` | Created | Yes | No | date | 110px | `MM/dd/yyyy` format |

### Status Chip Mapping

| Status | CSS Class | Visual |
|--------|-----------|--------|
| Pending | `chip--muted` | Gray |
| Packed | `chip--info` | Blue |
| Shipped | `chip--primary` | Primary color |
| InTransit | `chip--warning` | Yellow/orange |
| Delivered | `chip--success` | Green |
| Cancelled | `chip--error` | Red |

### Row Interaction

Rows are clickable (`[clickableRows]="true"`). Clicking a row opens the shipment detail dialog via `DetailDialogService`.

**Empty state:** Icon `local_shipping`, message "No shipments found."

**Loading:** `LoadingBlockDirective` wraps the table area. The filter bar and header remain interactive during loading.

---

## Shipment Detail Dialog

The detail view opens as a `MatDialog` (via `DetailDialogService`) containing a `ShipmentDetailPanelComponent`. The URL updates to `?detail=shipment:{id}`.

### Header

- Icon: `local_shipping` (Material outlined)
- Title: Shipment number (e.g., "SHP-00042")
- Subtitle: Customer name
- Close button: `close` icon in upper-right

### Information Grid

The detail panel displays an info grid with the following fields (conditionally shown):

| Field | Label | Always Shown | Format |
|-------|-------|--------------|--------|
| Status | Status | Yes | Colored chip |
| Sales Order | Sales Order | Yes | `EntityLinkComponent` (type: `sales-order`) -- clickable, navigates to SO detail |
| Customer | Customer | Yes | Plain text |
| Carrier | Carrier | When present | Plain text |
| Tracking Number | Tracking # | When present | Monospace font |
| Shipped Date | Shipped Date | When shipped | `MM/dd/yyyy` |
| Delivered Date | Delivered | When delivered | `MM/dd/yyyy` |
| Weight | Weight | When present | `{value} lbs` |
| Shipping Cost | Shipping Cost | When present | Currency format (e.g., `$15.75`) |
| Linked Invoice | Linked Invoice | When present | `EntityLinkComponent` (type: `invoice`) |

### Notes Section

Displayed only when `shipment.notes` is non-null. Shows a label "Notes" followed by the notes text.

### Line Items Section

Shows "Line Items ({count})" label followed by a table:

| Column | Alignment | Content |
|--------|-----------|---------|
| Description | Left | Line description (from SO line or part) |
| Quantity | Right | Integer quantity |

### Timestamps

A secondary info grid shows:

| Field | Format |
|-------|--------|
| Created | `MM/dd/yyyy` |
| Updated | `MM/dd/yyyy` |

### Tracking Timeline

Appears only when tracking data has been loaded (after clicking the "Track" button). Shows a `TrackingTimelineComponent` with:

- **Header:** Shipping status icon, status text, tracking number, and estimated delivery date (when available, formatted `MM/dd/yyyy`)
- **Timeline:** Vertical timeline with dot markers and connecting lines. Each event shows:
  - Description text
  - Timestamp (`MM/dd/yyyy hh:mm a` format)
  - Location (with `place` icon, when present)
- **Empty state:** `schedule` icon with "No tracking events" message when events array is empty
- **Close button:** `close` icon to dismiss the tracking timeline

### Activity Section

An `EntityActivitySectionComponent` is rendered at the bottom with `entityType="Shipment"` and the shipment's ID. This shows the chronological activity log for the shipment.

### Action Buttons

Actions are conditionally displayed based on shipment status:

| Button | Icon | Condition | Action |
|--------|------|-----------|--------|
| Get Rates | `request_quote` | Status is `Pending` or `Packed` | Opens the shipping rates dialog |
| Mark Shipped | `local_shipping` | Status is `Pending` or `Packed` | Transitions to `Shipped` (with confirmation) |
| Track | `location_searching` | Has tracking number AND tracking timeline is not already shown | Loads tracking data from carrier API |
| Mark Delivered | `check_circle` | Status is `Shipped` or `InTransit` | Transitions to `Delivered` (with confirmation) |

**Mark Shipped confirmation dialog:**
- Title: "Mark as Shipped?"
- Message: "This will mark shipment {number} as shipped."
- Confirm label: "Mark Shipped"
- Severity: `info`
- On confirm: calls `POST /api/v1/shipments/{id}/ship`, refreshes detail, shows success snackbar

**Mark Delivered confirmation dialog:**
- Title: "Mark as Delivered?"
- Message: "This will mark shipment {number} as delivered."
- Confirm label: "Mark Delivered"
- Severity: `info`
- On confirm: calls `POST /api/v1/shipments/{id}/deliver`, refreshes detail, shows success snackbar

---

## Create Shipment Dialog

Opened via the "New Shipment" button on the list page. Uses `ShipmentDialogComponent` with `app-dialog` shell.

**Dialog width:** 1000px
**Layout:** Split layout (`[splitLayout]="true"`) -- lines table on the left (main area), shipment details form on the right (sidebar).
**Draft support:** Enabled via `DraftConfig` with `entityType: 'shipment'`, `entityId: 'new'`, `route: '/shipments'`. Drafts include both form values and line items.

### Sidebar Fields (Shipment Details)

| Field | Control | Label | Type | Required | Validation | data-testid |
|-------|---------|-------|------|----------|------------|-------------|
| Sales Order | `app-autocomplete` | Sales Order | autocomplete | Yes | `Validators.required` | `shipment-so` |
| Carrier | `app-input` | Carrier | text | No | None | `shipment-carrier` |
| Tracking Number | `app-input` | Tracking Number | text | No | None | `shipment-tracking` |
| Weight | `app-input` | Weight | number | No | None | `shipment-weight` |
| Shipping Cost | `app-input` | Shipping Cost | number | No | None | `shipment-cost` |
| Notes | `app-textarea` | Notes | textarea (3 rows) | No | None | `shipment-notes` |

**Sales Order autocomplete options:** Loaded from `SalesOrderService.getSalesOrders()` on dialog open. Display format: `{orderNumber} -- {customerName}({customerPO})` (customer PO shown in parentheses only when present). Value: sales order ID.

### Main Area (Shipment Lines)

The main area contains a "Shipment Lines" section with a lines table and an add-line form.

**Lines table columns:**

| Column | Content |
|--------|---------|
| Part # | Part number (monospace) |
| Description | Part description |
| Qty | Quantity (right-aligned) |
| Actions | Remove button (`close` icon, danger style) |

**Empty state:** "No line items added yet" message when no lines exist.

**Add line form** (3-column layout via `add-line--3col` class):

| Field | Control | Label | Type | Required | data-testid |
|-------|---------|-------|------|----------|-------------|
| Part | `app-autocomplete` | Part | autocomplete | Yes | -- |
| Quantity | `app-input` | Qty | number | Yes (min: 1) | `shipment-line-qty` |

**Part autocomplete options:** Loaded from `PartsService.getParts('Active')` on dialog open. Display format: `{partNumber} -- {description}`. Value: part ID.

**Add button:** "Add" with `add` icon, disabled when line form is invalid. Adds the line to the local lines array and resets the line form (quantity resets to 1).

### Footer Buttons

| Button | Style | Icon | data-testid | Condition |
|--------|-------|------|-------------|-----------|
| Cancel | `action-btn` | -- | -- | Always shown |
| Create Shipment | `action-btn--primary` | `save` | `shipment-save-btn` | Disabled when form invalid, no lines, or saving |

**Validation popover:** Attached to the Create Shipment button. Shows form field violations plus "At least one line item is required" when the lines array is empty.

**On save:** Calls `POST /api/v1/shipments` with the form data and line items. On success: clears draft, shows success snackbar ("Shipment created"), emits `saved` event (which closes the dialog and reloads the list).

---

## Shipment Lines

### Linking to Sales Order Lines

Shipment lines can be created in two modes:

1. **Sales Order Line-based:** When `salesOrderLineId` is provided, the line tracks fulfillment against the SO line. The handler validates that the requested quantity does not exceed `RemainingQuantity` on the SO line and increments `ShippedQuantity` on save.

2. **Part-based:** When only `partId` is provided (no `salesOrderLineId`), the line is created without fulfillment tracking. This mode is used in the create dialog UI (which uses part autocomplete rather than SO line selection).

### Fulfillment Tracking

When shipment lines reference SO lines:
- `ShippedQuantity` on the SO line is incremented by the shipment line's quantity
- If all SO lines are fully shipped (`IsFullyShipped`), the SO status updates to `Shipped`
- If any SO line has partial shipments, the SO status updates to `PartiallyShipped`
- The handler rejects quantities exceeding `RemainingQuantity` with an `InvalidOperationException`

### Validation Rules

- At least one line item is required per shipment
- Each line must reference either a `SalesOrderLineId` or a `PartId` (at least one must be set)
- Quantity must be greater than 0

---

## Packages

Shipment packages represent physical boxes/containers within a shipment. They are managed via dedicated API endpoints and are used by the carrier integration for rate shopping and label generation.

### Package Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | int | Auto-generated primary key |
| `shipmentId` | int | Parent shipment FK |
| `trackingNumber` | string? | Per-package tracking number |
| `carrier` | string? | Carrier name |
| `weight` | decimal? | Weight in lbs |
| `length` | decimal? | Length in inches |
| `width` | decimal? | Width in inches |
| `height` | decimal? | Height in inches |
| `status` | string | Package status (default: "Pending") |

### Package API Operations

Packages are managed through the `ShipmentService` on the frontend:

- **List packages:** `GET /api/v1/shipments/{id}/packages`
- **Add package:** `POST /api/v1/shipments/{id}/packages`
- **Update package:** `PATCH /api/v1/shipments/{id}/packages/{packageId}`
- **Remove package:** `DELETE /api/v1/shipments/{id}/packages/{packageId}` (hard delete)

Note: Package management is available via the API but does not have a dedicated UI panel in the current detail view. Packages are consumed by the carrier integration when generating labels -- if no packages exist on the shipment, a default package is constructed from the shipment's weight with 10x10x10 inch dimensions.

---

## Carrier Integration

### Architecture

Carrier integration uses the `IShippingService` pluggable interface:

```
IShippingService
  ├── MockShippingService (development/testing)
  └── [Future] UPS / FedEx / USPS / DHL direct integrations
```

The mock service is registered when `MockIntegrations=true` (default in development). It returns three canned rates and generates mock tracking numbers/labels.

### Rate Shopping

Accessed via the "Get Rates" button on the shipment detail panel (available for `Pending` and `Packed` shipments).

**Shipping Rates Dialog** (`ShippingRatesDialogComponent`):

- **Dialog width:** 520px
- **Title:** "Shipping Rates"
- **Loading state:** `LoadingBlockDirective` overlay while rates are fetched

**Rates table columns:**

| Column | Alignment | Content |
|--------|-----------|---------|
| Carrier | Left | Carrier name (e.g., "UPS") |
| Service | Left | Service name (e.g., "Ground") |
| Price | Right | Currency format (monospace) |
| Days | Right | Estimated transit days with "d" suffix |

**Row interaction:** Clicking a rate row selects it (highlighted with `rates-table__row--selected` class).

**Footer buttons:**

| Button | Style | Condition |
|--------|-------|-----------|
| Cancel | `action-btn` | Always shown (label changes to "Done" after label creation) |
| Create Label | `action-btn--primary` | Shown until label is created; disabled when no rate selected or creating |

**Mock rates returned:**

| Carrier ID | Carrier | Service | Price | Days |
|------------|---------|---------|-------|------|
| `ups-ground` | UPS | Ground | $12.50 | 5 |
| `fedex-home` | FedEx | Home Delivery | $15.75 | 3 |
| `usps-priority` | USPS | Priority Mail | $8.90 | 4 |

**Empty state:** When no rates are returned, shows `local_shipping` icon with "No rates available" message.

### Label Generation

After selecting a rate and clicking "Create Label":

1. Calls `POST /api/v1/shipments/{id}/label` with `carrierId` and `serviceName`
2. The handler builds a `ShipmentRequest` from the shipment's shipping address and packages
3. The `IShippingService.CreateLabelAsync()` generates the label
4. The shipment's `trackingNumber` and `carrier` fields are updated with the label data
5. The dialog transitions to a "Label Created" success view

**Label Created view:**

- Success icon: `check_circle` (green)
- Title: "Label Created!"
- Carrier name display
- Tracking number display (monospace)
- "Download Label" link (opens `labelUrl` in new tab, if URL is present)

**Error handling:** Errors during rate fetching or label creation show an error snackbar.

### Tracking

Accessed via the "Track" button on the shipment detail panel (visible when a tracking number exists and the tracking timeline is not already displayed).

Calls `GET /api/v1/shipments/{id}/tracking`, which delegates to `IShippingService.GetTrackingAsync()`. Returns null if the shipment has no tracking number.

**Tracking data model:**

| Field | Type | Description |
|-------|------|-------------|
| `trackingNumber` | string | The tracking number |
| `status` | string | Current status text (e.g., "In Transit") |
| `estimatedDelivery` | string? | Estimated delivery date (ISO string) |
| `events` | TrackingEvent[] | Chronological list of tracking events |

Each `TrackingEvent` contains:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | Date | Event timestamp |
| `location` | string | Location description |
| `description` | string | Event description text |

---

## Manual Mode

Carrier and tracking number can be entered manually at shipment creation time (via the Carrier and Tracking Number fields in the create dialog) or updated later via the `PUT /api/v1/shipments/{id}` endpoint.

Manual mode is always available regardless of carrier integration status. The "Track" button will attempt to look up tracking information via `IShippingService.GetTrackingAsync()` even for manually entered tracking numbers -- the mock service returns canned tracking data for any tracking number, while real carrier integrations would validate the number format and query the carrier API.

---

## Entity Links

The shipment detail panel displays cross-entity links via `EntityLinkComponent`:

| Link | Entity Type | Condition | Target |
|------|-------------|-----------|--------|
| Sales Order | `sales-order` | Always shown | Opens SO detail dialog |
| Invoice | `invoice` | When `invoiceId` is present | Opens invoice detail dialog |

These links navigate via `?detail=type:id` URL pattern, opening the target entity's detail dialog.

---

## Every Button/Action

### List Page

| Button | Location | Icon | Action |
|--------|----------|------|--------|
| New Shipment | Page header, right | `add` | Opens create shipment dialog |
| (Row click) | Table row | -- | Opens shipment detail dialog |

### Create Dialog

| Button | Location | Icon | Action |
|--------|----------|------|--------|
| Add (line) | Below lines table | `add` | Adds part + quantity as a new line item |
| Remove (line) | Line item row | `close` | Removes the line from the list |
| Cancel | Dialog footer, left | -- | Closes the dialog without saving |
| Create Shipment | Dialog footer, right | `save` | Validates and creates the shipment |

### Detail Dialog

| Button | Location | Icon | Condition | Action |
|--------|----------|------|-----------|--------|
| Close | Header, right | `close` | Always | Closes the detail dialog |
| Get Rates | Actions section | `request_quote` | Status is Pending/Packed | Opens shipping rates dialog |
| Mark Shipped | Actions section | `local_shipping` | Status is Pending/Packed | Confirmation dialog, then transitions to Shipped |
| Track | Actions section | `location_searching` | Has tracking # and timeline not shown | Loads tracking data |
| Mark Delivered | Actions section | `check_circle` | Status is Shipped/InTransit | Confirmation dialog, then transitions to Delivered |
| Close Tracking | Tracking section header | `close` | Tracking timeline visible | Hides the tracking timeline |

### Shipping Rates Dialog

| Button | Location | Icon | Condition | Action |
|--------|----------|------|-----------|--------|
| (Rate row click) | Rates table | -- | Rates loaded | Selects the rate for label creation |
| Cancel / Done | Footer, left | -- | Always | Closes dialog ("Done" after label created) |
| Create Label | Footer, right | -- | Rate selected, label not yet created | Creates shipping label via carrier API |
| Download Label | Label result section | `download` | Label created with URL | Opens label PDF in new tab |

---

## API Endpoints

All endpoints are prefixed with `/api/v1/shipments`. All require `Authorization` header with JWT token and role of Admin, Manager, or OfficeManager.

### Core CRUD

#### `GET /api/v1/shipments`

List all shipments with optional filters.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `salesOrderId` | int | No | Filter by sales order |
| `status` | ShipmentStatus | No | Filter by status |

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "shipmentNumber": "SHP-00001",
    "salesOrderId": 10,
    "salesOrderNumber": "SO-00010",
    "customerName": "Acme Corp",
    "status": "Pending",
    "carrier": null,
    "trackingNumber": null,
    "shippedDate": null,
    "createdAt": "2026-03-15T00:00:00Z"
  }
]
```

#### `GET /api/v1/shipments/{id}`

Get shipment detail with lines.

**Response:** `200 OK`

```json
{
  "id": 1,
  "shipmentNumber": "SHP-00001",
  "salesOrderId": 10,
  "salesOrderNumber": "SO-00010",
  "customerName": "Acme Corp",
  "shippingAddressId": 5,
  "status": "Shipped",
  "carrier": "UPS",
  "trackingNumber": "1Z999AA10123456784",
  "shippedDate": "2026-03-16T14:30:00Z",
  "deliveredDate": null,
  "shippingCost": 15.75,
  "weight": 12.5,
  "notes": "Fragile -- handle with care",
  "invoiceId": null,
  "lines": [
    {
      "id": 1,
      "salesOrderLineId": 20,
      "partId": null,
      "description": "Widget Assembly A",
      "quantity": 50,
      "notes": null
    }
  ],
  "createdAt": "2026-03-15T00:00:00Z",
  "updatedAt": "2026-03-16T14:30:00Z"
}
```

#### `POST /api/v1/shipments`

Create a new shipment.

**Request Body:**

```json
{
  "salesOrderId": 10,
  "shippingAddressId": 5,
  "carrier": "UPS",
  "trackingNumber": "1Z999AA10123456784",
  "shippingCost": 15.75,
  "weight": 12.5,
  "notes": "Fragile",
  "lines": [
    {
      "salesOrderLineId": 20,
      "quantity": 50,
      "notes": null,
      "partId": null
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `salesOrderId` | int | Yes | Parent sales order (must not be Draft or Cancelled) |
| `shippingAddressId` | int? | No | Customer address ID (defaults to SO's shipping address) |
| `carrier` | string? | No | Carrier name |
| `trackingNumber` | string? | No | Tracking number |
| `shippingCost` | decimal? | No | Shipping cost |
| `weight` | decimal? | No | Total weight |
| `notes` | string? | No | Free-text notes |
| `lines` | array | Yes | At least one line required |
| `lines[].salesOrderLineId` | int? | Conditional | SO line ID (required if no `partId`) |
| `lines[].partId` | int? | Conditional | Part ID (required if no `salesOrderLineId`) |
| `lines[].quantity` | int | Yes | Must be > 0 |
| `lines[].notes` | string? | No | Line-level notes |

**Response:** `201 Created` with `Location` header pointing to `GET /api/v1/shipments/{id}`.

**Validation errors (400):**
- `salesOrderId` must be > 0
- Lines must not be empty
- Each line must reference either a sales order line or a part
- Quantity must be > 0

**Business errors:**
- `404` -- Sales order not found
- `400` (InvalidOperationException) -- Cannot create shipment for Draft or Cancelled orders
- `400` (InvalidOperationException) -- Cannot ship more than remaining quantity on SO line

#### `PUT /api/v1/shipments/{id}`

Update shipment fields. Only non-null fields are applied (partial update semantics despite PUT verb).

**Request Body:**

```json
{
  "carrier": "FedEx",
  "trackingNumber": "794644790132",
  "shippingCost": 22.00,
  "weight": 15.0,
  "notes": "Updated notes"
}
```

All fields are optional. Only provided (non-null) fields are updated.

**Response:** `204 No Content`

**Business errors:**
- `404` -- Shipment not found
- `400` (InvalidOperationException) -- Cannot update Delivered or Cancelled shipments

### Status Transitions

#### `POST /api/v1/shipments/{id}/ship`

Transition shipment to `Shipped` status. Sets `shippedDate` to current UTC time.

**Request Body:** Empty (`{}`)

**Response:** `204 No Content`

**Precondition:** Status must be `Pending` or `Packed`. Returns `400` otherwise.

#### `POST /api/v1/shipments/{id}/deliver`

Transition shipment to `Delivered` status. Sets `deliveredDate` to current UTC time.

**Request Body:** Empty (`{}`)

**Response:** `204 No Content`

**Precondition:** Status must be `Shipped` or `InTransit`. Returns `400` otherwise.

### PDF Documents

#### `GET /api/v1/shipments/{id}/packing-slip`

Generate and download a packing slip PDF.

**Response:** `200 OK` with `Content-Type: application/pdf`, filename `packing-slip-{id}.pdf`.

Includes: company name (from system settings), customer info, shipping address, line items with part numbers and quantities.

#### `GET /api/v1/shipments/{id}/bill-of-lading`

Generate and download a bill of lading PDF.

**Response:** `200 OK` with `Content-Type: application/pdf`, filename `bill-of-lading-{id}.pdf`.

Includes: company name, address, and phone (from system settings), customer info, shipping address, line items, and package details (dimensions and weights).

### Carrier Integration

#### `POST /api/v1/shipments/{id}/rates`

Get shipping rates from the configured carrier service.

**Request Body:**

```json
{
  "fromAddress": {
    "name": "Warehouse",
    "street": "123 Main St",
    "city": "Springfield",
    "state": "IL",
    "zip": "62704",
    "country": "US"
  },
  "toAddress": {
    "name": "Customer",
    "street": "456 Oak Ave",
    "city": "Chicago",
    "state": "IL",
    "zip": "60601",
    "country": "US"
  },
  "packages": [
    {
      "weightLbs": 10.0,
      "lengthIn": 12.0,
      "widthIn": 8.0,
      "heightIn": 6.0
    }
  ],
  "serviceType": null
}
```

**Response:** `200 OK`

```json
[
  {
    "carrierId": "ups-ground",
    "carrierName": "UPS",
    "serviceName": "Ground",
    "price": 12.50,
    "estimatedDays": 5
  }
]
```

**Validation:** `fromAddress`, `toAddress`, and at least one package are required.

Note: The frontend `ShipmentService.getRates()` calls `GET /api/v1/shipments/{id}/rates` (without a body), while the backend expects a `POST` with address/package data. The frontend rates dialog calls this endpoint to fetch available rates.

#### `POST /api/v1/shipments/{id}/label`

Create a shipping label via the carrier service.

**Request Body:**

```json
{
  "carrierId": "ups-ground"
}
```

**Response:** `200 OK`

```json
{
  "trackingNumber": "MOCK-UPS-GROUND-a1b2c3d4e5",
  "labelUrl": "mock:///labels/MOCK-UPS-GROUND-a1b2c3d4e5.pdf",
  "carrierName": "UPS"
}
```

**Side effects:**
- Updates the shipment's `trackingNumber` and `carrier` fields with the label data
- Saves changes to the database

**Business errors:**
- `404` -- Shipment not found
- `400` (InvalidOperationException) -- Shipment has no shipping address assigned

#### `GET /api/v1/shipments/{id}/tracking`

Get tracking information for a shipment via the carrier service.

**Response:** `200 OK`

```json
{
  "trackingNumber": "1Z999AA10123456784",
  "status": "In Transit",
  "estimatedDelivery": "2026-03-20T00:00:00Z",
  "events": [
    {
      "timestamp": "2026-03-16T10:00:00Z",
      "location": "Origin Facility",
      "description": "Package picked up"
    },
    {
      "timestamp": "2026-03-17T08:00:00Z",
      "location": "Distribution Center",
      "description": "In transit to destination"
    }
  ]
}
```

Returns `null` if the shipment has no tracking number.

### Address Validation

#### `POST /api/v1/shipments/validate-address`

Validate a shipping address via the `IAddressValidationService`.

**Request Body:**

```json
{
  "street": "123 Main St",
  "city": "Springfield",
  "state": "IL",
  "zip": "62704",
  "country": "US"
}
```

All fields are required. Delegates to `IAddressValidationService.ValidateAsync()` (USPS or mock).

### Packages

#### `GET /api/v1/shipments/{id}/packages`

List all packages for a shipment, ordered by ID.

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "shipmentId": 42,
    "trackingNumber": null,
    "carrier": null,
    "weight": 10.0,
    "length": 12.0,
    "width": 8.0,
    "height": 6.0,
    "status": "Pending"
  }
]
```

#### `POST /api/v1/shipments/{id}/packages`

Add a package to a shipment.

**Request Body:**

```json
{
  "trackingNumber": null,
  "carrier": null,
  "weight": 10.0,
  "length": 12.0,
  "width": 8.0,
  "height": 6.0
}
```

All fields are optional.

**Response:** `201 Created`

#### `PATCH /api/v1/shipments/{id}/packages/{packageId}`

Update a package. Only non-null fields are applied.

**Request Body:**

```json
{
  "weight": 12.5,
  "status": "Packed"
}
```

Updatable fields: `trackingNumber`, `carrier`, `weight`, `status`.

**Response:** `200 OK` with updated package.

#### `DELETE /api/v1/shipments/{id}/packages/{packageId}`

Remove a package. This is a hard delete (not soft delete).

**Response:** `204 No Content`

---

## Status Lifecycle

### Statuses

| Status | Description |
|--------|-------------|
| `Pending` | Initial state. Shipment created, not yet packed or shipped. |
| `Packed` | Items are packed and ready for pickup/shipping. |
| `Shipped` | Shipment has been handed off to the carrier. `shippedDate` is set. |
| `InTransit` | Carrier has confirmed the shipment is in transit (typically set by tracking updates). |
| `Delivered` | Shipment has been delivered. `deliveredDate` is set. Terminal state. |
| `Cancelled` | Shipment has been cancelled. Terminal state. |

### Transition Rules

```
Pending ──────────────────────────┐
   │                              │
   v                              v
Packed ────────> Shipped ────> InTransit ────> Delivered
                    │                              
                    └──────────────────────────────> Delivered
```

| Transition | Endpoint | Allowed From | Sets |
|------------|----------|-------------|------|
| Ship | `POST /{id}/ship` | Pending, Packed | `shippedDate = UtcNow` |
| Deliver | `POST /{id}/deliver` | Shipped, InTransit | `deliveredDate = UtcNow` |

**Update restrictions:**
- `Delivered` and `Cancelled` shipments cannot be updated via `PUT /{id}`

**Notes:**
- There is no explicit API endpoint to transition to `Packed`, `InTransit`, or `Cancelled` statuses. The `Packed` status can be reached via direct database update or future UI. `InTransit` is intended to be set by carrier tracking webhook integration. `Cancelled` would require a dedicated cancel endpoint (not yet implemented).
- Shipment creation always starts in `Pending` status.

### Impact on Sales Order Status

When shipment lines reference SO lines, the create handler automatically updates the parent sales order's status:

| Condition | SO Status Set To |
|-----------|-----------------|
| All SO lines fully shipped | `Shipped` |
| Any SO line partially shipped | `PartiallyShipped` |

---

## Data Model

### Shipment Entity

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | int | No | Primary key (auto-increment) |
| `shipment_number` | string | No | Auto-generated (e.g., "SHP-00001") |
| `sales_order_id` | int | No | FK to `sales_orders` |
| `shipping_address_id` | int? | Yes | FK to `customer_addresses` |
| `status` | ShipmentStatus | No | Default: `Pending` |
| `carrier` | string? | Yes | Carrier name |
| `tracking_number` | string? | Yes | Tracking number |
| `shipped_date` | timestamptz? | Yes | When shipment was shipped |
| `delivered_date` | timestamptz? | Yes | When shipment was delivered |
| `shipping_cost` | decimal? | Yes | Shipping cost |
| `weight` | decimal? | Yes | Total weight (lbs) |
| `notes` | string? | Yes | Free-text notes |
| `created_at` | timestamptz | No | Auto-set by `BaseEntity` |
| `updated_at` | timestamptz | No | Auto-set by `BaseEntity` |
| `deleted_at` | timestamptz? | Yes | Soft delete timestamp |
| `created_by` | int? | Yes | FK to user (from `BaseAuditableEntity`) |

**Navigation properties:** `SalesOrder`, `ShippingAddress`, `Lines` (collection), `Packages` (collection), `Invoice`

### ShipmentLine Entity

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | int | No | Primary key |
| `shipment_id` | int | No | FK to `shipments` |
| `sales_order_line_id` | int? | Yes | FK to `sales_order_lines` |
| `part_id` | int? | Yes | FK to `parts` |
| `quantity` | int | No | Quantity shipped |
| `notes` | string? | Yes | Line-level notes |

**Navigation properties:** `Shipment`, `SalesOrderLine`, `Part`

### ShipmentPackage Entity

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `id` | int | No | Primary key |
| `shipment_id` | int | No | FK to `shipments` |
| `tracking_number` | string? | Yes | Per-package tracking |
| `carrier` | string? | Yes | Carrier name |
| `weight` | decimal? | Yes | Weight (lbs) |
| `length` | decimal? | Yes | Length (inches) |
| `width` | decimal? | Yes | Width (inches) |
| `height` | decimal? | Yes | Height (inches) |
| `status` | string | No | Default: "Pending" |

---

## Known Limitations

1. **No cancel endpoint.** There is no API endpoint to transition a shipment to `Cancelled` status. This would need to be added, along with logic to reverse SO line `ShippedQuantity` adjustments.

2. **No transition to Packed or InTransit.** The `Packed` and `InTransit` statuses exist in the enum but have no dedicated API endpoints. `Packed` would need a `POST /{id}/pack` endpoint. `InTransit` is intended for carrier tracking webhook integration, which is not yet built.

3. **No edit dialog.** The create dialog exists but there is no edit dialog for modifying an existing shipment's lines or details in the UI. Updates to carrier, tracking number, weight, cost, and notes are possible via the `PUT` API endpoint but not exposed in the frontend.

4. **Package management has no UI.** Packages can be created, updated, and deleted via API endpoints, but there is no package management panel in the shipment detail dialog. Packages are consumed by the label generation flow (dimensions/weights for rate shopping).

5. **Carrier integrations are mock-only.** Direct carrier API integrations (UPS, FedEx, USPS, DHL) are not yet implemented. The `MockShippingService` returns canned rates and tracking data. The interface and factory pattern are in place for real implementations.

6. **Label generation uses placeholder origin address.** The `CreateShippingLabelHandler` builds a hardcoded origin address (`"123 Warehouse St"`) rather than pulling from system settings or company location configuration. This would need to use the company's primary location address in production.

7. **Frontend rate request mismatch.** The frontend `ShipmentService.getRates()` uses `GET` to fetch rates (no body), while the backend `POST /{id}/rates` expects from/to addresses and package dimensions in the request body. The shipping rates dialog calls this from the UI but the rate shopping flow on the frontend may need adjustment to pass address and package data properly.

8. **No void/refund for labels.** Once a shipping label is created, there is no mechanism to void or refund it. This would require carrier-specific void APIs.

9. **Tracking is pull-only.** Tracking data is fetched on-demand when the user clicks "Track." There is no webhook or polling mechanism to automatically update tracking status as the shipment progresses.

10. **No partial shipment line editing.** Once a shipment is created with its lines, individual lines cannot be added, removed, or modified. Adjusting quantities or lines requires creating a new shipment.
