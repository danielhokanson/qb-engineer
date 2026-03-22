# Notifications

**Route:** `/notifications` (also as panel via bell icon)
**Access Roles:** All roles
**Page Title:** notifications.title

## Purpose

Notifications deliver real-time alerts for job moves, mentions, approvals, system
events, and chat messages. The bell icon in the header shows an unread badge.
The notification panel slides from the right on bell click.

## Notification Panel (Header Bell)

### Tabs
- notifications.allNotifications
- notifications.preferences


### Notification Types

| Type | Trigger | Severity |
|:-----|:--------|:---------|
| Job moved | Card moved to new stage on kanban | Info |
| Mention | User @mentioned in activity comment | Info |
| Expense approved/rejected | Manager action on expense | Info / Warning |
| Compliance deadline | Compliance form due date approaching | Warning |
| System alert | DB backup, sync failure, AI error | Warning / Error |
| Chat message | New direct message or group mention | Info |

### Notification Actions

- Mark as read (individual or all)
- Dismiss (remove from list)
- Pin (keep at top of list)
- Click to navigate to source entity

## Full Notifications Page

List view of all notifications with advanced filtering:
- Filter by: source, severity, type, unread only
- Bulk actions: mark all read, dismiss all

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

### 📋 Top of Content Area (first rows, column headers)

- **All Notifications** (center)
- **Preferences** (center)
- **Mark All Read (done_all)** — look for the `done_all` icon (center)
- **Dismiss All (clear_all)** — look for the `clear_all` icon (right side of toolbar)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

Real-time notifications via SignalR with a well-organized panel and filtering
provide a professional notification experience.

### Usability Observations

- Pinned notifications always appear at top of list
- Desktop browser notifications for critical alerts when app is out of focus
- Notification preferences per type (configurable by user)

### Functional Gaps / Missing Features

- No mobile push notifications (PWA push not yet implemented)
- No notification digest email (daily/weekly summary)
- No notification muting per user or per entity
- Notification preferences UI exists but not all types are configurable
