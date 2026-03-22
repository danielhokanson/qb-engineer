# Expenses

**Route:** `/expenses`
**Access Roles:** All roles (submit own; Manager/Admin approve all)
**Page Title:** expenses.title

## Purpose

Employee expense reporting and approval workflow. Employees submit expense claims
with receipts. Managers approve/reject. Approved expenses can sync to QB.

## Table Columns

| Date | Description | Category | Amount | Submitted By | Status | Receipt |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Tabs

- My Expenses
- Approval Queue
- Upcoming


## Toolbar Actions

- help_outline
- add expenses.createExpense


## Create Expense Dialog Fields

| Field | Type | Required |
|:------|:-----|:---------|
| Amount | Text | — |
| Date | Text | — |
| Category (Materials/Tools/Travel/Office/Other) | Text | — |
| Description | Text | — |
| Job Reference | Text | — |
| Receipt (file upload) | Text | — |


## Expense Statuses

Draft → Submitted → Under Review → Approved / Rejected → Reimbursed

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
- **Create Expense (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

Clean expense submission flow. Receipt photo capture via CameraCapture is a
standout feature for mobile use.

### Usability Observations

- Receipt attachment via camera capture works on mobile browsers
- Category codes align with QB expense categories for sync
- Approval queue is a distinct tab for managers — clear separation

### Functional Gaps / Missing Features

- No mileage expense type (distance-based calculation)
- No per-diem rules (fixed rate by location)
- No expense policy enforcement (max amounts per category)
- No corporate card integration
- No OCR on receipt to pre-fill amount/merchant
