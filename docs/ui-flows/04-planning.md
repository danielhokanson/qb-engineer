# Planning Cycles

**Route:** `/planning`
**Access Roles:** PM, Manager, Admin
**Page Title:** planning.title

## Purpose

Planning Cycles (2-week sprints by default) provide structured commitment windows.
PMs use the split-panel view to drag jobs from the backlog into the current cycle.
Daily EOD prompts ask for top-3 priorities. Cycle reviews capture lessons learned.

## Layout

Split-panel view:
- **Left panel:** Backlog — all uncommitted jobs, sortable/filterable
- **Right panel:** Active cycle board — committed jobs organized by stage

## Tabs / Sections

- Active Cycle
- Past Cycles
- EOD Prompts


## Toolbar Actions

- help_outline
- add planning.newCycle


## Create Cycle Dialog Fields

| Field | Type | Required |
|:------|:-----|:---------|
| Name / Label | Text | — |
| Start Date | Text | — |
| End Date | Text | — |
| Goal / Focus | Text | — |


## Key Interactions

| Action | How |
|:-------|:----|
| Commit job to cycle | Drag from backlog panel to cycle panel |
| Remove job from cycle | Drag back to backlog |
| End cycle | "End Cycle" → rolls incomplete jobs back to backlog |
| EOD Prompt | Evening modal asks "What are your top 3 for tomorrow?" |

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
- **New Cycle (add)** — look for the `add` icon (top-right corner)

### 📋 Top of Content Area (first rows, column headers)

- **Create First Cycle** (center)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

The split-panel drag-and-drop planning experience maps well to sprint planning
rituals. The EOD prompt is a thoughtful productivity feature.

### Usability Observations

- Cycle burn-down visible on dashboard widget
- Past cycles are read-only with summary statistics
- Cycle duration is configurable (not locked to 2 weeks)

### Functional Gaps / Missing Features

- No capacity planning (no way to see estimated hours vs. capacity)
- No velocity tracking across cycles (no chart of committed vs. completed)
- No team-level cycle view (each user sees their own cycle)
- EOD prompt timing not configurable (always evening)
- No cycle retrospective capture beyond basic notes
