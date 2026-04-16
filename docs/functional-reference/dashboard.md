# Dashboard — Functional Reference

## Overview

The Dashboard is the default landing page for all authenticated users. It provides a high-level operational summary of the manufacturing environment: active jobs, overdue items, time logged, team workload, upcoming deadlines, planning cycle progress, open sales orders, and job margins. The dashboard is fully customizable -- users can rearrange, add, and remove widgets via a drag-and-drop GridStack grid, and layout preferences persist per user.

Three viewing modes are available: the standard widget grid, a distraction-free Focus Mode showing only essential tasks, and a full-screen Ambient Mode designed for wall-mounted displays or idle monitoring.

---

## Route

| Property | Value |
|----------|-------|
| Path | `/dashboard` |
| Component | `DashboardComponent` |
| Route file | `features/dashboard/dashboard.routes.ts` |
| Lazy loaded | Yes, via `loadChildren` in `app.routes.ts` |
| Guards | `authGuard`, `mobileRedirectGuard` (inherited from parent layout route) |
| Default route | `/` redirects to `/dashboard` |
| Access | All authenticated roles (no role restriction on the route itself) |

The dashboard accepts an optional query parameter `?focus=true` to activate Focus Mode, persisted in `UserPreferencesService` under the key `dashboard:focusMode`.

---

## Page Layout

The dashboard page has the following vertical structure:

1. **Page Header** -- Title ("Dashboard"), subtitle, context label ("Production"), and action buttons (Focus Mode, Ambient, Export, Customize).
2. **Edit Bar** -- Conditionally shown when edit mode is active. Contains drag hint text, Add Widget button (with dropdown), and Reset Layout button.
3. **Getting Started Banner** -- Conditionally shown for new installations until setup steps are completed or the banner is dismissed.
4. **KPI Chips Row** -- Three `KpiChipComponent` instances displaying Active Jobs, Overdue Jobs, and Hours Logged.
5. **Widget Grid** -- GridStack-powered 12-column grid containing all active widgets.

When Focus Mode is active, items 3-5 are replaced by the `FocusModeComponent`.

When Ambient Mode is active, a full-screen overlay (`AmbientModeComponent`) covers the entire page.

### Component File Structure

| File | Purpose |
|------|---------|
| `dashboard.component.ts` | Main smart component; loads data, manages grid, handles modes |
| `dashboard.component.html` | Template with conditional rendering for all modes |
| `dashboard.component.scss` | Layout, buttons, edit bar, grid overrides, mobile styles |

---

## KPI Chips

Three KPI chips are rendered in a horizontal flex row (wraps on mobile). Each uses the shared `KpiChipComponent`.

### Active Jobs

| Property | Value |
|----------|-------|
| Value | `kpis.activeCount` (integer) |
| Label | "Active" (i18n key: `dashboard.active`) |
| Change indicator | `kpis.activeChange` -- number of jobs completed this week; prefixed with `+` if positive |
| Change direction | `up` |

**Calculation (backend):** Count of all non-archived jobs on the default production track type.

### Overdue Jobs

| Property | Value |
|----------|-------|
| Value | `kpis.overdueCount` (integer) |
| Label | "Overdue" (i18n key: `dashboard.overdue`) |
| Value color | `warn` (renders in warning color) |
| Change indicator | `kpis.overdueChange` -- currently always `0` (placeholder) |
| Change direction | `down` |

**Calculation (backend):** Count of active jobs whose `DueDate` is before today (UTC).

### Hours Logged

| Property | Value |
|----------|-------|
| Value | `kpis.totalHours` (string, e.g. "12.5h" or "45m") |
| Label | "Hours" (i18n key: `dashboard.hours`) |
| Change indicator | `kpis.hoursStatus` -- "up" if hours > 0, otherwise "neutral" |
| Change direction | `up` |

**Calculation (backend):** Sum of `DurationMinutes` from all `TimeEntry` records within the current ISO week (Monday to Sunday), converted to hours. If less than 60 minutes total, displayed in minutes (e.g. "45m").

### KPI Response Model

```csharp
public record DashboardKPIsResponseModel(
    int ActiveCount,
    int ActiveChange,     // Jobs completed this week
    int OverdueCount,
    int OverdueChange,    // Currently always 0
    string TotalHours,    // Formatted string: "12.5h" or "45m"
    string HoursStatus);  // "up" | "neutral"
```

---

## Widget Grid

### GridStack Configuration

The widget grid uses the [GridStack](https://gridstackjs.com/) library, dynamically imported on first render.

| Setting | Value |
|---------|-------|
| Columns | 12 (desktop), 6 (tablet: 768-1024px), 1 (mobile: < 768px) |
| Cell height | 60px |
| Margin | 4px |
| Animation | Enabled |
| Float | Disabled (widgets pack upward) |
| Drag/Resize | Disabled by default; enabled in edit mode |

GridStack is imported lazily (`await import('gridstack')`) to keep it out of the main bundle.

A `ResizeObserver` monitors the grid container width and dynamically adjusts column count for responsive behavior.

### Widget Registry

All available widgets are defined in `models/widget-registry.ts` as the `WIDGET_REGISTRY` constant array. Each entry is a `DashboardWidgetConfig`:

```typescript
interface DashboardWidgetConfig {
  id: string;           // Unique identifier
  title: string;        // Display title
  icon: string;         // Material icon name
  component: string;    // Switch-case key for rendering
  defaultX: number;     // Default grid column position
  defaultY: number;     // Default grid row position
  defaultW: number;     // Default width in grid columns
  defaultH: number;     // Default height in grid rows
  minW?: number;        // Minimum width
  minH?: number;        // Minimum height
}
```

### Default Widget Layout (3x3 Grid)

| Row | Position 0-3 | Position 4-7 | Position 8-11 |
|-----|-------------|-------------|---------------|
| Row 0 (y=0) | Today's Tasks (4x4) | Jobs by Stage (4x4) | Team Load (4x4) |
| Row 1 (y=4) | Deadlines (4x4) | Activity (4x4) | Margin Summary (4x4) |
| Row 2 (y=8) | Cycle Progress (4x4) | Open Orders (4x4) | End of Day (4x4) |

All widgets default to 4 columns wide and 4 rows tall, filling the 12-column grid in three equal columns per row.

### Widget Wrapper

Every widget is rendered inside `<app-dashboard-widget>`, the shared `DashboardWidgetComponent`, which provides the widget shell (title bar with icon, content projection area). The `widgetKey` input is passed for preference persistence.

---

## Widgets

### Today's Tasks

| Property | Value |
|----------|-------|
| ID | `todays-tasks` |
| Component | `TodaysTasksWidgetComponent` |
| Icon | `task_alt` |
| Min size | 2w x 2h |
| Data source | `DashboardData.tasks` (from main dashboard API) |

**What it shows:**

- A priority-sorted list of tasks (jobs) for the current day.
- Tasks are sorted by status priority: overdue first, then active, upcoming, completed.
- Each task row displays: time slot, colored bar (stage color), title, job number, assignee avatar, and status badge.
- An overdue banner appears at the top when any tasks have `statusColor === 'overdue'`, showing the count.
- Each task has a "View Job" icon button that opens the `JobDetailDialogComponent` via `DetailDialogService`.
- A "Top 3 for Tomorrow" section appears at the bottom if the user has saved tomorrow's priorities (stored in user preferences under key `dashboard:top3-tomorrow`).

**Empty state:** Shows `EmptyStateComponent` with icon `task_alt` and message "No tasks today".

**Task model:**

```typescript
interface DashboardTask {
  id: number;
  time: string;              // e.g. "8:00a", "8:30a"
  title: string;
  jobNumber: string;
  barColor: string;          // Stage color hex
  assignee: { initials: string; color: string };
  status: string;            // "LATE", "ACTIVE", "NEXT", "FINISHING"
  statusColor: 'active' | 'upcoming' | 'overdue' | 'completed';
}
```

**Backend status derivation:** Status is derived from the job's position in the production pipeline:
- `LATE` (overdue) -- due date is before today
- `NEXT` (upcoming) -- job is in the first third of stages
- `ACTIVE` -- job is in the middle third
- `FINISHING` -- job is in the final third

Display times are generated sequentially starting at 8:00 AM with 30-minute increments per task.

---

### Jobs by Stage

| Property | Value |
|----------|-------|
| ID | `jobs-by-stage` |
| Component | `JobsByStageWidgetComponent` |
| Icon | `bar_chart` |
| Min size | 2w x 3h |
| Data source | `DashboardData.stages` (from main dashboard API) |

**What it shows:**

A horizontal bar chart showing the distribution of active jobs across production stages. Each row displays the stage name, a proportional bar filled with the stage color, and the numeric count.

Bar width is calculated as `(count / maxCount) * 100%`, where `maxCount` is the highest job count across all stages (minimum 1 to prevent division by zero).

**Stage model:**

```typescript
interface StageCount {
  label: string;    // Stage name
  count: number;    // Jobs in this stage
  color: string;    // Stage color hex
  maxCount: number; // Max across all stages (for bar scaling)
}
```

---

### Team Load

| Property | Value |
|----------|-------|
| ID | `team-load` |
| Component | `TeamLoadWidgetComponent` |
| Icon | `groups` |
| Min size | 2w x 3h |
| Data source | `DashboardData.team` (from main dashboard API) |

**What it shows:**

A workload bar chart per team member. Each row shows the member's avatar (via `AvatarComponent`), name, a proportional bar colored with their avatar color, and the numeric task count. Members are sorted by task count descending.

**Team member model:**

```typescript
interface TeamMember {
  initials: string;
  name: string;      // "FirstName LastName"
  color: string;     // Avatar color hex
  taskCount: number;
  maxTasks: number;  // max(taskCount, 5) -- for bar scaling
}
```

**Backend:** Team data is derived by grouping active jobs by `AssigneeId`. Only assigned jobs contribute. `maxTasks` is set to `max(actualCount, 5)` to avoid visual over-scaling for users with few tasks.

---

### Deadlines

| Property | Value |
|----------|-------|
| ID | `deadlines` |
| Component | `DeadlinesWidgetComponent` |
| Icon | `event` |
| Min size | 2w x 2h |
| Data source | `DashboardData.deadlines` (from main dashboard API) |

**What it shows:**

A chronological list of upcoming job deadlines within the next 14 days. Each row shows the due date (formatted as "MMM d", e.g. "Apr 16"), job number, and description (with truncation tooltip). Overdue items receive a visual `--overdue` modifier class.

**Deadline model:**

```typescript
interface DeadlineEntry {
  date: string;         // "MMM d" format
  jobNumber: string;
  description: string;  // Job title
  isOverdue: boolean;   // DueDate < today
}
```

---

### Activity

| Property | Value |
|----------|-------|
| ID | `activity` |
| Component | `ActivityWidgetComponent` |
| Icon | `history` |
| Min size | 2w x 2h |
| Data source | `DashboardData.activity` (from main dashboard API) |

**What it shows:**

The 5 most recent activity log entries across all jobs. Each entry displays a colored Material icon (based on action type), descriptive text (with rich text rendering via `RichTextPipe`), and a relative timestamp.

**Activity model:**

```typescript
interface ActivityEntry {
  icon: string;       // Material icon name
  iconColor: string;  // Hex color
  text: string;       // "John Created job #1234"
  time: string;       // "5m ago", "2h ago", "3d ago", "Mar 15"
}
```

**Backend icon mapping:**

| Action | Icon | Color |
|--------|------|-------|
| Created | `add_circle` | `#22c55e` (green) |
| StageMoved | `swap_horiz` | `#3b82f6` (blue) |
| FieldChanged | `edit` | `#f59e0b` (amber) |
| Assigned | `person_add` | `#8b5cf6` (purple) |
| Unassigned | `person_remove` | `#94a3b8` (slate) |
| SubtaskAdded | `checklist` | `#06b6d4` (cyan) |
| SubtaskCompleted | `task_alt` | `#22c55e` (green) |
| CommentAdded | `comment` | `#6366f1` (indigo) |
| Archived | `archive` | `#64748b` (slate) |
| Restored | `unarchive` | `#f97316` (orange) |

**Relative time formatting:**
- < 1 min: "just now"
- < 60 min: "{N}m ago"
- < 24 hours: "{N}h ago"
- < 7 days: "{N}d ago"
- Older: "MMM d" date format

---

### Margin Summary

| Property | Value |
|----------|-------|
| ID | `margin-summary` |
| Component | `MarginSummaryWidgetComponent` |
| Icon | `trending_up` |
| Min size | 2w x 2h |
| Data source | `GET /api/v1/dashboard/margin-summary` (separate API call) |

**What it shows:**

Financial margin summary for jobs created in the last 30 days. Displays the average margin percentage prominently (with green/red coloring for positive/negative), plus a breakdown of revenue, cost, margin, and job count.

Revenue and cost values are formatted with the Angular `CurrencyPipe`.

**Data model:**

```typescript
interface MarginSummary {
  totalRevenue: number;
  totalCost: number;
  totalMargin: number;
  averageMarginPercentage: number;
  jobCount: number;
}
```

**Backend calculation:**

- **Revenue:** Sum of invoice line totals (quantity * unit price) from invoices linked through `Job.SalesOrderLine.SalesOrder.Invoices`.
- **Labor cost:** Time entries for each job, converted to hours and multiplied by the labor rate (from `SystemSettings.LaborRate`, default $75/hr).
- **Material cost:** Sum of purchase order line totals (ordered quantity * unit price) for each job.
- **Expense cost:** Sum of expense amounts linked to each job.
- **Total cost:** Labor + material + expense costs.
- **Margin:** Revenue minus total cost.
- **Average margin %:** Mean of per-job margin percentages (only for jobs with revenue > 0).

---

### Cycle Progress

| Property | Value |
|----------|-------|
| ID | `cycle-progress` |
| Component | `CycleProgressWidgetComponent` |
| Icon | `loop` |
| Min size | 2w x 2h |
| Data source | `PlanningService.getCurrentCycle()` (separate API call) |

**What it shows:**

Progress of the current planning cycle. Displays:
- Cycle name (links to `/planning`)
- Status label: days remaining or "Overdue" if past end date
- Progress bar with percentage and count (e.g. "3/10 (30%)")
- Up to 5 cycle entries showing completion status (check circle vs empty circle), job number, job title, and stage chip
- "More entries" link if the cycle has more than 5 entries

Uses `LoadingBlockDirective` during data fetch.

**Empty state:** Shows `EmptyStateComponent` with icon `event_note`, message "No active cycle", and a "Start Planning" action button that navigates to `/planning`.

---

### Open Orders

| Property | Value |
|----------|-------|
| ID | `open-orders` |
| Component | `OpenOrdersWidgetComponent` |
| Icon | `shopping_cart` |
| Min size | 2w x 2h |
| Data source | `GET /api/v1/dashboard/open-orders` (separate API call) |

**What it shows:**

A summary of open sales orders across three statuses: Confirmed, In Production, and Partially Shipped. Displays the total order count prominently, followed by a per-status breakdown, and a "View all orders" link to `/sales-orders`.

**Data model:**

```typescript
interface OpenOrderSummary {
  totalOrders: number;
  confirmedCount: number;
  inProductionCount: number;
  partiallyShippedCount: number;
  totalValue: number;
}
```

**Backend:** Queries `SalesOrders` with status in `[Confirmed, InProduction, PartiallyShipped]`, includes lines, and sums `LineTotal` for total value.

---

### End of Day

| Property | Value |
|----------|-------|
| ID | `eod-prompt` |
| Component | `EodPromptWidgetComponent` |
| Icon | `nightlight` |
| Min size | 2w x 2h |
| Data source | `UserPreferencesService` (client-side only) |

**What it shows:**

A daily reflection prompt asking users to note their top 3 priorities for tomorrow. Two states:

1. **Form state:** A textarea (`<app-textarea>`) with a Save button. The label comes from i18n key `dashboard.eodPrompt`.
2. **Saved state:** Displays the saved text with a green check circle icon, plus an Edit button to modify.

**Persistence:** Saved to `UserPreferencesService` under a date-keyed key: `eod:YYYY-MM-DD` (today's date). Each day starts fresh.

---

## Edit Mode

### Entering Edit Mode

Click the "Customize" button in the page header. The button toggles to "Done Editing" (with check icon) and gets the `btn--primary` class.

### Edit Bar

When editing, a `dashboard-edit-bar` appears below the header:
- **Left side:** Drag indicator icon + "Drag widgets to rearrange" hint text.
- **Right side:** "Add Widget" button (with dropdown menu) and "Reset Layout" button.

### Drag and Drop

In edit mode, GridStack's `enableMove` and `enableResize` are set to `true`, allowing:
- **Drag:** Reposition widgets by dragging.
- **Resize:** Resize widgets by dragging corner/edge handles.

Widget changes fire GridStack's `change` event, which triggers `saveLayout()`.

### Adding Widgets

The "Add Widget" button opens a dropdown menu listing all widgets not currently on the grid (computed as `availableWidgets`). Clicking a widget:
1. Adds its ID to `activeWidgetIds`.
2. Closes the menu.
3. After DOM update (`requestAnimationFrame`), registers the new element with GridStack via `makeWidget()`.
4. Saves the layout.

The button is disabled when all widgets are already active.

### Removing Widgets

Each widget shows a close button (X icon, top-right corner) during edit mode. Clicking it:
1. Removes the element from GridStack via `removeWidget()`.
2. Removes the ID from `activeWidgetIds`.
3. Saves the layout.

### Reset Layout

The "Reset Layout" button:
1. Restores all widgets (`activeWidgetIds` set to full registry).
2. Removes the saved layout from user preferences.
3. Destroys and reinitializes the GridStack grid with default positions.

### Exiting Edit Mode

Click "Done Editing". This:
1. Sets `editing` to `false`.
2. Disables GridStack move and resize.
3. Closes the add menu if open.
4. Saves the current layout.

---

## Focus Mode

### Entering Focus Mode

Click the "Focus Mode" button in the page header, or navigate to `?focus=true`. The preference is also persisted in `UserPreferencesService` under key `dashboard:focusMode`.

### What it Shows

Focus Mode replaces the entire widget grid and KPI row with a simplified, centered layout (max-width 800px) containing three sections:

1. **My Tasks** -- Renders the `TodaysTasksWidgetComponent` with the same task data.
2. **Open Orders** -- Renders the `OpenOrdersWidgetComponent` (makes its own API call).
3. **End of Day** -- Renders the `EodPromptWidgetComponent`.

A header bar shows the Focus Mode icon, title, and a close button to exit.

### Exiting Focus Mode

Click the close icon in the focus header, or click the Focus Mode button again in the page header. Navigates to `?focus=null`, removing the query param.

Focus Mode and Ambient Mode are mutually exclusive: activating Focus Mode deactivates Ambient Mode if it is on.

---

## Ambient Mode

### Purpose

Ambient Mode is a full-screen, dark overlay designed for wall-mounted monitors, kiosk displays, or idle monitoring. It shows essential metrics at a glance without interactive controls.

### Entering Ambient Mode

Click the "Ambient" button in the page header. This sets the `ambientMode` signal to `true`, rendering the `AmbientModeComponent` overlay.

### What it Shows

A fixed-position overlay (z-index `$z-loading`) with dark background and white text:

1. **Clock** -- Large time display (e.g. "02:30 PM") updated every second, with full date below (e.g. "Wednesday, April 16").
2. **KPI Summary** -- Three large KPI values: Active Jobs, Overdue (in warning color), Hours Today.
3. **Upcoming Deadlines** -- Up to 5 deadline entries showing job number, description, and date. Overdue items get a red left border.
4. **Exit Hint** -- Bottom text: "Press Escape or click anywhere to exit."

### Data Refresh

Ambient Mode fetches fresh dashboard data every 60 seconds (via `setInterval`). The clock updates every second.

### Exiting Ambient Mode

- Press `Escape` key
- Click anywhere on the overlay

Both actions emit the `exit` output, setting `ambientMode` to `false` in the parent.

### Cleanup

On destroy, both intervals are cleared and both `document` event listeners (`keydown`, `click`) are removed.

---

## Getting Started Banner

The `GettingStartedBannerComponent` is a guided onboarding checklist shown to new users. It appears between the KPI row and the widget grid.

### Visibility Conditions

The banner is visible when:
- The user has not dismissed it (checked via `dashboard:getting-started-dismissed` preference)
- Fewer than 3 of the 4 setup steps are complete

### Setup Steps

| Step | Route | Done condition |
|------|-------|----------------|
| Create your first job | `/kanban` | `activeCount > 0` |
| Add a customer | `/customers` | `stages.length > 0` |
| Set up track types | `/admin/track-types` | `stages.length > 3` |
| Explore reports | `/reports` | Always `false` (manual exploration) |

Each step is a clickable button that navigates to the associated route. Completed steps show a green check circle; incomplete steps show an empty circle with a forward arrow.

### Dismissal

Clicking the close button sets the `dashboard:getting-started-dismissed` preference to `true` and hides the banner permanently.

---

## API Endpoints

### GET /api/v1/dashboard

Main dashboard data endpoint. Returns all KPIs, tasks, stages, team load, activity, and deadlines in a single response.

**Controller:** `DashboardController.GetDashboard()`
**Handler:** `GetDashboardHandler` (uses `IDashboardRepository`)

**Response shape:**

```json
{
  "tasks": [
    {
      "id": 42,
      "time": "8:00a",
      "title": "Machine housing bracket",
      "jobNumber": "JOB-0042",
      "barColor": "#3b82f6",
      "assignee": { "initials": "DH", "color": "#8b5cf6" },
      "status": "ACTIVE",
      "statusColor": "active"
    }
  ],
  "stages": [
    { "label": "Materials Ordered", "count": 5, "color": "#f59e0b", "maxCount": 12 }
  ],
  "team": [
    { "initials": "DH", "name": "Daniel Hokanson", "color": "#8b5cf6", "taskCount": 8, "maxTasks": 8 }
  ],
  "activity": [
    { "icon": "add_circle", "iconColor": "#22c55e", "text": "Daniel Created job #JOB-0042", "time": "5m ago" }
  ],
  "deadlines": [
    { "date": "Apr 20", "jobNumber": "JOB-0042", "description": "Machine housing bracket", "isOverdue": false }
  ],
  "kpis": {
    "activeCount": 24,
    "activeChange": 3,
    "overdueCount": 2,
    "overdueChange": 0,
    "totalHours": "32.5h",
    "hoursStatus": "up"
  }
}
```

**Data source (repository):**

The `DashboardRepository` fetches:
1. The default active `TrackType` with its active stages
2. All non-archived jobs on that track (with `CurrentStage` and `Customer` includes)
3. The 5 most recent `JobActivityLog` entries
4. User info for all referenced assignees and activity users

**Polling:** The frontend polls this endpoint every 5 minutes (`POLL_INTERVAL_MS = 300000`). The initial load uses `LoadingService.track()` for a global overlay; subsequent polls are silent.

---

### GET /api/v1/dashboard/open-orders

Sales order summary for the Open Orders widget.

**Controller:** `DashboardController.GetOpenOrders()`
**Handler:** `GetOpenOrdersSummaryHandler`

**Response shape:**

```json
{
  "totalOrders": 12,
  "confirmedCount": 5,
  "inProductionCount": 4,
  "partiallyShippedCount": 3,
  "totalValue": 145000.00
}
```

**Data source:** Queries `SalesOrders` with status in `[Confirmed, InProduction, PartiallyShipped]`, includes lines for value summation.

---

### GET /api/v1/dashboard/margin-summary

Financial margin data for the Margin Summary widget.

**Controller:** `DashboardController.GetMarginSummary()`
**Handler:** `GetMarginSummaryHandler`

**Response shape:**

```json
{
  "totalRevenue": 250000.00,
  "totalCost": 180000.00,
  "totalMargin": 70000.00,
  "averageMarginPercentage": 28.5,
  "jobCount": 15
}
```

**Data source:** Jobs created in the last 30 days. Revenue from linked invoices, costs from time entries (at configured labor rate), purchase order lines, and expenses.

---

### GET /api/v1/dashboard/layout

Returns the default widget layout based on the authenticated user's highest-privilege role. Used for initial layout suggestions.

**Controller:** `DashboardController.GetDefaultLayout()`
**Handler:** `GetDefaultDashboardLayoutHandler`

**Response shape:**

```json
{
  "role": "Admin",
  "visibleWidgets": ["tasks", "stages", "team", "activity", "deadlines", "cycle", "orders", "eod", "margin"],
  "columns": 3
}
```

**Role-based defaults:**

| Role | Widgets | Columns |
|------|---------|---------|
| Admin | All 9 | 3 |
| Manager | All except `eod` | 3 |
| PM | tasks, stages, team, deadlines, cycle, orders, eod | 3 |
| OfficeManager | tasks, orders, deadlines, activity, margin | 3 |
| Engineer | tasks, stages, deadlines, cycle, eod | 3 |
| ProductionWorker | tasks, deadlines | 2 |

The handler selects the highest-privilege role the user has (Admin > Manager > PM > OfficeManager > Engineer > ProductionWorker).

---

## User Preferences

Dashboard layout and state are persisted via `UserPreferencesService` (localStorage with debounced API PATCH).

### Preference Keys

| Key | Type | Purpose |
|-----|------|---------|
| `dashboard:layout:v5` | `DashboardSavedLayout` | Widget positions, sizes, and visibility |
| `dashboard:focusMode` | `boolean` | Whether Focus Mode is the default view |
| `dashboard:getting-started-dismissed` | `boolean` | Whether the onboarding banner is hidden |
| `dashboard:top3-tomorrow` | `string[]` | Top 3 priorities for tomorrow (Today's Tasks widget) |
| `eod:YYYY-MM-DD` | `string` | End of Day prompt response for a specific date |

### Layout Persistence

The saved layout model:

```typescript
interface DashboardSavedLayout {
  widgets: DashboardWidgetLayout[];
}

interface DashboardWidgetLayout {
  id: string;  // Widget ID from registry
  x: number;   // Grid column position
  y: number;   // Grid row position
  w: number;   // Width in grid columns
  h: number;   // Height in grid rows
}
```

**Save triggers:** Any widget reposition or resize during edit mode, adding a widget, removing a widget.

**Load behavior:** On grid initialization, the component checks for a saved layout. If found, it sets `activeWidgetIds` to only the saved widget IDs and applies saved positions/sizes via `grid.update()` after a `requestAnimationFrame` delay to ensure DOM readiness.

---

## Data Export

The "Export" button in the page header generates a CSV file containing:

1. KPI values (Active Jobs, Overdue Jobs, Total Hours)
2. Stage breakdown (stage name and count)
3. Team load (member name and task count)
4. Deadlines (date, job number, title, overdue status)

The file is named `dashboard-YYYY-MM-DD.csv` and downloaded via a programmatic blob URL.

---

## Responsive Behavior

### Breakpoints

| Width | Grid columns | Behavior |
|-------|-------------|----------|
| >= 1024px | 12 | Full 3-column layout |
| 768-1023px | 6 | Widgets stack into 2 or fewer columns |
| < 768px | 1 | Single column, widgets stack vertically |

Column switching is handled by a `ResizeObserver` on the grid container, not by CSS media queries, since GridStack requires programmatic column changes.

### Mobile-Specific Styles

- **KPI chips:** Stack vertically (`flex-direction: column`)
- **Edit bar:** Stacks vertically; actions row takes full width with right alignment
- **Add widget menu:** Anchors to right edge instead of left
- **Focus Mode:** Content naturally fills single column (max-width: 800px already constrains)
- **Ambient Mode:** Full-screen overlay works at all sizes; content centers naturally

### Cleanup

On component destroy:
- `ResizeObserver` is disconnected
- GridStack instance is destroyed (with `false` to preserve DOM)
- Polling interval is cleaned up via `takeUntilDestroyed`
