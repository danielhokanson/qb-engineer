# MRP (Material Requirements Planning) -- Functional Reference

## Overview

The MRP module implements a full Material Requirements Planning engine for manufacturing. It calculates material needs by exploding bills of material (BOMs), netting against on-hand inventory and open supply, and generating planned orders for purchasing or manufacturing. The module includes Master Production Scheduling (MPS), demand forecasting with statistical methods, supply/demand pegging, and exception management.

This feature has **both a UI and a backend API**.

## Routes

| Route | Component | Description |
|-------|-----------|-------------|
| `/mrp` | Redirects to `/mrp/dashboard` | Default tab |
| `/mrp/dashboard` | `MrpComponent` | KPI overview with latest run stats |
| `/mrp/planned-orders` | `MrpComponent` | Planned order list with firm/release actions |
| `/mrp/exceptions` | `MrpComponent` | Exception messages requiring attention |
| `/mrp/runs` | `MrpComponent` | MRP run history |
| `/mrp/master-schedule` | `MrpComponent` | Master Production Schedule management |
| `/mrp/forecasts` | `MrpComponent` | Demand forecast management |

Tabs: `dashboard`, `planned-orders`, `exceptions`, `runs`, `master-schedule`, `forecasts`

## API Endpoints

### MRP Controller (`/api/v1/mrp`)

All endpoints require `Admin` or `Manager` role.

#### MRP Runs

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `GET` | `/api/v1/mrp/runs` | List all MRP runs | -- | `List<MrpRunResponseModel>` |
| `GET` | `/api/v1/mrp/runs/{id}` | Get a specific run with details | -- | `MrpRunResponseModel` |
| `POST` | `/api/v1/mrp/runs` | Execute an MRP run (persists) | `ExecuteMrpRunRequest` | 201 + `MrpRunResponseModel` |
| `POST` | `/api/v1/mrp/runs/simulate` | Simulate an MRP run (read-only) | `ExecuteMrpRunRequest` | `MrpRunResponseModel` |

#### Planned Orders

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `GET` | `/api/v1/mrp/planned-orders?mrpRunId={id}&status={status}` | List planned orders with optional filters | Query params | `List<MrpPlannedOrderResponseModel>` |
| `PATCH` | `/api/v1/mrp/planned-orders/{id}` | Update a planned order (firm/add notes) | `UpdatePlannedOrderRequest` | 204 No Content |
| `POST` | `/api/v1/mrp/planned-orders/{id}/release` | Release a planned order (creates PO or Job) | -- | `ReleasePlannedOrderResult` |
| `POST` | `/api/v1/mrp/planned-orders/bulk-release` | Release multiple planned orders at once | `BulkReleaseRequest` | `List<ReleasePlannedOrderResult>` |
| `DELETE` | `/api/v1/mrp/planned-orders/{id}` | Cancel/delete a planned order | -- | 204 No Content |

#### Exceptions

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `GET` | `/api/v1/mrp/exceptions?mrpRunId={id}&unresolvedOnly={bool}` | List MRP exceptions | Query params | `List<MrpExceptionResponseModel>` |
| `POST` | `/api/v1/mrp/exceptions/{id}/resolve` | Mark an exception as resolved | `ResolveExceptionRequest` | 204 No Content |

#### Master Schedules

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `GET` | `/api/v1/mrp/master-schedules?status={status}` | List master schedules | Query param | `List<MasterScheduleResponseModel>` |
| `GET` | `/api/v1/mrp/master-schedules/{id}` | Get master schedule with lines | -- | `MasterScheduleDetailResponseModel` |
| `POST` | `/api/v1/mrp/master-schedules` | Create a master schedule | `CreateMasterScheduleRequest` | 201 + `MasterScheduleDetailResponseModel` |
| `PUT` | `/api/v1/mrp/master-schedules/{id}` | Update a master schedule | `UpdateMasterScheduleRequest` | `MasterScheduleDetailResponseModel` |
| `POST` | `/api/v1/mrp/master-schedules/{id}/activate` | Activate a draft schedule | -- | `MasterScheduleResponseModel` |
| `GET` | `/api/v1/mrp/master-schedules/{id}/vs-actual` | Compare MPS planned vs actual production | -- | `List<MpsVsActualResponseModel>` |

#### Demand Forecasts

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `GET` | `/api/v1/mrp/forecasts?partId={id}` | List demand forecasts | Query param | `List<DemandForecastResponseModel>` |
| `POST` | `/api/v1/mrp/forecasts` | Generate a new demand forecast | `GenerateForecastRequest` | 201 + `DemandForecastResponseModel` |
| `POST` | `/api/v1/mrp/forecasts/{id}/approve` | Approve a draft forecast | -- | 204 No Content |
| `POST` | `/api/v1/mrp/forecasts/{id}/apply` | Apply an approved forecast to a master schedule | `ApplyForecastRequest` | 204 No Content |
| `POST` | `/api/v1/mrp/forecasts/{forecastId}/overrides` | Add a manual override to a forecast period | `CreateOverrideRequest` | 201 + `ForecastOverrideResponseModel` |

#### Part Plan and Pegging

| Method | Path | Description | Response |
|--------|------|-------------|----------|
| `GET` | `/api/v1/mrp/runs/{runId}/parts/{partId}/plan` | Time-phased plan for a part within a run | `MrpPartPlanResponseModel` |
| `GET` | `/api/v1/mrp/runs/{runId}/parts/{partId}/pegging` | Supply/demand pegging for a part | `List<MrpPeggingResponseModel>` |

## Entities

### MrpRun

A single execution of the MRP engine.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `RunNumber` | `string` | Auto-generated run identifier |
| `RunType` | `MrpRunType` | Full, NetChange, or Simulation |
| `Status` | `MrpRunStatus` | Queued, Running, Completed, Failed |
| `IsSimulation` | `bool` | True if results are ephemeral |
| `StartedAt` | `DateTimeOffset?` | Execution start time |
| `CompletedAt` | `DateTimeOffset?` | Execution end time |
| `PlanningHorizonDays` | `int` | How far ahead to plan (default 90) |
| `TotalDemandCount` | `int` | Number of demand records generated |
| `TotalSupplyCount` | `int` | Number of supply records identified |
| `PlannedOrderCount` | `int` | Number of planned orders created |
| `ExceptionCount` | `int` | Number of exception messages |
| `ErrorMessage` | `string?` | Error details if run failed |
| `InitiatedByUserId` | `int?` | User who triggered the run |

### MrpPlannedOrder

A proposed order generated by the MRP engine.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `MrpRunId` | `int` | FK to MrpRun |
| `PartId` | `int` | FK to Part |
| `OrderType` | `MrpOrderType` | Purchase or Manufacture |
| `Status` | `MrpPlannedOrderStatus` | Planned, Firmed, Released, Cancelled |
| `Quantity` | `decimal` | Order quantity |
| `StartDate` | `DateTimeOffset` | When to start/order |
| `DueDate` | `DateTimeOffset` | When material is needed |
| `IsFirmed` | `bool` | True if user has confirmed the order |
| `ReleasedPurchaseOrderId` | `int?` | FK to PO created on release |
| `ReleasedJobId` | `int?` | FK to Job created on release |
| `ParentPlannedOrderId` | `int?` | FK to parent (for dependent demand) |
| `Notes` | `string?` | User notes |

### MrpDemand

A demand record identified during an MRP run.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `MrpRunId` | `int` | FK to MrpRun |
| `PartId` | `int` | FK to Part |
| `Source` | `MrpDemandSource` | Where the demand comes from |
| `SourceEntityId` | `int?` | FK to source entity (SO, MPS line, etc.) |
| `Quantity` | `decimal` | Demanded quantity |
| `RequiredDate` | `DateTimeOffset` | When the material is needed |
| `IsDependent` | `bool` | True if derived from BOM explosion |
| `ParentPlannedOrderId` | `int?` | FK to parent planned order |
| `BomLevel` | `int` | BOM depth level (0 = finished good) |

### MrpSupply

A supply record identified during an MRP run.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `MrpRunId` | `int` | FK to MrpRun |
| `PartId` | `int` | FK to Part |
| `Source` | `MrpSupplySource` | Where the supply comes from |
| `SourceEntityId` | `int?` | FK to source entity (PO, production run, etc.) |
| `Quantity` | `decimal` | Available quantity |
| `AvailableDate` | `DateTimeOffset` | When supply will be available |
| `AllocatedQuantity` | `decimal` | How much has been allocated to demand |

### MrpException

An exception message flagged by the MRP engine for human review.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `MrpRunId` | `int` | FK to MrpRun |
| `PartId` | `int` | FK to Part |
| `ExceptionType` | `MrpExceptionType` | Type of exception |
| `Message` | `string` | Human-readable description |
| `SuggestedAction` | `string?` | Recommended resolution |
| `IsResolved` | `bool` | Resolution status |
| `ResolvedByUserId` | `int?` | Who resolved it |
| `ResolvedAt` | `DateTimeOffset?` | When resolved |
| `ResolutionNotes` | `string?` | Resolution details |

### MasterSchedule

A Master Production Schedule defining planned output by part and date.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `Name` | `string` | Schedule name |
| `Description` | `string?` | Optional description |
| `Status` | `MasterScheduleStatus` | Draft, Active, Completed, Cancelled |
| `PeriodStart` | `DateTimeOffset` | Schedule period start |
| `PeriodEnd` | `DateTimeOffset` | Schedule period end |
| `CreatedByUserId` | `int` | Who created it |

### MasterScheduleLine

A single line in the MPS.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `MasterScheduleId` | `int` | FK to MasterSchedule |
| `PartId` | `int` | FK to Part |
| `Quantity` | `decimal` | Planned production quantity |
| `DueDate` | `DateTimeOffset` | Target completion date |
| `Notes` | `string?` | Optional notes |

### DemandForecast

A statistical demand forecast for a specific part.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `Name` | `string` | Forecast name |
| `PartId` | `int` | FK to Part |
| `Method` | `ForecastMethod` | Statistical method used |
| `Status` | `ForecastStatus` | Draft, Approved, Applied, Expired |
| `HistoricalPeriods` | `int` | Number of historical periods analyzed |
| `ForecastPeriods` | `int` | Number of periods forecasted |
| `SmoothingFactor` | `double?` | Alpha for exponential smoothing |
| `ForecastStartDate` | `DateTimeOffset` | When the forecast begins |
| `ForecastDataJson` | `string?` | Serialized forecast buckets |
| `AppliedToMasterScheduleId` | `int?` | FK to MPS if applied |
| `CreatedByUserId` | `int?` | Who generated it |

### ForecastOverride

A manual adjustment to a forecast period.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `DemandForecastId` | `int` | FK to DemandForecast |
| `PeriodStart` | `DateTimeOffset` | Which period to override |
| `OriginalQuantity` | `decimal` | System-calculated quantity |
| `OverrideQuantity` | `decimal` | User-provided quantity |
| `Reason` | `string?` | Justification |
| `OverriddenByUserId` | `int?` | Who made the override |

## Enums

### MrpRunType

| Value | Description |
|-------|-------------|
| `Full` | Complete regeneration -- all demands and supplies recalculated |
| `NetChange` | Only recalculates parts with changes since last run |
| `Simulation` | Full run but results are not persisted |

### MrpRunStatus

| Value | Description |
|-------|-------------|
| `Queued` | Waiting to execute |
| `Running` | In progress |
| `Completed` | Finished successfully |
| `Failed` | Encountered an error |

### MrpPlannedOrderStatus

| Value | Description |
|-------|-------------|
| `Planned` | System-generated, not yet reviewed |
| `Firmed` | User-confirmed, will not be changed by next run |
| `Released` | Converted to a real PO or production Job |
| `Cancelled` | Removed |

### MrpOrderType

| Value | Description |
|-------|-------------|
| `Purchase` | Buy from vendor (releases as Purchase Order) |
| `Manufacture` | Make in-house (releases as Job) |

### MrpDemandSource

| Value | Description |
|-------|-------------|
| `SalesOrder` | Demand from a customer sales order line |
| `MasterSchedule` | Demand from the MPS |
| `Forecast` | Demand from an approved demand forecast |
| `ManualDemand` | Manually entered demand |
| `DependentDemand` | Derived from BOM explosion of a parent planned order |

### MrpSupplySource

| Value | Description |
|-------|-------------|
| `OnHand` | Current inventory |
| `PurchaseOrder` | Open purchase orders |
| `PlannedOrder` | Previously planned orders (firmed) |
| `ProductionRun` | Active production runs |
| `InTransit` | Material in transit from vendors |

### MrpExceptionType

| Value | Description |
|-------|-------------|
| `Expedite` | An existing order needs to arrive sooner |
| `Defer` | An existing order can be pushed out |
| `Cancel` | An existing order is no longer needed |
| `PastDue` | Demand cannot be met by its required date |
| `ShortSupply` | Insufficient supply to cover demand |
| `OverSupply` | Excess supply beyond demand |
| `LeadTimeViolation` | Lead time prevents timely delivery |

### MasterScheduleStatus

| Value | Description |
|-------|-------------|
| `Draft` | Being prepared, not yet driving MRP |
| `Active` | Currently driving MRP demand |
| `Completed` | Period has passed |
| `Cancelled` | Abandoned |

### ForecastMethod

| Value | Description |
|-------|-------------|
| `MovingAverage` | Simple moving average of historical periods |
| `ExponentialSmoothing` | Exponential smoothing with configurable alpha |
| `WeightedMovingAverage` | Weighted moving average (recent periods weighted higher) |

### ForecastStatus

| Value | Description |
|-------|-------------|
| `Draft` | Generated but not reviewed |
| `Approved` | Reviewed and approved for use |
| `Applied` | Applied to a Master Production Schedule |
| `Expired` | No longer valid |

## Status Lifecycles

### MRP Run: `Queued` --> `Running` --> `Completed` or `Failed`

### Planned Order: `Planned` --> `Firmed` --> `Released` or `Cancelled`

- `Planned`: Auto-generated by engine; may be modified by next full run
- `Firmed`: User-confirmed; protected from regeneration
- `Released`: Converted to a Purchase Order (if `Purchase`) or Job (if `Manufacture`)
- `Cancelled`: Removed from consideration

### Master Schedule: `Draft` --> `Active` --> `Completed` or `Cancelled`

### Demand Forecast: `Draft` --> `Approved` --> `Applied` or `Expired`

## Key Response Models

### MrpPartPlanResponseModel (Time-Phased Plan)

```json
{
  "partId": 42,
  "partNumber": "BRK-001",
  "partDescription": "Steel Bracket",
  "buckets": [
    {
      "periodStart": "2026-04-14T00:00:00Z",
      "periodEnd": "2026-04-20T23:59:59Z",
      "grossRequirements": 100,
      "scheduledReceipts": 50,
      "plannedOrderReceipts": 50,
      "projectedOnHand": 25,
      "netRequirements": 50,
      "plannedOrderReleases": 50
    }
  ]
}
```

### ReleasePlannedOrderResult

```json
{
  "plannedOrderId": 15,
  "orderType": "Purchase",
  "createdPurchaseOrderId": 203,
  "createdJobId": null
}
```

### MpsVsActualResponseModel

```json
{
  "partId": 42,
  "partNumber": "BRK-001",
  "partDescription": "Steel Bracket",
  "plannedQuantity": 500,
  "actualQuantity": 450,
  "variance": -50,
  "variancePercent": -10.0
}
```

## UI Tabs and Features

### Dashboard Tab (default)
- KPI chips: Latest Run status, Unresolved Exceptions, Planned Orders (not firmed), Firmed Orders
- Quick-access summary of the MRP state

### Planned Orders Tab
- DataTable with status filter (All/Planned/Firmed/Released/Cancelled)
- Columns: Part #, Description, Type, Status, Qty, Start, Due, Firmed, Actions
- Row actions: Firm (marks as firmed), Release (creates PO or Job)
- Status chips color-coded

### Exceptions Tab
- DataTable with filter (All/Unresolved Only)
- Columns: Type, Part #, Message, Suggested Action, Resolved, Actions
- Row action: Resolve with notes
- Exception types color-coded (Expedite/PastDue/ShortSupply = error, Defer/OverSupply = warning)

### Runs Tab
- DataTable of all MRP run history
- Columns: Run #, Type, Status, Orders, Exceptions, Demands, Supplies, Started, Completed
- Action buttons: Execute Run, Simulate Run

### Master Schedule Tab
- DataTable of master schedules
- Columns: Name, Status, Start, End, Lines, Created
- Action: Activate (moves Draft to Active)

### Forecasts Tab
- DataTable of demand forecasts
- Columns: Name, Part #, Method, Status, Periods, Overrides, Created
- Action: Approve (moves Draft to Approved)

## Integration Points

- **Parts**: MRP plans at the part level; BOM explosion uses `BOMEntry` records to derive dependent demand
- **BOMs**: `BOMEntry.BOMSourceType` (Make/Buy/Stock) determines whether planned orders are Purchase or Manufacture type
- **Inventory**: On-hand quantities from `BinContent` are supply sources
- **Purchase Orders**: Open PO lines are supply sources; releasing a Purchase planned order creates a new PO
- **Jobs**: Active jobs with production runs are supply sources; releasing a Manufacture planned order creates a new Job
- **Sales Orders**: Open SO lines are demand sources
- **Scheduling**: Released Manufacture orders flow into the scheduling engine for work center assignment
- **Lead Times**: `BOMEntry.LeadTimeDays` and `Part` lead time settings drive planned order start dates

## Known Limitations

- Net Change runs (`MrpRunType.NetChange`) exist as an enum value but the engine may not fully optimize to only reprocess changed parts
- The MRP engine processes all BOM levels in memory; very deep BOMs (10+ levels) with many parts could be memory-intensive
- Demand forecasting methods are basic statistical (moving average, exponential smoothing); no machine learning or seasonal decomposition
- Safety stock levels are not explicitly modeled as a separate field; they would need to be handled via manual demand or forecast overrides
- Lot sizing rules (lot-for-lot, EOQ, POQ) are not configurable per part; the engine uses lot-for-lot by default
- The forecast-to-MPS pipeline requires manual steps (generate, approve, apply); there is no automated scheduling of forecast generation
