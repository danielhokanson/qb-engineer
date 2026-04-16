# Calendar

## Overview

The calendar provides a visual timeline of job due dates and purchase order delivery dates. It displays all non-archived jobs plotted by their due date across month, week, and day views, with optional purchase order delivery overlays. Jobs can be filtered by track type, and clicking any job navigates to it on the kanban board.

The calendar is a read-only visualization tool -- it does not support creating or editing jobs or events directly. Its purpose is to give project managers and engineers a time-based view of upcoming work and incoming materials.

---

## Route

| Route | Component | Access |
|-------|-----------|--------|
| `/calendar` | `CalendarComponent` | All authenticated roles |

The route has a single path with no child routes or tab segments.

---

## Views

The calendar supports three views, toggled via a button group in the header.

### Month View

The default view. Displays a standard calendar grid with:

- **Weekday header row** -- Seven columns (Sun through Sat), labels localized via i18n.
- **Day cells** -- Each cell shows the day number and up to 3 job chips. Days outside the current month are dimmed (`calendar-cell--other`). Today's cell is highlighted (`calendar-cell--today`).
- **Overflow indicator** -- When a day has more than 3 jobs, a "+N more" label is shown below the visible chips.
- **PO delivery events** -- When the PO deliveries toggle is enabled, purchase order delivery chips appear below job chips in each cell.
- **Day click** -- Clicking any day cell switches to the day view for that date.

Previous/next month padding cells are included to fill the grid to complete weeks.

### Week View

Displays seven columns for the current week (Sunday through Saturday).

- **Column headers** -- Weekday abbreviation and date number. Today's header is highlighted.
- **Column body** -- All jobs due on that day are listed as expanded job chips showing job number, title, priority icon, overdue indicator, and customer name.
- **PO delivery events** -- Shown below jobs when enabled.
- **Empty columns** -- Show "No jobs" text when a day has no jobs or PO events.
- **Column header click** -- Switches to day view for that date.

### Day View

Displays a detailed list for a single date.

- **Header** -- Shows job count ("N jobs due") and PO delivery count (if enabled and > 0).
- **Job cards** -- Expanded cards with:
  - Stage color left border and tint background.
  - Priority icon (Critical: `priority_high`, High: `arrow_upward`).
  - Job number, title, overdue warning icon.
  - Metadata row: customer name, stage name, assignee initials, priority chip.
- **PO delivery cards** -- Shown when PO deliveries are enabled:
  - Shipping icon, PO number, vendor name, status chip, line count.
- **Empty state** -- "No jobs due" message with `event_available` icon when no items exist for the day.

---

## Navigation

### Period Navigation

| Control | Behavior |
|---------|----------|
| Previous button (`chevron_left`) | Month: go to previous month. Week: go back 7 days. Day: go back 1 day. |
| Next button (`chevron_right`) | Month: go to next month. Week: go forward 7 days. Day: go forward 1 day. |
| Today button | Sets the current date to today's date (navigates the view to the current period). |

### Header Label

The header label adapts to the current view:

- **Month** -- "March 2026" (full month name and year).
- **Week** -- "March 15-21, 2026" (when same month) or "Mar 28 - Apr 3, 2026" (when spanning months).
- **Day** -- "Tuesday, March 17, 2026" (full weekday, month, day, year).

---

## Track Type Filter

A select dropdown in the header allows filtering jobs by track type. Options are loaded from `KanbanService.getTrackTypes()` on component init.

Options:

- **"All Track Types"** (value: `null`) -- Shows all jobs regardless of track type. This is the default.
- One option per track type -- Filters to only show jobs belonging to that track type.

The filter operates client-side. All jobs are loaded once on init; the `trackTypeControl` value changes drive a `computed()` that filters the `allJobs` array by `trackTypeId`.

---

## PO Deliveries Toggle

A toggle button in the header labeled "PO Deliveries" (with a `local_shipping` icon) controls whether purchase order expected delivery dates are shown on the calendar.

Behavior:

- **Off (default)** -- No PO events are loaded or displayed.
- **On** -- Loads PO delivery events from `GET /api/v1/purchase-orders/calendar?from=YYYY-MM-DD&to=YYYY-MM-DD` for the visible date range. Events are displayed as distinct chips/cards in all three views.
- **Persistence** -- The toggle state is saved to `UserPreferencesService` under the key `calendar:showPo` and restored on page load.

The date range for PO queries covers the full calendar grid (including padding days from adjacent months visible in the month view). When the current date changes (month navigation), PO events are reloaded automatically if the toggle is on.

### PO Calendar Event Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Purchase order ID |
| `poNumber` | string | PO number |
| `vendorName` | string | Vendor display name |
| `expectedDeliveryDate` | string | `YYYY-MM-DD` format (DateOnly serialization) |
| `status` | string | PO status |
| `lineCount` | number | Number of lines on the PO |

PO events are indexed by date into a `Map<string, PoCalendarEvent[]>` for O(1) template lookups.

---

## Calendar Events -- What Appears

### Jobs

All non-archived jobs with a due date are displayed on the calendar. Jobs are loaded from `GET /api/v1/jobs?isArchived=false` on component init (one request for all jobs, then filtered client-side).

Each job chip shows:

| Element | Description |
|---------|-------------|
| Stage color border | Left border color matching the job's current kanban stage |
| Background tint | `--job-tint` CSS variable set to track type color (or stage color as fallback) |
| Priority icon | `priority_high` for Critical, `arrow_upward` for High; none for Medium/Normal/Low |
| Job number | The job's identifying number |
| Title | The job's title (truncated in month view) |
| Overdue indicator | Warning icon when `isOverdue` is true |
| Customer name | Shown in week and day views (not in month view due to space) |
| Assignee initials | Shown in day view metadata row |

### CalendarJob Model

| Field | Type | Description |
|-------|------|-------------|
| `id` | number | Job ID |
| `jobNumber` | string | Job display number |
| `title` | string | Job title |
| `stageName` | string | Current kanban stage name |
| `stageColor` | string | Stage color hex |
| `assigneeInitials` | string or null | Assignee initials for avatar |
| `assigneeColor` | string or null | Assignee avatar color |
| `priorityName` | string | Priority label (Critical, High, Medium, Normal, Low) |
| `dueDate` | Date or null | Job due date (jobs without due dates do not appear) |
| `isOverdue` | boolean | Whether the job is past its due date |
| `customerName` | string or null | Associated customer name |
| `trackTypeId` | number | Track type ID for filtering |
| `trackTypeColor` | string or null | Track type color for tinting |

### PO Delivery Events

See the PO Deliveries Toggle section above. PO events are visually distinct from job chips -- they use a shipping icon and a different color scheme to differentiate incoming materials from production work.

---

## Event Display and Click Behavior

### Job Chips

High-priority jobs (High or Critical) receive the `job-chip--high-priority` CSS class for visual emphasis. Overdue jobs show a warning icon.

**Click behavior:** Clicking a job chip navigates to the kanban board with the job selected:

```
/kanban?jobId={jobId}
```

In month view, clicking a job chip stops propagation to prevent also triggering the day-click handler.

### Day Cells

Clicking a day cell in month or week view switches to the day view for that date.

### PO Events

PO event chips stop click propagation but do not navigate anywhere. They serve as informational indicators only.

---

## Creating Events

The calendar does not support creating jobs or events directly. Job management is handled through the kanban board and backlog features. Event management is handled through the admin events panel. The calendar is strictly a read-only visualization.

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/jobs?isArchived=false` | Load all non-archived jobs for calendar display |
| `GET` | `/api/v1/purchase-orders/calendar?from=&to=` | Load PO delivery events within a date range |
| `GET` | `/api/v1/kanban/track-types` | Load track types for the filter dropdown |

The calendar does not have a dedicated backend controller. It composes data from existing job and purchase order endpoints.
