# Customers

**Route:** `/customers`
**Access Roles:** Office Manager, PM, Manager, Admin
**Page Title:** customers.title

## Purpose

Customer master data — companies and contacts that purchase products/services.
Customers link to Jobs, Quotes, Sales Orders, Invoices, and Payments.
Multi-address support (billing, shipping, multiple sites).

## Table Columns

| customers.colName | customers.colCompany | customers.colEmail | customers.colPhone | customers.colActive filter_list | customers.colContacts | customers.colJobs | customers.colCreated | downloadsettings |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Tabs (Customer Detail)

- Overview
- Addresses
- Contacts
- Jobs
- Orders
- Invoices
- Files
- Activity


## Toolbar Actions

- add customers.createCustomer


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
- **Create Customer (add)** — look for the `add` icon (top-right corner)

### 📋 Top of Content Area (first rows, column headers)

- **Filter Column (filter_list)** — look for the `filter_list` icon (right side of toolbar)
- **Export Csv (download)** — look for the `download` icon (top-right corner)
- **Manage Columns (settings)** — look for the `settings` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

Customer management is solid. Multi-address support is a key strength for customers
with multiple shipping locations.

### Usability Observations

- Address verification via USPS API validates and standardizes addresses
- QB sync indicator shows which customers are linked to QuickBooks
- Customer detail tabs provide rich history (all jobs, orders, invoices)

### Functional Gaps / Missing Features

- No customer portal (customer can't log in to view their orders/invoices)
- No customer-specific pricing (price list assignment to customer exists but UI is limited)
- No duplicate detection on customer creation
- Customer contacts are flat (no org chart / hierarchy)
- No credit limit enforcement (credit terms is informational only)
