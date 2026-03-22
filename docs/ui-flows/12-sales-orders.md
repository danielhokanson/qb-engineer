# Sales Orders

**Route:** `/sales-orders`
**Access Roles:** Office Manager, PM, Manager, Admin
**Page Title:** salesOrders.title

## Purpose

Sales Orders represent confirmed customer commitments (mapped to QB Sales Receipts or
Invoices depending on QB flow). Each SO line links to a Kanban job that fulfills it.
Partial fulfillment is supported — multiple shipments per SO line.

## Table Columns

| SO # | Customer | Date | Due Date | Total | Fulfillment % | Status | QB Synced |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add salesOrders.newOrder


## SO Statuses

Draft → Confirmed → In Fulfillment → Partially Shipped → Fully Shipped → Invoiced

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
- **salesOrders.newOrder** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

The SO fulfillment tracking (linking lines to jobs, tracking shipment progress) is
a key differentiator for job shops that need granular order tracking.

### Usability Observations

- SO lines link to Jobs on the Kanban board
- Fulfillment percentage auto-calculates from shipment records
- Convert to Invoice button appears when all lines are shipped

### Functional Gaps / Missing Features

- No SO amendment workflow (customer change orders after confirmation)
- No SO acknowledgment PDF (different from quote — formal order confirmation)
- No partial cancellation (cancel individual lines, not entire SO)
- No back-order management (split line into shipped + back-ordered quantities)
