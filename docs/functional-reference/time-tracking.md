# Time Tracking

Functional reference for the time tracking feature at `/time-tracking`.

---

## 1. Overview

The Time Tracking feature provides two primary methods for employees to record work time:

1. **Timer** -- start/stop a real-time timer that records elapsed duration automatically
2. **Manual Entry** -- log a time entry with a specific date, hours, and minutes

Time entries can optionally be linked to jobs and categorized by work type. The feature integrates with SignalR (`TimerHub`) for real-time updates across browser tabs and users.

Additional capabilities managed by admin/manager users include:
- **Clock Events** -- clock in/out and break tracking (primarily for kiosk/shop floor)
- **Time Corrections** -- admin/manager corrections with full audit trail
- **Pay Period** -- configurable pay period settings and period locking
- **Overtime Rules** -- daily/weekly threshold configuration with multiplier rates
- **Shift Assignments** -- employee shift scheduling with differential rates

---

## 2. Routes & Navigation

| Route | Component | Description |
|-------|-----------|-------------|
| `/time-tracking` | `TimeTrackingComponent` | Single-page time tracking view |

The feature is a single route with no child routes. All functionality (timer, manual entry, list) is on one page. Dialog-based interactions for manual entry, starting timers, and stopping timers overlay the main view.

The page header includes contextual action buttons that change based on timer state:
- **No active timer:** "Start Timer" (primary) + "Manual Entry" buttons
- **Active timer:** "Stop Timer (elapsed)" (warn) + "Manual Entry" buttons

---

## 3. Timer Controls

### 3.1 Starting a Timer

Clicking "Start Timer" opens a dialog with:

| Field | Control | FormControl | Validators | Notes |
|-------|---------|-------------|------------|-------|
| Category | `<app-select>` | `category` | None | Optional work category |
| Notes | `<app-textarea>` | `notes` | None | Optional notes, 2 rows |

**API:** `POST /api/v1/time-tracking/timer/start`

```typescript
interface StartTimerRequest {
  jobId?: number;
  category?: string;
  notes?: string;
}
```

On success, the server creates a `TimeEntry` with `TimerStart` set to the current UTC time and `TimerStop` set to null. The timer appears as a running entry in the DataTable with a "Running" badge.

**data-testid attributes:** `timer-category`, `timer-notes`, `timer-start-btn`

### 3.2 Stopping a Timer

Clicking the "Stop Timer" button (which displays elapsed time) opens a dialog showing:

- Current elapsed time in bold
- Active timer's category (if set)
- Optional notes textarea (2 rows)

| Field | Control | FormControl | Validators | Notes |
|-------|---------|-------------|------------|-------|
| Notes | `<app-textarea>` | `stopNotesControl` | None | Optional, standalone FormControl |

**API:** `POST /api/v1/time-tracking/timer/stop`

```typescript
interface StopTimerRequest {
  notes?: string;
}
```

On success, the server sets `TimerStop` to current UTC time and calculates `DurationMinutes` from the elapsed period. The entry transitions from "running" to a completed time entry.

**data-testid attributes:** `timer-stop-notes`, `timer-stop-btn`

### 3.3 Timer Elapsed Display

The `getTimerElapsed()` method calculates real-time elapsed duration from the active timer's `timerStart` timestamp:

```
elapsed = Math.floor((Date.now() - new Date(timer.timerStart).getTime()) / 60000)
```

Displayed in format: `Xh Ym` (e.g., "2h 15m") or `Xm` when under one hour (e.g., "45m").

### 3.4 Active Timer Detection

After loading entries, the component scans for an entry where `timerStart` is set and `timerStop` is null. This entry is stored in the `activeTimer` signal and determines header button state.

---

## 4. Manual Entry

Clicking "Manual Entry" opens a dialog with draft support (`DraftConfig` entity type: `time-entry`, entity ID: `new`).

### Form Fields

| Field | Control | FormControl | Validators | data-testid |
|-------|---------|-------------|------------|-------------|
| Date | `<app-datepicker>` | `date` | `required` | `time-entry-date` |
| Category | `<app-select>` | `category` | None | `time-entry-category` |
| Hours | `<app-input>` type=number | `hours` | `required`, `min(0)`, `max(24)` | `time-entry-hours` |
| Minutes | `<app-input>` type=number | `minutes` | `required`, `min(0)`, `max(59)` | `time-entry-minutes` |
| Notes | `<app-textarea>` | `notes` | None | `time-entry-notes` |

### Category Options

| Value | Label Key |
|-------|-----------|
| `''` (empty) | `timeTracking.categoryNone` |
| `Production` | `timeTracking.categoryProduction` |
| `Setup` | `timeTracking.categorySetup` |
| `Inspection` | `timeTracking.categoryInspection` |
| `Maintenance` | `timeTracking.categoryMaintenance` |
| `Training` | `timeTracking.categoryTraining` |
| `Meeting` | `timeTracking.categoryMeeting` |
| `Admin` | `timeTracking.categoryAdmin` |
| `Cleanup` | `timeTracking.categoryCleanup` |
| `Other` | `timeTracking.categoryOther` |

### Save Behavior

Duration is calculated as `(hours * 60) + minutes`. If total duration is zero or negative, the save is rejected.

**API:** `POST /api/v1/time-tracking/entries`

```typescript
interface CreateTimeEntryRequest {
  jobId?: number;
  date: string;           // Date-only string (YYYY-MM-DD)
  durationMinutes: number;
  category?: string;
  notes?: string;
}
```

The date is formatted via `toDateOnly()` utility. On success, the dialog closes, the draft is cleared, entries are reloaded, and a success snackbar appears.

**data-testid:** `time-entry-save-btn`

---

## 5. Time Entry List (DataTable)

The main content area displays all time entries in a `DataTableComponent` with table ID `time-tracking`.

### Columns

| Field | Header | Type | Sortable | Width | Custom Template |
|-------|--------|------|----------|-------|-----------------|
| `icon` | -- | -- | No | 32px | Entry type icon (see below) |
| `date` | Date | `date` | Yes | -- | Raw date |
| `userName` | User | -- | Yes | -- | Full name |
| `jobNumber` | Job | -- | No | -- | Job badge or em dash |
| `category` | Category | -- | Yes | -- | Category text or em dash |
| `durationMinutes` | Duration | -- | Yes | -- | Formatted or "Running" badge |
| `notes` | Notes | -- | No | -- | Truncated notes text |
| `type` | Type | -- | No | 80px | "Manual" or "Timer" chip |
| `actions` | -- | -- | No | 64px | Delete or lock icon |

### Icon Column

| Condition | Icon | Class |
|-----------|------|-------|
| Timer running (`timerStart` set, `timerStop` null) | `timer` | `type-icon--running` |
| Manual entry (`isManual` true) | `edit_note` | `type-icon` |
| Timer entry (completed) | `timer` | `type-icon` |

### Duration Column

- Running timers show a "Running" badge (green animated indicator)
- Completed entries show formatted duration: `Xh Ym` or `Xm`

### Type Column

- Manual entries: "Manual" chip with `entry-type--manual` class
- Timer entries: "Timer" chip with `entry-type--timer` class

### Actions Column

- **Locked entries** (`isLocked` or date before today): lock icon with tooltip
- **Editable entries**: red delete icon button with confirmation dialog

### Row Styling

Active timer entries (running) get the `row--active` class for visual highlighting.

### Editability Rules

An entry is editable when:
1. `isLocked` is false
2. Entry date is today or in the future

```typescript
isEditable(entry: TimeEntry): boolean {
  if (entry.isLocked) return false;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return new Date(entry.date).getTime() >= today.getTime();
}
```

### Date Range Filters

Two standalone `<app-datepicker>` controls above the table:

| Filter | Control | Effect |
|--------|---------|--------|
| From | `dateFromControl` | Filters entries on or after this date |
| To | `dateToControl` | Filters entries on or before this date |

Both are optional. Changes trigger `loadEntries()` which calls the API with `from` and `to` query parameters.

### Total Summary

Below the filters, a summary line shows: "X.X hours total -- Y entries" computed from all loaded entries.

```typescript
getTotalHours(): string {
  const total = this.entries().reduce((sum, e) => sum + e.durationMinutes, 0);
  return (total / 60).toFixed(1);
}
```

### Empty State

When no entries exist, shows the `schedule` icon with the message from `emptyState.noTimeEntries`.

---

## 6. Deleting Time Entries

Deleting a time entry requires confirmation via `ConfirmDialogComponent` (severity: `danger`).

**API:** `DELETE /api/v1/time-tracking/entries/{id}`

The server soft-deletes the entry (sets `DeletedAt`). On success, entries are reloaded and a success snackbar appears.

---

## 7. Clock Events

Clock events track employee clock-in, clock-out, and break events. They are separate from time entries and are primarily used on the shop floor kiosk.

### ClockEvent Model

```typescript
interface ClockEvent {
  id: number;
  userId: number;
  userName: string;
  eventTypeCode: string;   // Reference-data-driven code
  reason: string | null;
  scanMethod: string | null; // How the event was triggered
  timestamp: Date;
  source: string | null;   // Event origin (kiosk, web, etc.)
}
```

### API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/time-tracking/clock-events` | User | List clock events (filterable) |
| `POST` | `/api/v1/time-tracking/clock-events` | User | Create clock event |
| `GET` | `/api/v1/time-tracking/clock-status` | User | Get current clock-in status |

### Query Parameters for GET

| Param | Type | Description |
|-------|------|-------------|
| `userId` | int | Filter by user |
| `from` | DateOnly | Start date filter |
| `to` | DateOnly | End date filter |

### Create Request

```typescript
interface CreateClockEventRequest {
  eventTypeCode: string;
  reason?: string;
  scanMethod?: string;
  source?: string;
}
```

### Backend Entity

```csharp
public class ClockEvent : BaseEntity
{
    int UserId;
    ClockEventType EventType;      // Enum (legacy)
    string EventTypeCode;          // Reference-data-driven code
    int? OperationId;
    string? Reason;
    string? ScanMethod;
    DateTimeOffset Timestamp;
    string? Source;
}
```

Event type codes are managed via the `reference_data` table under group `clock_event_type`, making them admin-configurable.

---

## 8. Time Corrections (Admin/Manager)

Time corrections allow administrators and managers to modify existing time entries with a full audit trail. Every correction creates a `TimeCorrectionLog` record preserving the original values.

### Correction Request

```typescript
interface CorrectTimeEntryRequest {
  jobId?: number | null;
  date?: string | null;
  durationMinutes?: number | null;
  startTime?: string | null;
  endTime?: string | null;
  category?: string | null;
  notes?: string | null;
  reason: string;              // Required -- audit trail
}
```

Only fields that need to change should be included. The `reason` field is mandatory to explain why the correction was made.

### Correction Log Model

```typescript
interface TimeCorrectionLog {
  id: number;
  timeEntryId: number;
  correctedByUserId: number;
  correctedByName: string;
  reason: string;
  originalJobId: number | null;
  originalJobNumber: string | null;
  originalDate: string;
  originalDurationMinutes: number;
  originalStartTime: string | null;
  originalEndTime: string | null;
  originalCategory: string | null;
  originalNotes: string | null;
  createdAt: string;
}
```

### Backend Entity

```csharp
public class TimeCorrectionLog : BaseAuditableEntity
{
    int TimeEntryId;
    int CorrectedByUserId;
    string Reason;
    int? OriginalJobId;
    DateOnly OriginalDate;
    int OriginalDurationMinutes;
    DateTimeOffset? OriginalStartTime;
    DateTimeOffset? OriginalEndTime;
    string? OriginalCategory;
    string? OriginalNotes;
    // Navigation
    TimeEntry TimeEntry;
}
```

### API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `PATCH` | `/api/v1/time-tracking/entries/{id}/correct` | Admin, Manager | Correct a time entry |
| `GET` | `/api/v1/time-tracking/corrections` | Admin, Manager | List correction logs |

### Correction Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `userId` | int | Filter by the user whose entry was corrected |
| `from` | DateOnly | Start date filter |
| `to` | DateOnly | End date filter |

### Audit Trail

Each correction records:
- Who made the correction (`CorrectedByUserId`)
- Why (`Reason` -- required field)
- A complete snapshot of the original values before the change
- Timestamp via `BaseAuditableEntity.CreatedAt`

The admin time corrections feature has a dedicated admin page at `/admin/time-corrections`.

---

## 9. Job Linking

Time entries can be linked to jobs via the optional `jobId` field. When linked:
- The `jobNumber` field is populated on the response model
- The DataTable shows a styled job badge in the Job column
- Time data contributes to the job's labor cost calculations

### TimeEntry Fields for Job Linking

| Field | Description |
|-------|-------------|
| `jobId` | FK to Job entity (nullable) |
| `jobNumber` | Resolved job number string (read-only, from join) |
| `operationId` | FK to Operation entity (nullable) -- for operation-level tracking |
| `entryType` | `TimeEntryType` enum (default: `Run`) |

### Costing Fields

| Field | Type | Description |
|-------|------|-------------|
| `laborCost` | decimal | Calculated labor cost for the entry |
| `burdenCost` | decimal | Burden/overhead cost for the entry |

These fields are set server-side based on the employee's hourly rate and configured burden rates.

---

## 10. SignalR Real-Time (TimerHub)

The time tracking component connects to the `TimerHub` on initialization and disconnects on destroy.

### Connection Lifecycle

```typescript
constructor() {
  this.initTimerHub();
}

ngOnDestroy(): void {
  this.timerHub.disconnect();
}

private async initTimerHub(): Promise<void> {
  await this.timerHub.connect();
  this.timerHub.onTimerStartedEvent(() => this.loadEntries());
  this.timerHub.onTimerStoppedEvent(() => this.loadEntries());
}
```

### Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `timerStarted` | Server to Client | A user started a timer |
| `timerStopped` | Server to Client | A user stopped a timer |

Both events trigger a full entry reload. This ensures the UI stays current when:
- The same user starts/stops a timer from another tab
- A manager or admin starts/stops a timer for another user
- Another user's timer activity appears in an admin view

### Backend Broadcasting

Timer start/stop MediatR handlers inject `IHubContext<TimerHub>` and broadcast events after `SaveChangesAsync`:

```csharp
await timerHub.Clients.All.SendAsync("timerStarted", event, ct);
await timerHub.Clients.All.SendAsync("timerStopped", event, ct);
```

---

## 11. Pay Period Management

### Current Pay Period

```typescript
interface PayPeriod {
  type: string;          // e.g., "BiWeekly", "Weekly", "SemiMonthly"
  periodStart: string;
  periodEnd: string;
  daysRemaining: number;
}
```

**API:** `GET /api/v1/time-tracking/pay-period`

### Pay Period Settings (Admin Only)

**API:** `PUT /api/v1/time-tracking/pay-period/settings`

Body: `{ type: string, anchorDate?: string }`

The anchor date sets the reference point for calculating pay period boundaries. Admin only.

### Period Locking (Admin/Manager)

**API:** `POST /api/v1/time-tracking/lock-period`

Locks all time entries within a pay period, preventing further edits. Sets `IsLocked = true` on affected entries. Returns the count of locked entries.

---

## 12. Overtime Rules

Configurable overtime calculation rules for labor cost computation.

### OvertimeRule Model

```typescript
interface OvertimeRule {
  id: number;
  name: string;
  dailyThresholdHours: number;        // e.g., 8
  weeklyThresholdHours: number;       // e.g., 40
  overtimeMultiplier: number;         // e.g., 1.5
  doubletimeThresholdDailyHours: number | null;   // e.g., 12
  doubletimeThresholdWeeklyHours: number | null;  // e.g., 60
  doubletimeMultiplier: number;       // e.g., 2.0
  isDefault: boolean;
  applyDailyBeforeWeekly: boolean;    // Daily OT calculated first
}
```

### Overtime Breakdown

```typescript
interface OvertimeBreakdown {
  regularHours: number;
  overtimeHours: number;
  doubletimeHours: number;
  regularCost: number;
  overtimeCost: number;
  doubletimeCost: number;
  totalCost: number;
  dailyBreakdown: DailyOvertimeDetail[];
}
```

### API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/time-tracking/overtime/{userId}?weekOf=YYYY-MM-DD` | Admin, Manager | Get overtime breakdown for a user/week |
| `GET` | `/api/v1/time-tracking/overtime-rules` | Admin, Manager | List all overtime rules |
| `POST` | `/api/v1/time-tracking/overtime-rules` | Admin | Create new overtime rule |

---

## 13. Shift Assignments

Admin-managed shift assignments for employees.

### ShiftAssignment Model

```typescript
interface ShiftAssignment {
  id: number;
  userId: number;
  userName: string;
  shiftId: number;
  shiftName: string;
  effectiveFrom: string;
  effectiveTo: string | null;         // null = indefinite
  shiftDifferentialRate: number | null; // e.g., 1.50 per hour
  notes: string | null;
}
```

### API

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/admin/shift-assignments` | Admin | List shift assignments (filterable by userId) |
| `POST` | `/api/v1/admin/shift-assignments` | Admin | Create shift assignment |
| `DELETE` | `/api/v1/admin/shift-assignments/{id}` | Admin | Delete shift assignment |

---

## 14. API Endpoints (Complete)

### Time Entries

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/time-tracking/entries` | User | List time entries |
| `POST` | `/api/v1/time-tracking/entries` | User | Create manual time entry |
| `PATCH` | `/api/v1/time-tracking/entries/{id}` | User | Update time entry |
| `DELETE` | `/api/v1/time-tracking/entries/{id}` | User | Soft-delete time entry |
| `PATCH` | `/api/v1/time-tracking/entries/{id}/correct` | Admin, Manager | Correct with audit trail |

#### GET /entries Query Parameters

| Param | Type | Description |
|-------|------|-------------|
| `userId` | int | Filter by user (admin sees all, regular users see own) |
| `jobId` | int | Filter by linked job |
| `from` | DateOnly | Start date filter |
| `to` | DateOnly | End date filter |

### Timer

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/v1/time-tracking/timer/start` | User | Start a timer |
| `POST` | `/api/v1/time-tracking/timer/stop` | User | Stop running timer |

### Clock Events

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/time-tracking/clock-events` | User | List clock events |
| `POST` | `/api/v1/time-tracking/clock-events` | User | Create clock event |
| `GET` | `/api/v1/time-tracking/clock-status` | User | Current clock status |

### Pay Period

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/time-tracking/pay-period` | User | Get current pay period |
| `PUT` | `/api/v1/time-tracking/pay-period/settings` | Admin | Update pay period settings |
| `POST` | `/api/v1/time-tracking/lock-period` | Admin, Manager | Lock a pay period |

### Corrections

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/time-tracking/corrections` | Admin, Manager | List correction logs |

### Overtime

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/time-tracking/overtime/{userId}` | Admin, Manager | Overtime breakdown |
| `GET` | `/api/v1/time-tracking/overtime-rules` | Admin, Manager | List rules |
| `POST` | `/api/v1/time-tracking/overtime-rules` | Admin | Create rule |

### Shift Assignments

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/admin/shift-assignments` | Admin | List assignments |
| `POST` | `/api/v1/admin/shift-assignments` | Admin | Create assignment |
| `DELETE` | `/api/v1/admin/shift-assignments/{id}` | Admin | Delete assignment |

---

## 15. Entity Models

### TimeEntry Entity

```csharp
public class TimeEntry : BaseAuditableEntity
{
    int? JobId;
    int UserId;
    DateOnly Date;
    int DurationMinutes;
    string? Category;
    string? Notes;
    DateTimeOffset? TimerStart;
    DateTimeOffset? TimerStop;
    bool IsManual;
    bool IsLocked;
    string? AccountingTimeActivityId;  // QB sync reference
    // Operation-level tracking
    int? OperationId;
    TimeEntryType EntryType;           // Default: Run
    // Costing
    decimal LaborCost;
    decimal BurdenCost;
    // Navigation
    Job? Job;
    Operation? Operation;
}
```

### TimeEntry Response Model (Frontend)

```typescript
interface TimeEntry {
  id: number;
  jobId: number | null;
  jobNumber: string | null;
  userId: number;
  userName: string;
  date: Date;
  durationMinutes: number;
  category: string | null;
  notes: string | null;
  timerStart: Date | null;
  timerStop: Date | null;
  isManual: boolean;
  isLocked: boolean;
  createdAt: Date;
}
```

---

## 16. Status & Validation Rules

### Time Entry Validation

| Rule | Enforcement |
|------|-------------|
| `date` is required | `Validators.required` on FormControl |
| `hours` must be 0-24 | `Validators.min(0)`, `Validators.max(24)` |
| `minutes` must be 0-59 | `Validators.min(0)`, `Validators.max(59)` |
| Total duration must be positive | Client-side check: `duration <= 0` rejects save |
| Only one active timer per user | Server-side enforcement |
| Locked entries cannot be edited | Client-side (`isEditable`) and server-side check |
| Past entries cannot be edited (before today) | Client-side check in `isEditable()` |

### Timer Rules

| Rule | Description |
|------|-------------|
| One timer at a time | Starting a timer when one is already running should stop the existing one (server-side) |
| Timer creates a TimeEntry | `IsManual = false`, `TimerStart` set, `TimerStop` null |
| Stopping calculates duration | `DurationMinutes = (TimerStop - TimerStart) in minutes` |

### Locking Rules

| Rule | Description |
|------|-------------|
| Admin/Manager can lock pay periods | Bulk `IsLocked = true` on entries within period |
| Locked entries show lock icon | No delete/edit actions available |

### Correction Rules

| Rule | Description |
|------|-------------|
| Reason is mandatory | `CorrectTimeEntryRequest.reason` is required |
| Only Admin/Manager can correct | `[Authorize(Roles = "Admin,Manager")]` |
| Original values are preserved | Full snapshot stored in `TimeCorrectionLog` |
| Correction is an update, not a replacement | Only changed fields are modified |

---

## 17. Known Limitations

1. **No inline editing of time entries.** Entries can only be deleted from the main UI. Editing requires the admin correction flow (admin/manager role). There is no "edit" action button for regular users.

2. **No update dialog for existing entries.** The `UpdateTimeEntryRequest` model and `PATCH /entries/{id}` endpoint exist on the service but are not exposed in the main UI component.

3. **Timer does not auto-refresh elapsed display.** The `getTimerElapsed()` method calculates elapsed time on each call but is not driven by an interval timer. The displayed elapsed time in the header button updates on re-render (e.g., when Angular's change detection runs).

4. **Category options are hardcoded in the component.** While the options are i18n-ready, they are not loaded from the `reference_data` table. Adding new categories requires a code change.

5. **No pagination on the entries list.** All entries matching the date filter are loaded at once. For users with large volumes of time entries, this could be slow. The API returns a flat `List<TimeEntry>`, not a paginated response.

6. **Job linking is available only via API.** The manual entry dialog and timer start dialog do not include a job picker. The `jobId` field on `CreateTimeEntryRequest` and `StartTimerRequest` exists but is not surfaced in the UI. Job-linked time entries are typically created from the kanban board or shop floor.

7. **Clock events are not displayed on the time tracking page.** The service has `getClockEvents()` and `createClockEvent()` methods, but the time tracking component does not render them. Clock events are consumed by the shop floor kiosk display.

8. **Overtime breakdown is not shown on the employee time tracking page.** The overtime API endpoints exist and are accessible to Admin/Manager roles, but there is no UI component on the main time tracking page for viewing overtime calculations.

9. **Shift assignments are managed via admin routes.** The `TimeTrackingService` exposes shift assignment methods, but they call the `/api/v1/admin/shift-assignments` endpoint and are not part of the employee self-service view.

10. **Pay period information is not displayed.** The service has `getCurrentPayPeriod()` but the time tracking component does not show pay period boundaries or remaining days.

11. **Date filter does not default to current pay period.** Both date filters start as null, meaning all entries are loaded. There is no automatic scoping to the current pay period.

12. **QuickBooks sync reference.** The `AccountingTimeActivityId` field on `TimeEntry` is reserved for QuickBooks time activity sync but is not surfaced in the UI.
