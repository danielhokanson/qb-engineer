# Quality / QC

## Overview

The Quality module is the centralized hub for quality management across the manufacturing lifecycle. It encompasses nine functional areas organized as tabs within a single page: QC Inspections, Lot Tracking, SPC Charts, SPC Data Entry, SPC Out-of-Control Events, Non-Conformance Reports (NCRs), Corrective/Preventive Actions (CAPAs), Engineering Change Orders (ECOs), and Gage Management. Supporting backend subsystems include PPAP (Production Part Approval Process), FMEA (Failure Mode and Effects Analysis), and COPQ (Cost of Poor Quality) reporting.

The system supports a complete quality workflow: define inspection templates, perform inspections against jobs and lots, track lot traceability, monitor process stability with SPC control charts, detect and respond to out-of-control conditions, document non-conformances, drive root-cause corrective actions, manage engineering changes, and maintain gage calibration records. NCRs can spawn CAPAs, and SPC out-of-control events can also spawn CAPAs, creating a closed-loop quality system.

---

## Routes & Navigation

The Quality feature is lazy-loaded at `/quality` and uses the standard `:tab` route parameter pattern.

| Route | Tab | Description |
|-------|-----|-------------|
| `/quality` | (redirect) | Redirects to `/quality/inspections` |
| `/quality/inspections` | Inspections | QC inspection list with status filter |
| `/quality/lots` | Lot Tracking | Lot records with traceability |
| `/quality/spc-charts` | SPC Charts | X-bar and R control charts |
| `/quality/spc-data` | SPC Data Entry | Record subgroup measurements |
| `/quality/spc-ooc` | OOC Events | Out-of-control event log |
| `/quality/ncrs` | NCRs | Non-conformance reports |
| `/quality/capas` | CAPAs | Corrective/preventive actions |
| `/quality/ecos` | ECOs | Engineering change orders |
| `/quality/gages` | Gages | Gage management and calibration |

Routes are defined in `quality.routes.ts`. The `QualityComponent` reads the active tab from the URL via `ActivatedRoute.paramMap` and renders the corresponding tab content. Tab clicks call `switchTab()` which navigates via `router.navigate(['..', tab])`.

**Tab icons:**

| Tab | Icon |
|-----|------|
| Inspections | `fact_check` |
| Lot Tracking | `qr_code_2` |
| SPC Charts | `show_chart` |
| SPC Data Entry | `edit_note` |
| OOC Events | `warning` |
| NCRs | `report_problem` |
| CAPAs | `assignment_turned_in` |
| ECOs | `engineering` |
| Gages | `straighten` |

---

## QC Templates

Templates define reusable checklists for inspections. Each template has a name, optional description, optional part association, and an ordered list of checklist items.

### Template Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `name` | string | Template name |
| `description` | string or null | Optional description |
| `partId` | number or null | Associated part (optional) |
| `partNumber` | string or null | Part number (read-only) |
| `isActive` | boolean | Whether the template is active |
| `items` | QcTemplateItem[] | Ordered checklist items |

### Template Item Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `description` | string | Check description |
| `specification` | string or null | Specification reference |
| `sortOrder` | number | Display order |
| `isRequired` | boolean | Whether this check is mandatory |

### Creating a Template

Templates are created via the `POST /api/v1/quality/templates` endpoint. The UI currently populates the template select dropdown for inspection creation from the template list. Template creation is restricted to Admin and Manager roles.

**Create Template Request:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Template name |
| `description` | string | No | Template description |
| `partId` | number | No | Associated part ID |
| `items` | array | Yes | Checklist items array |
| `items[].description` | string | Yes | Item description |
| `items[].specification` | string | No | Specification reference |
| `items[].sortOrder` | number | Yes | Display order |
| `items[].isRequired` | boolean | Yes | Whether mandatory |

Note: There is no dedicated template management UI page. Templates are created via the API and listed in the inspection creation dialog's template dropdown.

---

## QC Inspections

### Inspection List

The Inspections tab displays a DataTable with columns:

| Column | Header | Type | Sortable | Filterable | Width |
|--------|--------|------|----------|------------|-------|
| `createdAt` | Date | date | Yes | No | 120px |
| `jobNumber` | Job | text | Yes | No | 100px |
| `templateName` | Template | text | Yes | No | auto |
| `inspectorName` | Inspector | text | Yes | No | auto |
| `lotNumber` | Lot Number | text | Yes | No | 140px |
| `status` | Status | enum | Yes | Yes | 100px |
| `resultsSummary` | Results | text | No | No | 100px |

**Table ID:** `qc-inspections`

**Empty state:** `fact_check` icon with i18n message `quality.noInspectionsFound`

### Inspection Status Values

| Value | Display Label | Chip Class |
|-------|---------------|------------|
| `InProgress` | In Progress | `chip--warning` |
| `Passed` | Passed | `chip--success` |
| `Failed` | Failed | `chip--error` |

### Inspection Filters

| Filter | Type | Options |
|--------|------|---------|
| Status | Select dropdown | All Statuses, In Progress, Passed, Failed |

Changing the status filter immediately reloads the inspection list.

### Results Summary

The results summary column shows `passed/total` (e.g., `4/5`). If no results are recorded, it shows `--`.

### Inspection Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `jobId` | number or null | Associated job |
| `jobNumber` | string or null | Job number (read-only) |
| `productionRunId` | number or null | Associated production run |
| `templateId` | number or null | Template used |
| `templateName` | string or null | Template name (read-only) |
| `inspectorId` | number | Inspector user ID |
| `inspectorName` | string | Inspector name (read-only) |
| `lotNumber` | string or null | Lot number inspected |
| `status` | string | InProgress, Passed, or Failed |
| `notes` | string or null | Inspection notes |
| `completedAt` | Date or null | Completion timestamp |
| `results` | QcInspectionResult[] | Individual check results |
| `createdAt` | Date | Creation timestamp |

### Inspection Result Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `checklistItemId` | number or null | Template item reference |
| `description` | string | Check description |
| `passed` | boolean | Pass/fail result |
| `measuredValue` | string or null | Recorded measurement |
| `notes` | string or null | Result notes |

### Create Inspection Dialog

**Dialog title:** i18n `quality.newQcInspection`

| Field | Label | Type | Required | Validation | data-testid |
|-------|-------|------|----------|------------|-------------|
| `templateId` | Template | Select | No | -- | `inspection-template` |
| `jobId` | Job ID | Number input | No | -- | `inspection-job` |
| `lotNumber` | Lot Number | Text input | No | -- | `inspection-lot` |
| `notes` | Notes | Textarea | No | -- | `inspection-notes` |

**Template options:** Populated from the loaded templates list. First option is `-- None --` (null value).

**Footer buttons:**
- Cancel (left) -- closes dialog
- Create Inspection (right, primary) -- disabled while `saving()` is true, has `[appValidationPopover]="inspectionViolations"`

**On save:** Posts to `POST /api/v1/quality/inspections`, then reloads the inspection list and shows a success snackbar.

### Create Inspection Button

Visible only when the Inspections tab is active. Located in the page header.
- Label: i18n `quality.newInspection`
- Icon: `add`
- data-testid: `new-inspection-btn`

---

## Lot Tracking

### Lot List

The Lots tab displays lot records in a DataTable with columns:

| Column | Header | Type | Sortable | Width | Align |
|--------|--------|------|----------|-------|-------|
| `lotNumber` | Lot Number | text | Yes | 160px | -- |
| `partNumber` | Part # | text | Yes | 120px | -- |
| `partDescription` | Description | text | Yes | auto | -- |
| `quantity` | Quantity | text | Yes | 80px | right |
| `jobNumber` | Job | text | Yes | 100px | -- |
| `supplierLotNumber` | Supplier Lot | text | Yes | 140px | -- |
| `expirationDate` | Expires | date | Yes | 110px | -- |
| `createdAt` | Created | date | Yes | 110px | -- |
| `actions` | (none) | -- | No | 50px | center |

**Table ID:** `lot-records`

**Empty state:** `qr_code_2` icon with i18n message `quality.noLotRecordsFound`

Lot numbers are displayed in monospace font (`$font-family-mono`).

### Lot Filters

| Filter | Type | Behavior |
|--------|------|----------|
| Search | Text input | Filters by lot number, part number. Triggers on Enter key. |

### Lot Record Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `lotNumber` | string | System-generated or user-specified lot number |
| `partId` | number | Associated part |
| `partNumber` | string | Part number (read-only) |
| `partDescription` | string or null | Part description (read-only) |
| `jobId` | number or null | Associated job |
| `jobNumber` | string or null | Job number (read-only) |
| `productionRunId` | number or null | Associated production run |
| `purchaseOrderLineId` | number or null | Associated PO line |
| `quantity` | number | Lot quantity |
| `expirationDate` | Date or null | Expiration date |
| `supplierLotNumber` | string or null | Supplier's lot identifier |
| `notes` | string or null | Notes |
| `createdAt` | Date | Creation timestamp |

### Create Lot Dialog

**Dialog title:** i18n `quality.newLotRecord`

| Field | Label | Type | Required | Validation |
|-------|-------|------|----------|------------|
| `partId` | Part ID | Number input | Yes | `Validators.required` |
| `quantity` | Quantity | Number input | Yes | `Validators.required`, `Validators.min(1)` |
| `lotNumber` | Lot Number | Text input | No | Placeholder: i18n `quality.lotNumberPlaceholder` (auto-generated if blank) |
| `jobId` | Job ID | Number input | No | -- |
| `supplierLotNumber` | Supplier Lot | Text input | No | -- |
| `notes` | Notes | Textarea | No | -- |

**Footer buttons:**
- Cancel (left) -- closes dialog
- Create Lot (right, primary) -- disabled when form invalid or `saving()`, has `[appValidationPopover]="lotViolations"`

**On save:** Posts to `POST /api/v1/lots`, reloads lot list, shows success snackbar.

### Lot Actions

Each lot row has a traceability button in the actions column:
- Icon: `account_tree`
- Tooltip: i18n `quality.viewTraceability`
- Action: Opens the traceability dialog for that lot

### Traceability Dialog

**Dialog title:** i18n `quality.traceabilityTitle` with `{ lot: lotNumber }` interpolation
**Width:** 800px

The traceability dialog shows all entities linked to a specific lot number. The header displays the part number and description.

**Sections displayed (conditionally -- only when data exists):**

| Section | Icon | Content |
|---------|------|---------|
| Jobs | `work` | Job number + title for each linked job |
| Production Runs | `precision_manufacturing` | Run number + status chip for each run |
| Purchase Orders | `receipt_long` | PO number + vendor name for each PO |
| Bin Locations | `warehouse` | Location name + quantity at each location |
| QC Inspections | `fact_check` | Status chip + inspector name + date for each inspection |

If no linked records exist across all sections, an empty state is shown with `info` icon and i18n message `quality.noLinkedRecords`.

**Footer:** Close button (primary).

### Traceability Model

| Field | Type | Description |
|-------|------|-------------|
| `lotNumber` | string | The queried lot number |
| `partNumber` | string | Associated part number |
| `partDescription` | string or null | Part description |
| `jobs` | LotTraceJob[] | Linked jobs |
| `productionRuns` | LotTraceProductionRun[] | Linked production runs |
| `purchaseOrders` | LotTracePurchaseOrder[] | Linked purchase orders |
| `binLocations` | LotTraceBinLocation[] | Current storage locations |
| `inspections` | LotTraceInspection[] | QC inspections performed |

---

## SPC (Statistical Process Control)

SPC is fully implemented with three dedicated tabs: SPC Charts, SPC Data Entry, and OOC Events. The SPC subsystem operates on **characteristics** -- measurable features of parts that are monitored for process stability.

### SPC Characteristics

The `SpcCharacteristicsComponent` is shared between the SPC Charts and SPC Data Entry tabs. When no characteristic is selected, it fills the full tab width. When a characteristic is selected, it becomes a 400px sidebar on the left, and the chart or data entry form occupies the remaining space.

**Characteristics DataTable columns:**

| Column | Header | Type | Sortable | Width | Align |
|--------|--------|------|----------|-------|-------|
| `partNumber` | Part # | text | Yes | 120px | -- |
| `name` | Characteristic | text | Yes | auto | -- |
| `operationName` | Operation | text | Yes | 140px | -- |
| `nominalValue` | Nominal | number | Yes | 90px | right |
| `specLimits` | Spec Limits | custom | No | 140px | center |
| `sampleSize` | n | number | Yes | 50px | center |
| `measurementCount` | Measurements | number | Yes | 110px | right |
| `latestCpk` | Cpk | number | Yes | 80px | right |
| `isActive` | Active | boolean | Yes | 70px | center |
| `actions` | (none) | -- | No | 50px | center |

**Table ID:** `spc-characteristics`

Rows are clickable. Clicking a row emits `characteristicSelected` which either navigates to the SPC Charts tab (from the SPC Charts tab sidebar) or sets the selected characteristic (from SPC Data Entry).

**Cpk color coding:**
- >= 1.33: green (`spc-cpk--good`)
- >= 1.0 but < 1.33: warning (`spc-cpk--warning`)
- < 1.0: danger (`spc-cpk--danger`)
- null: muted dash

**Active column:** Green `check_circle` icon when active, muted `cancel` icon when inactive.

**Edit button:** Each row has an `edit` icon button in the actions column.

### SPC Characteristic Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `partId` | number | Associated part |
| `partNumber` | string | Part number (read-only) |
| `operationId` | number or null | Associated operation |
| `operationName` | string or null | Operation name (read-only) |
| `name` | string | Characteristic name (e.g., "Bore Diameter") |
| `description` | string or null | Description |
| `measurementType` | string | `Variable` or `Attribute` |
| `nominalValue` | number | Target/nominal value |
| `upperSpecLimit` | number | Upper specification limit (USL) |
| `lowerSpecLimit` | number | Lower specification limit (LSL) |
| `unitOfMeasure` | string or null | Unit (e.g., "mm", "in") |
| `decimalPlaces` | number | Precision for display (0-6) |
| `sampleSize` | number | Subgroup sample size n (2-25) |
| `sampleFrequency` | string or null | Sampling frequency description |
| `gageId` | number or null | Associated gage |
| `isActive` | boolean | Whether actively monitored |
| `notifyOnOoc` | boolean | Send notification on out-of-control |
| `measurementCount` | number | Total measurements recorded (read-only) |
| `latestCpk` | number or null | Most recent Cpk value (read-only) |

### Create/Edit Characteristic Dialog

**Dialog title:** "New Characteristic" or "Edit Characteristic"
**Width:** 520px

| Field | Label | Type | Required | Validation | Default |
|-------|-------|------|----------|------------|---------|
| `partId` | Part ID | Number input | Yes | `Validators.required` | -- |
| `operationId` | Operation ID | Number input | No | -- | -- |
| `name` | Name | Text input | Yes | `Validators.required`, `maxLength(200)` | -- |
| `description` | Description | Textarea | No | -- | -- |
| `measurementType` | Measurement Type | Select | No | -- | `Variable` |
| `nominalValue` | Nominal Value | Number input | Yes | `Validators.required` | 0 |
| `unitOfMeasure` | Unit of Measure | Text input | No | -- | -- |
| `lowerSpecLimit` | Lower Spec Limit | Number input | Yes | `Validators.required` | 0 |
| `upperSpecLimit` | Upper Spec Limit | Number input | Yes | `Validators.required` | 0 |
| `sampleSize` | Sample Size (n) | Number input | Yes | `Validators.required`, `min(2)`, `max(25)` | 5 |
| `decimalPlaces` | Decimal Places | Number input | Yes | `Validators.required`, `min(0)`, `max(6)` | 4 |
| `sampleFrequency` | Sample Frequency | Text input | No | Placeholder: "e.g., Every 50 pieces" | -- |
| `notifyOnOoc` | Notify on OOC | Toggle | No | -- | true |
| `isActive` | Active | Toggle | No | -- | true |

**Measurement Type options:** Variable, Attribute

**Footer buttons:**
- Cancel (left)
- Create/Update (right, primary) -- disabled when form invalid or saving, has validation popover

### SPC Charts Tab

When a characteristic is selected, the SPC Charts tab shows the `SpcChartComponent` which renders:

1. **Header:** Characteristic name, KPI chips (Cp, Cpk, Ppk, sigma, Points count), and a Recalculate button.
2. **Spec info bar:** LSL, Nominal, USL values displayed inline.
3. **X-bar Chart:** Line chart showing subgroup means over time with UCL, CL, LCL lines. Out-of-control points are highlighted in red with larger radius (6px vs 3px).
4. **R Chart:** Line chart showing subgroup ranges with UCL, CL, LCL lines.

**Chart library:** ng2-charts (Chart.js)

**KPI chips:**
| Label | Value | Color |
|-------|-------|-------|
| Cp | 2 decimal places | default |
| Cpk | 2 decimal places | green (>= 1.33), warn (>= 1.0), default (< 1.0) |
| Ppk | 2 decimal places | default |
| sigma | 4 decimal places | default |
| Points | integer count | default |

**Recalculate button:** Calls `POST /api/v1/spc/characteristics/{id}/recalculate-limits`, then refreshes the chart data. Shows success snackbar on completion.

**Control limit lines:**
- UCL: red dashed (`#ef4444`, dash [5,5])
- CL (center line): gray dashed (`#6b7280`, dash [3,3])
- LCL: red dashed (`#ef4444`, dash [5,5])

**X-bar data line:** Blue (`#3b82f6`), OOC points red (`#ef4444`)
**Range data line:** Purple (`#8b5cf6`)

**Empty state:** When no measurement data, shows `show_chart` icon with "No measurement data yet. Record subgroups to generate charts."

**Chart loads the last 50 data points** by default.

### SPC Data Entry Tab

The data entry tab shows the `SpcDataEntryComponent` for recording individual subgroup measurements.

**Header displays:** Characteristic name, part number, sample size (n), and unit of measure.

**Context fields:**

| Field | Label | Type | Required |
|-------|-------|------|----------|
| `jobIdControl` | Job ID | Number input | No |
| `lotNumberControl` | Lot Number | Text input | No |

**Measurement grid:** A grid of `n` input rows (matching the characteristic's `sampleSize`), each with:
- Row label (1, 2, 3, ...)
- Number input with `step` matching the characteristic's decimal precision
- data-testid: `spc-value-{index}`
- Enter key on last filled input submits the subgroup

**Computed statistics (live):**
- Mean (X-bar): Calculated from filled values
- Range (R): Max - Min of filled values

**Notes field:** Textarea with 2 rows

**Action buttons:**
- Clear (left) -- resets all values and notes
- Record Subgroup (right, primary, with `save` icon) -- disabled when not all values are filled or saving

**On submit:** Calls `POST /api/v1/spc/measurements`. If the recorded measurement is out of control, the snackbar includes a warning: "Subgroup #N recorded. Warning OOC: {rule}". Emits `measurementRecorded` event which refreshes the characteristics list.

### SPC Measurement Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `characteristicId` | number | Parent characteristic |
| `jobId` | number or null | Associated job |
| `productionRunId` | number or null | Associated production run |
| `lotNumber` | string or null | Lot number |
| `measuredByName` | string | Who recorded it |
| `measuredAt` | string (ISO) | When recorded |
| `subgroupNumber` | number | Sequential subgroup number |
| `values` | number[] | Individual readings |
| `mean` | number | Subgroup mean |
| `range` | number | Subgroup range |
| `stdDev` | number | Subgroup standard deviation |
| `median` | number | Subgroup median |
| `isOutOfSpec` | boolean | Outside specification limits |
| `isOutOfControl` | boolean | Violated control rules |
| `oocRuleViolated` | string or null | Which Western Electric rule was violated |
| `notes` | string or null | Notes |

### SPC Control Limits Model

| Field | Type | Description |
|-------|------|-------------|
| `xBarUcl` | number | X-bar upper control limit |
| `xBarLcl` | number | X-bar lower control limit |
| `xBarCenterLine` | number | X-bar center line (grand mean) |
| `rangeUcl` | number | Range upper control limit |
| `rangeLcl` | number | Range lower control limit |
| `rangeCenterLine` | number | Range center line (mean range) |
| `cp` | number | Process capability index |
| `cpk` | number | Process capability index (adjusted) |
| `pp` | number | Process performance index |
| `ppk` | number | Process performance index (adjusted) |
| `processSigma` | number | Process sigma estimate |
| `sampleCount` | number | Number of subgroups used |
| `isActive` | boolean | Whether these are the active limits |

### SPC Capability Report Model

Available via `GET /api/v1/spc/capability/{characteristicId}`. Includes histogram bucket data and normal curve overlay points for capability visualization.

| Field | Type | Description |
|-------|------|-------------|
| `characteristicId` | number | Characteristic |
| `characteristicName` | string | Name |
| `usl` | number | Upper spec limit |
| `lsl` | number | Lower spec limit |
| `nominal` | number | Nominal value |
| `cp` | number | Process capability |
| `cpk` | number | Adjusted capability |
| `pp` | number | Process performance |
| `ppk` | number | Adjusted performance |
| `mean` | number | Overall mean |
| `sigma` | number | Process sigma |
| `sampleCount` | number | Total samples |
| `histogramBuckets` | HistogramBucket[] | Frequency distribution |
| `normalCurve` | NormalCurvePoint[] | Normal distribution overlay |

### SPC Out-of-Control Events Tab

The `SpcOocListComponent` displays detected out-of-control events with acknowledgment and CAPA creation workflows.

**OOC Events DataTable columns:**

| Column | Header | Type | Sortable | Filterable | Width |
|--------|--------|------|----------|------------|-------|
| `detectedAt` | Detected | date | Yes | No | 130px |
| `partNumber` | Part | text | Yes | No | 100px |
| `characteristicName` | Characteristic | text | Yes | No | auto |
| `ruleName` | Rule | text | Yes | No | 200px |
| `severity` | Severity | enum | Yes | Yes | 110px |
| `status` | Status | enum | Yes | Yes | 120px |
| `acknowledgedByName` | Acknowledged By | text | Yes | No | 140px |
| `actions` | (none) | -- | No | No | 80px |

**Table ID:** `spc-ooc-events`

**Filters:**

| Filter | Type | Options |
|--------|------|---------|
| Status | Select | All Statuses, Open, Acknowledged, CAPA Created, Resolved |
| Severity | Select | All Severities, Warning, Out of Control, Out of Spec |

**OOC Event Severity:**

| Value | Chip Class |
|-------|------------|
| `Warning` | `chip--warning` |
| `OutOfControl` | `chip--error` |
| `OutOfSpec` | `chip--error` |

**OOC Event Status:**

| Value | Chip Class |
|-------|------------|
| `Open` | `chip--error` |
| `Acknowledged` | `chip--warning` |
| `CapaCreated` | `chip--info` |
| `Resolved` | `chip--success` |

**Row actions:**
- **Acknowledge** (check icon `done`) -- visible when status is `Open`. Opens acknowledge dialog.
- **Create CAPA** (assignment icon) -- visible when status is `Open` or `Acknowledged`. Creates a CAPA from the OOC event directly.

### Acknowledge OOC Dialog

**Dialog title:** "Acknowledge OOC Event"

Displays the rule name and description of the event as read-only info, plus:

| Field | Label | Type | Required |
|-------|-------|------|----------|
| `ackNotes` | Acknowledgment Notes | Textarea (3 rows) | No |

**Footer buttons:**
- Cancel (left)
- Acknowledge (right, primary, with `done` icon) -- disabled while saving

**On acknowledge:** Calls `POST /api/v1/spc/out-of-control/{id}/acknowledge`, reloads the event list, shows success snackbar.

### OOC Event Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `characteristicId` | number | Parent characteristic |
| `characteristicName` | string | Characteristic name |
| `partNumber` | string | Part number |
| `measurementId` | number | Triggering measurement |
| `detectedAt` | string (ISO) | Detection timestamp |
| `ruleName` | string | Western Electric rule name |
| `description` | string | Rule description |
| `severity` | string | Warning, OutOfControl, or OutOfSpec |
| `status` | string | Open, Acknowledged, CapaCreated, or Resolved |
| `acknowledgedByName` | string or null | Who acknowledged |
| `acknowledgedAt` | string or null | When acknowledged |
| `acknowledgmentNotes` | string or null | Acknowledgment notes |
| `capaId` | number or null | Linked CAPA (if created) |

---

## NCRs (Non-Conformance Reports)

The NCR tab manages documented non-conformances found during receiving, in-process, final inspection, shipping, customer returns, or audits. NCRs track affected quantities, containment actions, and dispositions. They can be linked to CAPAs for root-cause investigation.

### NCR List

**NCR DataTable columns:**

| Column | Header | Type | Sortable | Filterable | Width |
|--------|--------|------|----------|------------|-------|
| `ncrNumber` | NCR # | text | Yes | No | 140px |
| `type` | Type | enum | Yes | Yes | 90px |
| `partNumber` | Part | text | Yes | No | 120px |
| `detectedAtStage` | Stage | text | Yes | No | 120px |
| `description` | Description | text | Yes | No | auto |
| `affectedQuantity` | Qty | number | Yes | No | 70px |
| `status` | Status | enum | Yes | Yes | 120px |
| `detectedAt` | Detected | date | Yes | No | 100px |
| `actions` | (none) | -- | No | No | 80px |

**Table ID:** `ncr-list`

**Filters:**

| Filter | Type | Options |
|--------|------|---------|
| Type | Select | All Types, Internal, Supplier, Customer |
| Status | Select | All Statuses, Open, Under Review, Contained, Dispositioned, Closed |

### NCR Types

| Value | Description |
|-------|-------------|
| `Internal` | Defect found internally |
| `Supplier` | Defect from a supplier |
| `Customer` | Defect reported by customer |

### NCR Detection Stages

| Value | Display |
|-------|---------|
| `Receiving` | Receiving |
| `InProcess` | In Process |
| `FinalInspection` | Final Inspection |
| `Shipping` | Shipping |
| `Customer` | Customer |
| `Audit` | Audit |

### NCR Disposition Codes

| Value | Display |
|-------|---------|
| `UseAsIs` | Use As Is |
| `Rework` | Rework |
| `Scrap` | Scrap |
| `ReturnToVendor` | Return to Vendor |
| `SortAndScreen` | Sort & Screen |
| `Reject` | Reject |

### NCR Status Values

| Value | Display | Chip Class |
|-------|---------|------------|
| `Open` | Open | `chip--error` |
| `UnderReview` | Under Review | `chip--warning` |
| `Contained` | Contained | `chip--info` |
| `Dispositioned` | Dispositioned | `chip--primary` |
| `Closed` | Closed | `chip--muted` |

### NCR Row Actions

- **Disposition** (gavel icon) -- visible when status is not `Dispositioned` or `Closed`. Opens the disposition dialog.
- **Create CAPA** (assignment_turned_in icon) -- visible when no CAPA is linked (`capaId` is null) and status is not `Closed`. Creates a CAPA from the NCR.

### Create NCR Dialog

**Dialog title:** "Create Non-Conformance"
**Width:** 520px

| Field | Label | Type | Required | Validation | Default |
|-------|-------|------|----------|------------|---------|
| `type` | Type | Select | Yes | nonNullable | `Internal` |
| `detectedAtStage` | Detection Stage | Select | Yes | nonNullable | `Receiving` |
| `partId` | Part ID | Number input | Yes | `Validators.required` | -- |
| `jobId` | Job ID | Number input | No | -- | -- |
| `description` | Description | Textarea | Yes | `Validators.required` | -- |
| `affectedQuantity` | Affected Quantity | Number input | Yes | `Validators.required`, `min(0.01)` | -- |
| `defectiveQuantity` | Defective Quantity | Number input | No | -- | -- |
| `containmentActions` | Containment Actions | Textarea | No | -- | -- |

**Footer buttons:**
- Cancel (left)
- Create (right, primary) -- disabled when form invalid or saving, has validation popover

### Disposition NCR Dialog

**Dialog title:** "Disposition NCR"
**Width:** 420px

| Field | Label | Type | Required | Validation | Default |
|-------|-------|------|----------|------------|---------|
| `code` | Disposition Code | Select | Yes | nonNullable | `UseAsIs` |
| `notes` | Notes | Textarea | No | -- | -- |
| `reworkInstructions` | Rework Instructions | Textarea | Conditional | Required when code is `Rework` | -- |

The Rework Instructions field only appears when the disposition code is set to `Rework`.

**Footer buttons:**
- Cancel (left)
- Record Disposition (right, primary) -- disabled while saving

### NCR Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `ncrNumber` | string | System-generated NCR number |
| `type` | NcrType | Internal, Supplier, or Customer |
| `partId` | number | Affected part |
| `partNumber` | string | Part number |
| `partDescription` | string | Part description |
| `jobId` | number or null | Associated job |
| `jobNumber` | string or null | Job number |
| `productionRunId` | number or null | Production run |
| `lotNumber` | string or null | Lot number |
| `salesOrderLineId` | number or null | Sales order line |
| `purchaseOrderLineId` | number or null | Purchase order line |
| `qcInspectionId` | number or null | Originating inspection |
| `detectedById` | number | User who detected |
| `detectedByName` | string | Detector name |
| `detectedAt` | string (ISO) | Detection date |
| `detectedAtStage` | NcrDetectionStage | Where detected |
| `description` | string | Defect description |
| `affectedQuantity` | number | Total affected |
| `defectiveQuantity` | number or null | Confirmed defective |
| `containmentActions` | string or null | Immediate containment |
| `containmentById` | number or null | Who contained |
| `containmentByName` | string or null | Containment person name |
| `containmentAt` | string or null | Containment date |
| `dispositionCode` | NcrDispositionCode or null | How to handle |
| `dispositionById` | number or null | Who dispositioned |
| `dispositionByName` | string or null | Disposition person name |
| `dispositionAt` | string or null | Disposition date |
| `dispositionNotes` | string or null | Disposition notes |
| `reworkInstructions` | string or null | Rework instructions |
| `materialCost` | number or null | Material cost impact |
| `laborCost` | number or null | Labor cost impact |
| `totalCostImpact` | number or null | Total cost impact |
| `status` | NcrStatus | Current status |
| `capaId` | number or null | Linked CAPA |
| `capaNumber` | string or null | CAPA number |
| `customerId` | number or null | Affected customer |
| `customerName` | string or null | Customer name |
| `vendorId` | number or null | Responsible vendor |
| `vendorName` | string or null | Vendor name |
| `createdAt` | string (ISO) | Creation date |

---

## CAPAs (Corrective & Preventive Actions)

CAPAs track root-cause investigations and corrective/preventive actions through a structured lifecycle. They can be created manually, from NCRs, or from SPC out-of-control events.

### CAPA List

**CAPA DataTable columns:**

| Column | Header | Type | Sortable | Filterable | Width |
|--------|--------|------|----------|------------|-------|
| `capaNumber` | CAPA # | text | Yes | No | 140px |
| `type` | Type | text | Yes | No | 100px |
| `title` | Title | text | Yes | No | auto |
| `ownerName` | Owner | text | Yes | No | 150px |
| `priority` | Priority | number | Yes | No | 80px |
| `status` | Status | enum | Yes | Yes | 150px |
| `dueDate` | Due | date | Yes | No | 100px |
| `tasks` | Tasks | custom | No | No | 80px |
| `actions` | (none) | -- | No | No | 60px |

**Table ID:** `capa-list`

The Tasks column displays `completedTaskCount/taskCount` (e.g., `3/5`).

**Filters:**

| Filter | Type | Options |
|--------|------|---------|
| Type | Select | All Types, Corrective, Preventive |
| Status | Select | All Statuses, Open, Root Cause Analysis, Action Planning, Implementation, Verification, Effectiveness Check, Closed |

### CAPA Types

| Value | Description |
|-------|-------------|
| `Corrective` | Fix an existing problem |
| `Preventive` | Prevent a potential problem |

### CAPA Source Types

| Value | Display |
|-------|---------|
| `Ncr` | NCR |
| `CustomerComplaint` | Customer Complaint |
| `InternalAudit` | Internal Audit |
| `ExternalAudit` | External Audit |
| `SpcOoc` | SPC Out of Control |
| `ManagementReview` | Management Review |
| `Other` | Other |

### CAPA Status Values (Lifecycle Phases)

CAPAs progress through a structured lifecycle. Each status represents a phase. The `advancePhase` action moves to the next phase.

| Value | Display | Chip Class | Next Phase |
|-------|---------|------------|------------|
| `Open` | Open | `chip--error` | RootCauseAnalysis |
| `RootCauseAnalysis` | Root Cause Analysis | `chip--warning` | ActionPlanning |
| `ActionPlanning` | Action Planning | `chip--info` | Implementation |
| `Implementation` | Implementation | `chip--primary` | Verification |
| `Verification` | Verification | `chip--warning` | EffectivenessCheck |
| `EffectivenessCheck` | Effectiveness Check | `chip--info` | Closed |
| `Closed` | Closed | `chip--success` | (terminal) |

### CAPA Priority Values

| Value | Display | Chip Class |
|-------|---------|------------|
| 1 | 1 -- Critical | `chip--error` |
| 2 | 2 -- High | `chip--error` |
| 3 | 3 -- Medium | `chip--warning` |
| 4 | 4 -- Low | `chip--muted` |
| 5 | 5 -- Informational | `chip--muted` |

### CAPA Row Actions

- **Advance Phase** (arrow_forward icon) -- visible when status is not `Closed`. Calls `POST /api/v1/quality/capas/{id}/advance`, shows snackbar with new status.

### Root Cause Methods

| Value | Display |
|-------|---------|
| `FiveWhy` | 5 Why |
| `Fishbone` | Fishbone (Ishikawa) |
| `FaultTree` | Fault Tree |
| `EightD` | 8D |
| `Pareto` | Pareto |
| `IsIsNot` | Is/Is Not |

### Create CAPA Dialog

**Dialog title:** "Create CAPA"
**Width:** 520px

| Field | Label | Type | Required | Validation | Default |
|-------|-------|------|----------|------------|---------|
| `type` | Type | Select | Yes | nonNullable | `Corrective` |
| `sourceType` | Source | Select | Yes | nonNullable | `Other` |
| `title` | Title | Text input | Yes | `Validators.required`, `maxLength(500)` | -- |
| `problemDescription` | Problem Description | Textarea | Yes | `Validators.required` | -- |
| `impactDescription` | Impact Description | Textarea | No | -- | -- |
| `ownerId` | Owner ID | Number input | Yes | `Validators.required` | -- |
| `priority` | Priority | Select | No | -- | 3 (Medium) |
| `dueDate` | Due Date | Datepicker | Yes | `Validators.required` | -- |

**Footer buttons:**
- Cancel (left)
- Create (right, primary) -- disabled when form invalid or saving, has validation popover

### CAPA Task Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `capaId` | number | Parent CAPA |
| `title` | string | Task title |
| `description` | string or null | Task description |
| `assigneeId` | number | Assigned user |
| `assigneeName` | string | Assignee name |
| `dueDate` | string (ISO) | Task due date |
| `status` | CapaTaskStatus | Open, InProgress, Completed, or Cancelled |
| `completedAt` | string or null | Completion timestamp |
| `completedById` | number or null | Who completed |
| `completedByName` | string or null | Completer name |
| `completionNotes` | string or null | Completion notes |
| `sortOrder` | number | Display order |

### CAPA Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `capaNumber` | string | System-generated number |
| `type` | CapaType | Corrective or Preventive |
| `sourceType` | CapaSourceType | Origin of the CAPA |
| `sourceEntityId` | number or null | Source entity reference |
| `sourceEntityType` | string or null | Source entity type |
| `title` | string | CAPA title |
| `problemDescription` | string | Problem description |
| `impactDescription` | string or null | Impact assessment |
| `rootCauseAnalysis` | string or null | Root cause findings |
| `rootCauseMethod` | RootCauseMethod or null | Analysis method used |
| `rootCauseMethodData` | string or null | Structured method data |
| `rootCauseAnalyzedById` | number or null | Analyst user |
| `rootCauseAnalyzedByName` | string or null | Analyst name |
| `rootCauseCompletedAt` | string or null | Analysis completion date |
| `containmentAction` | string or null | Immediate containment |
| `correctiveActionDescription` | string or null | Corrective action |
| `preventiveAction` | string or null | Preventive action |
| `verificationMethod` | string or null | How effectiveness is verified |
| `verificationResult` | string or null | Verification results |
| `verifiedById` | number or null | Verifier user |
| `verifiedByName` | string or null | Verifier name |
| `verificationDate` | string or null | Verification date |
| `effectivenessCheckDueDate` | string or null | When to check effectiveness |
| `effectivenessCheckDate` | string or null | When checked |
| `effectivenessResult` | string or null | Effectiveness findings |
| `isEffective` | boolean or null | Whether the action was effective |
| `effectivenessCheckedById` | number or null | Checker user |
| `effectivenessCheckedByName` | string or null | Checker name |
| `ownerId` | number | CAPA owner |
| `ownerName` | string | Owner name |
| `status` | CapaStatus | Current lifecycle phase |
| `priority` | number | 1-5 priority |
| `dueDate` | string (ISO) | Due date |
| `closedAt` | string or null | Closure date |
| `closedById` | number or null | Who closed |
| `closedByName` | string or null | Closer name |
| `taskCount` | number | Total tasks |
| `completedTaskCount` | number | Completed tasks |
| `relatedNcrCount` | number | Linked NCR count |
| `createdAt` | string (ISO) | Creation date |

---

## ECOs (Engineering Change Orders)

ECOs manage formal changes to parts, BOMs, operations, drawings, and specifications. They follow a lifecycle from Draft through Review, Approval, Implementation, to Implemented.

### ECO List

**ECO DataTable columns:**

| Column | Header | Type | Sortable | Filterable | Width |
|--------|--------|------|----------|------------|-------|
| `ecoNumber` | ECO # | text | Yes | No | 160px |
| `title` | Title | text | Yes | No | auto |
| `changeType` | Type | enum | Yes | Yes | 130px |
| `priority` | Priority | enum | Yes | Yes | 90px |
| `status` | Status | enum | Yes | Yes | 130px |
| `requestedByName` | Requested By | text | Yes | No | 140px |
| `affectedItemCount` | Items | number | Yes | No | 60px |
| `createdAt` | Created | date | Yes | No | 100px |
| `actions` | (none) | -- | No | No | 50px |

**Table ID:** `eco-list`

Rows are clickable -- clicking opens the ECO detail dialog.

**Filters:**

| Filter | Type | Options |
|--------|------|---------|
| Status | Select | All Statuses, Draft, Review, Approved, In Implementation, Implemented, Cancelled |

### ECO Change Types

| Value | Display |
|-------|---------|
| `New` | New |
| `Revision` | Revision |
| `Obsolescence` | Obsolescence |
| `CostReduction` | Cost Reduction |
| `QualityImprovement` | Quality Improvement |

### ECO Priority Values

| Value | Chip Class |
|-------|------------|
| `Critical` | `chip--error` |
| `High` | `chip--warning` |
| `Normal` | `chip--info` |
| `Low` | `chip--muted` |

### ECO Status Values

| Value | Display | Chip Class |
|-------|---------|------------|
| `Draft` | Draft | `chip--muted` |
| `Review` | Review | `chip--info` |
| `Approved` | Approved | `chip--success` |
| `InImplementation` | In Implementation | `chip--warning` |
| `Implemented` | Implemented | `chip--primary` |
| `Cancelled` | Cancelled | `chip--error` |

### ECO Lifecycle Permissions

| Action | Method | Allowed When |
|--------|--------|-------------|
| Edit | `canEdit()` | Status is Draft or Review |
| Approve | `canApprove()` | Status is Review |
| Implement | `canImplement()` | Status is Approved or InImplementation |

### Create ECO Dialog

**Dialog title:** "Create Engineering Change Order"
**Width:** 520px

| Field | Label | Type | Required | Validation | Default | data-testid |
|-------|-------|------|----------|------------|---------|-------------|
| `title` | Title | Text input | Yes | `Validators.required`, `maxLength(200)` | -- | `eco-title` |
| `changeType` | Change Type | Select | Yes | nonNullable | `Revision` | `eco-change-type` |
| `priority` | Priority | Select | Yes | nonNullable | `Normal` | `eco-priority` |
| `description` | Description | Textarea | Yes | `Validators.required` | -- | `eco-description` |
| `reasonForChange` | Reason for Change | Textarea | No | -- | -- | `eco-reason` |
| `impactAnalysis` | Impact Analysis | Textarea | No | -- | -- | `eco-impact` |
| `effectiveDate` | Effective Date | Datepicker | No | -- | -- | `eco-effective-date` |

**Footer buttons:**
- Cancel (left)
- Create (right, primary, data-testid: `eco-save-btn`) -- disabled when form invalid or saving, has validation popover

### ECO Detail Dialog

**Dialog title:** "{ecoNumber} -- {title}"
**Width:** 800px

Opens when clicking a row or the visibility icon. Displays:

1. **Header meta:** Status chip, priority chip, change type chip
2. **Info fields:** Requested By, Created date, Effective Date (if set), Approved By + date (if approved), Implemented date (if implemented)
3. **Description section** (always shown)
4. **Reason for Change** (conditional)
5. **Impact Analysis** (conditional)
6. **Affected Items section** with nested DataTable and Add Item button (when editable)

**Affected Items DataTable columns:**

| Column | Header | Width | Align |
|--------|--------|-------|-------|
| `entityType` | Type | 100px | -- |
| `entityId` | Entity ID | 80px | center |
| `changeDescription` | Change Description | auto | -- |
| `isImplemented` | Implemented | 100px | center |
| `actions` | (none) | 50px | -- |

**Table ID:** `eco-affected-items`

Implemented column shows `check_circle` (green) or `radio_button_unchecked` (gray).

**Footer buttons (conditional):**
- Approve (primary, with `check` icon) -- visible when `canApprove()`, triggers confirm dialog
- Implement (primary, with `build` icon) -- visible when `canImplement()`, triggers confirm dialog
- Close (always visible)

### Approve ECO Confirmation

Confirm dialog: "Approve ECO?" / "Approve {ecoNumber}? This will allow implementation to begin." / severity: info

### Implement ECO Confirmation

Confirm dialog: "Implement ECO?" / "Mark {ecoNumber} as implemented? All affected items will be marked as implemented." / severity: warn

### Add Affected Item Dialog

**Dialog title:** "Add Affected Item"
**Width:** 520px

| Field | Label | Type | Required | Validation |
|-------|-------|------|----------|------------|
| `entityType` | Entity Type | Select | Yes | nonNullable, default `Part` |
| `entityId` | Entity ID | Number input | Yes | `Validators.required`, `min(1)` |
| `changeDescription` | Change Description | Textarea | Yes | `Validators.required`, `maxLength(500)` |
| `oldValue` | Old Value (JSON) | Textarea | No | -- |
| `newValue` | New Value (JSON) | Textarea | No | -- |

**Entity Type options:** Part, BOM, Operation, Drawing, Specification

**Footer buttons:**
- Cancel (left)
- Add (right, primary) -- disabled when form invalid or saving, has validation popover

### Delete Affected Item

Confirm dialog: "Remove Affected Item?" / "Remove this affected item from the ECO?" / severity: danger

---

## Gages (Calibration Management)

The Gages tab manages measurement instruments and their calibration records. Gages track calibration intervals, due dates, and historical calibration records.

### Gage List

**Gage DataTable columns:**

| Column | Header | Type | Sortable | Filterable | Width |
|--------|--------|------|----------|------------|-------|
| `gageNumber` | Gage # | text | Yes | No | 110px |
| `description` | Description | text | Yes | No | auto |
| `gageType` | Type | text | Yes | No | 110px |
| `status` | Status | enum | Yes | Yes | 130px |
| `nextCalibrationDue` | Next Cal Due | date | Yes | No | 110px |
| `calibrationCount` | Cal Records | number | Yes | No | 90px |

**Table ID:** `gage-list`

Rows are clickable -- clicking opens the gage detail dialog.

**Filters:**

| Filter | Type | Behavior |
|--------|------|----------|
| Search | Text input | Free-text search, triggers on Enter |
| Status | Select | All, In Service, Due for Calibration, Out for Calibration, Out of Service, Retired |

### Gage Status Values

| Value | Display | Chip Class |
|-------|---------|------------|
| `InService` | In Service | `chip--success` |
| `DueForCalibration` | Due for Cal | `chip--warning` |
| `OutForCalibration` | Out for Cal | `chip--info` |
| `OutOfService` | Out of Service | `chip--error` |
| `Retired` | Retired | `chip--muted` |

### Create Gage Dialog

**Dialog title:** "New Gage"
**Width:** 520px

| Field | Label | Type | Required | Validation | Default |
|-------|-------|------|----------|------------|---------|
| `description` | Description | Text input | Yes | `Validators.required`, `maxLength(500)` | -- |
| `gageType` | Gage Type | Text input | No | -- | -- |
| `manufacturer` | Manufacturer | Text input | No | -- | -- |
| `model` | Model | Text input | No | -- | -- |
| `serialNumber` | Serial Number | Text input | No | -- | -- |
| `calibrationIntervalDays` | Calibration Interval (Days) | Number input | Yes | `Validators.required`, `min(1)` | 365 |
| `accuracySpec` | Accuracy Spec | Text input | No | -- | -- |
| `rangeSpec` | Range Spec | Text input | No | -- | -- |
| `resolution` | Resolution | Text input | No | -- | -- |
| `notes` | Notes | Textarea | No | -- | -- |

**Footer buttons:**
- Cancel (left)
- Create (right, primary, with `save` icon) -- disabled when form invalid or saving, has validation popover

### Gage Detail Dialog

**Dialog title:** "{gageNumber}"
**Width:** 800px

Displays:
1. **Header:** Status chip + description
2. **Info grid** (conditional fields, only shown when populated): Type, Manufacturer, Model, Serial Number, Cal Interval, Last Calibrated, Next Cal Due, Accuracy, Range, Resolution, Location, Asset
3. **Notes** (if present)
4. **Calibration History section** with DataTable and "Record Calibration" button

**Calibration History DataTable columns:**

| Column | Header | Type | Sortable | Width |
|--------|--------|------|----------|-------|
| `calibratedAt` | Date | date | Yes | 110px |
| `result` | Result | text | Yes | 120px |
| `labName` | Lab | text | Yes | auto |
| `standardsUsed` | Standards | text | Yes | auto |
| `asFoundCondition` | As Found | text | Yes | auto |
| `asLeftCondition` | As Left | text | Yes | auto |
| `nextCalibrationDue` | Next Due | date | Yes | 110px |

**Table ID:** `gage-calibration-history`

**Calibration Result chip colors:**

| Value | Chip Class |
|-------|------------|
| `Pass` | `chip--success` |
| `Fail` | `chip--error` |
| `Adjusted` | `chip--warning` |
| `OutOfTolerance` | `chip--error` |

**Footer:** Close button (primary).

### Record Calibration Dialog

**Dialog title:** "Record Calibration"
**Width:** 520px

| Field | Label | Type | Required | Validation | Default |
|-------|-------|------|----------|------------|---------|
| `calibratedAt` | Calibrated Date | Datepicker | Yes | `Validators.required` | Today |
| `result` | Result | Select | Yes | `Validators.required` | `Pass` |
| `labName` | Lab Name | Text input | No | -- | -- |
| `standardsUsed` | Standards Used | Text input | No | -- | -- |
| `asFoundCondition` | As Found Condition | Text input | No | -- | -- |
| `asLeftCondition` | As Left Condition | Text input | No | -- | -- |
| `notes` | Notes | Textarea | No | -- | -- |

**Result options:** Pass, Fail, Adjusted, Out of Tolerance

**Footer buttons:**
- Cancel (left)
- Save (right, primary, with `save` icon) -- disabled when form invalid or calSaving, has validation popover

**On save:** Creates calibration record via `POST /api/v1/quality/gages/{id}/calibrations`, refreshes calibration history and gage list, shows success snackbar.

### Gage Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `gageNumber` | string | System-generated gage number |
| `description` | string | Gage description |
| `gageType` | string or null | Type (e.g., "Caliper", "Micrometer") |
| `manufacturer` | string or null | Manufacturer name |
| `model` | string or null | Model number |
| `serialNumber` | string or null | Serial number |
| `calibrationIntervalDays` | number | Days between calibrations |
| `lastCalibratedAt` | string or null | Last calibration date |
| `nextCalibrationDue` | string or null | Next due date |
| `status` | GageStatus | Current status |
| `locationId` | number or null | Storage location |
| `locationName` | string or null | Location name |
| `assetId` | number or null | Linked asset |
| `assetName` | string or null | Asset name |
| `accuracySpec` | string or null | Accuracy specification |
| `rangeSpec` | string or null | Range specification |
| `resolution` | string or null | Resolution |
| `notes` | string or null | Notes |
| `createdAt` | string (ISO) | Creation date |
| `calibrationCount` | number | Total calibration records |

### Calibration Record Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Auto-generated ID |
| `gageId` | number | Parent gage |
| `calibratedById` | number | Who calibrated |
| `calibratedAt` | string (ISO) | Calibration date |
| `result` | CalibrationResult | Pass, Fail, Adjusted, or OutOfTolerance |
| `labName` | string or null | Calibration lab |
| `certificateFileId` | number or null | Uploaded certificate |
| `standardsUsed` | string or null | Reference standards |
| `asFoundCondition` | string or null | Pre-calibration condition |
| `asLeftCondition` | string or null | Post-calibration condition |
| `nextCalibrationDue` | string or null | Computed next due date |
| `notes` | string or null | Notes |

---

## PPAP (Production Part Approval Process)

PPAP is implemented as a backend-only subsystem (no dedicated UI tab). It manages automotive-style production part approval submissions.

### PPAP Status Values

`PpapStatus` enum values are defined server-side.

### API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/ppap-submissions` | All | List submissions (filter by partId, customerId, status) |
| `GET` | `/api/v1/ppap-submissions/{id}` | All | Get submission detail |
| `POST` | `/api/v1/ppap-submissions` | Admin, Manager, Engineer | Create submission |
| `PUT` | `/api/v1/ppap-submissions/{id}` | Admin, Manager, Engineer | Update submission |
| `PUT` | `/api/v1/ppap-submissions/{id}/elements/{number}` | Admin, Manager, Engineer | Update individual PPAP element |
| `POST` | `/api/v1/ppap-submissions/{id}/submit` | Admin, Manager, Engineer | Submit for approval |
| `POST` | `/api/v1/ppap-submissions/{id}/response` | Admin, Manager | Record customer response |
| `POST` | `/api/v1/ppap-submissions/{id}/psw/sign` | Admin, Manager, Engineer | Sign Part Submission Warrant |
| `GET` | `/api/v1/ppap/level-requirements/{level}` | All | Get element requirements by PPAP level (1-5) |

**Note:** No frontend UI tab exists for PPAP. The API is available for integration or future UI development.

---

## FMEA (Failure Mode and Effects Analysis)

FMEA is implemented as a backend-only subsystem (no dedicated UI tab). It manages risk assessments for parts and processes.

### FMEA Types and Status

`FmeaType` and `FmeaStatus` enums are defined server-side.

### API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/fmeas` | All | List FMEAs (filter by type, partId, status) |
| `GET` | `/api/v1/fmeas/{id}` | All | Get FMEA detail |
| `POST` | `/api/v1/fmeas` | Admin, Manager, Engineer | Create FMEA |
| `PUT` | `/api/v1/fmeas/{id}` | Admin, Manager, Engineer | Update FMEA |
| `POST` | `/api/v1/fmeas/{id}/items` | Admin, Manager, Engineer | Add failure mode item |
| `PUT` | `/api/v1/fmeas/{id}/items/{itemId}` | Admin, Manager, Engineer | Update failure mode item |
| `DELETE` | `/api/v1/fmeas/{id}/items/{itemId}` | Admin, Manager, Engineer | Delete failure mode item |
| `POST` | `/api/v1/fmeas/{id}/items/{itemId}/action` | Admin, Manager, Engineer | Record recommended action |
| `POST` | `/api/v1/fmeas/{id}/items/{itemId}/link-capa` | Admin, Manager, Engineer | Link to existing CAPA |
| `GET` | `/api/v1/fmeas/high-rpn` | All | Get items above RPN threshold (default 200) |
| `GET` | `/api/v1/fmeas/{id}/risk-summary` | All | Get risk summary for an FMEA |

**Note:** No frontend UI tab exists for FMEA. The API is available for integration or future UI development.

---

## COPQ (Cost of Poor Quality) Reporting

COPQ is implemented as a reporting subsystem under the reports API namespace.

### API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/reports/copq` | All | Get COPQ report for date range |
| `GET` | `/api/v1/reports/copq/trend` | All | Get monthly COPQ trend (default 12 months) |
| `GET` | `/api/v1/reports/copq/pareto` | All | Get Pareto analysis for date range |

**Query parameters for COPQ report and Pareto:**
- `startDate` (DateOnly, required)
- `endDate` (DateOnly, required)

**Query parameters for trend:**
- `months` (int, default 12)

---

## Scanner Integration

The Quality module integrates with the global `ScannerService` for barcode/NFC scanning. The scanner context is set to `'quality'` in the `QualityComponent` constructor.

**Scan behavior by active tab:**

| Tab | Action |
|-----|--------|
| Lots | Scanned value fills the lot search input |
| All other tabs | Scanned value fills the inspection search input |

The scanner processes scans only when `scan.context === 'quality'`. After handling, the scan is cleared via `clearLastScan()`.

---

## API Endpoints

### QualityController (`/api/v1/quality`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/quality/templates` | All authenticated | List QC templates |
| `POST` | `/api/v1/quality/templates` | Admin, Manager | Create QC template |
| `GET` | `/api/v1/quality/inspections` | All authenticated | List inspections (filter by jobId, status, lotNumber) |
| `POST` | `/api/v1/quality/inspections` | All authenticated | Create inspection |
| `PUT` | `/api/v1/quality/inspections/{id}` | All authenticated | Update inspection (status, notes, results) |

### NcrCapaController (`/api/v1/quality`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/quality/ncrs` | All authenticated | List NCRs (filter by type, status, partId, jobId, vendorId, customerId, dateFrom, dateTo) |
| `POST` | `/api/v1/quality/ncrs` | All authenticated | Create NCR |
| `GET` | `/api/v1/quality/ncrs/{id}` | All authenticated | Get NCR detail |
| `PATCH` | `/api/v1/quality/ncrs/{id}` | All authenticated | Update NCR |
| `POST` | `/api/v1/quality/ncrs/{id}/disposition` | Admin, Manager | Disposition NCR |
| `POST` | `/api/v1/quality/ncrs/{id}/create-capa` | Admin, Manager | Create CAPA from NCR |
| `GET` | `/api/v1/quality/capas` | All authenticated | List CAPAs (filter by status, type, ownerId, priority, dueDateFrom, dueDateTo) |
| `POST` | `/api/v1/quality/capas` | Admin, Manager | Create CAPA |
| `GET` | `/api/v1/quality/capas/{id}` | All authenticated | Get CAPA detail |
| `PATCH` | `/api/v1/quality/capas/{id}` | Admin, Manager | Update CAPA |
| `POST` | `/api/v1/quality/capas/{id}/advance` | Admin, Manager | Advance CAPA lifecycle phase |
| `GET` | `/api/v1/quality/capas/{id}/tasks` | All authenticated | List CAPA tasks |
| `POST` | `/api/v1/quality/capas/{id}/tasks` | Admin, Manager | Create CAPA task |
| `PATCH` | `/api/v1/quality/capas/{id}/tasks/{taskId}` | All authenticated | Update CAPA task |

### ECO Endpoints (on QualityController, `/api/v1/quality`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/quality/ecos` | Admin, Manager, Engineer | List ECOs (filter by status) |
| `GET` | `/api/v1/quality/ecos/{id}` | Admin, Manager, Engineer | Get ECO detail |
| `POST` | `/api/v1/quality/ecos` | Admin, Manager, Engineer | Create ECO |
| `PATCH` | `/api/v1/quality/ecos/{id}` | Admin, Manager, Engineer | Update ECO |
| `POST` | `/api/v1/quality/ecos/{id}/approve` | Admin, Manager | Approve ECO |
| `POST` | `/api/v1/quality/ecos/{id}/implement` | Admin, Manager, Engineer | Mark ECO as implemented |
| `POST` | `/api/v1/quality/ecos/{id}/affected-items` | Admin, Manager, Engineer | Add affected item |
| `DELETE` | `/api/v1/quality/ecos/{id}/affected-items/{itemId}` | Admin, Manager, Engineer | Remove affected item |

### Gage Endpoints (on QualityController, `/api/v1/quality`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/quality/gages` | All authenticated | List gages (filter by status, search) |
| `GET` | `/api/v1/quality/gages/{id}` | All authenticated | Get gage detail |
| `POST` | `/api/v1/quality/gages` | Admin, Manager | Create gage |
| `PATCH` | `/api/v1/quality/gages/{id}` | Admin, Manager | Update gage |
| `GET` | `/api/v1/quality/gages/due` | All authenticated | Get gages due for calibration (daysAhead default 30) |
| `GET` | `/api/v1/quality/gages/{id}/calibrations` | All authenticated | Get calibration history |
| `POST` | `/api/v1/quality/gages/{id}/calibrations` | Admin, Manager | Record calibration |

### SpcController (`/api/v1/spc`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/spc/characteristics` | All authenticated | List characteristics (filter by partId, operationId, isActive) |
| `GET` | `/api/v1/spc/characteristics/{id}` | All authenticated | Get characteristic |
| `POST` | `/api/v1/spc/characteristics` | Admin, Manager | Create characteristic |
| `PUT` | `/api/v1/spc/characteristics/{id}` | Admin, Manager | Update characteristic |
| `GET` | `/api/v1/spc/characteristics/{id}/chart` | All authenticated | Get chart data (lastN points) |
| `POST` | `/api/v1/spc/measurements` | All authenticated | Record measurements (subgroups) |
| `GET` | `/api/v1/spc/measurements` | All authenticated | List measurements (filter by characteristicId, dateFrom, dateTo, jobId) |
| `POST` | `/api/v1/spc/characteristics/{id}/recalculate-limits` | Admin, Manager | Recalculate control limits (optional fromSubgroup, toSubgroup) |
| `GET` | `/api/v1/spc/capability/{characteristicId}` | All authenticated | Get process capability report |
| `GET` | `/api/v1/spc/out-of-control` | All authenticated | List OOC events (filter by status, severity, characteristicId) |
| `POST` | `/api/v1/spc/out-of-control/{id}/acknowledge` | All authenticated | Acknowledge OOC event |
| `POST` | `/api/v1/spc/out-of-control/{id}/create-capa` | Admin, Manager | Create CAPA from OOC event |

### LotsController (`/api/v1/lots`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/lots` | Admin, Manager, Engineer, ProductionWorker | List lot records (filter by partId, jobId, search) |
| `POST` | `/api/v1/lots` | Admin, Manager, Engineer, ProductionWorker | Create lot record |
| `GET` | `/api/v1/lots/{lotNumber}/trace` | Admin, Manager, Engineer, ProductionWorker | Get lot traceability |

---

## Cross-Feature Integration

### NCR to CAPA Flow

1. Create NCR with defect description, affected quantities, and containment actions.
2. From the NCR row, click "Create CAPA" (assignment_turned_in icon).
3. System calls `POST /api/v1/quality/ncrs/{id}/create-capa` with the NCR's `detectedById` as the CAPA owner.
4. CAPA is created with `sourceType: 'Ncr'` and linked back to the NCR via `capaId`.
5. NCR row action changes -- "Create CAPA" button is hidden once `capaId` is set.

### SPC OOC to CAPA Flow

1. An out-of-control event is detected when recording a measurement that violates a Western Electric rule.
2. From the OOC Events tab, acknowledge the event (optional notes).
3. Click "Create CAPA" on an Open or Acknowledged event.
4. System calls `POST /api/v1/spc/out-of-control/{id}/create-capa`.
5. Event status changes to `CapaCreated` and the `capaId` is set.

### Lot to Inspection Link

Inspections can reference a lot number, linking them in the traceability chain. When viewing lot traceability, all associated inspections are listed with their pass/fail status.

### SPC Characteristic to Gage Link

SPC characteristics can reference a `gageId`, associating the measuring instrument with the monitored dimension.

---

## Known Limitations

1. **No inline inspection result recording UI.** Inspections can be created but individual pass/fail results must be recorded via `PUT /api/v1/quality/inspections/{id}` (API-only or future UI).

2. **No template management UI.** QC templates can only be created via the API. There is no list/edit/delete UI for template management.

3. **Part ID and Job ID are raw number inputs.** The inspection and NCR creation forms use plain number inputs for Part ID and Job ID rather than entity pickers. Users must know the numeric IDs.

4. **Owner ID is a raw number input.** CAPA creation requires a numeric Owner ID rather than a user picker.

5. **No NCR detail view.** NCRs are listed in a table with inline actions (disposition, create CAPA) but there is no detail dialog for viewing or editing all NCR fields.

6. **No CAPA detail view.** CAPAs are listed in a table with the advance-phase action but there is no detail dialog for editing root cause analysis, verification, effectiveness check fields, or managing tasks inline.

7. **PPAP and FMEA are API-only.** Both subsystems have full CRUD APIs and MediatR handlers but no frontend UI tabs. They are available for direct API integration.

8. **COPQ reporting is API-only.** Cost of Poor Quality reports are served via the API but not surfaced in the Quality UI tabs.

9. **ECO affected items use raw Entity ID.** The Add Affected Item form requires a numeric entity ID rather than an entity picker.

10. **No SPC capability histogram UI.** The `SpcCapabilityReport` model includes histogram buckets and normal curve data, but there is no chart component rendering the capability histogram (the API is available).

11. **No gage edit form.** Gages can be created and have calibration records added, but there is no UI form for editing existing gage details (the PATCH API exists).

12. **SPC characteristics filter shows only active.** The characteristics list loads with `isActive: true` by default. There is no toggle to view inactive characteristics.
