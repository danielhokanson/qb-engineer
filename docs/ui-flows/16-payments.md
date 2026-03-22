# Payments ⚡ (Standalone Mode)

**Route:** `/payments`
**Access Roles:** Office Manager, Manager, Admin
**Page Title:** payments.title
**Mode:** Active when no accounting provider is connected (standalone mode)

## Purpose

Payment recording and application against invoices. Supports partial payments, multiple
payment methods, and payment application across multiple invoices.

## Table Columns

| Payment # | Customer | Date | Method | Amount | Applied To | Unapplied Balance |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add payments.newPayment


## Payment Methods

Check, ACH/Wire, Credit Card, Cash, Other

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
- **New Payment (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★☆☆

Basic payment recording works. The payment application flow (linking payment to
specific invoices) needs a more visual workflow.

### Usability Observations

- Payment can be applied across multiple invoices at once
- Unapplied balance (credit) carries forward for future application
- Payment method dropdown includes all standard manufacturing payment types

### Functional Gaps / Missing Features

- No payment processing integration (Stripe, Square, etc.)
- No ACH batch file generation
- No check printing
- No payment reconciliation workflow
