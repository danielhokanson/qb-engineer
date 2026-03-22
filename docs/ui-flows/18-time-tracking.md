# Time Tracking

**Route:** `/time-tracking`
**Access Roles:** All roles
**Page Title:** timeTracking.title

## Purpose

Time tracking records labor hours against jobs or overhead categories. Supports both
real-time timers (start/stop) and manual log entries. SignalR broadcasts timer state
across all open tabs. Time entries sync to QB Time Activities.

## Table Columns

| Date | Job | Category | Duration | Notes | Billable | Status |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Tabs

- My Time
- Team Time (admin/manager)
- Reports


## Toolbar Actions

- help_outline
- play_circle timeTracking.startTimer
- edit_note timeTracking.manualEntry


## Timer Feature

- Active timer shows elapsed time in real-time
- Timer state persists across page navigation
- SignalR broadcasts start/stop to all tabs (prevents duplicate timers)
- Stop dialog captures final notes and category before saving

## Manual Entry Fields

- Date, Hours, Minutes, Category, Job Reference, Notes, Billable toggle

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
- **timeTracking.startTimer** — look for the `play_circle` icon (right side of toolbar)
- **timeTracking.manualEntry** — look for the `edit_note` icon (top-right corner)

### 📋 Top of Content Area (first rows, column headers)

- **Open calendar** (left side of toolbar)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

Timer + manual log covers the two main time capture workflows. SignalR sync is
a strong feature for multi-tab users.

### Usability Observations

- Active timer badge visible in header while timer is running
- KB shortcut to start/stop timer (configurable)
- Shop Floor kiosk uses time tracking via clock-in/out (separate flow)

### Functional Gaps / Missing Features

- No time approval workflow (timesheets requiring manager sign-off)
- No overtime rules or alerts
- No pay period locking (employees can edit any past entry)
- No project budget vs actual hours comparison
- Team time view limited to admin/manager — PMs can't see team time for their projects
- No integration with ADP/Paychex for payroll export
