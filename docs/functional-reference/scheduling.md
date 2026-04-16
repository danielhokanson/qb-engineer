# Scheduling -- Functional Reference

## Overview

The Scheduling module provides finite-capacity production scheduling for job shop operations. It schedules operations from job routings onto work centers, considering capacity constraints, shift patterns, and priority rules. The system supports both forward scheduling (from a start date) and backward scheduling (from a due date), with Gantt visualization, dispatch lists per work center, and capacity load analysis.

This feature has **both a UI and a backend API**.

## Routes

| Route | Component | Description |
|-------|-----------|-------------|
| `/scheduling` | Redirects to `/scheduling/gantt` | Default tab |
| `/scheduling/gantt` | `SchedulingComponent` | Gantt chart view of scheduled operations |
| `/scheduling/dispatch` | `SchedulingComponent` | Per-work-center dispatch list |
| `/scheduling/work-centers` | `SchedulingComponent` | Work center management table |
| `/scheduling/shifts` | `SchedulingComponent` | Shift definition table |
| `/scheduling/runs` | `SchedulingComponent` | Schedule run history |

Tabs: `gantt`, `dispatch`, `work-centers`, `shifts`, `runs`

## API Endpoints

### Scheduling Controller (`/api/v1/scheduling`)

All endpoints require `Admin` or `Manager` role.

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `POST` | `/api/v1/scheduling/run` | Execute a scheduling run (persists results) | `RunSchedulerRequest` | `ScheduleRunResponseModel` |
| `POST` | `/api/v1/scheduling/simulate` | Simulate a scheduling run (does not persist) | `RunSchedulerRequest` | `ScheduleRunResponseModel` |
| `GET` | `/api/v1/scheduling/runs` | List all schedule run history | -- | `List<ScheduleRunResponseModel>` |
| `GET` | `/api/v1/scheduling/gantt?from={date}&to={date}` | Get Gantt data for a date range | Query: `from`, `to` (DateOnly) | `List<ScheduledOperationResponseModel>` |
| `PATCH` | `/api/v1/scheduling/operations/{id}` | Reschedule a single operation | `RescheduleRequest` | 204 No Content |
| `POST` | `/api/v1/scheduling/operations/{id}/lock` | Lock/unlock an operation from rescheduling | `LockRequest` | 204 No Content |
| `GET` | `/api/v1/scheduling/dispatch/{workCenterId}` | Get dispatch list for a work center | -- | `List<DispatchListItemModel>` |
| `GET` | `/api/v1/scheduling/work-center-load/{workCenterId}?from={date}&to={date}` | Get capacity load buckets for a work center | Query: `from`, `to` (DateOnly) | `WorkCenterLoadResponseModel` |

### Work Centers Controller (`/api/v1/work-centers`)

All endpoints require `Admin` or `Manager` role.

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `GET` | `/api/v1/work-centers` | List all work centers | -- | `List<WorkCenterResponseModel>` |
| `POST` | `/api/v1/work-centers` | Create a work center | `CreateWorkCenterRequest` | 201 + `WorkCenterResponseModel` |
| `PUT` | `/api/v1/work-centers/{id}` | Update a work center | `UpdateWorkCenterRequest` | `WorkCenterResponseModel` |
| `DELETE` | `/api/v1/work-centers/{id}` | Soft-delete a work center | -- | 204 No Content |

### Shifts Controller (`/api/v1/shifts`)

All endpoints require `Admin` or `Manager` role.

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `GET` | `/api/v1/shifts` | List all shifts | -- | `List<ShiftResponseModel>` |
| `POST` | `/api/v1/shifts` | Create a shift | `CreateShiftRequest` | 201 + `ShiftResponseModel` |
| `PUT` | `/api/v1/shifts/{id}` | Update a shift | `UpdateShiftRequest` | `ShiftResponseModel` |
| `DELETE` | `/api/v1/shifts/{id}` | Soft-delete a shift | -- | 204 No Content |

## Entities

### ScheduleRun

Represents a single execution of the scheduling engine.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key (auto-increment) |
| `RunDate` | `DateTimeOffset` | When the run was initiated |
| `Direction` | `ScheduleDirection` | Forward or Backward |
| `Status` | `ScheduleRunStatus` | Queued, Running, Completed, Failed |
| `ParametersJson` | `string` | JSON-serialized run parameters |
| `OperationsScheduled` | `int` | Count of operations placed |
| `ConflictsDetected` | `int` | Count of scheduling conflicts |
| `CompletedAt` | `DateTimeOffset?` | When the run finished |
| `RunByUserId` | `int` | User who initiated the run |
| `ErrorMessage` | `string?` | Error details if status is Failed |

Inherits from `BaseAuditableEntity` (adds `CreatedAt`, `UpdatedAt`, `DeletedAt`, `DeletedBy`, `CreatedBy`).

### ScheduledOperation

A single operation placed on a work center timeline.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `JobId` | `int` | FK to Job |
| `OperationId` | `int` | FK to Operation (routing step) |
| `WorkCenterId` | `int` | FK to WorkCenter |
| `ScheduledStart` | `DateTimeOffset` | Planned start time |
| `ScheduledEnd` | `DateTimeOffset` | Planned end time |
| `SetupStart` | `DateTimeOffset?` | Actual setup start |
| `SetupEnd` | `DateTimeOffset?` | Actual setup end |
| `RunStart` | `DateTimeOffset?` | Actual run start |
| `RunEnd` | `DateTimeOffset?` | Actual run end |
| `SetupHours` | `decimal` | Planned setup duration |
| `RunHours` | `decimal` | Planned run duration |
| `TotalHours` | `decimal` | Setup + run hours |
| `Status` | `ScheduledOperationStatus` | Scheduled, InProgress, Complete, Cancelled |
| `SequenceNumber` | `int` | Order within the job routing |
| `IsLocked` | `bool` | If true, scheduler will not move this operation |
| `ScheduleRunId` | `int?` | FK to the ScheduleRun that created it |

### WorkCenter

A machine, cell, or workstation where operations are performed.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `Name` | `string` | Display name |
| `Code` | `string` | Short unique code |
| `Description` | `string?` | Optional description |
| `CompanyLocationId` | `int?` | FK to CompanyLocation |
| `AssetId` | `int?` | FK to Asset (linked equipment) |
| `DailyCapacityHours` | `decimal` | Available hours per day (default 8) |
| `EfficiencyPercent` | `decimal` | Efficiency factor (default 100) |
| `NumberOfMachines` | `int` | Parallel capacity (default 1) |
| `LaborCostPerHour` | `decimal` | Direct labor rate |
| `BurdenRatePerHour` | `decimal` | Overhead rate |
| `IdealCycleTimeSeconds` | `decimal?` | For OEE calculations |
| `IsActive` | `bool` | Soft active flag |
| `SortOrder` | `int` | Display ordering |

### Shift

A defined time window for work center availability.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `Name` | `string` | e.g., "Day Shift", "Night Shift" |
| `StartTime` | `TimeOnly` | Shift start (e.g., 06:00) |
| `EndTime` | `TimeOnly` | Shift end (e.g., 14:30) |
| `BreakMinutes` | `int` | Total break time |
| `NetHours` | `decimal` | Productive hours (computed) |
| `IsActive` | `bool` | Active flag |

## Enums

### ScheduleDirection

| Value | Description |
|-------|-------------|
| `Forward` | Schedule from start date forward to determine completion dates |
| `Backward` | Schedule backward from due dates to determine required start dates |

### ScheduleRunStatus

| Value | Description |
|-------|-------------|
| `Queued` | Run is waiting to execute |
| `Running` | Run is in progress |
| `Completed` | Run finished successfully |
| `Failed` | Run encountered an error |

### ScheduledOperationStatus

| Value | Description |
|-------|-------------|
| `Scheduled` | Placed on timeline but not started |
| `InProgress` | Currently being worked |
| `Complete` | Finished |
| `Cancelled` | Removed from schedule |

## Request/Response Models

### RunSchedulerRequest

```json
{
  "direction": "Forward",
  "scheduleFrom": "2026-04-16",
  "scheduleTo": "2026-05-16",
  "jobIdFilter": [101, 102],
  "priorityRule": "DueDate"
}
```

`priorityRule` values: `"DueDate"`, `"Priority"`, `"FIFO"`

### ScheduleRunResponseModel

```json
{
  "id": 1,
  "runDate": "2026-04-16T12:00:00Z",
  "direction": "Forward",
  "status": "Completed",
  "operationsScheduled": 47,
  "conflictsDetected": 2,
  "completedAt": "2026-04-16T12:00:05Z",
  "runByUserId": 1,
  "errorMessage": null
}
```

### ScheduledOperationResponseModel

```json
{
  "id": 1,
  "jobId": 101,
  "jobNumber": "JOB-2026-0101",
  "jobTitle": "Bracket Assembly",
  "operationId": 5,
  "operationTitle": "CNC Milling",
  "workCenterId": 3,
  "workCenterName": "Haas VF-2",
  "scheduledStart": "2026-04-17T06:00:00Z",
  "scheduledEnd": "2026-04-17T10:30:00Z",
  "setupHours": 0.5,
  "runHours": 4.0,
  "totalHours": 4.5,
  "status": "Scheduled",
  "sequenceNumber": 2,
  "isLocked": false,
  "jobPriority": "High",
  "jobDueDate": "2026-04-25T00:00:00Z",
  "color": "#4CAF50"
}
```

### WorkCenterLoadResponseModel

```json
{
  "workCenterId": 3,
  "workCenterName": "Haas VF-2",
  "buckets": [
    {
      "weekStart": "2026-04-14",
      "capacityHours": 40.0,
      "scheduledHours": 32.5,
      "utilizationPercent": 81.25
    }
  ]
}
```

### DispatchListItemModel

```json
{
  "scheduledOperationId": 12,
  "jobId": 101,
  "jobNumber": "JOB-2026-0101",
  "operationId": 5,
  "operationTitle": "CNC Milling",
  "sequenceNumber": 2,
  "scheduledStart": "2026-04-17T06:00:00Z",
  "setupHours": 0.5,
  "runHours": 4.0,
  "priority": "High",
  "jobDueDate": "2026-04-25T00:00:00Z"
}
```

## UI Tabs and Features

### Gantt Tab (default)
- DataTable listing all scheduled operations within a 30-day window
- Columns: Job #, Operation, Work Center, Start, End, Hours, Status, Locked
- KPI chips: Total Scheduled, Total In Progress, Total Work Centers
- Actions: Execute Schedule (run scheduler), Toggle Lock on individual operations
- Status chips color-coded: Scheduled (info), InProgress (warning), Complete (success)

### Dispatch Tab
- Select a work center from a dropdown
- Shows prioritized operation queue for that work center
- Columns: Job #, Operation, Sequence, Start, Setup Hrs, Run Hrs, Priority, Due Date

### Work Centers Tab
- DataTable of all work centers
- Columns: Code, Name, Daily Capacity, Efficiency %, Machines, Active, Asset, Location

### Shifts Tab
- DataTable of shift definitions
- Columns: Name, Start Time, End Time, Break Minutes, Net Hours, Active

### Runs Tab
- History of all scheduling runs
- Columns: Run Date, Direction, Status, Ops Scheduled, Conflicts, Completed

## Integration Points

- **Jobs**: Operations from job routings are the primary input for scheduling
- **Operations / Routings**: Each `ScheduledOperation` references an `Operation` from a job's routing
- **Work Centers**: Operations are assigned to work centers; the `Operation` entity has a `WorkCenterId` FK
- **Assets**: Work centers can be linked to `Asset` records for equipment tracking
- **Company Locations**: Work centers belong to a specific facility
- **Shifts**: Shifts define available time windows; linked to work centers via `WorkCenterShift` junction table
- **MRP**: MRP planned orders of type `Manufacture` create jobs that feed into scheduling

## Known Limitations

- The Gantt tab currently shows a DataTable rather than a true Gantt chart visualization (Gantt bars are not rendered)
- Drag-and-drop rescheduling on the Gantt is not implemented; operations are rescheduled via the PATCH API
- The scheduler does not account for material availability (that is handled by MRP separately)
- Work center calendar overrides (`WorkCenterCalendar` entity exists) are not exposed via the UI
- No automatic re-scheduling when jobs are added or priorities change; users must manually trigger a run
- Simulation mode returns the same response shape as a real run but does not persist the results
