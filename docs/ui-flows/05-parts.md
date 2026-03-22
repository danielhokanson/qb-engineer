# Parts Catalog

**Route:** `/parts`
**Access Roles:** Engineer, PM, Manager, Admin
**Page Title:** parts.title

## Purpose

The Parts Catalog is the master list of all manufactured and purchased parts.
Each part has a Bill of Materials (BOM), a process plan (routing steps),
material specifications, and can be associated with inventory bins.

## Table Columns

| Part # | Description | Type | Status | Material | Customer | Rev | Updated |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Tabs

- Overview
- BOM
- Process Plan
- Files
- Jobs


## Toolbar Actions

- help_outline
- add parts.createPart


## Create Part Dialog Fields

| Field | Type | Required |
|:------|:-----|:---------|
| Part Number | Text | — |
| Description | Text | — |
| Type (Make/Buy/Stock) | Text | — |
| Status (Draft/Prototype/Active/Obsolete) | Text | — |
| Material | Text | — |
| Customer | Text | — |
| Revision | Text | — |
| Unit of Measure | Text | — |
| Lead Time (days) | Text | — |
| Standard Cost | Text | — |
| Notes | Text | — |


## Part Detail (Side Panel / Full Page)

When a part is selected, a detail panel slides out with:
- **Overview:** Core fields, revision history
- **BOM:** Bill of Materials (nested parts + quantities)
- **Process Plan:** Ordered list of manufacturing steps (operations, machine, time)
- **Files:** CAD files, drawings, specifications (MinIO storage)
- **Jobs:** Active and historical jobs using this part

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
- **Start Help Tour (help_outline)** — look for the `help_outline` icon (left side of toolbar)
- **Create Part (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

Parts catalog is a well-implemented master data module. The BOM and process plan
sub-panels are particularly strong for manufacturing traceability.

### Usability Observations

- Part number is user-defined (no auto-generation — intentional for shop numbering systems)
- Barcode scanning supported — scan a part label to jump directly to that part
- Status lifecycle (Draft → Prototype → Active → Obsolete) matches standard NPI flow
- BOM supports nested assemblies (multi-level BOM)

### Functional Gaps / Missing Features

- No BOM cost roll-up (sum of purchased component costs → total BOM cost)
- No BOM where-used reverse lookup (which assemblies use this part?)
- No ECO (Engineering Change Order) workflow — revision changes are manual
- No part number auto-generation or prefix/suffix rules
- Process plan time estimates not tied to actual job time tracking
- No tooling/fixture association per process step
- STEP/STL 3D preview not yet wired to process steps
