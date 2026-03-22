# Shipments

**Route:** `/shipments`
**Access Roles:** Office Manager, Manager, Admin
**Page Title:** shipments.title

## Purpose

Shipments track outbound deliveries against Sales Order lines. The shipping rates
dialog shows carrier rate quotes. Tracking numbers link to carrier tracking pages.
Address validation via USPS ensures accurate delivery addresses.

## Table Columns

| Shipment # | Customer | Ship Date | Carrier | Tracking # | Status | SO Reference |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add shipments.newShipment


## Shipping Rates Dialog

Opens carrier rate comparison (mock carriers in dev):
- Shows rate options per carrier/service level
- Click to select → pre-fills tracking info

## Shipment Statuses

Pending → Label Created → Picked Up → In Transit → Delivered / Exception

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
- **New Shipment (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★☆☆

Shipment creation works but carrier API integrations are still mock.

### Usability Observations

- Address validation warns before creating shipment with invalid address
- Tracking timeline shows carrier scan events
- Shipment links back to SO to close fulfillment loop

### Functional Gaps / Missing Features

- Carrier integrations (UPS, FedEx, USPS, DHL) are mocked — not yet connected to real APIs
- No label printing directly from the app (generates label via carrier API when implemented)
- No return shipment (RMA) workflow
- No multi-package shipment support
- No customs/international shipping documentation
