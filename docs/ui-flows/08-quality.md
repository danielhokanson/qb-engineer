# Quality Control

**Route:** `/quality`
**Access Roles:** Engineer, Manager, Admin
**Page Title:** quality.title

## Purpose

QC module manages inspection templates, inspection records, and production lot
traceability. Inspections are linked to jobs. Defect tracking feeds into
the scrap rate report.

## Tabs

- fact_check quality.qcInspections
- qr_code_2 quality.lotTracking


## Table Columns

| Job # | Part | Inspection Date | Inspector | Result (Pass/Fail) | Defect Count | Notes |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add quality.newInspection


## QC Template Structure

Templates define what to inspect:
- Checklist items (pass/fail checks)
- Measurement items (numeric value + tolerance)
- Signature items (inspector sign-off)
- Photo requirement flags

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
- **New Inspection (add)** — look for the `add` icon (top-right corner)

### 📋 Top of Content Area (first rows, column headers)

- **Qc Inspections (fact_check)** — look for the `fact_check` icon (left side of toolbar)
- **Lot Tracking (qr_code_2)** — look for the `qr_code_2` icon (left side of toolbar)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★☆☆

QC covers the basic inspection record use case. Template-driven inspections
reduce data entry. Lot traceability is present but under-connected.

### Usability Observations

- Inspection templates are reusable and can be linked to specific parts/operations
- Camera capture component available for attaching defect photos
- Barcode scanner context integrated for quick lot number lookup

### Functional Gaps / Missing Features

- No SPC (Statistical Process Control) charts for measurement data
- No non-conformance (NCR) report workflow
- No corrective action (CAPA) tracking
- Lot traceability is one-level (no component lot trace-back through BOM)
- No first-article inspection (FAI) workflow
- No customer-specific quality requirements or PPAP documentation
- Scrap rate report exists but no real-time scrap alert on the shop floor
