# Invoices ⚡ (Standalone Mode)

**Route:** `/invoices`
**Access Roles:** Office Manager, Manager, Admin
**Page Title:** invoices.title
**Mode:** Active when no accounting provider is connected (standalone mode)

## Purpose

Invoice management for standalone operation (no QB connection). When QB is connected,
invoices are managed in QB and this module becomes read-only. Invoices are generated
from shipped Sales Orders and sent to customers. Payments are applied against invoices.

## Table Columns

| Invoice # | Customer | Invoice Date | Due Date | Total | Balance Due | Status |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- pending_actions invoices.uninvoicedJobs
- add invoices.newInvoice


## Invoice Statuses

Draft → Sent → Partially Paid → Paid → Voided / Overdue

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
- **Uninvoiced Jobs (pending_actions)** — look for the `pending_actions` icon (right side of toolbar)
- **New Invoice (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

Standalone invoicing is clean and covers the AR lifecycle. QB sync handles the
connected case gracefully.

### Usability Observations

- "Uninvoiced Jobs" panel shows jobs ready to invoice with one click
- Invoice PDF generation via QuestPDF
- Payment application tracks partial payments across invoices

### Functional Gaps / Missing Features

- No recurring invoice automation
- No early-payment discount terms enforcement
- No invoice reminder email automation (send reminder when X days overdue)
- No customer statement generation from within invoices (exists in reports)
