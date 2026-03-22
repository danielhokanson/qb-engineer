# Vendors

**Route:** `/vendors`
**Access Roles:** Office Manager, Manager, Admin (⚡ full CRUD in standalone; read-only with QB)
**Page Title:** vendors.title

## Purpose

Vendor master data — companies from which materials and services are purchased.
Vendors link to Purchase Orders and Expenses. When QB is connected, vendor master
data is managed in QB and synced to the app.

## Table Columns

| Name | Contact | Email | Phone | City | State | Payment Terms | QB Synced |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add vendors.newVendor


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
- **New Vendor (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★☆☆

Vendor management is functional but relatively sparse — most data lives in QB.

### Usability Observations

- Vendor list syncs from QB when connected
- Address verification available for vendor shipping addresses
- Payment terms dropdown aligned with QB terms codes

### Functional Gaps / Missing Features

- No vendor performance tracking (on-time delivery %, quality metrics)
- No preferred vendor flag per part/category
- No vendor contact management (multiple contacts per vendor)
- No vendor document storage (certificates, W-9s)
