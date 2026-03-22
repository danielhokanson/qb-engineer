# Assets

**Route:** `/assets`
**Access Roles:** Engineer, Manager, Admin
**Page Title:** assets.title

## Purpose

Asset management tracks physical equipment, tools, fixtures, and tooling (molds, dies).
Tooling assets have extended fields for cavity count, shot life, and customer ownership.
Maintenance jobs are linked to assets via the Maintenance track type.

## Table Columns

| Name | Type | Status | Location | Serial # | Assigned To | Last Service | Notes |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add assets.addAsset


## Create Asset Dialog Fields

| Field | Type | Required |
|:------|:-----|:---------|
| Name | Text | — |
| Type (Equipment/Tooling/Fixture/Vehicle/Other) | Text | — |
| Status (Active/In Maintenance/Retired) | Text | — |
| Serial Number | Text | — |
| Location | Text | — |
| Assigned To | Text | — |
| Purchase Date | Text | — |
| Purchase Cost | Text | — |
| Cavity Count (tooling) | Text | — |
| Tool Life Expectancy (tooling) | Text | — |
| Customer Owned (tooling toggle) | Text | — |
| Notes | Text | — |


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
- **Add Asset** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★☆☆

Assets cover the core use case but tooling-specific features need more depth.

### Usability Observations

- Tooling assets show extended fields (cavity count, shot counter, customer ownership)
- Maintenance jobs link from asset detail to the Maintenance kanban track
- QR code generation for asset labels available via LabelPrintService

### Functional Gaps / Missing Features

- No shot counter auto-increment when jobs complete (requires manual update)
- No scheduled maintenance calendar / due date alerts
- No asset check-out/check-in workflow (who has this tool right now?)
- No depreciation tracking or book value
- No asset photos beyond generic file attachments
- Maintenance history not directly accessible from asset detail (must go to kanban and filter)
