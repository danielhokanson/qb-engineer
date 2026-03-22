# Kanban Board

**Route:** `/kanban`, `/board`
**Access Roles:** All roles (Production Workers: move only; PM: read-only; others: full)
**Page Title:** kanban.title

## Purpose

The Kanban board is the central operational view for tracking jobs through production
stages. Cards represent jobs and are moved through configurable stages that map to
QuickBooks document types (Estimate → Sales Order → Invoice → Payment).

## Board Layout

### Stage Columns (Production Track)

- Quote Requested
- Quoted (Estimate)
- Order Confirmed (Sales Order)
- Materials Ordered (PO)
- Materials Received
- In Production
- QC / Review
- Shipped (Invoice)
- Invoiced / Sent
- Payment Received


### Track Type Tabs

- Production
- R&D / Tooling
- Maintenance
- Other


## Toolbar Actions

- help_outline
- Production
- R&D/Tooling
- Maintenance
- view_column
- people
- add jobs.createJob


## Create Job Dialog

**Dialog:** New Job

### Form Fields

| Field | Type | Required |
|:------|:-----|:---------|
| Title | Text | — |
| Customer | Text | — |
| Part | Text | — |
| Priority | Text | — |
| Due Date | Text | — |
| Assigned To | Text | — |
| Track Type | Text | — |
| Description | Text | — |


## Job Card Contents

Each card displays:
- Job number and title
- Customer name
- Priority indicator (color + label)
- Due date (red if overdue)
- Assignee avatar
- Stage-specific context (e.g., PO number, invoice number)
- Hold indicator (if active holds exist)

## Key Interactions

| Action | How |
|:-------|:----|
| Move card | Drag and drop between columns |
| Multi-select | Ctrl+Click on cards |
| Bulk move | Select multiple → Move To |
| Open detail | Click card → slides open right panel |
| New job | "New Job" button in toolbar or per-column header |
| Filter by assignee | Swimlane toggle → select user |
| Archive job | Job detail panel → Archive |

## Finding Controls

Use these landmarks when you need help locating a specific control.
Positions are described relative to a standard 1920×1080 desktop layout.

### 🔵 Top Header Bar (always visible, 44px strip at very top)

- **Open Chat** — look for the `chat_bubble_outline` icon (right side of toolbar)
- **Ai Assistant (smart_toy)** — look for the `smart_toy` icon (right side of toolbar)
- **Notifications bell** — look for the `notifications_none` icon (top-right corner)
- **Toggle dark/light theme** — look for the `dark_mode` icon (top-right corner)
- **User, Admin** — look for the `menu` icon (top-right corner)

### 🟦 Page Toolbar (below header — search, filters, action buttons)

- **Dismiss onboarding banner** — look for the `close` icon (top-right corner)
- **Expand sidebar** — look for the `chevron_right` icon (left sidebar)
- **Start Help Tour (help_outline)** — look for the `help_outline` icon (left side of toolbar)
- **Production** (center)
- **R&D/Tooling** (center)
- **Maintenance** (right side of toolbar)
- **Column manager (show/hide columns)** — look for the `view_column` icon (right side of toolbar)
- **Swimlane / Team view** — look for the `people` icon (right side of toolbar)
- **Create Job (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★★

The Kanban board is the most-used feature and has the most polish. Drag-and-drop
is smooth, the stage column colors provide clear visual orientation, and SignalR
real-time sync ensures multi-user boards stay in sync automatically.

### Usability Observations

- Column colors are customizable per stage (CSS custom property --col-tint)
- WIP limits turn column headers red when exceeded
- Irreversible stages (Invoice, Payment) block backward moves
- Swimlane view allows per-assignee breakdown of the board
- Compact card density fits many jobs per column without scrolling

### Functional Gaps / Missing Features

- No card aging indicator (how long has a card been in this stage?)
- No cycle time analytics visible on the board itself
- No "blocked" card state (distinct from "on hold")
- Bulk operations limited to Move, Assign, Priority, Archive — no bulk edit of other fields
- No card count per customer visible on the board (need swimlanes)
- Search/filter within a single column not available

### Navigation Notes

- Selecting a job opens a slide-out detail panel (does not navigate away)
- Disposing a job navigates to dispose dialog, returns to board
- Track type tabs update the URL (/kanban → /kanban?track=2 etc.)
