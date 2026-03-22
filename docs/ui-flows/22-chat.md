# Chat

**Route:** `/chat`
**Access Roles:** All roles
**Page Title:** Chat

## Purpose

Internal messaging with real-time delivery via SignalR. Supports 1:1 direct messages
and group rooms. Messages can include file attachments and entity references
(link to a job, part, etc.).

## Layout

- **Left panel:** Room/DM list with unread badge
- **Right panel:** Message thread with input bar

## Toolbar Actions

- New Direct Message
- New Group Room


## Message Features

| Feature | Description |
|:--------|:------------|
| Text messages | Markdown formatting supported |
| File attachments | Upload files within chat |
| Entity references | @mention a job, part, or customer |
| Real-time delivery | SignalR push — no polling |
| Read receipts | Shows when messages are read |

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

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★☆☆

Chat provides the basics for internal communication without leaving the app.

### Usability Observations

- Notification badge on sidebar icon shows unread message count
- Desktop browser notifications for new messages when app is not in focus
- Entity references create clickable links to the referenced record

### Functional Gaps / Missing Features

- No message reactions (emoji reactions)
- No message threading (reply to specific message)
- No message editing after send
- No search within chat history
- No voice/video call integration
- No status presence indicators (online/away/busy)
- No mobile push notifications (only in-browser)
