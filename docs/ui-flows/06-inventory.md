# Inventory

**Route:** `/inventory`, `/inventory/stock`, `/inventory/receiving`
**Access Roles:** Engineer, Manager, Admin
**Page Title:** Inventory

## Purpose

Inventory management tracks stock levels across storage locations (bins/shelves/racks).
Supports receiving (inbound from POs), bin movements, and real-time stock queries.

## Tabs

- Stock
- Receiving
- Movements
- Locations


## Stock Tab — Table Columns

| Part # | Description | Total Qty | Available | Reserved | Location | Bin | Last Movement |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- New Movement
- Add Location
- Receive (from PO)
- Column Manager


## Key Features

| Feature | Description |
|:--------|:------------|
| Bin Locations | Hierarchical: Warehouse → Zone → Rack → Shelf → Bin |
| Receiving | Link to PO → receive line quantities → auto-update stock |
| Bin Movements | Record transfer between bins with reason codes |
| Expandable Rows | Click row to see per-bin breakdown for that part |
| Barcode Scanning | Scan part label → jumps to that part's stock entry |

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

Inventory is functionally solid for basic stock tracking, but the UI lacks some
features expected in a modern warehouse management system.

### Usability Observations

- Expandable DataTable rows elegantly show bin-level detail without modal overhead
- Receiving flow links naturally from PO (receive button on PO line)
- Scanner service integration makes physical receiving faster

### Functional Gaps / Missing Features

- No FIFO/LIFO tracking (all stock treated as fungible)
- No lot/serial number tracking for individual units (LotRecord entity exists but not connected to bins)
- No low-stock alerts or reorder point notifications
- No physical count / cycle count workflow
- No vendor-managed inventory (consignment stock)
- Bin movement doesn't validate bin capacity limits
- No quarantine bin status for rejected/suspect material
