# Quotes (Estimates)

**Route:** `/quotes`
**Access Roles:** PM, Office Manager, Manager, Admin
**Page Title:** quotes.title

## Purpose

Quotes (mapped to QuickBooks Estimates) are the starting point of the quote-to-cash
flow. A quote has line items with quantities and prices. When accepted by the customer,
a quote converts to a Sales Order.

## Table Columns

| Quote # | Customer | Date | Expiry | Total | Status | QB Synced |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add quotes.newQuote


## Create Quote Dialog Fields

| Field | Type | Required |
|:------|:-----|:---------|
| Customer | Text | — |
| Quote Date | Text | — |
| Expiry Date | Text | — |
| Terms | Text | — |
| Notes / Customer Message | Text | — |
| Line Items (part, qty, price, description) | Text | — |


## Quote Statuses

Draft → Sent → Accepted → Converted (to SO) / Declined / Expired

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
- **New Quote (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

Quote creation with line items is clean. QB sync keeps estimates in sync with QB.

### Usability Observations

- Line item part picker links to parts catalog
- Quote PDF generation via QuestPDF
- QB sync creates/updates Estimate in QB Online automatically

### Functional Gaps / Missing Features

- No quote versioning (V1, V2, V3 revisions visible to customer)
- No quote template system (start from a saved quote structure)
- No customer approval portal (customer receives PDF via email, calls to accept)
- No quote approval workflow (manager must approve before sending)
- No quote win/loss analysis dashboard
