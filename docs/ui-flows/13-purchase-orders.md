# Purchase Orders

**Route:** `/purchase-orders`
**Access Roles:** Engineer, Manager, Admin
**Page Title:** purchaseOrders.title

## Purpose

Purchase Orders manage outbound procurement — buying materials, components, and
services from vendors. PO lines link to jobs. Receiving records update inventory
stock levels automatically.

## Table Columns

| PO # | Vendor | Date | Expected | Total | Received % | Status |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Tabs

- Open POs
- Receiving
- Closed POs


## Toolbar Actions

- add purchaseOrders.newPo


## PO → Receiving Flow

1. Create PO with vendor + line items
2. PO status: Draft → Sent → Partially Received → Fully Received
3. "Receive" button opens receive dialog — enter quantities received
4. Receiving record auto-updates inventory bin quantities
5. Job on kanban board moves to "Materials Received" stage

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
- **purchaseOrders.newPo** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

The PO → receiving → inventory update chain is well implemented and closes the
procurement loop without manual inventory entry.

### Usability Observations

- PO PDF generation for sending to vendors
- Receiving dialog shows expected vs received quantities per line
- Partial receiving creates a follow-up open balance

### Functional Gaps / Missing Features

- No vendor portal (vendor can't view PO or confirm receipt)
- No 3-way match (PO → receipt → vendor invoice matching)
- No PO amendment workflow after sending
- No vendor lead time tracking per line item
- No blanket PO / release order structure
