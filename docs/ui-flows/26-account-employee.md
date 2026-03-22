# Account & Employee Self-Service

**Route:** `/account/*`
**Access Roles:** All roles (own data only; Admin can view all)

## Purpose

The Account section is the employee self-service portal. Employees manage their
personal information, complete compliance forms, view pay stubs, and access
company documents. Profile completeness drives access to job assignments.

## Account Sidebar Navigation

| Section | Route | Description |
|:--------|:------|:------------|
| Profile | `/account/profile` | Name, photo, bio |
| Contact | `/account/contact` | Phone, personal email, home address |
| Emergency | `/account/emergency` | Emergency contact name/phone/relationship |
| Security | `/account/security` | Change password, change PIN, active sessions |
| Tax Forms | `/account/tax-forms` | Compliance forms (W-4, I-9, state withholding) |
| Pay Stubs | `/account/pay-stubs` | View/download pay stubs (QB Payroll sync) |
| Tax Documents | `/account/tax-documents` | W-2, 1099 downloads |
| Documents | `/account/documents` | Company documents (handbooks, policies) |

## Profile Completeness

Profile completeness blocks job assignment until key fields are filled:

| Requirement | Blocks |
|:------------|:-------|
| Emergency Contact | Job assignment |
| Home Address | Job assignment |
| W-4 Submitted | Payroll processing |
| I-9 Completed | Legal work authorization |
| State Withholding | State payroll taxes |

A completeness progress bar is shown on the profile sidebar.

## Contact Form Fields

| Field | Type | Required |
|:------|:-----|:---------|
| account.phoneNumber | Text | — |
| account.personalEmail | Text | — |
| addressForm.streetAddress | Text | — |
| addressForm.streetAddress2 | Text | — |
| addressForm.city | Text | — |
| addressForm.state | Text | — |
| addressForm.zipPostalCode | Text | — |
| addressForm.country | Text | — |


## Emergency Contact Form Fields

| Field | Type | Required |
|:------|:-----|:---------|
| account.emergencyName | Text | — |
| account.emergencyPhone | Text | — |
| account.relationship | Text | — |


## Tax Forms Section (Compliance)

Compliance forms are either:
1. **Electronic** — rendered dynamically via DynamicQbForm component, filled in-app
2. **PDF-based** — displayed as PDF, employee acknowledges and signs via DocuSeal

### Known Compliance Forms

| Form | Type | Description |
|:-----|:-----|:------------|
| Federal W-4 | Electronic | Employee withholding allowances |
| Federal I-9 | Electronic | Employment eligibility verification |
| State W-4 (varies by state) | Electronic | State income tax withholding |
| Employee Handbook | PDF Acknowledge | Company policies |
| Safety Policy | PDF Acknowledge | OSHA compliance acknowledgment |

## Pay Stubs Section

- Lists pay stubs sorted by pay period (most recent first)
- Download as PDF
- Shows: gross pay, deductions, net pay, YTD totals
- Data populated via QB Payroll API sync (stub returns empty without QB Payroll)

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

- **Back To Dashboard (arrow_back)** — look for the `arrow_back` icon (left side of toolbar)

### 📋 Top of Content Area (first rows, column headers)

- **Tax Compliance (description)** — look for the `description` icon (left side of toolbar)
- **Open calendar** (center)
- **Select color #6366f1** (center)
- **Select color #8b5cf6** (center)
- **Select color #ec4899** (center)
- **Select color #ef4444** (center)
- **Select color #f97316** (center)
- **Select color #eab308** (right side of toolbar)
- **Select color #22c55e** (right side of toolbar)
- **Select color #14b8a6** (right side of toolbar)
- **Select color #06b6d4** (center)
- **Select color #3b82f6** (center)
- **Select color #64748b** (center)
- **Select color #78716c** (center)

### 📄 Middle of Page (main content)

- **Save** — look for the `save` icon (right side of toolbar)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

The self-service portal reduces HR overhead significantly. The compliance form
electronic rendering (W-4 with dynamic calculation) is particularly sophisticated.

### Usability Observations

- W-4 withholding preview updates in real-time as user adjusts allowances
- DocuSeal integration handles legally binding e-signatures for PDF forms
- Profile completeness progress bar motivates employees to complete their profiles
- All form saves use the hover-popover validation pattern

### Functional Gaps / Missing Features

- No payroll history beyond pay stubs (no year-end W-2 generation — QB handles this)
- No benefits enrollment (health insurance, 401k — out of scope)
- No PTO balance display (no PTO tracking module)
- No performance review workflow
- No direct deposit setup UI (managed in QB Payroll)
- Documents section shows company documents but no per-employee document upload by HR
