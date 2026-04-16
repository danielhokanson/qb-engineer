# Assets

## Overview

The Assets feature provides a centralized registry for tracking company equipment, tooling, facilities, and vehicles. It supports the full asset lifecycle from acquisition to retirement, with specialized fields for tooling assets (mold cavities, shot counts, customer ownership), maintenance scheduling with recurring intervals, downtime logging aligned to the Six Big Losses (OEE) framework, and machine hour tracking.

Assets are classified by type and managed through a status lifecycle. Each asset can be linked to source jobs and parts (for tooling traceability), assigned maintenance schedules that auto-advance on completion, and associated with barcode/QR identifiers for scan-based lookup.

### Asset Types

| Type | Icon | Description |
|------|------|-------------|
| Machine | `precision_manufacturing` | CNC machines, presses, lathes, etc. |
| Tooling | `build` | Molds, dies, fixtures, jigs -- includes cavity count, shot tracking, customer-owned flag |
| Facility | `apartment` | Buildings, rooms, infrastructure |
| Vehicle | `local_shipping` | Trucks, forklifts, company vehicles |
| Other | `category` | Anything that does not fit the above |

### Asset Statuses

| Status | Chip Class | Display Label | Description |
|--------|------------|---------------|-------------|
| Active | `chip--success` | Active | In service and available |
| Maintenance | `chip--warning` | Maintenance | Undergoing scheduled or unscheduled maintenance |
| Retired | `chip--muted` | Retired | Permanently removed from service |
| OutOfService | `chip--error` | Out of Service | Temporarily unavailable (breakdown, pending repair) |

---

## Routes & Navigation

| Route | Component | Description |
|-------|-----------|-------------|
| `/assets` | `AssetsComponent` | Asset list page (DataTable + filters) |
| `/assets?detail=asset:{id}` | `AssetDetailDialogComponent` | Auto-opens detail dialog for the specified asset |

The feature is lazy-loaded via `ASSETS_ROUTES` in `assets.routes.ts`. There is a single route -- the list page. Asset detail is shown in a MatDialog overlay, not a separate route. The detail dialog URL parameter (`?detail=asset:{id}`) is managed by `DetailDialogService` and is shareable/bookmarkable.

Sidebar navigation icon: `precision_manufacturing`.

---

## Access & Permissions

The `AssetsController` requires authorization with one of three roles:

```
[Authorize(Roles = "Admin,Manager,Engineer")]
```

| Role | Access |
|------|--------|
| Admin | Full CRUD, maintenance schedules, downtime, machine hours |
| Manager | Full CRUD, maintenance schedules, downtime, machine hours |
| Engineer | Full CRUD, maintenance schedules, downtime, machine hours |
| Production Worker | No access |
| PM | No access |
| Office Manager | No access |

All three authorized roles have identical permissions -- there is no role-based field restriction within the feature.

---

## Asset List

The list page renders a `PageHeaderComponent` with inline filters and a DataTable.

### Page Header

Contains three filter controls and one action button, displayed in a horizontal toolbar:

| Control | Type | Behavior |
|---------|------|----------|
| Search | `<app-input>` with `FormControl` | Free-text search (passed as `?search=` query param to API). Searches `name` and `serial_number` fields server-side. |
| Type | `<app-select>` with null option | Filters by `AssetType`. Options: All Types (null), Machine, Tooling, Facility, Vehicle, Other. |
| Status | `<app-select>` with null option | Filters by `AssetStatus`. Options: All Statuses (null), Active, Maintenance, Retired, Out of Service. |
| New Asset button | `action-btn action-btn--primary` | Opens the create asset dialog. Icon: `add`. `data-testid="new-asset-btn"`. |

Filters are applied by calling `loadAssets()` which sends all three filter values to the API in a single request. The search, type, and status filters each have a reactive signal derived from their `FormControl.valueChanges`.

### DataTable Configuration

Table ID: `assets` (used for column preference persistence via `UserPreferencesService`).

| Column | Field | Header | Sortable | Filterable | Type | Width | Align | Custom Cell |
|--------|-------|--------|----------|------------|------|-------|-------|-------------|
| Icon | `icon` | (empty) | No | No | -- | 32px | left | Material icon from `getTypeIcon()` |
| Name | `name` | Name | Yes | No | text | auto | left | Bold text (`font-weight: 600`) |
| Type | `assetType` | Type | Yes | Yes | enum | auto | left | Muted text. Filter options: Machine, Tooling, Facility, Vehicle, Other |
| Location | `location` | Location | Yes | No | text | auto | left | Muted text, em dash for null |
| Manufacturer | `manufacturer` | Manufacturer | Yes | No | text | auto | left | Muted text, em dash for null |
| Status | `status` | Status | Yes | No | text | auto | left | Colored chip (`chip--success/warning/muted/error`) |
| Hours | `currentHours` | Hours | Yes | No | text | auto | right | Tabular-nums font variant; em dash when 0 |

Row click opens the detail dialog via `openAssetDetail()`. Rows are clickable (`[clickableRows]="true"`).

Empty state: icon `precision_manufacturing`, message from i18n key `assets.noAssetsFound`.

### Loading State

The list uses a component-level loading state (not the global overlay). While loading, a centered `page-loading` spinner with `hourglass_empty` icon is shown instead of the DataTable.

---

## Asset Detail Dialog

Opened via `DetailDialogService.open()` which renders `AssetDetailDialogComponent` as a MatDialog. The dialog wraps `AssetDetailPanelComponent` which contains all the detail content.

### Dialog Data

```typescript
interface AssetDetailDialogData {
  assetId: number;
}

interface AssetDetailDialogResult {
  action: 'edit';
  asset: AssetItem;
}
```

When the dialog closes with an `edit` action, the parent `AssetsComponent` opens the edit form dialog pre-populated with the asset's data, then reloads the list.

### Detail Panel Layout

The detail panel has a header and a scrollable body.

**Header:**
- Left: Type icon (from `getTypeIcon()`) + asset name (bold) + asset type (muted, below name)
- Right: Edit button (icon-only `edit`, tooltip "Edit", `aria-label="Edit asset"`) + Close button (icon-only `close`, tooltip "Close", `aria-label="Close panel"`)

**Body sections (top to bottom):**

1. **Info Grid** (2-column grid) -- always visible:

| Field | Condition | Display |
|-------|-----------|---------|
| Status | Always | Colored chip |
| Location | When not null | Plain text |
| Manufacturer | When not null | Plain text |
| Model | When not null | Plain text |
| Serial Number | When not null | Monospace font |
| Hours | Always | Numeric value |

2. **Tooling Details** -- only when `assetType === 'Tooling'`:

| Field | Condition | Display |
|-------|-----------|---------|
| Customer Owned | Always (within section) | "Yes" / "No" |
| Cavity Count | When not null | Numeric |
| Tool Life | When `toolLifeExpectancy` set | `{currentShotCount} / {toolLifeExpectancy}` |
| Source Job | When `sourceJobId` set | `EntityLinkComponent` -- clickable link to job detail |
| Source Part | When `sourcePartId` set | `EntityLinkComponent` -- clickable link to part detail |

3. **Notes** -- only when `notes` is not null. Rendered as a paragraph with muted color and 1.5 line height.

4. **Barcode Info** -- `BarcodeInfoComponent` in compact mode. Uses serial number (or name as fallback) as the natural identifier.

5. **Set Status** -- row of status buttons for all four statuses. The active status button is highlighted with primary color border and background. Clicking a different status immediately calls `updateAsset()` with the new status (optimistic inline update, no confirmation dialog).

6. **Maintenance History** -- loads the 10 most recent maintenance logs for this asset. Each log entry shows:
   - Schedule name (bold) + date (`MM/dd/yyyy`) on one row
   - Performed-by name + hours spent (if set, formatted as `Xh`) + cost (if set, formatted as `$X.XX`) on the meta row
   - Notes (if set) below in muted text

   Empty state: `build_circle` icon + "No maintenance logs" message.
   Loading state: small `hourglass_empty` spinner.

7. **Activity Timeline** -- `EntityActivitySectionComponent` for entity type "Asset" with the current asset ID.

---

## Create / Edit Dialog

The same dialog serves both creation and editing, toggled by `editingAsset()` signal. Title changes between "New Asset" (create) and "Edit Asset" (edit) via i18n keys.

### Dialog Configuration

- Uses `<app-dialog>` with draft support (`draftConfig` + `draftFormGroup`)
- Draft entity type: `asset`
- Draft entity ID: `'new'` for create, `{assetId}` for edit
- Draft route: `/assets`

### Form Fields

| Field | Control | Type | Required | Validation | data-testid | Notes |
|-------|---------|------|----------|------------|-------------|-------|
| Name | `<app-input>` | text | Yes | `Validators.required`, max 200 chars (server) | `asset-name` | |
| Type | `<app-select>` | enum | Yes | `Validators.required` | `asset-type` | Options: Machine, Tooling, Facility, Vehicle, Other. Default: Machine |
| Location | `<app-input>` | text | No | Max 200 chars (server) | `asset-location` | Side-by-side with Type in `.dialog-row` |
| Manufacturer | `<app-input>` | text | No | None | `asset-manufacturer` | Side-by-side with Model in `.dialog-row` |
| Model | `<app-input>` | text | No | None | `asset-model` | |
| Serial Number | `<app-input>` | text | No | Max 100 chars (server) | `asset-serial` | |
| Notes | `<app-textarea>` | text | No | None | `asset-notes` | |

**Tooling-only fields** (shown only when Type is set to "Tooling"):

| Field | Control | Type | Required | Validation | Notes |
|-------|---------|------|----------|------------|-------|
| Customer Owned | `<app-toggle>` | boolean | No | None | Default: false |
| Cavity Count | `<app-input>` | number | No | None | Side-by-side with Tool Life in `.dialog-row` |
| Tool Life Expectancy | `<app-input>` | number | No | None | Expected total shots before replacement |

### Footer Buttons

| Button | Class | Disabled | Icon | Action |
|--------|-------|----------|------|--------|
| Cancel | `action-btn` | Never | None | Closes dialog |
| Save / Create | `action-btn action-btn--primary` | When form invalid or `saving()` | `save` | Calls `saveAsset()`. `data-testid="asset-save-btn"`. Has `[appValidationPopover]="assetViolations"`. |

### Validation Popover

The save button has a validation popover that shows on hover when the form is invalid:

| FormControl | Violation Label |
|-------------|-----------------|
| `name` | "Name" |
| `assetType` | "Type" |

### Save Behavior

**Create:** POST to `/api/v1/assets`. On success: clears draft, closes dialog, reloads list, shows snackbar "Asset created".

**Update:** PATCH to `/api/v1/assets/{id}`. On success: clears draft, closes dialog, reloads list, shows snackbar "Asset updated".

On error: the `saving` signal is reset to false; error handling is delegated to the global `httpErrorInterceptor`.

### Edit Prefill

When editing, the form is patched with the existing asset values. Empty strings are used as fallback for null optional fields. The `editingAsset` signal holds the current asset being edited.

---

## Tooling Assets

Tooling assets have specialized fields that track mold/die/fixture lifecycle data. These fields are only visible in the UI when `assetType === 'Tooling'`.

### Tooling-Specific Fields

| Field | Entity Property | Type | Description |
|-------|-----------------|------|-------------|
| Customer Owned | `IsCustomerOwned` | bool | Whether the tooling belongs to a customer (stored on-site for production). Affects custody/liability. |
| Cavity Count | `CavityCount` | int? | Number of cavities in a mold (e.g., a 4-cavity injection mold produces 4 parts per shot). |
| Tool Life Expectancy | `ToolLifeExpectancy` | int? | Expected number of shots/cycles before the tool needs replacement. |
| Current Shot Count | `CurrentShotCount` | int | Running count of shots/cycles performed. Displayed as `{current} / {expected}` in the detail panel. |
| Source Job ID | `SourceJobId` | int? | FK to the job that produced/acquired this tooling. Shown as a clickable entity link. |
| Source Part ID | `SourcePartId` | int? | FK to the part this tooling produces. Shown as a clickable entity link. |

### Bidirectional Part-Tooling Link

Parts have a `ToolingAssetId` FK that references back to the tooling asset used to produce them. This creates a bidirectional relationship:
- Asset detail shows the source part via `SourcePartId`
- Part detail shows the linked tooling asset via `ToolingAssetId`

### Shot Count vs Tool Life

The detail panel shows tool life as a ratio: `currentShotCount / toolLifeExpectancy`. This is a manual tracking field -- the shot count is updated via the `UpdateAsset` PATCH endpoint (the `CurrentShotCount` field on `UpdateAssetRequestModel`). There is no automated shot counting integration.

---

## Maintenance Schedules

Assets can have recurring maintenance schedules. Each schedule defines an interval and tracks when maintenance was last performed.

### Maintenance Schedule Entity

| Field | Type | Description |
|-------|------|-------------|
| `Id` | int | Primary key |
| `AssetId` | int | FK to the asset |
| `Title` | string | Schedule name (e.g., "Weekly Lubrication", "Annual Calibration") |
| `Description` | string? | Detailed description of maintenance tasks |
| `IntervalDays` | int | Days between maintenance occurrences |
| `IntervalHours` | decimal? | Machine hours between maintenance (alternative interval) |
| `LastPerformedAt` | DateTimeOffset? | When maintenance was last completed |
| `NextDueAt` | DateTimeOffset | When next maintenance is due |
| `IsActive` | bool | Whether the schedule is active (soft-deactivated schedules are excluded from queries) |
| `MaintenanceJobId` | int? | FK to a kanban job created from this schedule |

### Maintenance Log Entry

Each time maintenance is performed, a log entry is created:

| Field | Type | Description |
|-------|------|-------------|
| `Id` | int | Primary key |
| `MaintenanceScheduleId` | int | FK to the schedule |
| `PerformedById` | int | FK to the user who performed the maintenance |
| `PerformedAt` | DateTimeOffset | When performed (auto-set to current UTC time) |
| `HoursAtService` | decimal? | Machine hours at time of service |
| `Notes` | string? | Service notes |
| `Cost` | decimal? | Cost of maintenance |

### Auto-Advance

When a maintenance log is recorded via `POST /api/v1/assets/maintenance/{scheduleId}/log`, the handler automatically:
1. Sets `LastPerformedAt` to the current UTC time
2. Advances `NextDueAt` by `IntervalDays` from the current time

### Maintenance Job Creation

A maintenance schedule can generate a kanban job via `POST /api/v1/assets/maintenance/{scheduleId}/create-job`. This:
1. Finds the "Maintenance" track type (by name containing "Maintenance")
2. Creates a new job with title `"Maintenance: {AssetName} -- {ScheduleTitle}"`
3. Places the job in the first stage of the Maintenance track
4. Links the schedule to the job via `MaintenanceJobId`
5. Sets the job's due date to the schedule's `NextDueAt`

If no Maintenance track type exists, the endpoint returns 404 with a message directing the admin to create one.

### UI Representation

The detail panel shows the **Maintenance History** section with the 10 most recent log entries. There is currently no UI for creating or managing maintenance schedules directly from the assets feature -- schedules are managed via the API endpoints. The detail panel shows log entries only (not the schedule definitions).

---

## Downtime Logging

Assets support downtime event tracking aligned with the Six Big Losses framework for OEE (Overall Equipment Effectiveness).

### Downtime Categories (Six Big Losses)

| Category | Description |
|----------|-------------|
| `EquipmentFailure` | Unplanned stops due to equipment breakdown |
| `SetupAdjustment` | Time lost during setup and changeover |
| `Idling` | Minor stops and idling losses |
| `ReducedSpeed` | Running below optimal speed |
| `ProcessDefects` | Defects requiring rework |
| `ReducedYield` | Startup losses and reduced yield |

### Downtime Log Entity

| Field | Type | Description |
|-------|------|-------------|
| `Id` | int | Primary key |
| `AssetId` | int | FK to the asset |
| `WorkCenterId` | int? | FK to a work center |
| `ReportedById` | int? | FK to the user who reported (auto-set from JWT) |
| `StartedAt` | DateTimeOffset | When the downtime began |
| `EndedAt` | DateTimeOffset? | When the downtime ended (null = ongoing) |
| `Category` | DowntimeCategory? | Six Big Losses category |
| `DowntimeReasonId` | int? | FK to a reference data reason |
| `Reason` | string | Free-text reason description |
| `Resolution` | string? | How the downtime was resolved |
| `Description` | string? | Additional description |
| `IsPlanned` | bool | Whether the downtime was planned (scheduled maintenance) vs unplanned |
| `JobId` | int? | FK to a related job |
| `Notes` | string? | Additional notes |
| `DurationMinutes` | decimal | Computed: elapsed minutes (live-calculated if ongoing) |
| `DurationHours` | decimal | Computed: elapsed hours (live-calculated if ongoing) |

### Ending Downtime

Open downtime events (where `EndedAt` is null) can be closed via `PATCH /api/v1/assets/downtime/{id}/end`, which sets `EndedAt` to the current UTC time. Attempting to end an already-ended event returns 400 ("Downtime event has already ended").

### UI Representation

Downtime logging is managed via the API endpoints. The Angular service (`AssetsService`) provides `getDowntimeLogs()`, `createDowntimeLog()`, and the API supports ending downtime, but there is no dedicated downtime UI panel in the current asset detail dialog.

---

## Asset-Job/Part Links

### Source Job (`SourceJobId`)

Links a tooling asset to the job that produced or acquired it. Displayed in the detail panel as a clickable `EntityLinkComponent` that navigates to the job's detail dialog (`?detail=job:{id}`). Only shown when the value is set and the asset type is Tooling.

### Source Part (`SourcePartId`)

Links a tooling asset to the part it produces. Displayed in the detail panel as a clickable `EntityLinkComponent` that navigates to the part's detail dialog (`?detail=part:{id}`). Only shown when the value is set and the asset type is Tooling.

### Part's Tooling Asset (`ToolingAssetId`)

Parts have a reciprocal `ToolingAssetId` FK back to the tooling asset. This is set on the Part entity and displayed in the part detail view, not the asset detail view.

### Barcode/QR Identifier

On asset creation, the backend automatically generates a barcode entry via `IBarcodeService.CreateBarcodeAsync()` using the asset's serial number (or name as fallback) as the natural identifier. The `BarcodeInfoComponent` in the detail panel displays this barcode/QR code in compact mode.

---

## Machine Hours

Assets track cumulative machine hours via the `CurrentHours` field (decimal). Hours are displayed in the list table (right-aligned, tabular-nums font) and in the detail panel info grid.

### Update Machine Hours

```
PATCH /api/v1/assets/{id}/hours
```

Dedicated endpoint for updating machine hours without modifying other asset fields. Validates that `CurrentHours >= 0`.

The Angular service exposes `updateMachineHours(id, currentHours)` but there is no dedicated UI control for updating hours in the current implementation -- hours can be updated via the general edit dialog or the API directly.

---

## Every Button/Action

### Page Header

| Button | Label | Icon | Behavior | Disabled State |
|--------|-------|------|----------|----------------|
| New Asset | i18n `assets.addAsset` | `add` | Opens create dialog with form reset to defaults | Never |

### Detail Panel Header

| Button | Type | Icon | Tooltip | Behavior | aria-label |
|--------|------|------|---------|----------|------------|
| Edit | `icon-btn` | `edit` | "Edit" | Closes detail dialog with `{ action: 'edit', asset }` result, which triggers edit form dialog | "Edit asset" |
| Close | `icon-btn` | `close` | "Close" | Closes the detail dialog | "Close panel" |

### Detail Panel Status Buttons

Four status buttons in a horizontal group. Each is a `status-btn` with:
- Active state: `status-btn--active` class (primary color border + light primary background)
- Click: Immediately PATCHes the asset with the new status. No confirmation dialog.
- Visual feedback: Snackbar "Asset updated" on success.

### Create/Edit Dialog Footer

| Button | Label | Icon | Behavior | Disabled State |
|--------|-------|------|----------|----------------|
| Cancel | i18n `common.cancel` | None | Closes dialog without saving | Never |
| Save/Create | i18n `assets.saveChanges` or `assets.createAsset` | `save` | Submits form | When `form.invalid` or `saving()` is true |

---

## API Endpoints

All endpoints require `Authorization: Bearer {token}` and role `Admin`, `Manager`, or `Engineer`.

### Asset CRUD

#### List Assets

```
GET /api/v1/assets?type={AssetType}&status={AssetStatus}&search={string}
```

All query parameters are optional. Returns the full list (no pagination).

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "name": "Haas VF-2",
    "assetType": "Machine",
    "location": "Bay 3",
    "manufacturer": "Haas",
    "model": "VF-2",
    "serialNumber": "SN-20240101",
    "status": "Active",
    "photoFileId": null,
    "currentHours": 4520.5,
    "notes": null,
    "isCustomerOwned": false,
    "cavityCount": null,
    "toolLifeExpectancy": null,
    "currentShotCount": 0,
    "sourceJobId": null,
    "sourceJobNumber": null,
    "sourcePartId": null,
    "sourcePartNumber": null,
    "createdAt": "2024-06-15T10:00:00Z",
    "updatedAt": "2024-12-01T14:30:00Z"
  }
]
```

#### Create Asset

```
POST /api/v1/assets
Content-Type: application/json

{
  "name": "4-Cavity Housing Mold",
  "assetType": "Tooling",
  "location": "Tool Crib",
  "manufacturer": "DME",
  "model": "Custom",
  "serialNumber": "MOLD-2024-001",
  "notes": "Customer-owned tooling for Acme Corp",
  "isCustomerOwned": true,
  "cavityCount": 4,
  "toolLifeExpectancy": 500000,
  "sourceJobId": 1055,
  "sourcePartId": 42
}
```

**Validation:**
- `Name` -- required, max 200 characters
- `SerialNumber` -- max 100 characters
- `Location` -- max 200 characters

**Response:** `201 Created` with `Location: /api/v1/assets/{id}` header

Response body matches the `AssetResponseModel` shape shown above.

**Side effects:** Creates a barcode entry (`IBarcodeService`) using serial number or name as the natural identifier.

#### Update Asset

```
PATCH /api/v1/assets/{id}
Content-Type: application/json

{
  "status": "Maintenance",
  "currentHours": 4600.0
}
```

All fields are optional -- only provided fields are updated. Null/missing fields are left unchanged.

**Validation:**
- `Id` -- must be > 0
- `Name` -- max 200 characters (when provided)
- `SerialNumber` -- max 100 characters (when provided)
- `Location` -- max 200 characters (when provided)

**Response:** `200 OK` with updated `AssetResponseModel`

**Error:** `404` if asset not found.

#### Delete Asset (Soft Delete)

```
DELETE /api/v1/assets/{id}
```

Sets `DeletedAt` to the current UTC timestamp. Does not hard-delete the record.

**Response:** `204 No Content`

**Error:** `404` if asset not found.

### Machine Hours

#### Update Machine Hours

```
PATCH /api/v1/assets/{id}/hours
Content-Type: application/json

{ "currentHours": 4600.0 }
```

**Validation:** `CurrentHours >= 0`, `AssetId > 0`.

**Response:** `200 OK` with updated `AssetResponseModel`

### Activity Log

#### Get Asset Activity

```
GET /api/v1/assets/{id}/activity
```

Returns the polymorphic activity log for this asset (entity type "Asset").

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "description": "Status changed to Maintenance",
    "createdAt": "2024-12-01T14:30:00Z",
    "userInitials": "DH",
    "userColor": "#4CAF50",
    "action": "StatusChanged"
  }
]
```

### Maintenance Schedules

#### List Maintenance Schedules (per asset)

```
GET /api/v1/assets/{id}/maintenance
```

Returns active schedules for the specified asset, ordered by `NextDueAt`.

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "assetId": 5,
    "assetName": "Haas VF-2",
    "title": "Weekly Lubrication",
    "description": "Lubricate all linear guides and ball screws",
    "intervalDays": 7,
    "intervalHours": 40.0,
    "lastPerformedAt": "2024-11-24T08:00:00Z",
    "nextDueAt": "2024-12-01T08:00:00Z",
    "isActive": true,
    "isOverdue": true
  }
]
```

#### List All Maintenance Schedules

```
GET /api/v1/assets/maintenance
```

Returns all active schedules across all assets.

**Response:** Same shape as above.

#### Create Maintenance Schedule

```
POST /api/v1/assets/{id}/maintenance
Content-Type: application/json

{
  "assetId": 5,
  "title": "Annual Calibration",
  "description": "Full axis calibration with laser interferometer",
  "intervalDays": 365,
  "intervalHours": null,
  "nextDueAt": "2025-06-15T08:00:00Z"
}
```

**Validation:**
- `Title` -- required, max 200 characters
- `IntervalDays` -- must be > 0
- `AssetId` -- must be > 0

**Response:** `201 Created` with `Location: /api/v1/assets/{id}/maintenance/{scheduleId}` header

**Error:** `404` if asset not found.

#### Delete Maintenance Schedule (Soft Delete)

```
DELETE /api/v1/assets/maintenance/{scheduleId}
```

Soft-deletes the schedule by setting `DeletedAt`.

**Response:** `204 No Content`

**Error:** `404` if schedule not found.

### Maintenance Logs

#### Get Asset Maintenance Logs

```
GET /api/v1/assets/{id}/maintenance/logs
```

Returns the 10 most recent maintenance log entries for the asset, ordered by `PerformedAt` descending. Joins through the schedule to resolve the schedule title and performer name.

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "scheduleName": "Weekly Lubrication",
    "performedAt": "2024-11-24T08:00:00Z",
    "performedByName": "Hartman, Daniel",
    "hoursSpent": 0.5,
    "notes": "All guides lubricated, no abnormal wear",
    "cost": 25.00
  }
]
```

#### Log Maintenance Performed

```
POST /api/v1/assets/maintenance/{scheduleId}/log
Content-Type: application/json

{
  "hoursAtService": 4500.0,
  "notes": "Replaced worn guide on X-axis",
  "cost": 150.00
}
```

All fields are optional.

**Response:** `201 Created`

```json
{
  "id": 10,
  "maintenanceScheduleId": 1,
  "performedByName": "Hartman, Daniel",
  "performedAt": "2024-12-01T14:30:00Z",
  "hoursAtService": 4500.0,
  "notes": "Replaced worn guide on X-axis",
  "cost": 150.00
}
```

**Side effects:** Updates `LastPerformedAt` and advances `NextDueAt` on the schedule.

**Error:** `404` if schedule not found.

### Maintenance Job Creation

#### Create Maintenance Job

```
POST /api/v1/assets/maintenance/{scheduleId}/create-job
```

No request body. Creates a kanban job on the Maintenance track type.

**Response:** `201 Created` with `Location: /api/v1/jobs/{jobId}` header

```json
{ "jobId": 2045 }
```

**Error:** `404` if schedule not found, or if no "Maintenance" track type exists, or if the track has no stages.

### Downtime Logging

#### Get Asset Downtime Logs

```
GET /api/v1/assets/{id}/downtime
```

Returns all downtime logs for the specified asset, ordered by `StartedAt` descending.

**Response:** `200 OK`

```json
[
  {
    "id": 1,
    "assetId": 5,
    "assetName": "Haas VF-2",
    "reportedById": 1,
    "startedAt": "2024-12-01T10:00:00Z",
    "endedAt": "2024-12-01T12:30:00Z",
    "reason": "Spindle bearing failure",
    "resolution": "Replaced spindle bearings",
    "isPlanned": false,
    "notes": "Ordered replacement bearings from MSC",
    "durationHours": 2.5,
    "createdAt": "2024-12-01T10:05:00Z"
  }
]
```

#### Get All Downtime Logs

```
GET /api/v1/assets/downtime
```

Returns all downtime logs across all assets.

#### Create Downtime Log

```
POST /api/v1/assets/{id}/downtime
Content-Type: application/json

{
  "assetId": 5,
  "workCenterId": null,
  "startedAt": "2024-12-01T10:00:00Z",
  "endedAt": null,
  "category": "EquipmentFailure",
  "downtimeReasonId": null,
  "reason": "Spindle bearing failure",
  "resolution": null,
  "description": "Unusual noise detected during high-speed operation",
  "isPlanned": false,
  "jobId": 1055,
  "notes": null
}
```

**Validation:**
- `AssetId` -- must be > 0
- `Reason` -- required, max 500 characters
- `Resolution` -- max 500 characters
- `Notes` -- max 2000 characters
- `EndedAt` -- must be after `StartedAt` (when provided)

**Response:** `201 Created` with `Location` header

**Error:** `404` if asset not found.

#### End Downtime Event

```
PATCH /api/v1/assets/downtime/{id}/end
```

No request body. Sets `EndedAt` to the current UTC time.

**Response:** `200 OK` with updated `DowntimeLogResponseModel`

**Error:** `404` if downtime log not found. `400` if already ended ("Downtime event has already ended").

---

## Status Lifecycle

Asset statuses are user-driven -- there are no automated status transitions or workflow restrictions. Any authorized user can set any status at any time from the detail panel.

```
Active <--> Maintenance <--> Retired <--> OutOfService
```

All transitions are bidirectional and unrestricted. The status is updated via `PATCH /api/v1/assets/{id}` with `{ "status": "NewStatus" }`.

There is no confirmation dialog for status changes. The update is immediate with a snackbar confirmation.

---

## Subcontract Orders

The `AssetsService` also provides methods for subcontract order management, though these are job-operation-scoped rather than asset-scoped:

- `getSubcontractOrders(jobId)` -- lists subcontract orders for a job
- `sendOutSubcontract(jobId, operationId, data)` -- creates a subcontract send-out
- `receiveBackSubcontract(orderId, data)` -- records receipt of subcontracted work

Subcontract orders track work sent to external vendors for specific job operations, with status lifecycle: `Pending -> Sent -> InProcess -> Shipped -> Received -> QcPending -> Complete` (or `Rejected`). These are co-located in the assets service for organizational convenience but are functionally part of the job/operations domain.

---

## Known Limitations

1. **No pagination.** The asset list endpoint returns all assets in a single response. For shops with thousands of assets, this could become a performance concern. The DataTable provides client-side sorting and filtering but the full dataset is loaded.

2. **No dedicated maintenance schedule UI.** Maintenance schedules can be created, queried, and deleted via API, but the asset detail panel only shows maintenance _logs_ (the 10 most recent). There is no UI panel for viewing/creating/editing maintenance schedule definitions.

3. **No dedicated downtime UI.** Downtime logs can be created and queried via API, but there is no UI panel in the asset detail for viewing or creating downtime events.

4. **No photo upload UI.** The `PhotoFileId` field exists on the entity but there is no file upload control in the create/edit dialog.

5. **Manual shot count tracking.** The `CurrentShotCount` for tooling assets must be updated manually via the API. There is no automated integration with machine controllers or counters, and the edit dialog does not expose this field.

6. **No source job/part selection in create/edit dialog.** The `SourceJobId` and `SourcePartId` fields are accepted by the API but are not exposed as form fields in the create/edit dialog. They must be set via direct API calls.

7. **Asset detail loads all assets.** The detail panel fetches the full asset list via `getAssets()` and filters client-side by ID to find the selected asset, rather than having a dedicated `GET /api/v1/assets/{id}` endpoint.

8. **No maintenance schedule hour-based interval trigger.** The `IntervalHours` field is stored but only `IntervalDays` is used for auto-advancing `NextDueAt`. Hour-based intervals would require integration with machine hour tracking.

9. **Delete not wired in UI.** The `deleteAsset()` method exists in the component but is empty (placeholder for future toolbar action). Assets can only be deleted via direct API call.

10. **Maintenance performer name format.** The maintenance log handler uses `"{FirstName} {LastName}"` format for the performer name, while the log list query uses `"{LastName}, {FirstName}"`. This inconsistency means the `MaintenanceLogResponseModel` and `MaintenanceLogListItemResponseModel` may show different name formats for the same user.
