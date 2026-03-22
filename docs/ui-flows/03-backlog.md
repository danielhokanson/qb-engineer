# Backlog

**Route:** `/backlog`
**Access Roles:** All roles (PM, Manager, Admin for full management)
**Page Title:** backlog.title

## Purpose

The backlog is a prioritized list of all jobs not yet active on the Kanban board.
PMs drag jobs from the backlog into Planning Cycles to commit to a sprint.
The backlog uses the DataTable component with full sort/filter/column management.

## Table Columns

| jobs.jobNumber filter_list | common.title filter_list | jobs.stage filter_list | common.priority filter_list | common.assignee filter_list | jobs.customer filter_list | common.dueDate filter_list | downloadsettings |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add jobs.createJob


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
- **Create Job (add)** — look for the `add` icon (top-right corner)

### 📋 Top of Content Area (first rows, column headers)

- **Filter Column (filter_list)** — look for the `filter_list` icon (left side of toolbar)
- **Export Csv (download)** — look for the `download` icon (top-right corner)
- **Manage Columns (settings)** — look for the `settings` icon (top-right corner)

### 🟩 Bottom Action Bar (Save / Cancel buttons)

- **First page** (top-right corner)
- **Previous page** (top-right corner)
- **Next page** (top-right corner)
- **Last page** (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

The backlog provides a clean list view that complements the board view.
DataTable sorting and filtering make it easy to prioritize.

### Usability Observations

- Multi-column sort supported (Shift+click column headers)
- Per-column filter popover (text, date range, enum)
- Column visibility and reorder persist via UserPreferences
- Right-click context menu on column headers for quick actions

### Functional Gaps / Missing Features

- No bulk re-prioritization (drag to reorder within the backlog list)
- No backlog "bucket" grouping (e.g., group by customer or track type)
- No backlog estimation (story points or time estimate field)
- Moving from backlog to board requires the Planning view — not directly from backlog table
