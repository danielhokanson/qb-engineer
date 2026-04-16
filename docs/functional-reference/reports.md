# Reports

## Overview

The Reports module provides three complementary reporting systems:

1. **Pre-built Reports** -- 28 curated reports with dedicated API endpoints, chart visualizations (ng2-charts), and data tables. Accessed from the main `/reports` page.
2. **Dynamic Report Builder** -- A user-configurable report engine that can query 28 entity sources with 350+ fields, apply filters, group data, visualize with charts, and save/share report definitions. Accessed at `/reports/builder`.
3. **Sankey Flow Diagrams** -- 10 flow-visualization reports showing relationships between entities (e.g., quote-to-cash pipeline, material-to-product flow). Accessed at `/reports/sankey`.

Reports also support **scheduled delivery** via email (Admin/Manager only), **export** to CSV, XLSX, and PDF formats, and **drill-down charts** with interactive click-to-drill behavior.

## Routes

| Route | Component | Description |
|-------|-----------|-------------|
| `/reports` | `ReportsComponent` | Main reports page with 28 pre-built reports. |
| `/reports/builder` | `ReportBuilderComponent` | Dynamic report builder. |
| `/reports/sankey` | `SankeyReportsComponent` | Sankey flow diagram reports. |

## Authorization

- Pre-built reports: Available to all authenticated users (some reports are user-scoped, e.g., "My Time Log").
- Report Builder: `Admin`, `Manager`, `OfficeManager`, or `PM` roles.
- Report Schedules: `Admin` or `Manager` roles only.

---

## Pre-Built Reports (28)

Each report has a dedicated backend handler, a typed response model, and renders as a chart (bar, line, pie, doughnut) and/or a data table.

### Report List

| # | ID | Label | Date Range | Description |
|---|-----|-------|------------|-------------|
| 1 | `jobs-by-stage` | Jobs by Stage | No | Count of active jobs per kanban stage. Bar chart. |
| 2 | `overdue-jobs` | Overdue Jobs | No | List of jobs past their due date. Table. |
| 3 | `time-by-user` | Time by User | Yes | Hours logged per user in the date range. Bar chart + table. |
| 4 | `expense-summary` | Expense Summary | Yes | Expenses grouped by category in the date range. Pie chart + table. |
| 5 | `lead-pipeline` | Lead Pipeline | No | Leads grouped by status. Funnel/bar chart. |
| 6 | `job-completion-trend` | Job Completion Trend | No | Jobs completed per month (default 6 months). Line chart. |
| 7 | `on-time-delivery` | On-Time Delivery | Yes | Percentage of jobs completed by their due date. KPI + table. |
| 8 | `average-lead-time` | Average Lead Time | No | Average days from job creation to completion, by track type. Bar chart. |
| 9 | `team-workload` | Team Workload | No | Active jobs per assignee. Bar chart + table. |
| 10 | `customer-activity` | Customer Activity | No | Jobs, orders, and revenue per customer. Table. |
| 11 | `my-work-history` | My Work History | No | Current user's completed jobs. Table. |
| 12 | `my-time-log` | My Time Log | Yes | Current user's time entries in the date range. Table. |
| 13 | `ar-aging` | AR Aging | No | Accounts receivable aging buckets (Current, 30, 60, 90+ days). Table. |
| 14 | `revenue` | Revenue | Yes | Revenue by period in the date range. Bar/line chart. |
| 15 | `simple-pnl` | Profit and Loss | Yes | Simplified P&L statement for the date range. Table. |
| 16 | `my-expense-history` | My Expenses | Yes | Current user's expenses in the date range. Table. |
| 17 | `quote-to-close` | Quote to Close | Yes | Quote conversion rates and time-to-close metrics. Table. |
| 18 | `shipping-summary` | Shipping Summary | Yes | Shipments and delivery metrics in the date range. Table. |
| 19 | `time-in-stage` | Time in Stage | No | Average time jobs spend in each kanban stage. Bar chart. |
| 20 | `employee-productivity` | Employee Productivity | Yes | Hours, jobs completed, and efficiency per employee. Table. |
| 21 | `inventory-levels` | Inventory Levels | No | Current stock levels by part with reorder alerts. Table. |
| 22 | `maintenance` | Maintenance | Yes | Maintenance schedules, logs, and compliance in the date range. Table. |
| 23 | `quality-scrap` | Quality and Scrap | Yes | QC inspection pass/fail rates and scrap quantities. Table + chart. |
| 24 | `cycle-review` | Cycle Review | No | Planning cycle completion and rollover rates. Table. |
| 25 | `job-margin` | Job Margin | Yes | Revenue vs. cost per job in the date range. Table. |
| 26 | `my-cycle-summary` | My Cycle Summary | No | Current user's planning cycle performance. Table. |
| 27 | `lead-sales` | Lead to Sales | Yes | Lead conversion and revenue attribution. KPI + table. |
| 28 | `rd` | R&D Report | Yes | R&D track type jobs, hours, and expenses. Table. |

### Date Range Controls

Reports with `needsDateRange: true` show two `DatepickerComponent` controls (Start / End). Default range: last 30 days (start) to today (end). Dates are sent to the API as ISO strings via `toIsoDate()`.

### Chart Rendering

Charts use ng2-charts (Chart.js wrapper) with `DrillableChartComponent` for interactive drill-down. Chart types are chosen per report:
- **Bar:** Jobs by Stage, Time by User, Average Lead Time, Team Workload, Revenue
- **Line:** Job Completion Trend
- **Pie/Doughnut:** Expense Summary, Lead Pipeline
- **Table-only:** Overdue Jobs, Customer Activity, My Work History, AR Aging, etc.

### Pre-Built Report API Endpoints

Base path: `/api/v1/reports`

| Endpoint | Method | Parameters |
|----------|--------|------------|
| `/reports/jobs-by-stage` | GET | `trackTypeId?` |
| `/reports/overdue-jobs` | GET | -- |
| `/reports/time-by-user` | GET | `start`, `end` |
| `/reports/expense-summary` | GET | `start`, `end` |
| `/reports/lead-pipeline` | GET | -- |
| `/reports/job-completion-trend` | GET | `months?` (default 6) |
| `/reports/on-time-delivery` | GET | `start`, `end` |
| `/reports/average-lead-time` | GET | -- |
| `/reports/team-workload` | GET | -- |
| `/reports/customer-activity` | GET | -- |
| `/reports/my-work-history` | GET | -- |
| `/reports/my-time-log` | GET | `start`, `end` |
| `/reports/ar-aging` | GET | -- |
| `/reports/revenue` | GET | `start`, `end`, `groupBy?` (default `period`) |
| `/reports/simple-pnl` | GET | `start`, `end` |
| `/reports/my-expense-history` | GET | `start`, `end` |
| `/reports/quote-to-close` | GET | `start`, `end` |
| `/reports/shipping-summary` | GET | `start`, `end` |
| `/reports/time-in-stage` | GET | -- |
| `/reports/employee-productivity` | GET | `start`, `end` |
| `/reports/inventory-levels` | GET | -- |
| `/reports/maintenance` | GET | `start`, `end` |
| `/reports/quality-scrap` | GET | `start`, `end` |
| `/reports/cycle-review` | GET | -- |
| `/reports/job-margin` | GET | `start`, `end` |
| `/reports/my-cycle-summary` | GET | -- |
| `/reports/lead-sales` | GET | `start`, `end` |
| `/reports/rd` | GET | `start`, `end` |

---

## Dynamic Report Builder

The Report Builder allows users to construct ad-hoc reports by selecting an entity source, choosing columns, applying filters, setting grouping/sorting, and optionally adding a chart visualization. Reports can be saved for reuse and shared with other users.

### Entity Sources (28)

The RunReport handler supports 28 entity sources. The CreateSavedReport validator supports a subset of 13 (the original set); the run endpoint is more permissive.

| Entity Source | Label | Navigation Properties Included |
|---------------|-------|-------------------------------|
| `Jobs` | Jobs | Customer, TrackType, CurrentStage, Part, ParentJob |
| `Parts` | Parts | PreferredVendor, ToolingAsset |
| `Customers` | Customers | -- |
| `Expenses` | Expenses | Job |
| `TimeEntries` | Time Entries | Job |
| `Invoices` | Invoices | Customer, SalesOrder, Shipment |
| `Leads` | Leads | ConvertedCustomer |
| `Assets` | Assets | SourceJob, SourcePart |
| `PurchaseOrders` | Purchase Orders | Vendor, Job |
| `SalesOrders` | Sales Orders | Customer, Quote |
| `Quotes` | Quotes | Customer |
| `Shipments` | Shipments | SalesOrder then Customer |
| `Inventory` | Inventory (BinContents) | Location, Job |
| `Payments` | Payments | Customer |
| `Vendors` | Vendors | -- |
| `ProductionRuns` | Production Runs | Job, Part |
| `LotRecords` | Lot Records | Part, Job, ProductionRun |
| `QcInspections` | QC Inspections | Job, ProductionRun then Part, Template |
| `MaintenanceSchedules` | Maintenance Schedules | Asset, MaintenanceJob |
| `MaintenanceLogs` | Maintenance Logs | Schedule then Asset |
| `DowntimeLogs` | Downtime Logs | Asset |
| `CustomerReturns` | Customer Returns | Customer, OriginalJob, ReworkJob |
| `BinMovements` | Bin Movements | FromLocation, ToLocation |
| `PlanningCycles` | Planning Cycles | -- |
| `InvoiceLines` | Invoice Lines | Invoice then Customer, Part |
| `SalesOrderLines` | Sales Order Lines | SalesOrder then Customer, Part |
| `PurchaseOrderLines` | Purchase Order Lines | PurchaseOrder then Vendor, Part |
| `QuoteLines` | Quote Lines | Quote then Customer, Part |

### Field Definitions

Each entity source exposes typed field definitions via `GET /api/v1/report-builder/entities`. Each field has:

| Property | Type | Description |
|----------|------|-------------|
| `field` | string | Property path (e.g., `JobNumber`, `Customer.Name`). |
| `label` | string | Human-readable label. |
| `type` | string | Data type: `string`, `number`, `date`, `boolean`, `enum`. |
| `isFilterable` | boolean | Whether this field can be used in filters. |
| `isSortable` | boolean | Whether this field can be used for sorting. |
| `isGroupable` | boolean | Whether this field can be used for grouping. |

Nested properties (e.g., `Customer.Name`, `TrackType.Name`) are resolved via dot-notation through navigation properties.

### Filter Operators

The `ReportFilterOperator` enum:

| Operator | Applies To | Description |
|----------|------------|-------------|
| `Equals` | All types | Exact match. |
| `NotEquals` | All types | Not equal. |
| `Contains` | string | Substring match. |
| `StartsWith` | string | Prefix match. |
| `GreaterThan` | number, date | Greater than. |
| `LessThan` | number, date | Less than. |
| `GreaterThanOrEqual` | number, date | Greater than or equal. |
| `LessThanOrEqual` | number, date | Less than or equal. |
| `Between` | number, date | Range (uses Value and Value2). |
| `IsNull` | All nullable | Field is null. |
| `IsNotNull` | All nullable | Field is not null. |
| `In` | string, number, enum | Value is in a comma-separated list. |

### Report Builder Form Fields

| Control | Description |
|---------|-------------|
| Entity Source | Select: one of the 28 entity sources. |
| Columns | Multi-select: fields to include in the output. At least one required. |
| Filters | Repeatable rows: Field + Operator + Value (+ Value2 for Between). |
| Group By | Select: field to group rows by. |
| Sort Field | Select: field to sort by. |
| Sort Direction | Select: asc or desc. |
| Chart Type | Select: bar, line, pie, doughnut, or table. |
| Chart Label Field | Select: field for chart x-axis / labels. |
| Chart Value Field | Select: field for chart y-axis / values. |
| Saved Report | Select: load a previously saved report definition. |

### Chart Types

| Type | Description |
|------|-------------|
| bar | Vertical bar chart. |
| line | Line chart with data points. |
| pie | Pie chart for proportional data. |
| doughnut | Doughnut chart (pie with center hole). |
| table | Data table only (no chart). |

---

## Saved Reports

### Entity: SavedReport

Extends `BaseAuditableEntity`.

| Field | Type | Description |
|-------|------|-------------|
| Name | string | Report name. Max 200 chars. |
| Description | string? | Report description. Max 500 chars. |
| EntitySource | string | Entity source identifier. |
| ColumnsJson | string | JSON array of column field names. |
| FiltersJson | string? | JSON array of ReportFilterModel. |
| GroupByField | string? | Field to group by. |
| SortField | string? | Field to sort by. |
| SortDirection | string? | asc or desc. |
| ChartType | string? | Chart visualization type. |
| ChartLabelField | string? | Chart label field. |
| ChartValueField | string? | Chart value field. |
| IsShared | bool | Whether this report is visible to all users. |
| UserId | int | FK to the user who created the report. |

---

## Report Schedules

Scheduled reports are emailed to recipients on a cron schedule.

### Entity: ReportSchedule

Extends `BaseAuditableEntity`.

| Field | Type | Description |
|-------|------|-------------|
| SavedReportId | int | FK to SavedReport. |
| CronExpression | string | Cron schedule (e.g., `0 8 * * 1` for Monday 8 AM). Max 100 chars. |
| RecipientEmailsJson | string | JSON array of recipient email addresses. |
| Format | ReportExportFormat | Export format for the email attachment. |
| IsActive | bool | Whether the schedule is active. |
| LastSentAt | DateTimeOffset? | Timestamp of the last email sent. |
| NextRunAt | DateTimeOffset? | Next scheduled run time. |
| SubjectTemplate | string? | Custom email subject template. Max 500 chars. |

---

## Export

Saved reports can be exported in three formats via `GET /api/v1/report-builder/{id}/export?format={format}`.

### Export Formats (ReportExportFormat)

| Format | Content Type | Description |
|--------|-------------|-------------|
| Csv | text/csv | Comma-separated values with quoted fields. |
| Xlsx | application/vnd.openxmlformats-officedocument.spreadsheetml.sheet | Excel workbook via ClosedXML. Headers are bold with colored background. Columns auto-sized. |
| Pdf | application/pdf | PDF document via QuestPDF. Tabular layout with headers. |

Export runs the report with pageSize=10000 (effectively no pagination) to capture all data.

---

## Sankey Flow Diagrams (10)

Sankey diagrams visualize flow and volume between stages/categories using the `SankeyChartComponent`.

| # | ID | Label | Date Range | Description |
|---|-----|-------|------------|-------------|
| 1 | quote-to-cash | Quote to Cash | Yes | Flow from quotes through orders, production, shipping, to payment. |
| 2 | job-stage-flow | Job Stage Flow | No | Volume of jobs flowing through kanban stages. |
| 3 | material-to-product | Material to Product | No | BOM material flow from raw materials to finished parts. |
| 4 | worker-orders | Worker to Orders | No | Job assignment distribution across workers. |
| 5 | expense-flow | Expense Flow | Yes | Expense distribution by category and job. |
| 6 | vendor-supply-chain | Vendor Supply Chain | No | Material flow from vendors through POs to inventory. |
| 7 | quality-rejection | Quality Rejection | Yes | QC inspection results -- pass/fail/rework flow. |
| 8 | inventory-location | Inventory by Location | No | Part distribution across storage locations. |
| 9 | customer-revenue | Customer Revenue | Yes | Revenue flow from customers through invoices. |
| 10 | training-completion | Training Completion | No | Employee progress through training paths/modules. |

---

## Report Builder API Endpoints

Base path: `/api/v1/report-builder`

### Get Entity Definitions

```
GET /api/v1/report-builder/entities
```

Returns all available entity sources with their field definitions (type, filterable, sortable, groupable).

Response: 200 OK with ReportEntityDefinitionModel[]

### Run Report

```
POST /api/v1/report-builder/run
```

Executes a report query and returns paginated results.

Request body:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| entitySource | string | Yes | One of the 28 entity sources. |
| columns | string[] | Yes | Fields to include in the output. At least one. |
| filters | ReportFilterModel[]? | No | Array of filter conditions. |
| groupByField | string? | No | Field to group results by. |
| sortField | string? | No | Field to sort by. |
| sortDirection | string? | No | asc or desc. |
| page | int? | No | Page number (default 1). |
| pageSize | int? | No | Page size (default 100, max 1000). |

Response: 200 OK with RunReportResponseModel

| Field | Type | Description |
|-------|------|-------------|
| columns | string[] | The requested column names. |
| rows | Dictionary[] | Array of row dictionaries keyed by column name. |
| totalCount | int | Total matching rows before pagination. |
| groupedData | Dictionary? | Rows grouped by the groupByField value. Null if no grouping. |

### List Saved Reports

```
GET /api/v1/report-builder/saved
```

Response: 200 OK with SavedReportResponseModel[]

### Get Saved Report

```
GET /api/v1/report-builder/saved/{id}
```

Response: 200 OK with SavedReportResponseModel

### Create Saved Report

```
POST /api/v1/report-builder/saved
```

Request body (CreateSavedReportRequestModel):

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| name | string | Yes | Max 200 chars. |
| description | string? | No | Max 500 chars. |
| entitySource | string | Yes | Must be a valid entity source. |
| columns | string[] | Yes | At least one. |
| filters | ReportFilterModel[]? | No | Filter conditions. |
| groupByField | string? | No | Grouping field. |
| sortField | string? | No | Sort field. |
| sortDirection | string? | No | asc or desc. |
| chartType | string? | No | bar, line, pie, doughnut, or table. |
| chartLabelField | string? | No | Chart label axis field. |
| chartValueField | string? | No | Chart value axis field. |
| isShared | bool | Yes | Whether visible to all users. |

Response: 201 Created with SavedReportResponseModel

### Update Saved Report

```
PUT /api/v1/report-builder/saved/{id}
```

Same body as Create. Returns 200 OK with updated SavedReportResponseModel.

### Delete Saved Report

```
DELETE /api/v1/report-builder/saved/{id}
```

Soft-deletes the saved report. Response: 204 No Content

### Export Report

```
GET /api/v1/report-builder/{id}/export?format={Csv|Xlsx|Pdf}
```

Downloads the report in the specified format. Default format: Csv.

Response: File download with appropriate content type.

### List Report Schedules

```
GET /api/v1/report-builder/schedules
```

Admin/Manager only. Returns all report schedules.

### Create Report Schedule

```
POST /api/v1/report-builder/schedules
```

Request body (CreateReportScheduleRequestModel):

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| savedReportId | int | Yes | Must reference an existing saved report. |
| cronExpression | string | Yes | Valid cron expression. Max 100 chars. |
| recipientEmailsJson | string | Yes | JSON array of email addresses. |
| format | ReportExportFormat | Yes | Pdf, Csv, or Xlsx. |
| subjectTemplate | string? | No | Custom email subject. Max 500 chars. |

Response: 201 Created with ReportScheduleResponseModel

### Delete Report Schedule

```
DELETE /api/v1/report-builder/schedules/{id}
```

Admin/Manager only. Response: 204 No Content

---

## Frontend Architecture

### Services

| Service | Path | Purpose |
|---------|------|---------|
| ReportService | features/reports/services/report.service.ts | Calls pre-built report endpoints. |
| ReportBuilderService | features/reports/services/report-builder.service.ts | Calls Report Builder endpoints. Signal-based state. |
| SankeyReportService | features/reports/services/sankey-report.service.ts | Calls Sankey report endpoints. |

### Key Models

| Model | Path | Purpose |
|-------|------|---------|
| ReportType | models/report-type.type.ts | Union type of all 28 pre-built report IDs. |
| ReportDef | models/report-def.model.ts | Report metadata: id, label, icon, needsDateRange. |
| ReportEntityDefinition | models/report-builder.model.ts | Entity source with field definitions. |
| ReportFilter | models/report-builder.model.ts | Filter condition: field, operator, value, value2. |
| SavedReport | models/report-builder.model.ts | Saved report definition. |
| RunReportResponse | models/report-builder.model.ts | Report execution result. |
| SankeyReportType | models/sankey-report-type.type.ts | Union type of 10 Sankey report IDs. |

---

## Known Limitations

1. **Report Builder entity source validation gap.** The CreateSavedReport validator only allows 13 entity sources, but RunReport supports all 28. Saving a report with one of the 15 newer sources will fail validation.
2. **No server-side aggregation.** The Report Builder projects raw rows; aggregation (sum, average, count) for chart rendering is done client-side. Large datasets may be slow.
3. **No scheduled report update endpoint.** Schedules can be created and deleted but not updated (no PUT endpoint).
4. **No report duplication.** There is no clone or duplicate action for saved reports.
5. **Chart configuration is basic.** Chart colors are hardcoded in the frontend. No support for multi-series charts, secondary axes, or custom color schemes in saved report definitions.
6. **Export limit.** Export fetches up to 10,000 rows. Reports with more data will be truncated.
7. **No drill-through from pre-built reports.** Charts show data but do not link to entity detail dialogs (e.g., clicking a bar in Jobs by Stage does not open the job).
8. **Sankey diagrams have no export.** Flow diagrams cannot be exported to PDF or image format.