# Backlog

## Overview

The Backlog is the prioritized queue of all active (non-archived) jobs across all track types. It provides a flat, filterable view of every job in the system, complementing the kanban board's stage-grouped layout. Where the kanban board organizes jobs by workflow stage within a single track type, the backlog shows everything at once -- making it the primary tool for triaging, searching, and bulk-reviewing work.

Jobs created in the backlog use the same job entity and endpoints as the kanban board. Moving a job on the board or editing it from the backlog are equivalent operations against the same data.

## Route

| Path | Component | Lazy-loaded |
|------|-----------|-------------|
| `/backlog` | `BacklogComponent` | Yes |

**Access roles:** Admin, Manager, PM, Engineer, ProductionWorker, OfficeManager (inherited from `JobsController` authorization).

**URL state:**
- `?view=table` or `?view=card` -- controls active view mode (default: `table`; the `table` value is omitted from the URL for cleanliness).
- `?detail=job:{id}` -- opens the job detail dialog for the specified job. Set automatically when a row/card is clicked, cleared on dialog close.

The view mode preference is also persisted to `UserPreferencesService` under the key `backlog:viewMode`. On initial load, if no explicit `?view` query param is present, the saved preference is restored (defaulting to `table` if none is saved).

## Page Layout

The page is a full-height flex column with three zones:

1. **Page header** (`PageHeaderComponent`) -- title "Backlog" with subtitle, inline filter controls, view-mode toggle, and "New Job" button.
2. **Content area** -- either a `DataTableComponent` (table view) or a `BacklogCardGridComponent` (card view), filling the remaining vertical space.
3. **Job dialog** (conditional) -- the shared `JobDialogComponent` rendered when creating or editing a job.

### Toolbar Controls (left to right)

| Control | Type | Purpose |
|---------|------|---------|
| Search | `InputComponent` | Free-text filter on job number and title |
| Track | `SelectComponent` | Filter by track type (Production, R&D, etc.) |
| Priority | `SelectComponent` | Filter by priority level |
| Assignee | `SelectComponent` | Filter by assigned user |
| View toggle | Two icon buttons | Switch between table and card views |
| New Job | Button | Opens the job creation dialog |

## Filters

All filters operate client-side on the full job list loaded at page init. The backlog loads all non-archived jobs in a single request, then the `filteredJobs` computed signal applies each active filter in sequence.

### Search

Free-text, case-insensitive match against `job.title` and `job.jobNumber`. Filters as the user types (reactive via `FormControl.valueChanges`).

### Track Type

Dropdown populated from the `TrackType[]` loaded via `KanbanService.getTrackTypes()`. Selecting a track type filters to jobs whose current stage name matches one of that track type's stages. The "All Tracks" option (value `null`) shows all jobs.

### Priority

Static options derived from the shared `PRIORITIES` constant: Critical, High, Medium, Low. The "All Priorities" option shows all jobs.

### Assignee

Dropdown populated from `UserRef[]` loaded via `KanbanService.getUsers()`. Options display the user's full name; filtering matches on the user's initials (the `assigneeInitials` field on `KanbanJob`). The "All Assignees" option shows all jobs.

## View Modes

The backlog supports two view modes, toggled via icon buttons in the header toolbar.

### Table View (default)

Renders a full `DataTableComponent` with the `tableId` of `"backlog"`. Supports all standard DataTable features: column sorting (click header), per-column filtering, column visibility/reorder via gear icon, right-click context menu, and preference persistence.

Rows are clickable (`[clickableRows]="true"`). Clicking a row opens the job detail dialog.

**Row styling:**
- Overdue jobs receive the `row--overdue` CSS class.
- The currently selected job (detail dialog open) receives the `row--selected` class (primary-light background).
- Each row receives a `--row-tint` CSS custom property set to the job's stage color.

**Empty state:** Icon `search_off` with message "No jobs match your filters."

### Card View

Renders a `BacklogCardGridComponent` -- a responsive CSS grid of job cards. The grid uses `auto-fill` with a minimum card width of 280px, collapsing to a single column on mobile.

Clicking a card opens the same job detail dialog as table rows.

**Empty state:** Centered icon `search_off` with "No jobs match your filters."

### View Toggle Behavior

The two icon buttons in the toolbar use `icon-btn--active` styling on the current mode. Switching modes:
1. Navigates to the same route with `?view=card` or removes the `view` param for table mode.
2. Persists the choice to `UserPreferencesService` under `backlog:viewMode`.

## Table Columns

| Field | Header | Sortable | Filterable | Type | Width | Notes |
|-------|--------|----------|------------|------|-------|-------|
| `jobNumber` | Job # | Yes | Yes (text) | text | 80px | Monospace, uppercase, bold |
| `title` | Title | Yes | Yes (text) | text | auto | Truncated at 360px max-width |
| `stageName` | Stage | Yes | Yes (enum) | enum | 100px | Rendered as a colored chip using the stage's color |
| `priorityName` | Priority | Yes | Yes (enum) | enum | 90px | Colored dot + text label; options: Critical, High, Medium, Low |
| `assignee` | Assignee | No | Yes (enum) | enum | 60px | Avatar component (initials + color); em-dash if unassigned |
| `customerName` | Customer | Yes | Yes (enum) | enum | 120px | Plain text; em-dash if none |
| `dueDate` | Due Date | Yes | Yes (date) | date | 100px | Formatted MM/dd/yyyy; overdue dates shown in red bold |

**Filter options for enum columns are derived dynamically:**
- Stage options: distinct `stageName` values from the current job list, sorted alphabetically.
- Customer options: distinct non-null `customerName` values from the current job list, sorted alphabetically.
- Assignee options: user list with initials as values and full names as labels.
- Priority options: static from the `PRIORITIES` constant.

## Card View

Each card in the `BacklogCardGridComponent` displays:

| Section | Content |
|---------|---------|
| Header row | Job number (monospace, muted) + "On Hold" warning chip if the job has active holds |
| Title | Job title, bold, truncated with ellipsis |
| Stage | Colored chip with stage name |
| Meta row | Priority dot + priority name, assignee avatar (if assigned) |
| Customer | Business icon + customer name (only shown if customer is set) |
| Footer | Calendar icon + due date in MM/dd/yyyy format (or italic "No date") |

**Card states:**
- `backlog-card--overdue` -- left border changes to error color.
- `backlog-card--selected` -- border and background highlight in primary color.

Cards are keyboard-accessible: `role="button"`, `tabindex="0"`, respond to Enter and Space key presses.

## Creating Jobs

The "New Job" button in the header toolbar opens the shared `JobDialogComponent` in `create` mode. This is the same dialog used by the kanban board. The dialog receives the current `trackTypes` list for the track type selector.

On successful save, the backlog reloads its job list via `BacklogService.getJobs()`.

## Job Detail

Clicking a row (table view) or card (card view) opens the `JobDetailDialogComponent` as a full `MatDialog` via `DetailDialogService`. This:

1. Sets the `selectedJobId` signal (used for row/card highlighting).
2. Syncs `?detail=job:{id}` to the URL.
3. Passes the `jobId` and `users` list to the dialog.

On dialog close:
- The `selectedJobId` is cleared.
- If the dialog returned an `edit` action with a `JobDetail` payload, the edit dialog (`JobDialogComponent` in `edit` mode) is opened.

**URL-driven auto-open:** On page init, after data loads, the component checks for `?detail=job:{id}` in the URL via `DetailDialogService.getDetailFromUrl()`. If present, it auto-opens the detail dialog for that job. This supports direct links and browser refresh.

## API Endpoints

The backlog feature uses endpoints from `JobsController` and `KanbanService` (for reference data).

### Jobs

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/v1/jobs?isArchived=false` | Load all active jobs for the backlog |
| `GET` | `/api/v1/jobs/{id}` | Load job detail (used by detail dialog) |
| `POST` | `/api/v1/jobs` | Create a new job |
| `PUT` | `/api/v1/jobs/{id}` | Update an existing job |

The backlog service always passes `isArchived=false`. Optional query parameters `trackTypeId`, `assigneeId`, and `search` are supported by the API but the current implementation loads all jobs and filters client-side.

### Reference Data

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/v1/track-types` | Load track types for filter dropdown |
| `GET` | `/api/v1/users` | Load users for assignee filter dropdown |

### Data Loading

On init, the component uses `forkJoin` to load jobs, track types, and users in parallel, wrapped in `LoadingService.track()` which shows the global loading overlay. Subsequent reloads (after job creation/edit) only reload the job list.
