# Parts Catalog -- Functional Reference

## 1. Overview

The Parts Catalog is the central engineering data repository for all manufactured, purchased, and stocked components. It serves as the master record for part definitions, bills of materials (BOM), manufacturing routing/operations, revision history, pricing, alternate parts, serial number tracking, file attachments, and 3D model viewing.

Parts integrate with nearly every other feature in the system: kanban jobs reference parts, purchase orders procure them, inventory tracks their stock levels, sales orders sell them, and the BOM structure defines how assemblies are built from sub-components.

Key capabilities:

- Full CRUD for parts with auto-generated part numbers
- Multi-level bill of materials with Make/Buy/Stock sourcing
- Manufacturing routing (operations) with work centers, cycle times, materials, QC checkpoints, file attachments, and activity logs
- Revision tracking with effective dates and file associations
- Alternate/substitute part management with approval workflow
- Serial number tracking with genealogy and location history
- List price management with effective date history
- 3D STL file viewer (Three.js)
- Barcode/label generation and scanner integration
- Accounting system linkage (QuickBooks item mapping)
- Inventory summary with low-stock warnings
- Table and card grid view modes

---

## 2. Route and Access

**Route:** `/parts`

**URL state:**
- `?view=cards` -- switches to card grid view (default is `table`, omitted from URL)
- `?detail=part:{id}` -- auto-opens the part detail dialog for the given part ID (managed by `DetailDialogService`)

**Authorized roles:** Admin, Manager, Engineer, ProductionWorker, PM, OfficeManager

**Serial numbers** (separate controller): Admin, Manager, Engineer

The view mode preference is persisted via `UserPreferencesService` under the key `parts:viewMode` and restored on subsequent visits.

---

## 3. Page Layout

The page uses `PageHeaderComponent` with a title, subtitle, and a "New Part" action button.

Below the header is a single-panel layout containing:

1. **Filters bar** -- search input, status select, type select, and view toggle buttons (table/cards)
2. **Content area** -- either a `DataTableComponent` (table view) or a `PartsCardGridComponent` (card view), wrapped in a `LoadingBlockDirective` overlay

There is no side panel on the list page. Clicking a part opens a full `MatDialog` via `DetailDialogService`.

---

## 4. Filters

All filters are standalone `FormControl` instances (not part of a `FormGroup`). Changes trigger a re-fetch from the API.

| Filter | Control | Options | Behavior |
|--------|---------|---------|----------|
| Search | `FormControl<string>` (text input) | Free text | Filters by part number, description, external part number. Pressing Enter triggers load. Also populated by barcode scanner. |
| Status | `FormControl<PartStatus \| ''>` (select) | All Statuses (default), Active, Draft, Prototype, Obsolete | Sends `?status=` query param to API |
| Type | `FormControl<PartType \| ''>` (select) | All Types (default), Part, Assembly, RawMaterial, Consumable, Tooling, Fastener, Electronic, Packaging | Sends `?type=` query param to API |

---

## 5. Table Columns

The table view uses `DataTableComponent` with `tableId="parts"` for column preference persistence.

| Field | Header | Type | Sortable | Filterable | Width | Align | Custom Cell |
|-------|--------|------|----------|------------|-------|-------|-------------|
| `partNumber` | Part # | text | Yes | No | 120px | left | Styled with `part-number` class |
| `externalPartNumber` | Ext Part # | text | Yes | No | 120px | left | Plain text |
| `description` | Description | text | Yes | No | auto | left | Styled with `part-desc` class |
| `revision` | Rev | text | No | No | 60px | center | Plain text |
| `partType` | Type | text | Yes | No | auto | left | Icon (`account_tree` for Assembly, `settings` for others) + type label |
| `status` | Status | enum | Yes | Yes | auto | left | Status badge with color class (`--active`, `--draft`, `--prototype`, `--obsolete`) |
| `material` | Material | text | No | No | auto | left | Shows `---` when null |
| `bomEntryCount` | BOM | number | No | No | 60px | center | Shows count or `---` when zero |

Rows are clickable. Clicking a row opens the part detail dialog.

---

## 6. Card Grid View

The card grid view (`PartsCardGridComponent`) renders parts as visual cards in a responsive grid. Each card shows:

- **Thumbnail image** -- loaded via `getPartThumbnails()` API call (batch request for all visible part IDs). Falls back to a `inventory_2` icon when no thumbnail exists.
- **Part number** -- bold, primary identifier
- **Description** -- truncated with `title` tooltip for overflow
- **Status badge** -- colored by status (same classes as table)

Cards are keyboard-accessible (`tabindex="0"`, Enter/Space to activate) with `role="button"` and `aria-label` set to `"{partNumber} {description}"`.

Clicking a card opens the part detail dialog.

---

## 7. Create/Edit Part Dialog

Opened via the "New Part" button (create) or the edit button in the detail panel. Uses `DialogComponent` with the following form fields:

### Create Mode

The dialog title is "Create Part". The part number is auto-generated by the server and not shown in the form.

### Edit Mode

The dialog title is the part number (e.g., "PRT-00042"). The auto-generated part number is displayed as read-only text at the top of the form.

### Form Fields

| Field | Control | Type | Required | Validation | Default | Notes |
|-------|---------|------|----------|------------|---------|-------|
| Type | `app-select` | select | Yes | `Validators.required` | `Part` | Options: Part, Assembly, RawMaterial, Consumable, Tooling, Fastener, Electronic, Packaging |
| Description | `app-input` | text | Yes | `Validators.required` | `''` | Primary description of the part |
| Revision | `app-input` | text | No | `maxlength="5"` | `'A'` | Current revision letter/number |
| External Part Number | `app-input` | text | No | None | `''` | Customer or vendor part number |
| Material | `app-input` | text | No | None | `''` | Material specification (e.g., "6061-T6 Aluminum") |
| Mold/Tool Ref | `app-input` | text | No | None | `''` | Reference to associated tooling |
| Tooling Asset | `app-entity-picker` | entity picker | No | None | `null` | Searches assets filtered by `assetType: 'Tooling'` |
| Min Stock Threshold | `app-input` | number | No | `Validators.min(0)` | `null` | Inventory alert threshold |
| Reorder Point | `app-input` | number | No | `Validators.min(0)` | `null` | When to trigger reorder |
| Reorder Quantity | `app-input` | number | No | `Validators.min(0.01)` | `null` | How much to order |
| Lead Time (Days) | `app-input` | number | No | `Validators.min(0)` | `null` | Procurement lead time |
| Safety Stock (Days) | `app-input` | number | No | `Validators.min(0)` | `null` | Buffer stock in days |

The "Inventory Replenishment" fields are grouped under a section label.

### Validation

Validation uses the hover popover pattern (`ValidationPopoverDirective`). The save button is disabled when the form is invalid. Violations are derived from `FormValidationService.getViolations()` with field labels:
- Description: "Description"
- Type: "Type"

### Behavior on Save

- **Create:** POST to API, close dialog, reload parts list, show success snackbar, then auto-open the newly created part's detail dialog.
- **Edit:** PATCH to API, close dialog, reload parts list, show success snackbar.

---

## 8. Part Detail Dialog

The detail view opens as a full `MatDialog` via `DetailDialogService`, which syncs `?detail=part:{id}` to the URL. The dialog wraps `PartDetailPanelComponent`, which contains:

### Header

- Type icon (`account_tree` for Assembly, `settings` for others)
- Part number (primary text)
- Description (secondary text)
- Edit button (opens the edit dialog)
- Close button

### Tabs

The detail panel has the following tabs:

| Tab | Key | Badge | Condition |
|-----|-----|-------|-----------|
| Info | `info` | None | Always visible |
| BOM | `bom` | Entry count (when > 0) | Always visible |
| Used In | `usage` | Usage count (when > 0) | Always visible |
| Routing | `process` | None | Always visible |
| Files | `files` | File count (when > 0) | Always visible |
| Alternates | `alternates` | None | Always visible |
| Serials | `serials` | None | Only when `part.isSerialTracked` is true |
| 3D Viewer | `viewer` | None | Only when an STL file is attached |

### Info Tab

Displays a grid of part properties:

| Field | Display |
|-------|---------|
| Revision | Current revision letter |
| Type | Part type name |
| Status | Colored status badge |
| Material | Material spec or `---` |
| External Part Number | Shown only when set |
| Mold/Tool Ref | Shown only when set |
| Preferred Vendor | Vendor name, shown only when set |
| Tooling Asset | Asset name, shown only when set |

**Barcode section:** Renders `BarcodeInfoComponent` with `entityType="Part"`, using the part number as the natural identifier. Supports barcode/QR label generation and printing.

**Accounting linkage section** (visible only when accounting provider is configured):
- Shows linked accounting item name, provider, and external ID when linked
- "Link" button opens the Link Accounting Item dialog (lists items from accounting provider)
- "Unlink" button with confirmation dialog removes the linkage

**Inventory summary** (loaded from `GET /parts/{id}/inventory-summary`):
- Total quantity on hand
- Low stock warning (shown when total quantity is below `minStockThreshold`)
- Min stock threshold and reorder point values when configured

**Pricing section:**
- Current list price with effective date
- Inline form to set a new price: unit price (currency mask), effective date (datepicker), notes
- Price history table (last 5 non-current prices): price, effective from, effective until

**Status actions:**
- Row of status buttons (Active, Draft, Prototype, Obsolete)
- Current status is highlighted
- Clicking a different status immediately updates the part via PATCH

**Activity section:** `EntityActivitySectionComponent` renders the chronological activity log for the part (shown below all tab content, always visible).

### Link Accounting Item Dialog

Opens as a nested `DialogComponent` with width `520px`. Lists all accounting items from the configured provider (loaded via `AccountingService`). Each item shows:
- Name
- SKU (when present)
- Description (when present)
- Unit price (when present)

Clicking an item links it to the part and closes the dialog.

---

## 9. BOM (Bill of Materials)

The BOM tab displays the components that make up the current part. It supports two view modes toggled via icon buttons:

### Table View (default)

Uses `DataTableComponent` with `tableId="part-bom"`:

| Field | Header | Width | Align | Custom Cell |
|-------|--------|-------|-------|-------------|
| `sortOrder` | # | 40px | center | Sort order number |
| `childPartNumber` | Part | auto | left | Part number (bold) + description (secondary) |
| `quantity` | Qty | 60px | center | Numeric quantity |
| `sourceType` | Source | 80px | left | Colored chip (`--make` for Make, `--stock` for Stock, default for Buy). Filterable as enum. |
| `leadTimeDays` | Lead Time | 90px | left | Days with `d` suffix, or `---` |
| `referenceDesignator` | Ref Des | auto | left | Reference designator or `---` |
| `actions` | (none) | 40px | left | Delete button with confirmation |

### Tree View

Uses `BomTreeComponent` which renders BOM entries as indented tree nodes. Each node shows:
- Expand/collapse chevron (when children exist)
- Child part number and description
- Quantity
- Source type chip
- Delete button

The tree currently renders a flat list (level 0) since multi-level BOM nesting is resolved from the BOM entries array. Expand/collapse state is tracked per entry ID.

### Add BOM Entry Dialog

Opened via the "Add" button. Uses `DialogComponent`:

| Field | Control | Type | Required | Validation | Default |
|-------|---------|------|----------|------------|---------|
| Child Part | `app-entity-picker` | entity picker | Yes | `Validators.required` | `null` |
| Quantity | `app-input` | number | Yes | `Validators.required`, `Validators.min(0.01)` | `1` |
| Source Type | `app-select` | select | No | None | `'Buy'` |
| Reference Designator | `app-input` | text | No | None | `''` |
| Lead Time (Days) | `app-input` | number | No | None | `null` |
| Notes | `app-textarea` | textarea | No | None | `''` |

The entity picker searches against `GET /api/v1/parts?search={term}` and returns the part's `id` as the form value, displaying `partNumber`.

### Delete BOM Entry

Requires confirmation via `ConfirmDialogComponent` with `severity: 'danger'`. On confirm, calls `DELETE /api/v1/parts/{id}/bom/{bomEntryId}` which returns the updated part detail.

### BOM Source Types

| Source Type | Meaning |
|-------------|---------|
| `Make` | Manufactured in-house; will generate a sub-job during production |
| `Buy` | Purchased from a vendor; will generate a purchase order line |
| `Stock` | Consumed from existing inventory; no procurement action needed |

### Used In Tab

The "Used In" tab shows which parent assemblies reference the current part as a BOM component. Uses `DataTableComponent` with `tableId="part-used-in"`:

| Field | Header | Sortable |
|-------|--------|----------|
| `parentPartNumber` | Parent Part | Yes |
| `parentDescription` | Description | Yes |
| `quantity` | Qty | Yes |

Rows are clickable. Clicking a usage row navigates the detail panel to the parent part (reloads with the parent part ID).

---

## 10. Operations (Manufacturing Routing)

The routing tab (`RoutingComponent`) defines the sequence of manufacturing operations required to produce the part. It supports two view modes:

### List View (default)

Renders operations as vertical cards, each showing:
- Step number (large, in a circle/badge)
- Title
- QC badge (yellow "QC" chip when `isQcCheckpoint` is true)
- Instructions (when present)
- Work center name with `precision_manufacturing` icon (when assigned)
- Estimated time in minutes with `schedule` icon (when set)
- Edit and delete action buttons

### Flow View

`RoutingFlowViewComponent` renders operations as a horizontal flow diagram with arrow connectors between steps. Each node shows:
- "Operation {stepNumber}" label
- Title
- Instructions (when present)
- Work center (when assigned)
- Estimated time (when set)
- QC badge (when checkpoint)

### Operation Dialog

Full-featured dialog (`OperationDialogComponent`, width `800px`) with four tabs:

#### Details Tab

| Field | Control | Type | Required | Validation | Default |
|-------|---------|------|----------|------------|---------|
| Step Number | `app-input` | number | Yes | `Validators.required`, `Validators.min(1)` | Next step number (auto-calculated) |
| Estimated Minutes | `app-input` | number | No | `Validators.min(1)` | `null` |
| Title | `app-input` | text | Yes | `Validators.required`, `Validators.maxLength(200)` | `''` |
| Instructions | `app-textarea` | textarea | No | `maxlength="4000"` | `''` |
| Work Center | `app-entity-picker` | entity picker | No | None | `null` |
| Referenced Operation | `app-select` | select | No | None | `null` |
| QC Checkpoint | `app-toggle` | toggle | No | None | `false` |
| QC Criteria | `app-textarea` | textarea | No | `maxlength="1000"` | `''` |

The Work Center picker searches against assets (`entityType="assets"`, `displayField="name"`).

The Referenced Operation select lists other operations in the same routing (excluding the current one when editing), displayed as "Op {stepNumber}: {title}". Includes a "None" option.

The QC Criteria field only appears when the QC Checkpoint toggle is enabled.

#### Materials Tab (edit mode only)

Displays materials consumed by this operation in a table:

| Column | Content |
|--------|---------|
| Part Number | Child part number from BOM entry |
| Description | Child part description |
| Quantity | Consumption quantity |
| Notes | Notes or em-dash |
| Actions | Delete button |

Below the table is an "Add material" row with:
- BOM Entry select (only shows BOM entries not already assigned to this operation)
- Quantity input (default: 1)
- Add button

When no BOM entries are available (all assigned or none exist), a hint message is shown.

#### Files Tab (edit mode only)

- File grid showing uploaded files with preview (images show thumbnail, videos show player, others show icon)
- Each file has a delete button
- `FileUploadZoneComponent` for uploading new files (accepts `.jpg,.jpeg,.png,.gif,.mp4,.webm,.pdf,.step,.stl`, max 100MB)
- Files are associated with the operation entity

#### Activity Tab (edit mode only)

- `ActivityTimelineComponent` showing chronological activity log
- Comment textarea with "Post" button to add new comments
- Comments are stored via `POST /api/v1/parts/{id}/operations/{operationId}/activity`

The dialog supports draft auto-save via `DraftConfig`.

### Delete Operation

Requires confirmation via `ConfirmDialogComponent` with severity `danger`. Message includes step number and title.

---

## 11. Operation Materials

Operation materials link BOM entries to specific operations, defining which components are consumed at each step. This is the key connection between the bill of materials and the manufacturing routing.

**Entity structure (`OperationMaterial`):**

| Field | Type | Description |
|-------|------|-------------|
| `operationId` | int | FK to the parent operation |
| `bomEntryId` | int | FK to the BOM entry being consumed |
| `quantity` | decimal | Quantity consumed per operation cycle |
| `notes` | string? | Optional notes |

**Frontend model includes resolved fields:**
- `childPartNumber` -- the part number of the BOM entry's child part
- `childPartDescription` -- the description of the BOM entry's child part

Materials can only be added in edit mode (after the operation is created). The available BOM entries are filtered to exclude entries already assigned to the operation.

---

## 12. Part Revisions

Part revisions track the engineering change history of a part.

**Entity structure (`PartRevision`):**

| Field | Type | Description |
|-------|------|-------------|
| `partId` | int | FK to the parent part |
| `revision` | string | Revision identifier (e.g., "A", "B", "C") |
| `changeDescription` | string? | Description of what changed |
| `changeReason` | string? | Reason for the change |
| `effectiveDate` | DateTimeOffset | When this revision becomes active |
| `isCurrent` | bool | Whether this is the active revision |
| `files` | FileAttachment[] | Files associated with this revision |

**API endpoints:**

- `GET /api/v1/parts/{id}/revisions` -- list all revisions
- `POST /api/v1/parts/{id}/revisions` -- create a new revision

**Create revision request:**

| Field | Type | Required |
|-------|------|----------|
| `revision` | string | Yes |
| `changeDescription` | string | No |
| `changeReason` | string | No |
| `effectiveDate` | string (ISO date) | Yes |

The `fileCount` field on the revision response indicates how many files are associated with that revision.

---

## 13. Part Alternates

The alternates tab (`PartAlternatesTabComponent`) manages substitute, equivalent, and superseded part relationships.

### Alternates Table

Uses `DataTableComponent`:

| Field | Header | Width | Sortable | Custom Cell |
|-------|--------|-------|----------|-------------|
| `alternatePartNumber` | Part # | 120px | Yes | Plain text |
| `alternatePartDescription` | Description | auto | Yes | Plain text |
| `type` | Type | 110px | Yes | Colored chip: `chip--info` (Substitute), `chip--success` (Equivalent), `chip--warning` (Superseded) |
| `priority` | Priority | 80px | Yes | Number |
| `isApproved` | Approved | 90px | Yes | Check/X icon |
| `isBidirectional` | Bi-Dir | 70px | Yes | Check/X icon |
| `actions` | (none) | 80px | No | Approve + Delete buttons |

### Add Alternate Dialog

| Field | Control | Type | Required | Validation | Default |
|-------|---------|------|----------|------------|---------|
| Alternate Part | `app-entity-picker` | entity picker | Yes | `Validators.required` | `null` |
| Priority | `app-input` | number | Yes | `Validators.required`, `Validators.min(1)` | `1` |
| Type | `app-select` | select | No | None | `'Substitute'` |
| Conversion Factor | `app-input` | number | No | None | `null` |
| Is Approved | `app-toggle` | toggle | No | None | `false` |
| Notes | `app-textarea` | textarea | No | None | `''` |
| Bidirectional | `app-toggle` | toggle | No | None | `true` |

### Alternate Types

| Type | Meaning |
|------|---------|
| `Substitute` | Can be used in place of the original with possible differences |
| `Equivalent` | Functionally identical; direct drop-in replacement |
| `Superseded` | The original part has been replaced by this newer part |

### Approval Workflow

- Alternates can be created as unapproved (approval toggle off)
- The "Approve" action button (only visible on unapproved alternates) calls `PATCH` with `{ isApproved: true }`
- Server records `approvedById` and `approvedAt` timestamp

### Bidirectional Flag

When `isBidirectional` is true, the alternate relationship works both ways: Part A is an alternate for Part B, and Part B is an alternate for Part A.

### Delete Alternate

Requires confirmation via `ConfirmDialogComponent` with severity `danger`.

---

## 14. Part Pricing

The pricing section on the Info tab manages the part's list price history.

**Entity structure (`PartPrice`):**

| Field | Type | Description |
|-------|------|-------------|
| `partId` | int | FK to the part |
| `unitPrice` | decimal | Price per unit |
| `effectiveFrom` | DateTimeOffset | When this price takes effect |
| `effectiveTo` | DateTimeOffset? | When this price was superseded (null for current) |
| `notes` | string? | Optional notes |

**Derived fields on frontend:**
- `isCurrent` -- computed server-side; the price where `effectiveTo` is null or the latest effective price

**UI structure:**

1. **Current price display** -- shows the current price formatted as currency with effective date, or "No price set"
2. **Set new price form:**
   - Unit Price (`app-input`, currency mask, `$` prefix, required, `min(0)`)
   - Effective From (`app-datepicker`, defaults to today)
   - Notes (`app-input`)
   - "Set Price" button
3. **Price history table** (last 5 non-current entries):
   - Price (currency)
   - Effective from (MM/dd/yyyy)
   - Until (MM/dd/yyyy or `---`)

Setting a new price automatically closes out the previous current price by setting its `effectiveTo`.

---

## 15. 3D STL Viewer

The 3D Viewer tab appears in the detail panel only when an STL file is attached to the part. Detection is based on scanning the part's file attachments for a file whose name ends with `.stl` (case-insensitive).

The viewer uses `StlViewerComponent`, which wraps Three.js for real-time 3D rendering. The component receives the file download URL and renders at full container height.

**Supported file formats:** STL (binary and ASCII)

The viewer is dynamically loaded only when the user clicks the "3D Viewer" tab (lazy rendering via `@if` block), avoiding unnecessary Three.js initialization overhead.

---

## 16. Part Statuses

| Status | Meaning |
|--------|---------|
| `Draft` | Part definition is being created; not yet ready for use in production or ordering |
| `Prototype` | Part is in prototype/testing phase; may be used in R&D jobs but not released for production |
| `Active` | Part is released and available for production, ordering, and inventory |
| `Obsolete` | Part is no longer in active use; retained for historical reference but should not be used in new work |

**Transitions:** Status can be changed freely between any values via the status button group on the Info tab. There are no enforced transition rules -- any authorized user can set any status at any time. The status change is applied immediately via a PATCH request.

**Visual styling:** Each status has a dedicated CSS class for badge coloring:
- `status-badge--active` -- green/success
- `status-badge--draft` -- muted/gray
- `status-badge--prototype` -- purple/info
- `status-badge--obsolete` -- red/error

---

## 17. Part Types

| Type | Meaning |
|------|---------|
| `Part` | Standard manufactured or purchased component |
| `Assembly` | Multi-component assembly built from other parts (typically has BOM entries) |
| `RawMaterial` | Raw stock material (e.g., bar stock, sheet metal, pellets) |
| `Consumable` | Items consumed during manufacturing but not part of the finished product (e.g., coolant, sandpaper) |
| `Tooling` | Tooling components (e.g., mold inserts, fixtures, dies) |
| `Fastener` | Hardware fasteners (e.g., screws, bolts, nuts, rivets) |
| `Electronic` | Electronic components (e.g., PCBs, sensors, connectors) |
| `Packaging` | Packaging materials (e.g., boxes, foam, labels) |

The type is set at creation and can be changed via the edit dialog. The type influences the icon displayed in the table and detail panel:
- `Assembly` -- `account_tree` icon
- All others -- `settings` icon

---

## 18. Serial Number Tracking

The Serials tab (`SerialNumbersTabComponent`) appears only when `part.isSerialTracked` is true. It provides full serial number lifecycle management.

### Serial Numbers Table

Uses `DataTableComponent`:

| Field | Header | Width | Sortable | Filterable | Type |
|-------|--------|-------|----------|------------|------|
| `serialValue` | Serial # | 140px | Yes | No | text |
| `status` | Status | 110px | Yes | Yes (enum) | enum |
| `currentLocationName` | Location | auto | Yes | No | text |
| `jobNumber` | Job | 100px | Yes | No | text |
| `manufacturedAt` | Manufactured | 110px | Yes | No | date |
| `childCount` | Children | 80px | Yes | No | number |

**Status filter options:** Available, InUse, Shipped, Returned, Scrapped, Quarantined

### Serial Number Statuses

| Status | Meaning | Chip Color |
|--------|---------|------------|
| `Available` | Ready for use/sale | `chip--success` (green) |
| `InUse` | Currently in a production job | `chip--primary` (blue) |
| `Shipped` | Delivered to customer | `chip--info` (light blue) |
| `Returned` | Returned by customer | `chip--warning` (orange) |
| `Scrapped` | Destroyed/discarded | `chip--error` (red) |
| `Quarantined` | Held for quality investigation | `chip--muted` (gray) |

### Create Serial Number Dialog

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| Serial Number | `app-input` | Yes | `Validators.required`, `Validators.maxLength(100)` |
| Notes | `app-textarea` | No | None |

### Serial Detail Dialog

Shows full serial number details and history timeline.

### Serial Genealogy Dialog

Shows the parent-child hierarchy tree for a serial number. Useful for tracing component serial numbers through assembled products.

**Entity fields:**

| Field | Type | Description |
|-------|------|-------------|
| `serialValue` | string | Unique serial identifier |
| `status` | SerialNumberStatus | Current lifecycle status |
| `jobId` | int? | Associated production job |
| `lotRecordId` | int? | Associated production lot |
| `currentLocationId` | int? | Current storage location |
| `shipmentLineId` | int? | Shipment line (when shipped) |
| `customerId` | int? | Customer (when shipped) |
| `parentSerialId` | int? | Parent serial (for assemblies) |
| `manufacturedAt` | DateTimeOffset? | Manufacturing date |
| `shippedAt` | DateTimeOffset? | Ship date |
| `scrappedAt` | DateTimeOffset? | Scrap date |
| `notes` | string? | Free-text notes |

---

## 19. File Attachments

The Files tab provides drag-and-drop file upload and a list of attached files.

**Upload zone:** `FileUploadZoneComponent` configured for:
- Entity type: `parts`
- Accepted formats: `.pdf, .step, .stl, .dxf, .dwg, .png, .jpg, .jpeg`
- Max size: 50 MB

**File list:** Each file shows:
- File icon (`description` material icon)
- File name as a download link (opens in new tab)
- Content type label

Files are stored in MinIO and tracked via the `FileAttachment` entity (polymorphic by `EntityType`/`EntityId`).

When an STL file is present, the "3D Viewer" tab automatically appears in the detail panel.

---

## 20. Scanner Integration

The Parts page sets the scanner context to `'parts'` on initialization via `ScannerService.setContext('parts')`.

When a barcode scan is detected (keyboard-wedge input from USB barcode scanners or NFC readers), the scanned value is automatically placed into the search field and the parts list is reloaded. This enables rapid part lookup by scanning a barcode label.

The detail panel also includes `BarcodeInfoComponent` which generates barcode and QR code labels for the part number, supporting printing via `LabelPrintService`.

---

## 21. API Endpoints

### Parts Controller (`/api/v1/parts`)

| Method | Path | Description | Request | Response |
|--------|------|-------------|---------|----------|
| GET | `/` | List parts | `?status=Active&type=Part&search=...` | `PartListResponseModel[]` |
| GET | `/{id}` | Get part detail | -- | `PartDetailResponseModel` |
| POST | `/` | Create part | `CreatePartRequestModel` | `PartDetailResponseModel` (201) |
| PATCH | `/{id}` | Update part | `UpdatePartRequestModel` | `PartDetailResponseModel` |
| DELETE | `/{id}` | Soft-delete part | -- | 204 |
| GET | `/{id}/revisions` | List revisions | -- | `PartRevisionResponseModel[]` |
| POST | `/{id}/revisions` | Create revision | `CreatePartRevisionRequestModel` | `PartRevisionResponseModel` (201) |
| GET | `/{id}/operations` | List operations | -- | `OperationResponseModel[]` |
| POST | `/{id}/operations` | Create operation | `CreateOperationRequestModel` | `OperationResponseModel` (201) |
| PATCH | `/{id}/operations/{operationId}` | Update operation | `UpdateOperationRequestModel` | `OperationResponseModel` |
| DELETE | `/{id}/operations/{operationId}` | Delete operation | -- | 204 |
| POST | `/{id}/operations/{operationId}/materials` | Add operation material | `CreateOperationMaterialRequestModel` | `OperationMaterialResponseModel` (201) |
| DELETE | `/{id}/operations/{operationId}/materials/{materialId}` | Remove operation material | -- | 204 |
| GET | `/{id}/operations/{operationId}/activity` | Get operation activity | -- | `ActivityResponseModel[]` |
| POST | `/{id}/operations/{operationId}/activity` | Add operation comment | `{ comment: string }` | 201 |
| POST | `/{id}/link-accounting-item` | Link to accounting item | `{ externalId, externalRef }` | 204 |
| DELETE | `/{id}/link-accounting-item` | Unlink accounting item | -- | 204 |
| GET | `/thumbnails` | Get part thumbnails | `?partIds=1&partIds=2` | `PartThumbnailResponseModel[]` |
| GET | `/{id}/activity` | Get part activity | -- | `ActivityResponseModel[]` |
| GET | `/{id}/prices` | List prices | -- | `PartPriceResponseModel[]` |
| POST | `/{id}/prices` | Add price | `AddPartPriceRequestModel` | `PartPriceResponseModel` (201) |
| GET | `/{id}/alternates` | List alternates | -- | `PartAlternateResponseModel[]` |
| POST | `/{id}/alternates` | Create alternate | `CreatePartAlternateRequestModel` | `PartAlternateResponseModel` (201) |
| PATCH | `/{id}/alternates/{alternateId}` | Update alternate | `UpdatePartAlternateRequestModel` | `PartAlternateResponseModel` |
| DELETE | `/{id}/alternates/{alternateId}` | Delete alternate | -- | 204 |

### Serials Controller (`/api/v1/serials`)

| Method | Path | Description | Request | Response |
|--------|------|-------------|---------|----------|
| GET | `/part/{partId}` | List serials for a part | `?status=Available` | `SerialNumberResponseModel[]` |
| POST | `/part/{partId}` | Create serial number | `CreateSerialNumberRequestModel` | `SerialNumberResponseModel` (201) |
| GET | `/{serialValue}/genealogy` | Get genealogy tree | -- | `SerialGenealogyResponseModel` |
| POST | `/{id}/transfer` | Transfer serial to location | `TransferSerialRequestModel` | 204 |
| GET | `/{id}/history` | Get serial history | -- | `SerialHistoryResponseModel[]` |

### Files Controller (shared, used by parts)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/parts/{partId}/files` | List part files |
| POST | `/api/v1/{entityType}/{entityId}/files` | Upload file (multipart) |
| GET | `/api/v1/files/{fileId}/download` | Download file |
| DELETE | `/api/v1/files/{fileId}` | Delete file |

### Inventory Summary (via Parts Controller)

| Method | Path | Description | Response |
|--------|------|-------------|----------|
| GET | `/api/v1/parts/{id}/inventory-summary` | Get inventory summary | `{ totalQuantity, binLocations: [{ locationPath, quantity }] }` |

---

## 22. Backend Entity Details

### Part Entity

Extends `BaseAuditableEntity` (includes `Id`, `CreatedAt`, `UpdatedAt`, `DeletedAt`, `DeletedBy`, `CreatedBy`).

Notable fields beyond what the UI exposes:

| Field | Type | Description |
|-------|------|-------------|
| `IsMrpPlanned` | bool | Whether this part participates in MRP planning |
| `LotSizingRule` | enum? | MRP lot sizing rule |
| `FixedOrderQuantity` | decimal? | Fixed order quantity for MRP |
| `MinimumOrderQuantity` | decimal? | Minimum order quantity |
| `OrderMultiple` | decimal? | Order must be multiple of this |
| `PlanningFenceDays` | int? | MRP planning fence |
| `DemandFenceDays` | int? | MRP demand fence |
| `RequiresReceivingInspection` | bool | Whether incoming parts need QC |
| `ReceivingInspectionTemplateId` | int? | QC template for receiving |
| `InspectionFrequency` | enum | Every, SkipAfterN |
| `InspectionSkipAfterN` | int? | Skip inspection after N clean receipts |
| `CustomFieldValues` | string? | JSONB custom field data |
| `StockUomId` / `PurchaseUomId` / `SalesUomId` | int? | Unit of measure FKs |

### Operation Entity

Additional fields beyond UI-exposed properties:

| Field | Type | Description |
|-------|------|-------------|
| `AssetId` | int? | Specific asset/machine assignment |
| `SetupMinutes` | decimal | Setup/changeover time |
| `RunMinutesEach` | decimal | Per-piece run time |
| `RunMinutesLot` | decimal | Per-lot run time |
| `OverlapPercent` | decimal | Overlap with next operation (for pipelining) |
| `ScrapFactor` | decimal | Expected scrap rate |
| `IsSubcontract` | bool | Whether this operation is outsourced |
| `SubcontractVendorId` | int? | Subcontract vendor FK |
| `SubcontractCost` | decimal? | Subcontract cost per unit |
| `SubcontractLeadTimeDays` | int? | Subcontract lead time |
| `SubcontractInstructions` | string? | Instructions for subcontractor |
| `LaborRate` | decimal | Labor cost rate |
| `BurdenRate` | decimal | Overhead/burden rate |
| `EstimatedLaborCost` | decimal | Computed labor cost |
| `EstimatedBurdenCost` | decimal | Computed burden cost |

These fields are available in the entity and database but are not yet fully exposed in the UI operation dialog. They support future manufacturing cost estimation and scheduling features.
