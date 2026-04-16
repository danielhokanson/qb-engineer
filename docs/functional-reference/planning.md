# Planning Cycles

## Overview

Planning Cycles implement a sprint-style planning workflow for organizing and committing to work over a defined time period. The default cycle duration is 2 weeks (14 days), but cycles can be created with any date range.

The planning page presents a split-panel layout: a backlog of available jobs on the left, and the active cycle's committed entries on the right. Users drag jobs from the backlog into the cycle (or click the add button), then track progress through completion and cycle close-out.

Planning cycles complement the kanban board by adding a time-boxed commitment layer. While the kanban board manages workflow stages, planning cycles answer "what are we committing to finish in this period?"

## Route

| Path | Component | Lazy-loaded |
|------|-----------|-------------|
| `/planning` | `PlanningComponent` | Yes |

**Access roles:** Admin, Manager, PM, Engineer, ProductionWorker (from `PlanningCyclesController` authorization).

## Page Layout

The page is a full-height flex column with two zones:

1. **Page header** (`PageHeaderComponent`) -- title "Planning" with subtitle, a cycle selector dropdown, and a "New Cycle" button.
2. **Split panel layout** -- horizontal split with the backlog panel on the left and the cycle board on the right.

On tablet-width screens and below, the layout switches to vertical stacking: the backlog panel sits on top (max 40vh) with the cycle board below.

### Header Controls

| Control | Type | Purpose |
|---------|------|---------|
| Cycle selector | `SelectComponent` | Switch between existing cycles; options show name + status in parentheses |
| New Cycle | Button | Opens the cycle creation dialog |

## Cycle Management

### Creating a Cycle

The "New Cycle" button opens `CycleDialogComponent`, a 520px-wide dialog with the following fields:

| Field | Control | Validation | Default |
|-------|---------|------------|---------|
| Name | `InputComponent` | Required, max 100 chars | Empty |
| Start Date | `DatepickerComponent` | Required | Today |
| End Date | `DatepickerComponent` | Required | Today + 14 days |
| Goals | `TextareaComponent` | Optional, 3 rows | Empty |

The dialog calculates `durationDays` from the date range and includes it in the create request. On save, the new cycle is selected and the cycle list is refreshed.

The dialog supports the draft system via `DraftConfig` (entity type `planning-cycle`), enabling auto-save and recovery of unsaved form data.

### Editing a Cycle

The edit button (pencil icon) in the cycle panel action bar opens the same `CycleDialogComponent` pre-populated with the selected cycle's data. The edit request uses `UpdatePlanningCycleRequest` which allows partial updates (all fields optional).

### Selecting a Cycle

The cycle selector dropdown in the header lists all cycles with their status. Changing the selection loads the cycle detail via `PlanningService.getCycle(id)`. On initial page load, the component attempts to load the "current" cycle first (via `GET /api/v1/planning-cycles/current`). If no current cycle exists, it falls back to the first cycle in the list.

## Cycle Statuses

The `PlanningCycleStatus` enum defines three states:

| Status | Description | Visual | Allowed Actions |
|--------|-------------|--------|-----------------|
| `Planning` | Draft cycle, not yet started. Jobs can be committed and removed freely. | Muted chip | Activate, Edit, Commit/remove jobs |
| `Active` | Cycle is in progress. The active period between start and end dates. | Primary chip | Complete (with or without rollover), Edit, Commit/remove jobs, Mark entries complete |
| `Completed` | Cycle is finished. Read-only historical record. | Success chip | View only |

### Status Transitions

```
Planning --> Active --> Completed
```

- **Planning to Active:** Via the "Activate" button in the cycle panel action bar. Only visible when the selected cycle is in `Planning` (draft) status.
- **Active to Completed:** Via either the "Complete & Roll Over" or "Complete" button. Both require confirmation via `ConfirmDialogComponent`.

There is no backward transition. Once a cycle is activated it cannot return to draft, and once completed it cannot be reopened.

## Planning Day Flow

Day 1 of each cycle is conceptually "Planning Day" -- the time to review the backlog, set cycle goals, and commit jobs. The UI supports this through:

1. The goals field on the cycle, visible in the cycle board header when set.
2. The split-panel layout that puts the backlog alongside the cycle board for easy drag-and-drop commitment.
3. The "Activate" button that transitions the cycle from draft to active once planning is complete.

The workflow is: create a cycle in `Planning` status, commit jobs from the backlog, set goals, then activate when ready to begin work.

## Backlog Panel

The left panel (400px wide, min 320px) shows all available jobs that are not already committed to the selected cycle.

### Header

Displays the title "Backlog" and a count of filtered available jobs (e.g., "12 jobs").

### Filters

| Control | Type | Purpose |
|---------|------|---------|
| Search | `InputComponent` | Free-text filter on job number and title |
| Priority | `SelectComponent` | Filter by priority (uses `PRIORITY_FILTER_OPTIONS`) |

Filtering is client-side. Jobs already committed to the selected cycle are excluded from the backlog list before search/priority filters are applied.

### Job List

Each backlog job is rendered as a compact card showing:

| Element | Content |
|---------|---------|
| Top row | Job number (monospace, bold) + job title (truncated) |
| Bottom row | Stage chip (colored), priority dot + label, assignee avatar (if assigned) |
| Add button | Plus icon button to commit the job to the current cycle (only shown when a cycle is selected) |

### Drag and Drop

The backlog list is a CDK drop list (`id="planning-backlog"`) connected to the cycle panel drop zone (`id="planning-cycle-panel"`). Sorting within the backlog is disabled -- jobs maintain their natural order.

Dragging a job from the backlog to the cycle panel commits it to the cycle. The cycle panel highlights with a dashed primary-colored border and tinted background when receiving a drag.

### Committing Jobs

Jobs can be committed two ways:
1. **Drag and drop** -- drag from backlog list to cycle panel.
2. **Click the add button** -- the plus icon on each backlog job card.

Both call `PlanningService.commitJob(cycleId, jobId)` which POSTs to `/api/v1/planning-cycles/{id}/entries`. On success, the cycle detail is reloaded and a snackbar confirmation is shown.

### Empty State

When no jobs are available (all committed or filtered out), an `EmptyStateComponent` with the `inbox` icon and "No available jobs" message is displayed.

## Cycle Board

The right panel (`CycleBoardComponent`) displays the selected cycle's details and committed entries.

### Cycle Header

| Element | Content |
|---------|---------|
| Title | Cycle name |
| Date range | Start and end dates in MM/dd/yyyy format (monospace) |
| Days remaining | Countdown badge (warning-colored), only shown for active cycles |
| Completion count | "X / Y" completed entries (monospace) |
| Status chip | Colored chip -- muted (Planning/Draft), primary (Active), success (Completed) |

### Progress Bar

A horizontal bar showing completion percentage. The bar fill uses the success color. The percentage is displayed as a label to the right (e.g., "75%").

### Goals Section

If the cycle has goals set, they are displayed in a bordered card below the progress bar with a "GOALS" uppercase label header.

### Entry List

Committed jobs are displayed as a sortable list. Each entry card shows:

| Element | Content |
|---------|---------|
| Drag handle | `drag_indicator` icon for reordering |
| Top row | Job number (monospace, bold) + job title (truncated) |
| Bottom row | Stage chip (colored), priority label (color-coded by level), assignee name, rolled-over badge (replay icon, if applicable) |
| Actions | Complete button (checkmark outline) or completed indicator (filled green checkmark), Remove button (X icon) |

**Entry states:**
- `entry--completed` -- 60% opacity, job number and title have line-through text decoration.
- `entry--rolled-over` -- left border in warning color, replay icon badge shown.

### Drag-and-Drop Reordering

The entry list is a CDK drop list. Users can drag entries by their handle to reorder them. On drop, the component emits a `CdkDragDrop` event, and the parent component sends a `PUT /api/v1/planning-cycles/{id}/entries/order` request with the new sort order.

### Entry Actions

**Mark Complete:** Clicking the checkmark icon on an incomplete entry calls `POST /api/v1/planning-cycles/{id}/entries/{jobId}/complete`. The entry's `completedAt` timestamp is set, it visually fades (60% opacity) and gains strikethrough text. A success snackbar is shown.

**Remove from Cycle:** Clicking the X icon opens a confirmation dialog (`ConfirmDialogComponent` with `warn` severity). On confirmation, calls `DELETE /api/v1/planning-cycles/{id}/entries/{jobId}`. The job returns to the backlog. A success snackbar is shown.

### Cycle Panel Action Bar

The action bar sits above the cycle board and contains lifecycle buttons aligned to the right:

| Button | Visible When | Action |
|--------|-------------|--------|
| Edit (pencil icon) | Always | Opens cycle edit dialog |
| Activate | Cycle is in `Planning` (draft) status | Transitions to `Active` |
| Complete & Roll Over | Cycle is `Active` | Completes cycle with rollover |
| Complete | Cycle is `Active` | Completes cycle without rollover |

### Empty State

When no cycle is selected, an `EmptyStateComponent` with the `event_note` icon, "No cycle selected" message, and a "Create first cycle" action button is displayed.

## Cycle Completion

Completing an active cycle can be done in two ways:

### Complete with Rollover

The "Complete & Roll Over" button opens a confirmation dialog. On confirmation:

1. The current cycle's status changes to `Completed`.
2. A new cycle is automatically created.
3. Incomplete entries from the current cycle are copied to the new cycle with `isRolledOver = true`.
4. The UI switches to the newly created cycle.
5. A snackbar confirms the action.

The API call is `POST /api/v1/planning-cycles/{id}/complete` with `{ rolloverIncomplete: true }`. The response includes `{ newCycleId }` which the frontend uses to load and select the new cycle.

### Complete without Rollover

The "Complete" button opens a confirmation dialog with `warn` severity. On confirmation:

1. The current cycle's status changes to `Completed`.
2. Incomplete entries are not carried forward -- they remain as incomplete entries on the completed cycle and their jobs become available in the backlog again.
3. The cycle list is refreshed.
4. A snackbar confirms the action.

The API call is `POST /api/v1/planning-cycles/{id}/complete` with `{ rolloverIncomplete: false }`.

## API Endpoints

All endpoints are on the `PlanningCyclesController` at `/api/v1/planning-cycles`.

### Cycle CRUD

| Method | Path | Purpose | Response |
|--------|------|---------|----------|
| `GET` | `/api/v1/planning-cycles` | List all cycles | `PlanningCycleListItem[]` |
| `GET` | `/api/v1/planning-cycles/current` | Get the current active cycle | `PlanningCycleDetail` or `null` |
| `GET` | `/api/v1/planning-cycles/{id}` | Get cycle detail with entries | `PlanningCycleDetail` |
| `POST` | `/api/v1/planning-cycles` | Create a new cycle | `201` + `PlanningCycleDetail` |
| `PUT` | `/api/v1/planning-cycles/{id}` | Update cycle metadata | `204` |

### Cycle Lifecycle

| Method | Path | Purpose | Response |
|--------|------|---------|----------|
| `POST` | `/api/v1/planning-cycles/{id}/activate` | Transition from Planning to Active | `204` |
| `POST` | `/api/v1/planning-cycles/{id}/complete` | Complete cycle (with optional rollover) | `200` + `{ newCycleId }` |

**Complete request body:**
```json
{ "rolloverIncomplete": true }
```

### Entry Management

| Method | Path | Purpose | Response |
|--------|------|---------|----------|
| `POST` | `/api/v1/planning-cycles/{id}/entries` | Commit a job to the cycle | `204` |
| `DELETE` | `/api/v1/planning-cycles/{id}/entries/{jobId}` | Remove a job from the cycle | `204` |
| `PUT` | `/api/v1/planning-cycles/{id}/entries/order` | Reorder entries | `204` |
| `POST` | `/api/v1/planning-cycles/{id}/entries/{jobId}/complete` | Mark an entry as completed | `204` |

**Commit request body:**
```json
{ "jobId": 123 }
```

**Reorder request body:**
```json
{ "items": [{ "jobId": 1, "sortOrder": 0 }, { "jobId": 2, "sortOrder": 1 }] }
```

### Backlog Data

The planning page also loads backlog jobs via the same endpoint used by the Backlog feature:

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/v1/jobs?isArchived=false` | Load all active jobs for the backlog panel |

## Data Models

### PlanningCycle Entity

| Field | Type | Notes |
|-------|------|-------|
| `Id` | int | Primary key (from `BaseAuditableEntity`) |
| `Name` | string | Cycle name, required |
| `StartDate` | DateTimeOffset | Cycle start date |
| `EndDate` | DateTimeOffset | Cycle end date |
| `Goals` | string? | Optional cycle goals text |
| `Status` | PlanningCycleStatus | Planning, Active, or Completed |
| `DurationDays` | int | Duration in days, default 14 |
| `Entries` | ICollection | Navigation to committed entries |
| `CreatedAt`, `UpdatedAt`, `DeletedAt` | DateTimeOffset | Audit fields from `BaseAuditableEntity` |
| `CreatedBy` | int? | User who created the cycle |

### PlanningCycleEntry Entity

| Field | Type | Notes |
|-------|------|-------|
| `Id` | int | Primary key (from `BaseEntity`) |
| `PlanningCycleId` | int | FK to PlanningCycle |
| `JobId` | int | FK to Job |
| `CommittedAt` | DateTimeOffset | When the job was committed to the cycle |
| `CompletedAt` | DateTimeOffset? | When the entry was marked complete (null if incomplete) |
| `IsRolledOver` | bool | True if this entry was carried from a previous cycle |
| `SortOrder` | int | Display order within the cycle |
