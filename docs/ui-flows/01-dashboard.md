# Dashboard

**Route:** `/dashboard`
**Access Roles:** All roles
**Page Title:** dashboard.title

## Purpose

The dashboard is the user's home screen — a configurable grid of widgets showing
real-time operational metrics. Widgets adapt to the user's role (admin sees financial
data, engineers see job/production metrics, workers see task widgets).

## Widget Layout

Widgets are arranged in a gridstack layout. Users can drag to reorder and resize.

### Known Widgets

| Widget | Description |
|:-------|:------------|
| Open Orders | Count of active jobs by stage |
| Today's Tasks | Jobs assigned to the current user due today |
| Cycle Progress | Current planning cycle burn-down |
| EOD Prompt | End-of-day reflection prompt |
| Margin Summary | Revenue vs cost margin overview (admin/manager) |
| Getting Started Banner | Onboarding checklist (disappears when complete) |

### Detected Widget Titles

- task_alt Today's Tasks
- bar_chart Jobs by Stage
- groups Team Load
- event Deadlines
- history Activity
- trending_up Margin Summary
- loop Cycle Progress
- shopping_cart Open Orders
- nightlight End of Day


## Toolbar Actions

- help_outline
- nightlight dashboard.ambient
- download common.export
- edit dashboard.customize


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
- **Ambient Display Mode (nightlight)** — look for the `nightlight` icon (right side of toolbar)
- **Export (download)** — look for the `download` icon (right side of toolbar)
- **Customize Layout (edit)** — look for the `edit` icon (top-right corner)

### 📋 Top of Content Area (first rows, column headers)

- **Filter** — look for the `filter_list` icon (center)
- **Sort** — look for the `swap_vert` icon (center)
- **Customize** — look for the `tune` icon (center)
- **View Job (open_in_new)** — look for the `open_in_new` icon (center)

### 📄 Lower Content Area

- **Start Planning** (left side of toolbar)
- **Save** — look for the `save` icon (right side of toolbar)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

The configurable widget grid provides a strong "at a glance" overview. Role-specific
content ensures engineers don't see irrelevant financial widgets.

### Usability Observations

- Gridstack layout allows personalized widget arrangement
- Getting started banner guides new users through setup
- Ambient mode offers a distraction-free display for wall-mounted screens
- Dashboard loads all widgets simultaneously — correct use of global loading overlay

### Functional Gaps / Missing Features

- No widget marketplace (limited to built-in widget set)
- No per-widget date range configuration
- KPI trend arrows (up/down vs prior period) not present on most widgets
- No dashboard sharing or export to PDF
- Widgets don't auto-refresh on a timer (require manual page reload for live data)
