# Inventory

## Overview

The Inventory module provides warehouse and bin-level stock tracking for parts and materials. It manages the full lifecycle of physical inventory: receiving goods from purchase orders, storing items in hierarchical bin locations, transferring stock between bins, reserving stock for jobs and orders, counting stock via cycle counts, and monitoring consumption rates for automated replenishment.

Inventory is organized around a **warehouse/bin hierarchy** (Area > Rack > Shelf > Bin) where only Bin-type locations hold physical stock. Each piece of stock in a bin is represented as a `BinContent` record with a quantity, status, optional lot number, and job association. Every stock change (receive, pick, transfer, adjust, ship, return) creates a `BinMovement` audit record.

The module also provides Available-to-Promise (ATP) calculations, Units of Measure (UOM) management with cross-unit conversions, receiving inspection workflows, low-stock alerting, and automated reorder suggestions based on burn rate analysis.

---

## Routes & Navigation

The Inventory feature is a single component with tab-based navigation using a `:tab` route parameter.

| Route | Tab | Description |
|-------|-----|-------------|
| `/inventory` | (redirects) | Redirects to `/inventory/stock` |
| `/inventory/stock` | Stock Levels | Per-part inventory summary with expandable bin details |
| `/inventory/locations` | Locations | Storage location hierarchy tree + detail panel |
| `/inventory/movements` | Movements | Chronological bin movement history |
| `/inventory/receiving` | Receiving | Receiving records from purchase orders |
| `/inventory/stockOps` | Stock Ops | Transfer and adjust stock operations |
| `/inventory/cycleCounts` | Cycle Counts | Cycle count creation, review, approval |
| `/inventory/reservations` | Reservations | Active stock reservations for jobs/orders |
| `/inventory/replenishment` | Replenishment | Burn rate analysis + reorder suggestions |
| `/inventory/uom` | Units of Measure | UOM definitions and conversion rules |

**Route definition** (`inventory.routes.ts`):
```
{ path: '', redirectTo: 'stock', pathMatch: 'full' },
{ path: ':tab', component: InventoryComponent },
```

Tabs are rendered as a horizontal `tab-bar` with icons. The active tab is derived from the route parameter. Tab clicks call `switchTab()` which navigates via `router.navigate(['..', tab], { relativeTo: this.route })`.

Tab icons:
- Stock Levels: `inventory`
- Locations: `warehouse`
- Movements: `swap_horiz`
- Receiving: `local_shipping`
- Stock Ops: `tune`
- Cycle Counts: `fact_check`
- Reservations: `lock`
- Replenishment: `shopping_cart` (badge with pending suggestion count)
- Units of Measure: `straighten`

---

## Access & Permissions

**Controller authorization** (`InventoryController`):
```
[Authorize(Roles = "Admin,Manager,OfficeManager,Engineer,ProductionWorker")]
```

All five operational roles can access inventory for reading and basic operations (receive, transfer, reserve, create cycle counts).

**Restricted operations:**

| Operation | Required Roles | Endpoint |
|-----------|---------------|----------|
| Adjust Stock | Admin, Manager | `POST /api/v1/inventory/adjust` |
| Approve/Reject Cycle Count | Admin, Manager | `PUT /api/v1/inventory/cycle-counts/{id}` |
| Waive Inspection | Admin, Manager | `POST /api/v1/inventory/inspect/{id}/waive` |
| Create/Update UOM | Admin, Manager | `POST/PUT /api/v1/inventory/uom` |
| Create UOM Conversion | Admin, Manager | `POST /api/v1/inventory/uom/conversions` |
| Replenishment (all) | Admin, Manager | `GET/POST /api/v1/replenishment/*` |

---

## Stock Levels Tab

The default tab. Shows a per-part summary of on-hand, reserved, and available quantities across all bin locations.

### Low Stock Banner

When `GET /api/v1/inventory/low-stock` returns alerts, a yellow warning banner appears at the top:

- Icon: `warning`
- Text: `{count} part(s) below minimum stock threshold`
- Action button: "Create PO" -- navigates to `/purchase-orders`

The banner renders as `role="alert"` for accessibility.

### Search

A search input at the top filters the part inventory list. The search term is passed as a `?search=` query parameter to `GET /api/v1/inventory/parts`. Beside the search field:
- A clear button (`close` icon) appears when search has a value
- A count label shows `{n} parts with stock`

### DataTable

Table ID: `inventory-stock`

| Column | Header | Sortable | Width | Align | Notes |
|--------|--------|----------|-------|-------|-------|
| `partNumber` | Part # | Yes | 120px | left | Rendered in monospace `.part-number` style |
| `description` | Description | Yes | auto | left | Plain text |
| `material` | Material | Yes | 140px | left | Muted text, shows dash if null |
| `onHand` | On Hand | Yes | 90px | right | Total across all bins |
| `reserved` | Reserved | Yes | 90px | right | Shows dash if zero |
| `available` | Available | Yes | 90px | right | Red text (`.qty-zero`) when <= 0 |

**Row classes:**
- `stock-level--empty`: applied when `available <= 0`
- `stock-level--low`: applied when `available < onHand * 0.2` (below 20% of on-hand)

**Expandable rows:** Each row expands to show bin-level detail via `<ng-template appRowExpand>`. Track field: `partId`.

### Expanded Bin Detail Table

When a stock row is expanded, an inline table shows per-bin breakdown:

| Column | Header | Align | Notes |
|--------|--------|-------|-------|
| Bin Location | left | Full path (e.g., "Warehouse A > Rack 1 > Shelf 2 > Bin 3") |
| On Hand | right | Quantity at that bin |
| Reserved | right | Reserved quantity, styled with `.qty-reserved` class if > 0, dash if zero |
| Available | right | Available quantity, red text if <= 0 |
| Status | left | Chip styled by status (see Status section) |
| Lot # | left | Muted chip if present, dash if null |
| Expiration | left | Date formatted `MM/dd/yyyy`, color-coded: `.lot-expired` if past, `.lot-expiring-soon` if within 30 days |

**Data model** (`BinStock`):

```typescript
interface BinStock {
  locationId: number;
  locationName: string;
  locationPath: string;
  quantity: number;
  reservedQuantity: number;
  availableQuantity: number;
  status: BinContentStatus;
  lotNumber: string | null;
  lotId: number | null;
  lotExpirationDate: string | null;
  supplierLotNumber: string | null;
}
```

---

## Locations Tab

Split-panel layout: a tree view on the left and a detail panel on the right.

### Location Tree (Left Panel)

Renders the storage location hierarchy up to 4 levels deep (Area > Rack > Shelf > Bin). Each node shows:
- Expand/collapse toggle (if node has children)
- Icon based on location type: `warehouse` (Area), `view_column` (Rack), `shelves` (Shelf), `inventory_2` (Bin)
- Location name
- Content count badge (if > 0)

Tree nodes support keyboard navigation (`tabindex="0"`, Enter to select, `aria-label` for screen readers). Indentation increases per level via CSS classes `tree-node--l1`, `tree-node--l2`, `tree-node--l3`.

The expand/collapse state is tracked in a `Set<number>` signal (`expandedLocationIds`).

**Empty state:** When no locations exist, shows `<app-empty-state icon="warehouse" message="No locations configured" />`.

### Location Detail (Right Panel)

When a location is selected, the right panel shows:

1. **Header**: Location type icon, name, full path, and "Add Child" button
2. **Metadata**: Type label, barcode info via `<app-barcode-info>`, description (if present)
3. **Contents table** (Bin-type only): When the selected location is a Bin and has contents

**Bin Contents Table columns:**

| Column | Notes |
|--------|-------|
| Item | Entity name |
| Qty | Quantity |
| Status | Chip with status-specific styling |
| Lot # | Muted text, dash if null |
| Placed | Date formatted `MM/dd/yyyy hh:mm a` |

**Empty states:**
- Bin with no contents: `icon="inventory_2"`, message "Bin is empty"
- No location selected: `icon="touch_app"`, message "Select a location to view details"

### Page Header Button

When the Locations tab is active, the page header shows:
- **Add Location** button (primary, `add` icon)

### Add Location Dialog

Opened by: "Add Location" button in page header, or "Add Child" button in location detail.

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `name` | Name | Text input | Yes | `Validators.required` | |
| `locationType` | Type | Select | Yes | `Validators.required` | Options: Area, Rack, Shelf, Bin |
| `barcode` | Barcode | Text input | No | none | Only shown when type is Bin |
| `description` | Description | Text input | No | none | |
| `parentId` | (hidden) | number | No | none | Set programmatically when adding child |

**Default type logic:** When opened from "Add Child", type defaults to `Rack`; when opened from page header, defaults to `Area`.

**Validation popover labels:** Name, Type

**Footer buttons:**
- Cancel (secondary)
- Create Location (primary, disabled when form invalid or saving)

**On save:** `POST /api/v1/inventory/locations` -- reloads location tree, shows snackbar "Location created".

---

## Movements Tab

Shows a chronological log of all bin movements.

### DataTable

Table ID: `inventory-movements`

| Column | Field | Header | Sortable | Width | Align | Notes |
|--------|-------|--------|----------|-------|-------|-------|
| Item | `entityName` | Item | Yes | auto | left | |
| Qty | `quantity` | Qty | Yes | 70px | right | |
| From | `fromLocationName` | From | Yes | auto | left | Muted, dash if null |
| To | `toLocationName` | To | Yes | auto | left | Muted, dash if null |
| Reason | `reason` | Reason | Yes | 120px | left | Displayed as chip with human-readable label |
| By | `movedByName` | By | Yes | auto | left | |
| When | `movedAt` | When | Yes | 120px | left | Date type, formatted `MM/dd/yyyy hh:mm a` |

**Reason labels (mapped from enum values):**

| Enum Value | Display Label |
|------------|---------------|
| `Receive` | Received |
| `Pick` | Picked |
| `Restock` | Restocked |
| `QcRelease` | QC Released |
| `Ship` | Shipped |
| `Move` | Moved |
| `Adjustment` | Adjusted |
| `Return` | Returned |
| `Transfer` | Transferred |
| `CycleCount` | Cycle Count |

**Empty state:** `icon="swap_horiz"`, message "No movement history"

**Data source:** `GET /api/v1/inventory/movements?take=100`

---

## Receiving Tab

Shows receiving records from purchase orders and provides a dialog to record new receipts.

### Page Header Button

When the Receiving tab is active:
- **Receive Goods** button (primary, `add` icon)

### DataTable

Table ID: `inventory-receiving`

| Column | Field | Header | Sortable | Width | Align | Notes |
|--------|-------|--------|----------|-------|-------|-------|
| PO # | `purchaseOrderNumber` | PO # | Yes | 110px | left | Monospace `.part-number`, dash if null |
| Part # | `partNumber` | Part # | Yes | 120px | left | Monospace `.part-number`, dash if null |
| Qty | `quantityReceived` | Qty | Yes | 70px | right | |
| Received By | `receivedBy` | Received By | Yes | auto | left | |
| Location | `storageLocationName` | Location | Yes | auto | left | Muted, dash if null |
| Lot # | `lotNumber` | Lot # | Yes | 100px | left | Muted, dash if null |
| Date | `createdAt` | Date | Yes | 120px | left | Date type, formatted `MM/dd/yyyy hh:mm a` |

**Empty state:** `icon="local_shipping"`, message "No receiving records"

**Data source:** `GET /api/v1/inventory/receiving-history?take=50`

### Receive Goods Dialog

Opened by: "Receive Goods" button in page header.

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `purchaseOrderLineId` | PO Line ID | Select | Yes | `Validators.required` | Populated from open POs. Format: `{poNumber} -- {partNumber} ({remainingQty} remaining)` |
| `quantityReceived` | Quantity Received | Number input | Yes | `Validators.required`, `Validators.min(1)` | |
| `locationId` | Bin Location | Select | No | none | Dropdown of all bin locations, includes "-- None --" option |
| `lotNumber` | Lot # | Text input | No | none | |
| `notes` | Notes | Textarea (2 rows) | No | none | |

**PO Line population logic:** When the dialog opens, the system:
1. Fetches all purchase orders via `PurchaseOrderService.getPurchaseOrders()`
2. Filters to POs with status in `['Submitted', 'Acknowledged', 'PartiallyReceived']`
3. For each open PO, fetches full detail and filters lines where `remainingQuantity > 0`
4. Builds select options from those lines

**Validation popover labels:** PO Line ID, Quantity

**Footer buttons:**
- Cancel (secondary)
- Receive (primary, disabled when form invalid or saving)

**On save:** `POST /api/v1/inventory/receive` -- reloads receiving history, shows snackbar "Goods received".

---

## Stock Operations Tab

Displays two large operation cards in a grid layout:

1. **Transfer Stock** (`swap_horiz` icon) -- "Move stock between bin locations"
2. **Adjust Stock** (`tune` icon) -- "Correct inventory discrepancies"

Each card is keyboard-accessible (`role="button"`, `tabindex="0"`, Enter to activate).

### Page Header Buttons

When the Stock Ops tab is active:
- **Transfer** button (secondary, `swap_horiz` icon)
- **Adjust** button (secondary, `tune` icon)

### Transfer Stock Dialog

Opened by: Transfer card or Transfer header button.

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `sourceBinContentId` | Source Bin Content ID | Number input | Yes | `Validators.required` | Numeric ID of the bin content to move |
| `destinationLocationId` | Destination Location | Select | Yes | `Validators.required` | Dropdown of all bin locations |
| `quantity` | Quantity | Number input | Yes | `Validators.required`, `Validators.min(1)` | |
| `notes` | Notes | Textarea (2 rows) | No | none | |

**Validation popover labels:** Source Bin Content, Destination, Quantity

**Footer buttons:**
- Cancel (secondary)
- Transfer (primary, disabled when form invalid or saving)

**On save:** `POST /api/v1/inventory/transfer` -- reloads stock tab, shows snackbar "Stock transferred".

### Adjust Stock Dialog

Opened by: Adjust card or Adjust header button. **Restricted to Admin and Manager roles** on the backend.

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `binContentId` | Bin Content ID | Number input | Yes | `Validators.required` | |
| `newQuantity` | New Quantity | Number input | Yes | `Validators.required`, `Validators.min(0)` | Absolute target quantity (not delta) |
| `reason` | Reason | Text input | Yes | `Validators.required` | Free-text justification |
| `notes` | Notes | Textarea (2 rows) | No | none | |

**Validation popover labels:** Bin Content, New Quantity, Reason

**Footer buttons:**
- Cancel (secondary)
- Adjust (primary, disabled when form invalid or saving)

**On save:** `POST /api/v1/inventory/adjust` -- reloads stock tab, shows snackbar "Stock adjusted".

---

## Cycle Counts Tab

Cycle counts verify physical stock against system records for a specific bin location.

### Page Header Button

When the Cycle Counts tab is active:
- **New Count** button (primary, `add` icon)

### DataTable

Table ID: `inventory-cycle-counts`

| Column | Field | Header | Sortable | Filterable | Width | Align | Notes |
|--------|-------|--------|----------|-----------|-------|-------|-------|
| Location | `locationName` | Location | Yes | No | auto | left | |
| Counted By | `countedByName` | Counted By | Yes | No | auto | left | |
| Date | `countedAt` | Date | Yes | No | 120px | left | Date type, formatted `MM/dd/yyyy hh:mm a` |
| Status | `status` | Status | Yes | Yes (enum) | 110px | left | Filter options: Pending, Approved, Rejected |
| Items | `lineCount` | Items | Yes | No | 70px | right | Computed client-side from `lines.length` |
| Variance | `variance` | Variance | Yes | No | 90px | right | Computed sum of absolute line variances |

**Status chip classes:**
- Pending: `chip--warning`
- Approved: `chip--success`
- Rejected: `chip--error`

**Variance display:** Shows red text (`variance--negative`) when > 0, muted "0" when zero.

Rows are clickable (`clickableRows: true`) and open the cycle count detail dialog.

**Empty state:** `icon="fact_check"`, message "No cycle counts"

### Create Cycle Count Dialog

Opened by: "New Count" button in page header.

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `locationId` | Location | Select | Yes | `Validators.required` | Dropdown of all bin locations |
| `notes` | Notes | Textarea (2 rows) | No | none | |

**Validation popover labels:** Location

**Footer buttons:**
- Cancel (secondary)
- Create (primary, disabled when form invalid or saving)

**On save:** `POST /api/v1/inventory/cycle-counts` -- reloads list, shows snackbar "Cycle count created", then immediately opens the new cycle count in the detail dialog.

### Cycle Count Detail Dialog

Opened by: clicking a row in the cycle counts DataTable, or automatically after creating a new count.

**Width:** 800px

**Header info:**
- Counted By: user name
- Date: formatted `MM/dd/yyyy hh:mm a`
- Status: chip with status-specific class

**Line items table:**

| Column | Notes |
|--------|-------|
| Item | Entity name |
| Expected | System quantity |
| Actual | Editable inline `<input type="number">` when status is Pending; read-only text otherwise |
| Variance | Color-coded: positive shows `+` prefix, uses `variance--positive` / `variance--negative` class |
| Notes | Muted text, dash if null |

**Empty state row:** "No items at this location" (colspan 5)

**Footer buttons (only shown when status is Pending):**
- Reject (danger, secondary, left-aligned)
- Approve & Adjust (primary, disabled when saving)

**Approve:** `PUT /api/v1/inventory/cycle-counts/{id}` with `status: 'Approved'` and all line data. Reloads list, shows snackbar "Cycle count approved".

**Reject:** `PUT /api/v1/inventory/cycle-counts/{id}` with `status: 'Rejected'`. Reloads list, shows snackbar "Cycle count rejected".

---

## Reservations Tab

Shows active stock reservations and allows creating new ones.

### Page Header Button

When the Reservations tab is active:
- **Reserve Stock** button (primary, `add` icon)

### DataTable

Table ID: `inventory-reservations`

| Column | Field | Header | Sortable | Width | Align | Notes |
|--------|-------|--------|----------|-------|-------|-------|
| Part # | `partNumber` | Part # | Yes | 120px | left | Monospace `.part-number` |
| Description | `partDescription` | Description | Yes | auto | left | |
| Bin Location | `locationPath` | Bin Location | Yes | auto | left | |
| Qty | `quantity` | Qty | Yes | 80px | right | |
| Job # | `jobNumber` | Job # | Yes | 100px | left | Muted, dash if null |
| Job | `jobTitle` | Job | Yes | auto | left | Muted, dash if null |
| Notes | `notes` | Notes | No | auto | left | Muted, dash if null |
| Reserved | `createdAt` | Reserved | Yes | 120px | left | Date type, formatted `MM/dd/yyyy hh:mm a` |
| Actions | `actions` | (empty) | No | 60px | left | Release button |

**Actions column:** Each row has a danger icon button (`lock_open` icon) to release the reservation. The button has:
- `aria-label="Release reservation"`
- Tooltip: "Release reservation"
- Disabled when `saving()` is true
- Click stops propagation

**Empty state:** `icon="lock"`, message "No active reservations"

**Data source:** `GET /api/v1/inventory/reservations` with optional `?partId=` and `?jobId=` filters.

### Reserve Stock Dialog

Opened by: "Reserve Stock" button in page header.

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `partId` | Part ID | Number input | Yes | `Validators.required` | Numeric part ID |
| `binContentId` | Bin Content ID | Number input | Yes | `Validators.required` | Numeric bin content ID |
| `jobId` | Job ID (Optional) | Number input | No | none | |
| `quantity` | Quantity | Number input | Yes | `Validators.required`, `Validators.min(0.001)` | Supports fractional quantities |
| `notes` | Notes | Textarea (2 rows) | No | none | |

**Validation popover labels:** Part ID, Bin Content ID, Quantity

**Footer buttons:**
- Cancel (secondary)
- Reserve (primary, disabled when form invalid or saving)

**On save:** `POST /api/v1/inventory/reservations` -- reloads reservations and stock, shows snackbar "Reservation created".

**Release reservation:** `DELETE /api/v1/inventory/reservations/{id}` -- reloads reservations and stock, shows snackbar "Reservation released".

---

## Replenishment Tab

Provides burn rate analysis and automated reorder suggestions. **Restricted to Admin and Manager roles** via the `ReplenishmentController`.

### Pending Reorder Suggestions Section

When there are pending suggestions, a section appears with:
- Header: `notification_important` icon, "Pending Reorder Suggestions", warning chip with count
- Bulk approve button (shown when rows are selected): "Approve Selected ({count})"

**Suggestions DataTable** (Table ID: `replenishment-suggestions`, selectable):

| Column | Field | Header | Sortable | Width | Align | Notes |
|--------|-------|--------|----------|-------|-------|-------|
| Part # | `partNumber` | Part # | Yes | 120px | left | Monospace |
| Description | `partDescription` | Description | Yes | auto | left | |
| Vendor | `vendorName` | Vendor | Yes | 140px | left | Muted, dash if null |
| Available | `availableStock` | Available | Yes | 80px | right | Number formatted `1.0-2` |
| Burn/Day | `burnRateDailyAvg` | Burn/Day | Yes | 80px | right | Monospace, `1.2-2` format |
| Days Left | `daysOfStockRemaining` | Days Left | Yes | 80px | right | Color-coded chip (see below) |
| Stockout | `projectedStockoutDate` | Stockout | Yes | 100px | left | Date type, color-coded |
| Suggest Qty | `suggestedQuantity` | Suggest Qty | Yes | 90px | right | Monospace, `1.0-2` format |
| Actions | `actions` | (empty) | No | 120px | right | Approve + Dismiss buttons |

**Days remaining color coding:**
- <= 7 days: `chip chip--error`
- <= 21 days: `chip chip--warning`
- > 21 days: `chip chip--muted`

**Actions per row:**
- **Approve** (primary small button, `shopping_cart` icon): Approves the suggestion, creates a draft PO
- **Dismiss** (icon button, `close` icon): Opens the dismiss dialog

**Empty state (no pending suggestions):** Green check icon with message "No pending reorder suggestions -- inventory levels look good."

### Burn Rate Analysis Section

Shows consumption analysis for all tracked parts.

**Controls:**
- Search input: "Search parts" (Enter to apply)
- "Needs Reorder" toggle button: filters to parts that need reordering (highlights as primary when active)
- Refresh icon button

**Burn Rate DataTable** (Table ID: `inventory-burn-rates`):

| Column | Field | Header | Sortable | Width | Align | Notes |
|--------|-------|--------|----------|-------|-------|-------|
| Part # | `partNumber` | Part # | Yes | 120px | left | |
| Description | `partDescription` | Description | Yes | auto | left | |
| Vendor | `preferredVendorName` | Vendor | Yes | 140px | left | |
| Available | `availableStock` | Available | Yes | 90px | right | |
| On Order | `incomingPoQuantity` | On Order | Yes | 80px | right | |
| 30d / day | `burnRate30Day` | 30d / day | Yes | 80px | right | Monospace, 2 decimal places, dash if null |
| 60d / day | `burnRate60Day` | 60d / day | Yes | 80px | right | Same format |
| 90d / day | `burnRate90Day` | 90d / day | Yes | 80px | right | Same format |
| Days Left | `daysOfStockRemaining` | Days Left | Yes | 80px | right | Color-coded chip |
| Stockout | `projectedStockoutDate` | Stockout | Yes | 100px | left | Date type |
| Reorder | `needsReorder` | Reorder | Yes | 80px | center | Chip: "Yes" (error) or "OK" (success) |

**Row class:** `row--warning` applied when `needsReorder` is true.

**Empty state:** "No burn rate data -- start receiving and picking parts to build history"

**Data source:** `GET /api/v1/replenishment/burn-rates?search=&needsReorderOnly=true|false`

### Dismiss Suggestion Dialog

Opened by: Dismiss button on a suggestion row.

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `dismissReason` | Reason | Textarea (3 rows) | Yes | `Validators.required`, `Validators.maxLength(500)` | Explanation text |

**Contextual text:** "Dismissing the suggestion for {partNumber}. Please provide a reason so it can be reviewed later."

**Footer buttons:**
- Cancel (secondary)
- Dismiss (primary, disabled when control invalid or saving)

**On save:** `POST /api/v1/replenishment/suggestions/{id}/dismiss` -- reloads suggestions, shows snackbar "Suggestion dismissed".

### Bulk Approve

When one or more suggestions are selected via checkboxes:
- "Approve Selected ({count})" button appears in the section header
- `POST /api/v1/replenishment/suggestions/approve-bulk` with `{ suggestionIds: [...] }`
- On success: clears selection, reloads suggestions, shows snackbar "Approved {n} suggestions -- {n} PO(s) created"

---

## Units of Measure (UOM) Tab

Rendered as a child component (`UomManagementComponent`) with its own sub-tabs.

### Sub-Tabs

- **Units of Measure**: CRUD for UOM definitions
- **Conversions**: CRUD for cross-unit conversion rules

### UOM DataTable

Table ID: `uom-list`

| Column | Field | Header | Sortable | Filterable | Width | Align | Notes |
|--------|-------|--------|----------|-----------|-------|-------|-------|
| Code | `code` | Code | Yes | No | 80px | left | e.g., EA, FT, LB |
| Name | `name` | Name | Yes | No | auto | left | e.g., Each, Foot, Pound |
| Symbol | `symbol` | Symbol | Yes | No | 80px | left | e.g., ft, lb, kg |
| Category | `category` | Category | Yes | Yes (enum) | 120px | left | Filter: Count, Length, Weight, Volume, Area, Time |
| Decimals | `decimalPlaces` | Decimals | Yes | No | 90px | center | |
| Base | `isBaseUnit` | Base | Yes | No | 70px | center | Check icon if true |
| Actions | `actions` | (empty) | No | No | 60px | left | Edit button |

Rows are clickable and open the edit dialog. An edit icon button is also available per row.

**Header button:** "New UOM" (primary small button, `add` icon)

**Empty state:** `icon="straighten"`, message "No units of measure configured"

### UOM Create/Edit Dialog

**Width:** 520px

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `code` | Code | Text input | Yes | `Validators.required`, `Validators.maxLength(10)` | Placeholder: "e.g. EA, FT, LB" |
| `name` | Name | Text input | Yes | `Validators.required`, `Validators.maxLength(50)` | Placeholder: "e.g. Each, Foot, Pound" |
| `category` | Category | Select | Yes | `Validators.required` | Options: Count, Length, Weight, Volume, Area, Time |
| `symbol` | Symbol | Text input | No | none | Placeholder: "e.g. ft, lb, kg" |
| `decimalPlaces` | Decimal Places | Number input | Yes | `Validators.required`, `Validators.min(0)`, `Validators.max(6)` | Default: 2 |
| `sortOrder` | Sort Order | Number input | No | none | Default: 0 |
| `isBaseUnit` | Base Unit for Category | Toggle | No | none | Default: false |

Fields are arranged in 2-column rows (Code+Name, Category+Symbol, DecimalPlaces+SortOrder).

**Validation popover labels:** Code, Name, Category, Decimal Places

**Footer buttons:**
- Cancel (secondary)
- Create or Update (primary with `save` icon, disabled when form invalid or saving)

### Conversions DataTable

Table ID: `uom-conversions`

| Column | Field | Header | Sortable | Width | Align |
|--------|-------|--------|----------|-------|-------|
| From | `fromUomCode` | From | Yes | 100px | left |
| To | `toUomCode` | To | Yes | 100px | left |
| Factor | `conversionFactor` | Factor | Yes | 120px | right |
| Reversible | `isReversible` | Reversible | Yes | 100px | center |

**Header button:** "New Conversion" (primary small button, `add` icon)

**Empty state:** `icon="swap_horiz"`, message "No conversions configured"

### Conversion Create Dialog

**Width:** 520px

| Field | Label | Type | Required | Validators | Notes |
|-------|-------|------|----------|------------|-------|
| `fromUomId` | From UOM | Select | Yes | `Validators.required` | Options formatted as `{code} -- {name}` |
| `toUomId` | To UOM | Select | Yes | `Validators.required` | Same format |
| `conversionFactor` | Conversion Factor | Number input | Yes | `Validators.required`, `Validators.min(0.00000001)` | Placeholder: "e.g. 12 (1 ft = 12 in)" |
| `isReversible` | Reversible (auto-creates inverse) | Toggle | No | none | Default: true |

From and To UOM selects are in a 2-column row.

**Validation popover labels:** From UOM, To UOM, Conversion Factor

---

## Receiving Inspection Queue

A standalone component (`ReceivingInspectionQueueComponent`) that displays items awaiting quality inspection after receiving.

### DataTable

Table ID: `receiving-inspection-queue`

| Column | Field | Header | Sortable | Width | Align |
|--------|-------|--------|----------|-------|-------|
| Part # | `partNumber` | Part # | Yes | 120px | left |
| Description | `partDescription` | Description | Yes | auto | left |
| PO # | `poNumber` | PO # | Yes | 100px | left |
| Vendor | `vendorName` | Vendor | Yes | auto | left |
| Qty | `receivedQuantity` | Qty | Yes | 80px | right |
| Received | `receivedAt` | Received | Yes | 110px | left |
| Days | `daysWaiting` | Days | Yes | 70px | right |

**Row classes:**
- `row--overdue-critical`: waiting > 7 days
- `row--overdue-warning`: waiting > 3 days

**Empty state:** `icon="fact_check"`, message "No items pending inspection"

**Data source:** `GET /api/v1/inventory/pending-inspection`

---

## Scanner Integration

The inventory module integrates with the global `ScannerService` for barcode/NFC scanning.

**Context:** On component construction, `this.scanner.setContext('inventory')` is called.

**Scan behavior:** When a scan is detected with `context === 'inventory'`:
1. The scanned value is set as the search control value
2. Navigation switches to the Stock tab (`/inventory/stock`)
3. Stock is reloaded (search filter applies)

This means scanning a part number or barcode from any tab within inventory will switch to the stock tab and filter to the scanned value.

---

## API Endpoints

### Inventory Controller (`/api/v1/inventory`)

| Method | Path | Auth | Description | Request | Response |
|--------|------|------|-------------|---------|----------|
| GET | `/locations` | All roles | Get full location tree | -- | `StorageLocationResponseModel[]` |
| GET | `/locations/bins` | All roles | Get flat list of bin locations | -- | `StorageLocationFlatResponseModel[]` |
| POST | `/locations` | All roles | Create a storage location | `CreateStorageLocationRequestModel` | `StorageLocationResponseModel` (201) |
| DELETE | `/locations/{id}` | All roles | Soft-delete a location | -- | 204 |
| GET | `/locations/{locationId}/contents` | All roles | Get bin contents for a location | -- | `BinContentResponseModel[]` |
| POST | `/bin-contents` | All roles | Place content in a bin | `PlaceBinContentRequestModel` | `BinContentResponseModel` (201) |
| DELETE | `/bin-contents/{id}` | All roles | Remove bin content | -- | 204 |
| GET | `/parts` | All roles | Get per-part inventory summary | `?search=` | `InventoryPartSummaryResponseModel[]` |
| GET | `/movements` | All roles | Get movement history | `?locationId=&entityType=&entityId=&take=100` | `BinMovementResponseModel[]` |
| GET | `/low-stock` | All roles | Get low-stock alerts | -- | `LowStockAlertModel[]` |
| POST | `/receive` | All roles | Receive goods from PO | `ReceivePurchaseOrderRequestModel` | `ReceivingRecordResponseModel` (201) |
| GET | `/receiving-history` | All roles | Get receiving records | `?purchaseOrderId=&partId=&take=50` | `ReceivingRecordResponseModel[]` |
| POST | `/transfer` | All roles | Transfer stock between bins | `TransferStockRequestModel` | 204 |
| POST | `/adjust` | Admin, Manager | Adjust stock quantity | `AdjustStockRequestModel` | 204 |
| GET | `/cycle-counts` | All roles | List cycle counts | `?locationId=&status=` | `CycleCountResponseModel[]` |
| POST | `/cycle-counts` | All roles | Create a cycle count | `CreateCycleCountRequestModel` | `CycleCountResponseModel` (201) |
| PUT | `/cycle-counts/{id}` | Admin, Manager | Approve/reject cycle count | `UpdateCycleCountRequestModel` | 204 |
| GET | `/reservations` | All roles | List reservations | `?partId=&jobId=` | `ReservationResponseModel[]` |
| POST | `/reservations` | All roles | Create a reservation | `CreateReservationRequestModel` | `ReservationResponseModel` (201) |
| DELETE | `/reservations/{id}` | All roles | Release a reservation | -- | 204 |
| GET | `/pending-inspection` | All roles | Get items pending inspection | -- | `PendingInspectionItem[]` |
| POST | `/inspect/{receivingRecordId}` | All roles | Record inspection result | `InspectionResultRequestModel` | 204 |
| POST | `/inspect/{receivingRecordId}/waive` | Admin, Manager | Waive inspection requirement | -- | 204 |
| GET | `/uom` | All roles | List units of measure | `?category=` | `UomResponseModel[]` |
| POST | `/uom` | Admin, Manager | Create a UOM | `CreateUomRequestModel` | `UomResponseModel` (201) |
| PUT | `/uom/{id}` | Admin, Manager | Update a UOM | `CreateUomRequestModel` | `UomResponseModel` |
| GET | `/uom/conversions` | All roles | List UOM conversions | `?partId=` | `UomConversionResponseModel[]` |
| POST | `/uom/conversions` | Admin, Manager | Create a conversion | `CreateUomConversionRequestModel` | `UomConversionResponseModel` (201) |
| GET | `/uom/convert` | All roles | Convert a quantity | `?fromUomId=&toUomId=&quantity=&partId=` | `{ convertedQuantity, conversionFactor }` |
| GET | `/atp/{partId}` | All roles | Get ATP for a part | `?quantity=1` | `AtpResult` |
| GET | `/atp/{partId}/timeline` | All roles | Get ATP timeline | `?from=&to=` | `AtpBucket[]` |

### Replenishment Controller (`/api/v1/replenishment`)

| Method | Path | Auth | Description | Request | Response |
|--------|------|------|-------------|---------|----------|
| GET | `/burn-rates` | Admin, Manager | Get burn rate analysis | `?search=&needsReorderOnly=` | `BurnRateResponseModel[]` |
| GET | `/suggestions` | Admin, Manager | List reorder suggestions | `?status=` | `ReorderSuggestionResponseModel[]` |
| POST | `/suggestions/{id}/approve` | Admin, Manager | Approve a suggestion | -- | `ReorderSuggestionResponseModel` |
| POST | `/suggestions/approve-bulk` | Admin, Manager | Bulk approve suggestions | `{ suggestionIds: int[] }` | `{ approvedCount, skippedCount, createdPoIds }` |
| POST | `/suggestions/{id}/dismiss` | Admin, Manager | Dismiss a suggestion | `{ reason: string }` | 204 |

---

## Data Entities

### StorageLocation

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK, auto-increment |
| `Name` | string | Required |
| `LocationType` | LocationType enum | Area, Rack, Shelf, or Bin |
| `ParentId` | int? | FK to parent StorageLocation (self-referencing) |
| `Barcode` | string? | Optional barcode identifier |
| `Description` | string? | |
| `SortOrder` | int | Display ordering |
| `IsActive` | bool | Default true |
| `CreatedAt` | DateTimeOffset | Auto-set |
| `UpdatedAt` | DateTimeOffset | Auto-set |
| `CreatedBy` | int | FK to ApplicationUser |

Navigation: `Parent`, `Children`, `Contents` (BinContent collection)

### BinContent

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `LocationId` | int | FK to StorageLocation |
| `EntityType` | string | Default "part" (also: production_run, assembly, tooling) |
| `EntityId` | int | FK to the entity (e.g., Part.Id) |
| `Quantity` | decimal | Current quantity |
| `ReservedQuantity` | decimal | Quantity reserved for jobs/orders |
| `LotNumber` | string? | Lot tracking number |
| `JobId` | int? | FK to Job |
| `Status` | BinContentStatus | Stored, Reserved, ReadyToShip, QcHold |
| `PlacedBy` | int | FK to user who placed the item |
| `PlacedAt` | DateTimeOffset | When placed |
| `RemovedAt` | DateTimeOffset? | When removed (soft removal) |
| `RemovedBy` | int? | FK to user who removed |
| `Notes` | string? | |
| `UomId` | int? | FK to UnitOfMeasure |

Navigation: `Location`, `Job`, `Uom`, `Reservations`

### BinMovement

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `EntityType` | string | Default "part" |
| `EntityId` | int | |
| `Quantity` | decimal | |
| `LotNumber` | string? | |
| `FromLocationId` | int? | FK to StorageLocation (null for receives) |
| `ToLocationId` | int? | FK to StorageLocation (null for ships/picks) |
| `MovedBy` | int | FK to user |
| `MovedAt` | DateTimeOffset | |
| `Reason` | BinMovementReason? | See enum values below |

### Reservation

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `PartId` | int | FK to Part |
| `BinContentId` | int | FK to BinContent |
| `JobId` | int? | FK to Job |
| `SalesOrderLineId` | int? | FK to SalesOrderLine |
| `Quantity` | decimal | Reserved amount |
| `Notes` | string? | |
| `CreatedAt` | DateTimeOffset | Auto-set |
| `CreatedBy` | int | FK to ApplicationUser |

### CycleCount

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `LocationId` | int | FK to StorageLocation |
| `CountedById` | int | FK to ApplicationUser |
| `CountedAt` | DateTimeOffset | |
| `Status` | string | "Pending", "Approved", or "Rejected" |
| `Notes` | string? | |

Contains a `Lines` collection of `CycleCountLine`.

### CycleCountLine

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `CycleCountId` | int | FK to CycleCount |
| `BinContentId` | int? | FK to BinContent |
| `EntityType` | string | |
| `EntityId` | int | |
| `ExpectedQuantity` | int | System quantity at time of count |
| `ActualQuantity` | int | Physical count entered by user |
| `Variance` | int | Computed: `ActualQuantity - ExpectedQuantity` |
| `Notes` | string? | |

### ReceivingRecord

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `PurchaseOrderLineId` | int | FK to PurchaseOrderLine |
| `QuantityReceived` | int | |
| `ReceivedBy` | string? | User display name |
| `StorageLocationId` | int? | FK to StorageLocation |
| `Notes` | string? | |
| `InspectionStatus` | ReceivingInspectionStatus | Default: NotRequired |
| `InspectedById` | int? | |
| `InspectedAt` | DateTimeOffset? | |
| `InspectionNotes` | string? | |
| `InspectedQuantityAccepted` | decimal? | |
| `InspectedQuantityRejected` | decimal? | |
| `QcInspectionId` | int? | Link to QC inspection |
| `CreatedAt` | DateTimeOffset | Auto-set |
| `CreatedBy` | int | |

### UnitOfMeasure

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `Code` | string | Short code (e.g., EA, FT, LB) |
| `Name` | string | Full name (e.g., Each, Foot) |
| `Symbol` | string? | Display symbol |
| `Category` | UomCategory | Count, Length, Weight, Volume, Area, Time |
| `DecimalPlaces` | int | Default 2, max 6 |
| `IsBaseUnit` | bool | Whether this is the base unit for its category |
| `IsActive` | bool | Default true |
| `SortOrder` | int | |

### UomConversion

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `FromUomId` | int | FK to UnitOfMeasure |
| `ToUomId` | int | FK to UnitOfMeasure |
| `ConversionFactor` | decimal | Multiplier (from * factor = to) |
| `PartId` | int? | FK to Part (for part-specific conversions) |
| `IsReversible` | bool | Default true -- auto-creates inverse conversion |

### ReorderSuggestion

| Property | Type | Notes |
|----------|------|-------|
| `Id` | int | PK |
| `PartId` | int | FK to Part |
| `VendorId` | int? | FK to Vendor (preferred vendor) |
| `CurrentStock` | decimal | Snapshot at analysis time |
| `AvailableStock` | decimal | After reservations |
| `BurnRateDailyAvg` | decimal | Average daily consumption |
| `BurnRateWindowDays` | int | Analysis window (30, 60, or 90) |
| `DaysOfStockRemaining` | int? | Projected days until stockout |
| `ProjectedStockoutDate` | DateTimeOffset? | |
| `IncomingPoQuantity` | decimal | Open PO quantities |
| `EarliestPoArrival` | DateTimeOffset? | |
| `SuggestedQuantity` | decimal | Recommended order quantity |
| `Status` | ReorderSuggestionStatus | Pending, Approved, Dismissed, Expired |
| `ApprovedByUserId` | int? | |
| `ApprovedAt` | DateTimeOffset? | |
| `ResultingPurchaseOrderId` | int? | FK to PO created on approval |
| `DismissedByUserId` | int? | |
| `DismissedAt` | DateTimeOffset? | |
| `DismissReason` | string? | Required on dismiss |
| `Notes` | string? | |
| `CreatedAt` | DateTimeOffset | |
| `CreatedBy` | int | |

---

## Enums

### LocationType

| Value | Icon | Description |
|-------|------|-------------|
| `Area` | `warehouse` | Top-level warehouse area or zone |
| `Rack` | `view_column` | Physical rack within an area |
| `Shelf` | `shelves` | Shelf within a rack |
| `Bin` | `inventory_2` | Lowest-level container that holds stock |

### BinContentStatus

| Value | Display | Chip Class | Description |
|-------|---------|-----------|-------------|
| `Stored` | Stored | (none) | Normal available stock |
| `Reserved` | Reserved | `chip--primary` | Reserved for a job or order |
| `ReadyToShip` | Ready to Ship | `chip--success` | Staged for outbound shipment |
| `QcHold` | QC Hold | `chip--warning` | Held pending quality inspection |

### BinMovementReason

| Value | Display Label |
|-------|---------------|
| `Receive` | Received |
| `Pick` | Picked |
| `Restock` | Restocked |
| `QcRelease` | QC Released |
| `Ship` | Shipped |
| `Move` | Moved |
| `Adjustment` | Adjusted |
| `Return` | Returned |
| `Transfer` | Transferred |
| `CycleCount` | Cycle Count |

### ReceivingInspectionStatus

`NotRequired` | `Pending` | `InProgress` | `Passed` | `Failed` | `Waived` | `PartialAccept`

### UomCategory

`Count` | `Length` | `Weight` | `Volume` | `Area` | `Time`

### ReorderSuggestionStatus

| Value | Int | Notes |
|-------|-----|-------|
| `Pending` | 0 | Awaiting review |
| `Approved` | 1 | Approved, draft PO created |
| `Dismissed` | 2 | Manually dismissed with reason |
| `Expired` | 3 | Auto-closed when stock rises above reorder point |

---

## Available-to-Promise (ATP)

The ATP system calculates how much stock can be promised to new orders, factoring in current on-hand, existing allocations, and scheduled receipts.

**Endpoints:**

- `GET /api/v1/inventory/atp/{partId}?quantity=1` -- returns a single ATP calculation
- `GET /api/v1/inventory/atp/{partId}/timeline?from=&to=` -- returns a time-bucketed projection

**ATP Result:**

| Field | Type | Description |
|-------|------|-------------|
| `partId` | number | |
| `partNumber` | string | |
| `requestedQuantity` | number | The quantity being checked |
| `onHand` | number | Current physical stock |
| `allocatedToOrders` | number | Stock committed to existing orders |
| `scheduledReceipts` | number | Expected incoming from open POs |
| `availableToPromise` | number | Net available for new commitments |
| `earliestAvailableDate` | string? | When the requested qty will be available (null if already available) |
| `canFulfill` | boolean | Whether the requested quantity can be fulfilled now |

**ATP Timeline Bucket:**

| Field | Type | Description |
|-------|------|-------------|
| `date` | string | Date for this bucket |
| `cumulativeSupply` | number | Running total of expected supply |
| `cumulativeDemand` | number | Running total of expected demand |
| `netAvailable` | number | Supply minus demand |

---

## Loading States

- **Tab-level loading:** A `[appLoadingBlock]="loading()"` directive wraps the entire tab panel content area. Each tab sets `loading(true)` before its data fetch and `loading(false)` on completion.
- **Replenishment tab:** Has its own `replenishmentLoading` signal with a separate `[appLoadingBlock]` on the tab panel.
- **UOM component:** Has its own `loading` signal for its DataTables.
- **Save operations:** Controlled by `saving()` signal, disabling submit buttons during API calls.

---

## Services

### InventoryService

`providedIn: 'root'`. Base URL: `{apiUrl}/inventory`.

Handles all inventory API calls: locations, bin contents, part inventory, movements, receiving, transfers, adjustments, cycle counts, reservations, inspections, UOM, and ATP.

### ReplenishmentService

`providedIn: 'root'`. Base URL: `{apiUrl}/replenishment`.

Handles burn rate queries, reorder suggestion listing, approval (single + bulk), and dismissal.

---

## Known Limitations

1. **Reservation form uses raw IDs.** The reserve stock dialog requires entering Part ID and Bin Content ID as numeric values rather than offering searchable pickers. Users must know the IDs beforehand.

2. **Transfer form uses raw ID.** The source bin content field in the transfer dialog requires a numeric Bin Content ID rather than a picker.

3. **No inline delete for locations.** Location deletion is available via the API (`DELETE /locations/{id}`) but there is no delete button in the UI locations tree or detail panel.

4. **Cycle count quantities are integers.** `CycleCountLine.ExpectedQuantity` and `ActualQuantity` are `int` type, limiting precision for fractional-quantity items.

5. **No pagination on movement history.** Movements are fetched with a fixed `take=100` parameter. Very active warehouses may not see older movements.

6. **Receiving history has a fixed take limit.** History is fetched with `take=50`, no pagination controls.

7. **PO line loading is sequential.** The receive dialog fetches full PO details one at a time for each open PO, which may be slow with many open purchase orders.

8. **No bin content placement UI.** The `PlaceBinContent` API exists but there is no dedicated dialog in the inventory UI for placing new content into a bin (receiving handles this implicitly).

9. **ATP is API-only in the inventory context.** The ATP endpoints are available but the inventory tab UI does not render an ATP view. ATP is consumed by other features (sales orders, quotes) rather than displayed in the inventory module.

10. **Inspection queue component is standalone.** `ReceivingInspectionQueueComponent` exists but is not directly rendered within the inventory tab structure. It is used by the Quality module.

11. **UOM conversions have no delete UI.** Conversions can be created but there is no delete endpoint or button to remove them.

12. **Replenishment tab label is not i18n.** The "Replenishment" tab label and "Units of Measure" tab label use hardcoded English strings rather than translation keys.
