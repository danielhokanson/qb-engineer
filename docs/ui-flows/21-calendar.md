# Calendar

**Route:** `/calendar`
**Access Roles:** All roles
**Page Title:** calendar.title

## Purpose

Calendar view aggregates job due dates, planning cycle boundaries, and scheduled
tasks into a single timeline view.

## Views

| View | Description |
|:-----|:------------|
| Month | Standard month grid with event chips |
| Week | Hour-by-hour week view |
| Day | Single day detail view |

## Toolbar Actions

- calendar.month
- calendar.week
- calendar.day
- chevron_left
- chevron_right
- calendar.today


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
- **Month** (center)
- **Week** (right side of toolbar)
- **Day** (right side of toolbar)
- **Previous Period (chevron_left)** — look for the `chevron_left` icon (right side of toolbar)
- **Next Period (chevron_right)** — look for the `chevron_right` icon (top-right corner)
- **Today** (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★☆☆

Calendar is a useful at-a-glance view but needs more event sources and interaction.

### Usability Observations

- Job due dates appear as event chips on their due date
- Planning cycle start/end dates appear as multi-day events
- Color coding maps to job priority or stage

### Functional Gaps / Missing Features

- No calendar event creation (can't create a job or task from the calendar)
- No personal calendar items (meetings, reminders)
- No resource calendar (who is working on what, when)
- No iCal export or Google/Outlook calendar sync
- No recurring event display for scheduled tasks
