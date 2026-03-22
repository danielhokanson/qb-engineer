# Leads (CRM Pipeline)

**Route:** `/leads`
**Access Roles:** PM, Manager, Admin
**Page Title:** leads.title

## Purpose

Leads management provides a lightweight CRM pipeline. Leads represent prospective
customers or new opportunities. When a lead is qualified, it can be converted to a
Customer + Quote, launching the quote-to-cash flow.

## Table Columns

| Company | Contact Name | Email | Phone | Status | Source | Value (est.) | Created |
|:-------|:-------|:-------|:-------|:-------|:-------|:-------|:-------|


## Toolbar Actions

- add leads.createLead


## Create Lead Dialog Fields

| Field | Type | Required |
|:------|:-----|:---------|
| Company Name | Text | — |
| Contact Name | Text | — |
| Email | Text | — |
| Phone | Text | — |
| Source (Referral/Website/Cold/Trade Show/Other) | Text | — |
| Estimated Value | Text | — |
| Status | Text | — |
| Notes | Text | — |


## Lead Statuses

New → Contacted → Qualified → Proposal Sent → Won → Lost

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
- **Create Lead (add)** — look for the `add` icon (top-right corner)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★☆☆

Leads covers basic opportunity tracking. It's lightweight by design for job shops
that don't need full CRM functionality.

### Usability Observations

- Lead-to-customer conversion button creates customer record and optionally a quote
- Source field allows tracking marketing ROI
- Status progression is linear (no kanban-style pipeline view for leads)

### Functional Gaps / Missing Features

- No pipeline kanban view for leads (table only — harder to see funnel shape)
- No lead scoring or prioritization algorithm
- No follow-up task/reminder creation from a lead
- No email integration (send email from within lead)
- No lead assignment to sales team members with ownership rules
- No bulk status update for leads
- Won/Lost reason tracking is notes-only, not a structured field
