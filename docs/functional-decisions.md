# Functional Decisions

## Kanban Board
- Track types: Production, R&D/Tooling, Maintenance, Other + custom user-created
- Cards can move backward unless a QB document at that stage is irreversible (Invoice, Payment)
- Backward moves across QB boundaries: double confirmation showing consequences
- Irreversible stages: drag blocked with tooltip explaining why
- Board shows only planned active work
- Cards archived to full searchable task list (never deleted)
- SignalR real-time sync, last-write-wins for concurrency
- **Multi-select mode:** toggle via toolbar button or `Ctrl+Click` on cards. Selected cards get a checkbox overlay. Bulk actions toolbar appears: Move to Stage, Assign To, Set Priority, Archive. Confirmation dialog shows count and action before executing. Multi-select available on both Kanban board and list views.

## Production Track Stages (aligned to QB)
Quote Requested → Quoted (QB Estimate) → Order Confirmed (QB Sales Order) → Materials Ordered (QB PO) → Materials Received → In Production → QC/Review → Shipped (QB Invoice) → Invoiced/Sent → Payment Received (QB Payment)

## Task Linking & Subtasks
- Subtasks: lightweight checklist on a card (text, optional assignee, checkbox)
- Card linking with relationship types: related to, blocks/blocked by, parent/child
- No formal split mechanism — use linked cards for partial shipments

## Activity Log (Per-Entity Change History)
Every entity with a detail view (job, part, asset, lead, customer, expense) shows a chronological activity timeline.

- **Timeline format** — vertical timeline with newest entries at top. Each entry shows: timestamp, user avatar/name, action description, and old→new values for field changes.
- **Action types:** created, field changed, stage moved, file attached/removed, subtask added/completed, comment added, linked/unlinked, assigned/unassigned, status changed
- **Collapsible sections** — batch field changes in a single edit collapse into one entry ("Daniel updated 4 fields") that expands on click to show individual changes
- **Filterable** — filter by action type (moves, edits, comments, files) or by user. Default: show all.
- **Inline comments** — users can add timestamped comments directly in the activity log. Comments support @mentions (triggers notification).
- **System events** distinguished from user actions — system events (auto-reorder, sync, scheduled task) shown with a system icon and lighter styling
- **Not editable** — activity log entries are immutable. Comments can be deleted by author or admin (soft-delete, marked as "[deleted]")
- Stored in `job_activity_log` for jobs, `audit_log` for cross-entity system-wide audit

## Backlog
- New jobs arrive in backlog by default, not on the board
- Prioritized list, drag to reorder
- Curated during Planning Day — pull into planning cycle to commit
- Badge count in nav

## Planning Cycles
- Default 2-week duration (configurable in system_settings)
- Day 1 is Planning Day with guided flow:
  - Maintenance due this planning cycle (auto-create cards)
  - Rollover from last planning cycle
  - Backlog review and curation
  - Planning cycle goals (optional freeform)
- Split-panel planning screen: prioritized backlog (left) → planning cycle (right), drag to commit
- Daily prompts continue (Top 3 for tomorrow each evening)
- End of planning cycle: incomplete items roll over or return to backlog

## Leads
- Pre-customer lifecycle, lives in our app only (not in QB)
- Statuses: New → Contacted → Quoting → Converted → Lost
- Conversion creates QB customer via API + links records
- "Convert and Create Job" shortcut
- Internal quotes before conversion (not QB Estimates yet)
- Lost leads: reason captured, searchable, can be reopened
- Custom fields via same JSON system

## Customer Returns
- Engineer sees one button: "Customer Return"
- 3 questions: what happened (dropdown), how many, photo (optional)
- Defective/Wrong Part auto-creates rework card in backlog
- Office manager (or engineer in solo mode) handles QB credit memo
- Engineer never sees accounting terminology

## Expenses
- Simple 5-question daily prompt for engineer
- Self-approval permission per user (flag + optional dollar threshold)
- When self-approval off: goes to approval queue for manager/owner
- Searchable expense history, role-scoped visibility
- Writes to QB after approval (or immediately if self-approved)
- Receipt stored in MinIO

## Invoice Flow
- System setting: invoiceWorkflow — "direct" (current) or "managed" (future with office manager)
- Direct mode: engineer confirms "Ready to invoice" → app creates QB Invoice from Sales Order → double confirmation
- Managed mode: engineer confirms → goes to office manager queue
- Escalating nudge system: 0-2 days informational, 3-5 yellow, 5+ red
- Deposits/progress billing: read-only display from QB, handled by financial person in QB

## Order Management (Quote-to-Cash)
The kanban board is a **workflow visualization** tool — it shows where work is and helps organize tasks. The order management system is the **business transaction** layer — it tracks what the customer ordered, what was shipped, and what they owe. Both views exist in parallel and stay in sync.

### Sales Orders
A Sales Order is the business commitment between the company and a customer. It captures what was ordered, pricing, quantities, and delivery expectations.

**Sales Order fields:**
- Order number (auto-generated, sequential: `SO-0001`)
- Customer (FK → customers)
- Customer PO reference (text — the customer's purchase order number, externally provided)
- Order date
- Required delivery date (overall)
- Status: Draft → Confirmed → In Production → Partially Shipped → Shipped → Closed
- Notes / special instructions
- Shipping address (defaults from customer, overridable per order)
- Credit terms (defaults from customer, overridable per order)
- Tax exempt (from customer record)

**Sales Order Lines:**
- Part (FK → parts catalog)
- Description (auto-filled from part, editable)
- Quantity ordered
- Unit price (from price list or manual entry)
- Line total (computed)
- Quantity shipped (computed from shipments)
- Quantity remaining (computed: ordered - shipped)
- Per-line required delivery date (optional, overrides header)
- Status: Open → Partially Shipped → Shipped → Closed

**Relationship to Jobs:**
- Creating a Sales Order can auto-generate Job cards (one per line item, or one per order — configurable)
- Jobs link back to their Sales Order line via `sales_order_line_id`
- Moving a Job to "Shipped" stage updates the corresponding SO line's shipped quantity
- A Sales Order can have multiple Jobs (multi-line order) and a Job can exist without a Sales Order (internal work, R&D)
- The kanban board shows job progress; the Sales Order view shows fulfillment progress

**Multi-line orders:**
- One order, multiple products/quantities — each line can be fulfilled independently
- Partial shipments supported per line (ship 200 of 500 ordered)
- Order status auto-advances based on line statuses (all lines shipped → order "Shipped")

### Quotes / Estimates
Pre-order proposals sent to customers before commitment. Quotes can convert to Sales Orders.

**Quote fields:**
- Quote number (auto-generated: `QT-0001`)
- Customer (FK)
- Quote date, valid until date (expiration)
- Status: Draft → Sent → Accepted → Declined → Expired
- Quote lines: same structure as SO lines (part, qty, unit price, description)
- Notes / terms

**Quote → Sales Order conversion:**
- "Convert to Sales Order" action copies all lines to a new SO
- Quote status set to "Accepted", linked to the created SO
- If accounting provider is connected, creates an Estimate document in the accounting system
- If no accounting provider, quote exists only in the app — fully functional standalone

### Shipments & Partial Delivery
A Shipment records what was physically sent to the customer. Multiple shipments can fulfill a single Sales Order.

**Shipment fields:**
- Shipment number (auto-generated: `SH-0001`)
- Sales Order (FK — which order this fulfills)
- Ship date
- Carrier, service level, tracking number(s)
- Ship-to address (from SO, but overridable)
- Status: Pending → Shipped → Delivered
- Packing slip (auto-generated, printable)
- Shipping cost (optional, for cost tracking)

**Shipment Lines:**
- Sales Order Line (FK — which line item this fulfills)
- Quantity shipped (partial quantities allowed)
- Bin locations picked from (for audit trail)
- Lot numbers (if traceability enabled)

**Workflow:**
1. Job reaches "Shipped" stage OR user clicks "Create Shipment" from the Sales Order
2. System pre-fills shipment lines from remaining SO quantities
3. User adjusts quantities (partial ship), selects carrier, confirms
4. Shipment created → SO line shipped quantities updated → inventory decremented
5. If carrier API configured, shipping label generated (existing shipping integration)
6. Packing slip printed — lists items, quantities, customer PO reference, ship-to address
7. **⚡ ACCOUNTING BOUNDARY:** If accounting provider connected, creates an Invoice in the accounting system for shipped quantities. If standalone mode, creates a local Invoice (see Standalone Financial Mode below).

**Partial delivery tracking:**
- Ship 200 of 500 ordered → SO line shows "200 shipped, 300 remaining"
- Multiple shipments per SO line are tracked independently with dates and quantities
- Each shipment can generate its own invoice (per-shipment invoicing) or invoices can be batched

### Customer Addresses
Customers support multiple addresses for flexible shipping and billing.

**Address model:**
- Customer has one primary billing address (on the Customer entity)
- Customer has zero or more shipping addresses (separate `CustomerAddress` entity)
- Each address: label (e.g., "Main Warehouse", "Plant 2"), street, city, state, zip, country, contact name, contact phone
- One shipping address marked as default
- Sales Orders default to the customer's default shipping address, overridable per order
- Addresses are soft-deleted (historical orders preserve their shipping address)

### Order Views (UI)
- **Sales Orders list** — data table with filters: status, customer, date range, overdue. Shows order number, customer, PO ref, total, status, ship progress (e.g., "3 of 5 lines shipped")
- **Sales Order detail** — header info + line items table + linked shipments + linked jobs + linked invoices (if standalone mode) + activity log
- **Quotes list** — similar to SO list with quote-specific statuses and expiration date
- **Quote detail** — header + lines + "Convert to SO" action
- **Shipments list** — all shipments with tracking, carrier, status, SO reference
- **Open orders dashboard widget** — summary of unshipped order lines, overdue orders

## Standalone Financial Mode

> **⚡ ACCOUNTING BOUNDARY:** Everything in this section duplicates functionality that an accounting system (QuickBooks, Xero, etc.) handles natively. When an accounting provider is connected, these features are **disabled or read-only** — the accounting system is the source of truth. When no accounting provider is configured (standalone mode), the app provides these features internally so the business can operate without external accounting software.

The standalone financial mode is controlled by `system_settings.accountingProvider`:
- **Provider configured and connected:** Financial features sync to the provider. Local invoices, payments, and financial reports are disabled — data comes from the accounting system's API.
- **No provider configured (standalone):** The app manages invoices, payments, AR, and basic financial reporting internally. All data lives in local Postgres tables.
- **Provider configured but disconnected:** Sync queue holds pending operations. Local cache serves stale-but-usable data. Reconnection drains the queue.

### Invoicing (Standalone Mode)

> ⚡ When accounting provider is connected, invoices are created in the accounting system and read back via cache. The local invoice UI becomes read-only.

**Invoice fields:**
- Invoice number (auto-generated, sequential: `INV-0001`)
- Customer (FK)
- Sales Order (FK, optional — invoices can exist without an SO for ad-hoc billing)
- Shipment (FK, optional — links to the shipment that triggered this invoice)
- Invoice date, due date (computed from customer credit terms)
- Status: Draft → Sent → Partially Paid → Paid → Overdue → Void
- Line items: description, quantity, unit price, line total, tax
- Subtotal, tax amount, total
- Amount paid (computed from payments)
- Balance due (computed: total - paid)
- Notes / terms
- PDF generated via QuestPDF (printable, emailable)

**Invoice creation:**
- Auto-created from Shipment (one invoice per shipment, or batch shipments into one invoice — configurable)
- Manual creation from Sales Order (invoice for ordered quantities, not just shipped)
- Ad-hoc invoice (no SO or shipment — for services, miscellaneous charges)

**Invoice workflow:**
- Draft → review → mark as Sent (manual or email via SMTP)
- System tracks overdue invoices (past due date, unpaid)
- Overdue invoices surface on dashboard and generate notifications
- Escalating nudge system: 0-2 days past due = informational, 3-5 = yellow warning, 5+ = red alert
- Void an invoice: marks as void with reason, adjusts AR

### Payments (Standalone Mode)

> ⚡ When accounting provider is connected, payments are recorded in the accounting system. Local payment recording is disabled.

**Payment fields:**
- Payment number (auto-generated)
- Customer (FK)
- Payment date
- Amount
- Payment method (reference data: Check, ACH, Wire, Credit Card, Cash, Other)
- Reference number (check number, transaction ID, etc.)
- Notes
- Applied to: one or more invoices with amount per invoice

**Payment application:**
- A single payment can be split across multiple invoices
- Partial payments supported (pay $500 of a $1,200 invoice)
- Overpayments tracked as customer credit balance
- Unapplied payments held as credit until applied

### Accounts Receivable & Aging (Standalone Mode)

> ⚡ When accounting provider is connected, AR reports come from the accounting system. Local AR is disabled.

**AR Aging buckets:** Current, 1-30 days, 31-60 days, 61-90 days, 90+ days

**AR views:**
- **AR Aging Summary** — one row per customer: current, 30, 60, 90, 90+ balances, total outstanding
- **AR Aging Detail** — expanded view showing individual invoices per customer with aging
- **Customer Statement** — printable/PDF summary of all outstanding invoices for a customer, with payment history. Emailable via SMTP.
- **Dashboard widget** — total outstanding, total overdue, top 5 overdue customers

### Credit Terms
- Configurable per customer: Net 15, Net 30, Net 45, Net 60, COD, Prepaid, Custom (days)
- Default credit terms set in system settings (applies to new customers)
- Credit terms drive invoice due date calculation and AR aging
- Visible on Sales Order and Invoice

### Sales Tax (Standalone Mode)

> ⚡ When accounting provider is connected, tax calculations defer to the accounting system.

- Tax rate configurable per customer (some customers are tax-exempt)
- Tax exemption certificate stored as FileAttachment on Customer
- Default tax rate in system settings
- Tax applied at the invoice line level
- Basic tax report: total tax collected by period (monthly, quarterly, annual)
- No multi-jurisdiction tax automation — single rate per customer. For complex tax needs, use an accounting provider.

### Basic Financial Reports (Standalone Mode)

> ⚡ All reports in this section are disabled when an accounting provider is connected. Financial reporting belongs in the accounting system.

- **Revenue by Period** — invoiced revenue by month/quarter/year, with trend chart
- **Revenue by Customer** — total invoiced per customer, sortable, with percentage of total
- **Outstanding Receivables** — AR aging summary (same as AR view, also available as report with CSV export)
- **Payment History** — all payments received by period, by customer, by method
- **Simple P&L** — revenue (invoiced) minus expenses (from Expense module) by period. NOT a full income statement — just the data the app owns. For accrual-basis accounting, use an accounting provider.
- **Sales Tax Summary** — tax collected by period for filing
- **Customer Statement** — per-customer invoice + payment history (printable PDF)

### Vendor Management (Standalone Mode)

> ⚡ When accounting provider is connected, vendors are read-only from the accounting system (existing behavior). In standalone mode, vendors are managed locally.

- In standalone mode, "Add Vendor" creates a local vendor record (instead of redirecting to accounting system)
- Local vendor fields: company name, contact name, email, phone, address, payment terms, notes, status (active/inactive)
- Vendor records sync to accounting system when a provider is later connected

## Pricing & Quoting

### Price Lists
Per-customer or default pricing for parts. Supports quantity breaks for volume discounts.

**Price List fields:**
- Name (e.g., "Standard", "Preferred Customer", "Distributor")
- Effective date, expiration date (optional)
- Status: Active, Inactive
- Customer (FK, nullable — null = default price list)
- Price entries: Part (FK), unit price, minimum quantity (for breaks)

**Quantity breaks:**
- Multiple price entries per part with different minimum quantities
- Example: Part X — 1-99 units @ $5.00, 100-499 @ $4.50, 500+ @ $4.00
- Quote and SO line items auto-select the correct price based on quantity
- Manual override always available (user can type any price)

**Price resolution order:**
1. Customer-specific price list (if exists and has the part)
2. Default price list (if exists and has the part)
3. Part's base price (on the Part entity)
4. Manual entry (no configured price)

### Recurring Orders
Customers who order the same parts regularly can have order templates that auto-generate Sales Orders on a schedule.

**Recurring Order fields:**
- Customer (FK)
- Template name (e.g., "Monthly Holster Restock")
- Recurrence: weekly, biweekly, monthly, quarterly, custom interval (days)
- Next occurrence date
- Auto-create or draft (draft = creates a Draft SO for review; auto-create = creates Confirmed SO)
- Status: Active, Paused, Cancelled
- Template lines: Part (FK), quantity, unit price (from price list at time of creation)

**Workflow:**
- Hangfire background job checks recurring orders daily
- On due date: creates a new SO (draft or confirmed based on setting)
- Notification sent to order creator / manager
- Prices re-evaluated from current price list at creation time (not locked to template price)
- Admin can pause/cancel recurring orders at any time

### Margin Visibility
Cost-vs-revenue analysis per job, part, and customer. Uses data the app already owns.

**Cost components (from app data):**
- Material cost: BOM entries × part cost (from last PO price or part base cost)
- Labor cost: time entries × labor rate (configurable per role/user in system settings)
- Shipping cost: from shipment records
- Other costs: from expenses linked to a job

**Revenue:** from Sales Order line prices (or invoice totals in standalone mode)

**Margin views:**
- **Job margin** — total cost vs total revenue per job, shown on job detail
- **Part margin** — average margin across all jobs for a given part
- **Customer margin** — aggregate margin across all jobs for a customer
- **Margin report** — filterable list with margin %, sortable, CSV export
- Dashboard widget: top/bottom 5 jobs by margin

**Note:** Margin calculations are estimates based on app-owned data. For authoritative cost accounting, use the accounting system.

## Time Tracking
- Two input methods: start/stop timer or manual entry
- Part-time production workers are primary users
- Entries write to QB Online as Time Activities (drives payroll)
- Time entry fields map to QB: employee, customer, hours, date, service item, notes
- Same-day edits allowed; after EOD entries lock (admin override with audit)
- Missing time flagged in system health panel
- Pay period awareness with hour summaries

## File Management (MinIO)
- No file size limit by default (configurable in system_settings)
- Chunked upload for large files with progress bar
- Files never deleted, only superseded by newer revisions
- Default access: open to all authenticated users
- Optional per-file restriction: toggle on, pick users/roles
- Employee docs: always restricted to employee + Admin + Office Manager

## Asset/Equipment Registry
- Simple list: name, type, location, manufacturer, model, serial, status, photo
- Types: Machine, Tooling, Facility, Vehicle, Other
- Maintenance cards reference an asset instead of a customer
- Scheduled maintenance: interval-based (days or machine hours)
- Overdue schedules surface on Planning Day for auto-card creation
- Downtime logging: start/stop datetime fields on maintenance cards
- Machine hours: manually updated field on asset

## Production Traceability
- Data model supports FDA 21 CFR Part 820 / ISO 13485 level
- Traceability profiles (JSON template) control which fields are required
- Default "Standard" profile: lot number, material lot, machine, operator, quantity, QC pass/fail
- "Medical" profile: full DHR with incoming inspection, CoC, process parameters, dimensional results, sample retention
- Profiles assigned at customer, job, or track type level
- Production runs logged per job card (multiple runs per job)
- QC checklists defined per part/mold as templates
- Electronic signatures: re-prompt password for sign-off (TODO: [ANALYSIS] for full Part 11)

## Unified Notification System
Single system — everything is a notification. Users can author notifications to everyone, a specific user, or themselves. System auto-creates notifications from background jobs and events. One bell icon, one panel, one table.

**Sources:**
- **User-authored**: post a notification to everyone, a specific user, or self (private reminder)
- **System-generated**: background jobs and event handlers create notifications automatically

**System-generated notification types:**
- Job assigned to you, job overdue, job card moved
- Expense approved/rejected
- Maintenance schedule due
- Planning cycle starts tomorrow, Planning Day reminder
- QB sync failed, QB token expiring (admin only)
- Time entry missing for yesterday
- Lead follow-up overdue
- Note posted to you
- Backup failed (admin only)

**Notification UX:**
- Bell icon → dropdown panel with filter tabs: All | Messages | Alerts
- Filterable by: source (user/system), date range, severity (info/warning/critical), notification type (assignment, overdue, expense, maintenance, etc.), read/unread, dismissed/active
- Saved filter presets — users can save named filter combinations for quick reuse
- Each item: icon/avatar, preview text, timestamp
- **Link to source**: items with entity_type/entity_id show "View" link → navigates to job card, expense, lead, part, etc.
- **Inline reply**: for user-authored notifications, reply field right in the dropdown — no navigation needed
- **Dismiss**: non-essential items have dismiss action. Non-dismissable items persist until resolved — includes both system health (QB token expiry, backup failure) AND production/task status (QC failed, job blocked, overdue past threshold, expense pending approval, maintenance overdue). Each notification type has a `dismissable` flag set in a type registry; some types are conditionally non-dismissable based on severity.
- **Pin**: keep important items at top
- **Bulk actions**: "Mark all read", "Dismiss all"
- **"New Notification" button**: at top of panel to quickly post a user-authored notification

**Visibility rules:**
- everyone: all authenticated users see it
- user: only author + target user see it
- self: only author sees it (private reminder)

**Delivery:**
- SignalR for real-time push
- Stored in Postgres for persistence across sessions
- Per-user preference per notification type: in-app only, in-app + email, or muted
- Email via SMTP with .ics calendar attachments for schedule events

**Email Templates:**
- All notification emails use a shared branded wrapper template: app logo, app name (from admin branding settings), consistent header/footer
- Body content is per-notification-type using simple text templates with variable substitution (e.g., `{{job.title}}`, `{{user.displayName}}`, `{{dueDate}}`)
- Templates are code-defined (not admin-editable in v1) — consistent formatting, no WYSIWYG editor needed initially
- Admin branding (logo, colors, app name) automatically applied to all outbound emails
- Localized using the same terminology/i18n system as the UI
- Email types: assignment, overdue alert, expense approval, maintenance due, planning cycle reminder, account setup invite, scheduled digest

**System health panel (admin)** remains a separate view for operational monitoring (QB sync status, orphan detection, storage, backup) but critical health alerts ALSO create notifications in the bell queue for admin users.

## Reporting (engineering/delivery focused, not financial)

All reporting is operational — financial reporting stays in the accounting system. Pre-built views with date range pickers, filters, and CSV export. Charts via ng2-charts (Chart.js). No custom report builder for now.

### My Reports (All Authenticated Users)
Every employee sees their own data. Available to Engineer, Production Worker, PM, Manager, Admin.

- **My Work History** — jobs/tasks completed, filterable by date range, track type, customer. Shows stage transitions, time spent, and outcome.
- **My Time Log** — hours logged per day/week/month, broken down by job or internal task. Weekly/monthly totals. Matches what syncs to accounting as Time Activities.
- **My Expense History** — submitted expenses with status (approved / pending / rejected), filterable by category and date range.
- **My Planning Cycle Summary** — what I committed vs completed each planning cycle, personal throughput trend.
- **My Training Progress** — completed guided tours, pending training modules.

### Operational Reports (PM, Manager, Admin)
Broader views across team and operations.

- **Jobs by Stage** — snapshot of all active jobs across kanban stages, filterable by track type, customer, assignee.
- **Overdue Jobs** — jobs past due date, sorted by severity, with assignee and days overdue.
- **On-Time Delivery Rate** — trend chart showing percentage of jobs shipped by due date over time.
- **Average Lead Time** — quote-to-ship duration, filterable by customer, part, track type. Useful for quoting accuracy.
- **Time in Stage (Bottleneck Analysis)** — average dwell time per stage, highlights where jobs stall.
- **Team Workload** — current assignments per worker, capacity view, unassigned jobs.
- **Employee Productivity** — hours logged by employee, jobs completed, on-time rate. Filterable by date range.
- **Labor Hours by Job** — time entries rolled up per job (hours, not dollars — financials stay in QB).
- **Expense Summary** — all expenses by category, employee, status, date range. Totals and averages.
- **Cycle Review** — committed vs delivered per planning cycle, rollover rate trend, throughput (jobs per planning cycle).
- **Customer Activity** — jobs per customer, average lead time, on-time rate, return rate. Operational view of customer health.
- **Quote-to-Close Rate** — estimates sent vs orders confirmed, average time to close.

### Inventory & Production Reports (PM, Manager, Admin)
- **Inventory Levels** — current stock by part, location, with low-stock highlights and reorder status.
- **Inventory Movement History** — receipts, consumption, adjustments, transfers over time. Filterable by part, location.
- **Quality / Scrap Rate** — rejected quantities vs produced, by part, job, employee. Trend over time.
- **Cycle Time by Part** — average production time per part across jobs, useful for future quoting and capacity planning.
- **Shipping Summary** — shipments by carrier, service level, cost trends, delivery confirmation rates.

### Maintenance Reports (PM, Manager, Admin)
- **Scheduled vs Unscheduled** — ratio and trend of planned maintenance vs emergency repairs.
- **Downtime by Asset** — hours of downtime per asset, impact on production.
- **Overdue Schedules** — maintenance tasks past due, sorted by priority.
- **Maintenance Compliance** — schedule adherence rate over time.

### Lead & Sales Reports (PM, Manager, Admin)
- **Active Leads by Status** — pipeline view of leads by stage.
- **Conversion Rate** — leads converted to customers over time.
- **Follow-up Overdue** — leads with past-due follow-up dates.
- **Return Rate** — customer returns by reason, part, customer. Trend over time.

### R&D & Internal Reports (PM, Manager, Admin)
- **R&D Iterations** — iterations per project (how many cycles before production-ready).
- **Concept to Production** — handoff time from R&D to production track.
- **R&D Cards by Stage/Assignee** — current state of R&D work.
- **Internal Task Adherence** — scheduled task completion rates, overdue trends, average completion time.

### Admin-Only Reports
- **System Audit Log** — who changed what, when. Filterable by user, entity type, action type, date range. Searchable.
- **Integration Health** — sync queue depth, failure rate, last successful sync per integration (accounting, shipping, SMTP).
- **Storage Usage** — file storage by bucket (job files, receipts, employee docs), growth trend, current capacity.
- **User Activity** — login frequency, last active date, role distribution, unclaimed accounts.
- **Employee Onboarding Status** — unclaimed accounts, time-to-claim, active/inactive/deactivated roster.

### Scheduled Email Digest (Optional)
- Weekly summary email to managers/admin with key metrics: overdue jobs, planning cycle progress, maintenance due, low stock alerts.
- Configurable per user: opt-in, frequency (daily/weekly), content selection.
- Requires SMTP configured.

## Shop Floor Display & Time Clock Kiosk
- Dedicated route: /display/shop-floor
- No login required (read-only overview, trusted LAN)
- Shows: active production jobs, machine status, completed today, maintenance alerts, planning cycle progress
- **Worker presence list (always visible on idle screen):** names of all clocked-in workers, their current task/assignment, time on current task. This is the primary view when no scan interaction is happening — the display serves as a live "who's here, doing what" board.
- No individual performance metrics
- Full-screen, large text, high contrast, auto-refreshes via SignalR
- Browser kiosk mode on shop floor PC
- Configurable: which sections shown, rotation interval, which track types

### Time Clock (integrated into shop floor display)
- **Tiered authentication** — the kiosk uses the tiered auth system (see `roles-auth.md §Tiered Auth`). Scan methods (RFID/NFC or barcode) are the primary input; all scans require a **PIN confirmation** before any action is executed.
- **Passive scan listener** — the kiosk screen idles on the shop floor overview and waits for a scan event. No UI buttons needed to initiate clock-in/out. The worker simply scans their badge/barcode/NFC card, enters their PIN, and the system responds.
- **Admin configures scan method** in admin settings:
  - Barcode scanner (keyboard wedge — reads as keyboard input)
  - NFC reader
  - RFID reader
  - If no scan hardware is configured, workers fall back to the "Manual Login" link (Tier 3: username + password) to clock in/out and update production status
- **On scan + PIN (not clocked in):** system identifies the worker, clocks them in, shows a brief confirmation overlay (name, time, "Clocked In"), then returns to the shop floor overview
- **On scan (already clocked in, has assigned tasks):** system identifies the worker and shows a three-choice prompt: **"Update Task"**, **"Clock Out"**, or **"Break / Lunch"**
  - **Update Task** → shows the production quick action panel (see below)
  - **Clock Out** → if the worker has any active production runs or in-progress tasks, prompts them to update each one before clocking out (update qty, mark complete, or leave as-is). After all items are addressed, clocks them out.
  - **Break / Lunch** → logs break clock-out immediately (no task review needed — tasks remain in-progress during break)
- **On scan (already clocked in, no assigned tasks):** system shows a simple prompt: **"Clock Out"**, **"Break / Lunch"**, or **"Cancel"**. No task actions needed — just confirm intent.
- Clock-in/out events create time entries that sync to the accounting system as Time Activities
- The shop floor display shows the current worker presence list (who is clocked in, current task, time on task)

### Production Quick Actions (via "Update Task" after scan)
- When a clocked-in worker chooses "Update Task", they see quick actions for their current assigned task:
  - **Mark task/production run complete** — advances the card to the next stage
  - **Update quantity complete** — enters current count (produced, rejected) for the active production run
  - **Update current state** — brief status note ("waiting for material", "QC hold", etc.)
  - **Start new production run** — begins a new run entry on the assigned job
- Quick action interface: large buttons, minimal text input, optimized for gloved hands and dirty screens (44x44px+ touch targets)
- All quick actions are logged in the job activity log with the worker's identity and timestamp
- After action (or after a configurable idle timeout), screen returns to the shop floor overview automatically

### Clock Out Flow
- When a clocked-in worker chooses "Clock Out" and has outstanding items:
  - System shows a list of their active production runs / in-progress tasks
  - For each item: large buttons to **Update Qty**, **Mark Complete**, or **Leave As-Is**
  - Worker addresses each item (or skips), then confirms clock out
- If no outstanding items, clock out proceeds immediately with confirmation overlay

### Break / Lunch
- When a worker has no assigned tasks, scan prompt includes **"Break / Lunch"** option
- Workers with assigned tasks can also select break/lunch from the Clock Out prompt (third option alongside "Update Task" and "Clock Out")
- Break/lunch logs a clock-out event with a `break` or `lunch` reason tag — distinguished from end-of-shift clock-out
- **Return from break:** Next scan detects the worker is on break (last event was a break/lunch clock-out). System shows: "Welcome back, [Name] — back from [break/lunch]" and clocks them in automatically. No extra prompts — just scan and go.
- Break duration is calculated and logged (break start → return scan timestamp)
- If a worker is on break for longer than a configurable threshold (e.g., 60 min), the system flags it on the manager dashboard as a notification but does not block the return scan
- **No scan hardware?** Workers without badges use the regular app login to access the same production actions from their Production Worker view

## Dashboard
- Role-based default layouts — each role gets a sensible starting dashboard
- Per-user customizable widgets — rearrange, add, remove, resize
- Layout saved per-user as JSON in user_dashboard_layouts table
- Widget registry service — each widget declares: key, display name, default size, relevant roles, component reference
- Admin can enable/disable widgets system-wide

**Default layouts by role:**
- Engineer: daily priorities, assigned jobs, overdue items, recent activity, planning cycle progress, notifications
- PM: backlog count, progress chart, overdue jobs, lead pipeline, team workload, notifications
- Production Worker: not a dashboard — stays as simplified task list (no dashboard customization)
- Manager: team overview, expense approvals pending, planning cycle progress, overdue, notifications
- Admin: system health summary, user activity, QB sync status, storage usage, notifications

**Widget types include:** daily priorities, assigned jobs, overdue jobs, planning cycle progress/progress chart, backlog count, recent activity, lead pipeline, team workload, expense approvals, maintenance due, my time summary, notifications feed, system health (admin)

First login with no saved layout → role default. User customizes → saved to user_dashboard_layouts.

## Calendar View
A visual calendar showing jobs, maintenance, and internal tasks across time. Available to all roles except Production Worker.

### Month View (Default)
- Grid of days showing color-coded event blocks by type: jobs (blue), maintenance (amber), internal tasks (gray), planning cycle boundaries (green dashed line)
- **Dense days:** when a day has more than 3 events, the cell shows a summary block: "5 tasks" — clicking the block opens a day-detail popover listing all events with type, title, assignee, and status
- Click any individual event to navigate to its detail screen
- Current day highlighted. Overdue items shown with red indicator.
- Filter bar: by track type, assignee, status, customer

### Week View
- Horizontal timeline with each day as a column
- Events shown as horizontal bars spanning their duration
- Same click-to-detail and dense-day popover behavior

### Day View
- Detailed list of all events for a single day, grouped by type
- Includes: start/end times (if applicable), assignee, status, linked job/asset

### Data Sources
- **Job due dates** from active jobs (not archived)
- **Maintenance schedules** — recurring and one-time
- **Internal task schedules** — recurring facility/operational tasks
- **Planning cycle boundaries** — cycle start/end dates shown as markers
- **Planning Day** highlighted on cycle start date

### Integration
- Calendar is a standalone route (`/calendar`) and also available as a dashboard widget (mini month view showing event count per day)
- `.ics` export for any filtered view — import into external calendars (Google, Outlook)

## Screensaver/Ambient Mode (Engineer)
- Individual engineer's priorities in large readable format
- Triggers on idle, restores on mouse movement
- Dedicated route within the app

## Printing
- All list views and detail views are printable via browser print (`Ctrl+P`)
- `@media print` stylesheet hides nav, toolbar, sidebar, interactive controls — content only
- Dedicated printable views: work order sheet, packing slip, QC inspection report, part spec sheet, expense report
- QR/barcode label printing for lot tracking and asset tags — configurable label sizes
- Server-side PDF generation via QuestPDF for download/email: `GET /api/v1/jobs/{id}/pdf?type=work-order`
- "Print" and "Download PDF" buttons on applicable screens

## Disconnection & Offline Queue UX
- When the server connection drops, a persistent banner notifies the user: "Connection lost. Changes will be saved and sent when reconnected."
- Users can continue working — write operations queue in IndexedDB
- A badge on the banner shows the count of pending queued operations
- On reconnection: banner updates to "Connection restored. Sending X pending changes..." with progress
- If queued operations fail on sync (entity deleted/modified by others), a non-dismissable notification explains the conflict with resolution options
- No silent data loss — queued operations are never silently discarded

## Snackbar & Toast Notifications

Two distinct UI feedback systems, both dismissable, both high z-index above all other elements.

### Snackbar (Bottom Center)
- Angular Material `MatSnackBar`, positioned bottom-center of the viewport
- Used for **brief confirmations**: save success, delete confirmation, status updates
- Auto-dismiss after 4 seconds for informational messages; errors do not auto-dismiss
- **Creation navigation:** when the action creates a new entity with a detail screen (e.g., creating a job, adding a part), the snackbar includes an action button: "View Job" / "Open Part" — navigates to the new item. If context suggests the user should stay on the current page (e.g., bulk operations), the action opens the new item in a new tab instead.
- Single snackbar at a time — new snackbar replaces the previous one

### Toast (Upper Right)
- Custom `ToastComponent`, positioned upper-right corner of the viewport
- Used for **detailed feedback**: error messages with stack traces, API error details, multi-line status updates, sync conflict descriptions
- **Copy button** on every toast — copies the full toast content (including error details) to clipboard for support/bug reporting
- Stackable — multiple toasts stack vertically with 8px spacing between them, newest on top
- Auto-dismiss timer: informational toasts auto-dismiss after 8 seconds, warnings after 12 seconds, errors do **not** auto-dismiss (user must click X)
- Severity levels: info (blue), success (green), warning (amber), error (red) — each with distinct icon and left border color

### Z-Index Layering
All z-index values defined in `_variables.scss` as a centralized scale:

| Layer | z-index | Element |
|---|---|---|
| Base content | 0 | Normal page content |
| Sticky headers | 100 | Table headers, toolbars |
| Sidebar / nav | 200 | Navigation drawer |
| Dropdowns / menus | 300 | Mat-select panels, context menus |
| Dialogs / modals | 400 | Angular Material dialogs |
| Snackbar | 500 | Bottom-center snackbar |
| Global loading overlay | 900 | Full-screen spinner with backdrop |
| Toast | 1000 | Upper-right toast stack (highest) |

The global loading overlay sits above dialogs and snackbars but below toasts — a toast error can still be read and copied while the loading overlay is active.

## Loading & Progress System
- **Global loading overlay** via `LoadingService` — blocks interaction, shows animated spinner with a message stack. Main UI container marked `inert` while overlay is active (disables all interaction, tab focus, screen reader access). Toast container sits outside the `inert` boundary so errors remain accessible.
- Each loading cause registered with a message and a trigger (Observable, Promise, Signal, or manual)
- Messages dismiss independently when their trigger resolves — slides off with 300ms fade-out
- Overlay fades in/out over 300ms, minimum 400ms display to avoid flicker
- **Component-level blocking** via `LoadingBlockDirective` — local spinner overlay on a specific component/section, same 300ms fade transitions
- Use global overlay for page loads, local blocking for partial refreshes within a loaded page
- **Empty states** on all list views — icon, message, call-to-action button. Shared `EmptyStateComponent`.

## Global Search
Single search bar in the toolbar (`Ctrl+K` shortcut) searches across all entities. Postgres full-text search with `tsvector` + GIN indexes.

- **Unified results** grouped by entity type: Jobs, Parts, Customers, Leads, Files, Expenses, Assets, Contacts, Vendors
- **Result display:** icon, title, subtitle (e.g., customer name for a job), highlighted matching text, entity type badge
- **Faceted filtering** — after search, filter results by entity type via tabs or chips. Facet counts shown (e.g., "Jobs (3) · Parts (7) · Customers (1)")
- **Fuzzy matching** — Postgres `pg_trgm` extension for trigram similarity on short queries (handles typos). Full-text search with `ts_rank` for longer queries.
- **Custom field search** — JSONB custom field values included in search vectors, searchable alongside standard fields
- **Recent searches** — last 10 searches stored per user (local), shown on empty search focus
- **Quick navigation** — pressing Enter on a result navigates directly to the entity detail. Arrow keys navigate results.
- **Scoped search** — within entity list views (e.g., parts list), the search bar pre-scopes to that entity type with an option to "Search everything" to break out

## Centralized Reference Data
All lookup/dropdown values across the application are stored in a single `reference_data` table with recursive grouping:
- Top-level rows define groups (expense_category, return_reason, lead_source, contact_role, job_priority, asset_type, etc.)
- Child rows are the values within each group
- Admin manages all reference data from one settings screen: add, rename, reorder, deactivate
- Deactivated values hidden from dropdowns but preserved on existing records
- `code` field is immutable (used in application logic); `label` is admin-editable
- `metadata` JSONB column for group-specific extra fields (e.g., color for priorities, icon for asset types)
- No scattered lookup tables — one table, one admin screen, one Angular service

## Default Terminology Mapping
The application ships with manufacturing-friendly default labels. Admin can relabel any term via the terminology system. Internal code/schema names are stable and never change.

| Internal (Code/Schema) | Default Display Label | Notes |
|---|---|---|
| sprint | Planning Cycle | The recurring work period |
| sprint_duration_days | Planning Cycle Duration | system_settings key |
| planning_day | Planning Day | First day of each cycle |
| backlog | Backlog | Standard in manufacturing too |
| velocity | Throughput | Jobs per cycle |
| burndown | Progress Chart | Cycle progress visualization |
| carryover | Rollover | Work moved from prior cycle |
| committed | Planned | Work committed to a cycle |

## TODO: [ANALYSIS] Convention
- // TODO: [ANALYSIS] — business decision pending, needs stakeholder input
- Visible in UI as a banner/callout
- Searchable across codebase separately from dev TODOs
- Current items: employee doc storage, scheduled email reports, Part 11 compliance

## Part / Product / Assembly Catalog
- Recursive BOM structure — parts and assemblies nested to any depth
- Part record: part number, description, revision, status, type (part/assembly), material, mold/tool ref, QB Item linkage, traceability profile, custom fields (JSON)
- CAD/STL/CAM files attach at the part level, versioned by revision
- BOM entries: child part, quantity, reference designator, sort order, source type (Make/Buy/Stock), lead time (days), notes
- Revision control: full history, jobs reference specific revisions, obsolete revisions blocked
- Jobs reference a part → pre-populate specs, material, mold, files, traceability
- Where Used reverse lookup, part searchable via global search
- Parts link to QB Items by ListID for pricing (read-only from QB)

## BOM-Driven Work Breakdown

### BOM Source Types
- **Make** — component fabricated in-house, generates a sub-job during BOM explosion
- **Buy** — component purchased externally, flagged for PO creation (not auto-created)
- **Stock** — pulled from existing inventory (reservation deferred to future feature)

### Process Plan / Routing
- Parts (especially Assemblies) can have ordered manufacturing steps via `ProcessStep` entity
- Each step: sequence number, title, instructions, work center, estimated time
- QC checkpoints with pass/fail criteria
- Steps define HOW to build; BOM defines WHAT it's built from
- CRUD endpoints on PartsController (`/api/v1/parts/{id}/process-steps`)

### BOM Explosion
- When a Job references an Assembly part with BOM entries, user can "Explode BOM"
- One-level explosion only — prevents accidentally generating hundreds of jobs from deep BOMs
- Make entries → child Jobs with `ParentJobId` set, bidirectional `JobLinks`
- Buy entries → listed for manual PO creation
- Stock entries → listed for inventory picking (reservation deferred)
- Sub-assemblies can be individually exploded from their child jobs
- Handler: `ExplodeJobBom` in Features/Jobs/

### Job Hierarchy
- `ParentJobId` FK on Job enables tree structure
- Job detail shows parent link and child jobs list (`GetChildJobs` endpoint)
- Kanban card shows sub-job count indicator
- `LeadTimeDays` on BOMEntry supports scheduling visibility

## In-App Guided Training
- Tour definitions stored as JSON
- First-login tour, per-feature tours, role-based tours
- Help icon (?) on every page — always accessible, replays current screen tour
- Help mode toggle — contextual help icons on all interactive elements
- Build-time test: CI fails if any route is missing a tour definition
- Runtime sync check (DEV_MODE=true): overlay highlights stale or uncovered tour elements
- tour_completions table tracks per-user progress
- Admin training dashboard shows completion status

## Theming & Accessibility
- User-selectable light/dark mode toggle in toolbar, preference saved per-user
- Admin controls 3 brand colors (primary, accent, warn) via admin settings screen — runtime, no rebuild needed
- Contrast validation: UI warns admin if selected colors violate WCAG 3 thresholds before saving
- Logo, app name, and font configurable in admin settings
- WCAG 3 compliance target — APCA contrast scoring, reduced motion support, keyboard navigation, screen reader testing, 44x44px touch targets
- Both light and dark themes auto-generated from the admin-set palette

## Chat System
Two options evaluated: third-party integration or bespoke. Decision: **bespoke, built on existing SignalR infrastructure.**

Rationale: the app already has SignalR for real-time sync. Adding a chat hub is lightweight. A third-party chat service adds external dependency, data leaving the network, and subscription cost — all contrary to the self-hosted philosophy.

**Features:**
- 1:1 direct messages between any two users
- Group chats — created by any user, invite members, named channels
- Pre-created group chats by admin (e.g., "Shop Floor", "Engineering", "Management")
- Persistent message history stored in Postgres
- Real-time delivery via SignalR `ChatHub`
- Unread count badge on chat icon in toolbar (separate from notifications)
- Typing indicators, read receipts (optional per-user preference)
- File/image sharing — reuses existing MinIO file upload infrastructure
- @mention a user — triggers a notification in their bell queue
- Searchable message history
- Infinite scroll for message history — cursor-based pagination, loads older messages on scroll-up
- Chat icon always visible in toolbar (next to notification bell)
- Opens as a popover/slide-out panel — easily dismissable by clicking outside or pressing Escape
- User stays on their current page while chatting — no route navigation
- Popover remembers last-viewed channel on reopen

**What chat is NOT:**
- Not a replacement for the notification system — notifications are for system events and structured messages. Chat is for informal, real-time conversation.
- Not threaded (no reply chains) — keep it simple like a team messaging tool

**Integration with existing features:**
- "Share to chat" action on job cards, parts, expenses — inserts a link into the chat message
- Chat messages can reference entities: `#JOB-1234` auto-links to the job card

## Bin & Location Tracking
Physical storage locations organized in a recursive hierarchy. Every bin has a barcode label — scan to see contents or move items.

### Location Hierarchy
- **Area** → **Rack/Shelf** → **Bin** (recursive via `parent_id`, any depth)
- Examples: "Warehouse A" → "Rack 3" → "Shelf B" → "BIN-0042"
- Admin manages the hierarchy from a settings screen: add areas, racks, shelves, bins
- Each level has a name, optional description, and sort order
- Only bins (leaf nodes) hold inventory — parent levels are organizational

### Location & Bin Labels
- **Bin labels** — every bin gets a unique barcode value (auto-generated or admin-assigned). Labels include: barcode, bin code, location path (e.g., "WH-A / Rack 3 / Shelf B"), and optionally a QR code. These are placed on or near the physical bin.
- **Location labels (semi-permanent)** — shelves, racks, and areas can also have printed labels showing the location name and hierarchy path. These are larger labels designed to be affixed to shelves/racks as permanent identification. No barcode needed on these (optional) — they're for human navigation.
- **Print from admin settings** — when creating or editing a location (area, rack, shelf, bin), admin can print labels from the location detail screen
- **Bulk print** — admin can bulk-print all labels for a newly created area or rack in one pass
- Uses bwip-js for barcodes, configurable label sizes (same format system as production labels — sticker sheets, full-page, custom dimensions)

### What Goes in Bins
- **Parts / raw material** — with quantity and optional lot number
- **Production run output** — finished goods from a specific run, with quantity and lot
- **Assemblies / sub-assemblies** — with quantity
- **Tooling / molds** — reference to an asset record
- **Ready-to-ship items** — finished goods awaiting shipment, marked with `ready_to_ship` status
- **General inventory stock** — parts received on POs not tied to a specific customer or job (see "General Inventory / Unassigned Stock" below)
- Each bin entry tracks: what entity, quantity, lot number (if applicable), status (stored / reserved / ready_to_ship / qc_hold), who placed it, when

### General Inventory / Unassigned Stock
Parts can arrive on purchase orders that are **not assigned to any specific customer or job** — they are simply stock inventory kept on hand.
- **PO without a job reference:** When receiving parts from a PO that has no linked job, the received items go into bin storage as general inventory
- **bin_contents entry:** `entity_type` = `part`, `entity_id` = part record, no job reference. Status: `stored`
- **Allocation:** When a production run later needs that part, the system can **reserve** stock from general inventory bins (status changes from `stored` → `reserved`, with a job reference added)
- **Receiving flow:** On "Materials Received" stage, if the PO is job-linked, parts go to the job's context. If the PO is general stock, parts go to general inventory bins with a prompt for bin location.
- **Inventory view:** Parts catalog shows total on-hand quantity across all bins (general stock + job-allocated), with breakdown by bin location
- Works alongside job-specific procurement — a manufacturer can buy material for a specific order AND keep general stock of commonly used parts

### Scanning UX
- **Scan a bin barcode** → shows bin contents (items, quantities, lots) with options to add, remove, or move items
- **Scan a part/lot barcode** → shows which bin(s) it's currently in ("Where is this?")
- **Move items between bins**: scan source bin → select items → scan destination bin → confirm. Both bins update, move logged.
- Works from: shop floor kiosk (scan listener), Production Worker view, or any authenticated user on desktop/mobile
- Move history is fully auditable — who moved what, from where, to where, when

### Default Bin Locations
- **Parts and raw materials** can have a **default storage location** configured on the part record (e.g., "Part X always goes in BIN-0042")
- **Track types / production stages** can have a default output bin (e.g., "QC output always goes to QC-HOLD-01", "Finished goods go to SHIP-STAGING")
- When a production run is completed or a status change occurs, the system **pre-fills the bin location** from the default if one is configured
- If no default is set, the user is **prompted to specify the location** — "Where are you putting this?" with a bin picker (or scan)
- Defaults are suggestions — the user can always override at the time of placement
- Admin configures defaults from the part record, track type settings, or bin management screen

### Integration with Existing Features
- **Job cards** — when starting a production run, the system suggests bin locations for required materials ("Part X is in BIN-0042")
- **Production runs** — on completion, system pre-fills output bin from default; user confirms or changes. Prompted if no default set.
- **Part catalog** — part detail screen shows current bin location(s), quantities, and configured default bin
- **QC** — QC hold items can be moved to a designated QC bin (configurable default), released items moved to finished goods bins
- **Shipping** — packing slip references bin locations for pick list. Items marked `ready_to_ship` in their bin are surfaced on the shipping/invoice stage of job cards.
- **Printing** — bin contents printable as a pick list or inventory snapshot

## Production Label Printing
When a new production task or production run is created, the system prompts the user to print barcode labels.

### Label Prompt
- On production task/run creation → "Print label(s)?" prompt with preview
- User specifies **number of labels** — for large orders that will be split across multiple bins
- Default label count: 1. User can increase for multi-bin splits.
- Labels print via browser print dialog (bwip-js for barcode generation, CSS print stylesheet for layout)

### Label Contents
Every label includes both a scannable barcode and human-readable identification:
- **Barcode** — unique per label, encodes a label ID that resolves to the production run, lot, and bin-split index (e.g., `LBL-00042-003`). One barcode per label is sufficient — scanning it identifies the run, lot, and split.
- **Job number** — e.g., `JOB-1234`
- **Part name / description** — human-readable identification of what the label is placed on
- **Customer name** (if applicable)
- **Lot number** (if applicable)
- **Quantity in this bin** — how many units are represented by this label
- **Label X of N** — e.g., "Label 2 of 5" so the user knows there are multiple bins and which one this is
- **Production / run date**
- **Due date** (from job card)

### Barcode Strategy
Each printed label gets **one barcode** — a unique label ID (e.g., `LBL-00042-003`) that maps back to the production run, lot number, and split index in the database. This is sufficient because:
- Scanning the label barcode resolves to the full production run context (job, part, customer, lot, quantity)
- No need for a separate "order barcode" — the label ID already links to the order
- Bin barcodes are separate physical labels on the bins themselves (from the Bin & Location system)
- To place items in a bin: scan the production label → scan the bin → confirmed

### Label Format & Printing
- **Admin-configurable label layout** — admin settings screen allows selecting label dimensions and format:
  - Standard sticker sheets (Avery-style: 2x10, 3x10, 4x20 grids, etc.)
  - Single labels (thermal printer roll)
  - Full-page printout (for clear sleeves on larger containers)
  - Custom dimensions (width x height in mm)
- Page margins, label padding, and font sizes auto-adjust to selected format
- Print preview shows exact layout before printing
- Uses CSS `@media print` + `@page` rules for precise alignment
- bwip-js generates barcodes client-side; QuestPDF available for server-side PDF generation if needed

### Multi-Bin Workflow
For large orders where output is split across multiple bins:
1. User enters total quantity and number of bins (labels)
2. System auto-divides quantity across labels (evenly by default, user can adjust per-label)
3. Each label shows its specific quantity and its position (X of N)
4. On print, system creates corresponding `bin_contents` entries if bins are assigned
5. User can scan each label into a specific bin after printing

### Reprint
- Labels can be reprinted from the production run detail screen or job card
- "Print labels" action available on any existing production run

## Shipping & Carrier Integration
When a job reaches the "Shipped" stage, the system supports printing shipping labels and packing slips for outbound packages.

### Shipping Workflow
1. Job card moves to "Shipped" stage (or user clicks "Prepare Shipment" on a ready-to-ship job)
2. System pre-fills shipment details from the job and customer record: ship-to address, items, quantities, weights (from part catalog)
3. User selects carrier and service level (or enters manual tracking info)
4. If a carrier API is configured: system requests rates, user selects, system generates the shipping label
5. If no carrier API: user prints a generic packing slip and enters tracking number manually
6. Tracking number stored on the job card and visible to all users
7. Packing slip printed — lists items, quantities, bin locations (pick list), and customer ship-to address

### Pluggable Carrier Integration
Same pluggable pattern as accounting — `IShippingService` interface with provider-specific implementations.

**Interface operations:**
- Get rates (origin, destination, weight, dimensions → list of service/price options)
- Create shipment / generate label (returns label PDF + tracking number)
- Void shipment (cancel before pickup)
- Track shipment (returns status/events)

**Supported carriers (implemented over time):**
- **UPS** — UPS REST API (OAuth 2.0)
- **FedEx** — FedEx REST API (OAuth 2.0)
- **USPS** — USPS Web Tools API (shipping + free address validation)
- **DHL** — DHL Express API
- **Manual / No Carrier** — default mode, no API calls, user enters tracking number manually

**Provider setup:**
- Admin selects carrier(s) in settings — multiple carriers can be active simultaneously
- Each carrier has its own credential setup (API keys, account numbers, OAuth)
- Ship-from address configured in admin settings (company address)
- Default carrier and service level configurable (can be overridden per shipment)

### Shipping Labels
- **Carrier-generated labels:** PDF returned by carrier API, printed directly (standard 4x6 thermal or 8.5x11 paper)
- **Packing slips:** Generated by the app — includes: ship-to, ship-from, items with quantities, job reference, PO number, special instructions
- **Generic shipping labels (no carrier API):** Printable label with ship-to address, ship-from address, job reference, and blank area for manually applied carrier label
- Uses same label format system as production labels — admin-configurable dimensions

### Rate Shopping
- When multiple carriers are active, the "Prepare Shipment" screen shows rates from all configured carriers side-by-side
- User selects the best option (cheapest, fastest, preferred carrier)
- Rate quotes cached briefly (carrier-specific TTL, typically 15-30 minutes)

### Multi-Package Shipments
- Large orders may ship in multiple boxes
- User specifies number of packages, weight/dimensions per package
- Each package gets its own label and tracking number
- All tracking numbers stored on the job card

### Tracking
- Tracking number displayed on the job card detail (clickable link to carrier tracking page)
- Optional: background job polls carrier API for delivery confirmation
- Delivery confirmed → notification to relevant users

### Shipment History
- All shipments logged: carrier, service, tracking number, label cost, ship date, delivery date, packages
- Searchable/filterable shipment list view
- Shipping cost can be associated with the job for cost tracking

## Inventory Management
Unified inventory tracking built on top of the bin/location system and accounting integration. The app owns the physical inventory state (what's where, how much); the accounting system owns the financial inventory value.

### Purchase Order Lifecycle
POs follow an industry-standard workflow aligned with three-way matching (PO → Receipt → Invoice).

**PO Creation:**
- **From a job:** When a job reaches "Materials Ordered" stage, user creates a PO from the BOM — parts, quantities, and preferred vendor pre-populated. User selects vendor, adjusts quantities, adds notes.
- **Standalone (general stock):** Manager/Engineer creates a PO for inventory replenishment without linking to a specific job. Triggered manually or via auto-reorder.
- **Auto-reorder:** System generates a draft PO when stock drops below minimum (see Low Stock & Reorder below).

**PO Statuses:**
Draft → Submitted (synced to accounting) → Acknowledged → Partially Received → Received → Closed

- **Draft:** Created in-app, not yet sent to vendor or accounting. Editable — add/remove lines, change quantities, switch vendor.
- **Submitted:** Synced to accounting system as a PO. Vendor notified (if email configured). Limited editing — can add lines or increase quantities but cannot reduce below what's already received.
- **Acknowledged:** Vendor confirmed receipt (optional step — manual toggle or vendor portal response). Expected delivery date entered.
- **Partially Received:** Some line items received, others outstanding. Remaining quantities tracked as back-ordered.
- **Received:** All line items received in full. Triggers three-way match check.
- **Closed:** PO complete, no further action. System auto-closes when all lines received and matched.

**Partial Receipts:**
- Each PO line tracks: ordered qty, received qty, remaining qty
- Receiving screen shows only outstanding lines (remaining > 0)
- Each partial receive creates a receiving record with quantities, bin locations, and timestamps
- Back-ordered items remain visible on the PO and on a "Pending Deliveries" dashboard widget
- No automatic cancellation of back-ordered items — user manually closes or adjusts

**PO Modifications:**
- Draft POs: fully editable
- Submitted POs: can add lines, increase quantities, add notes. Cannot reduce quantity below already-received amount. Cannot delete lines with received quantities.
- Cancelled PO: user cancels with reason, synced to accounting, remaining unreceived quantities zeroed out

**Multi-PO per Job:**
- A single job can have multiple POs (different vendors, staggered orders)
- Job detail shows all linked POs with their statuses
- Job cannot advance past "Materials Received" until all linked POs are fully received (configurable — admin can allow partial advance)

**Preferred Vendors:**
- Each part can have a preferred vendor (stored on the part record)
- PO creation pre-selects the preferred vendor
- Vendor selection dropdown shows all active vendors with last price and lead time if available

### Vendor Management (Read-Only from Accounting)
Vendors are created and maintained in the accounting system (QuickBooks). The app syncs vendor records via `IAccountingService` and displays them as read-only.

- **Vendor list:** searchable/filterable list of all synced vendors with company name, contact info, status
- **Vendor detail (read-only):** company name, address, phone, email, payment terms, notes — all from accounting system
- **Linked data:** POs issued to this vendor, parts with this vendor as preferred, receiving history, on-time delivery rate
- **No local vendor creation** — "Add Vendor" redirects to accounting system or prompts to create there first
- **Sync frequency:** vendors refresh on each accounting sync cycle and on-demand via "Refresh" button
- **Vendor status:** active/inactive from accounting system. Inactive vendors hidden from PO vendor selection but preserved on historical records.

### Inventory Sources
- **Purchase orders (job-linked)** — materials ordered for a specific job. Received items are tracked against that job.
- **Purchase orders (general stock)** — materials ordered for inventory without a specific job. Received items go into general inventory bins.
- **Production output** — finished goods from production runs. Tracked by lot and quantity.
- **Customer returns** — returned items re-enter inventory (rework bin or general stock depending on disposition)

### Inventory Views
- **Part inventory summary** — for each part: total on-hand qty, qty reserved (allocated to jobs), qty available (on-hand minus reserved), qty on order (open POs), bin locations with quantities
- **Inventory list** — filterable/searchable list of all parts with stock levels. Low-stock items highlighted. CSV export.
- **Bin contents view** — browse by location hierarchy or scan a bin. Shows everything in that bin with quantities, lots, and statuses.
- **Movement history** — audit trail of all inventory movements (receives, picks, moves, ships) with who/when/why

### Receiving Workflow
1. PO arrives at "Materials Received" stage (or standalone receive without a PO)
2. User scans or selects items received, enters quantities
3. System prompts for bin location (pre-filled from part default if configured)
4. Bin contents updated, movement logged
5. If PO is job-linked, items are associated with that job. If general stock, items are unallocated.
6. Receive syncs to accounting system (updates PO status, can trigger bill creation)

### Allocation & Reservation
- When a production run is started for a job, the system checks if required parts are in general inventory
- Parts can be **reserved** for a job (status: `stored` → `reserved`, job_id set on bin_contents)
- Reserved parts are deducted from available inventory but remain physically in their bin until picked
- **Pick list** generated when production begins — lists parts, quantities, and bin locations for the worker to collect

### Low Stock & Reorder
- **Minimum stock level** (optional) configurable per part — triggers a low-stock alert when on-hand drops below threshold
- Low-stock alerts surface on the dashboard (manager/owner) and in the notification bell
- System can suggest a PO for low-stock items (manual approval required by default)
- Reorder quantity configurable per part (default reorder amount)
- **Auto-reorder (optional, per-part):** Admin can enable automatic PO generation for specific parts. When enabled and stock drops below minimum:
  - System generates a draft PO for the configured reorder quantity
  - **Warning notification** sent to admin/manager with PO details before it is submitted
  - Admin has a configurable window (e.g., 24 hours) to review and cancel before the PO is finalized and sent to the accounting system
  - If not cancelled within the window, PO is submitted automatically
  - Auto-reorder is **off by default** — must be explicitly enabled per part by admin
  - Auto-reorder history logged for audit (what was auto-ordered, when, whether cancelled)

### Accounting System Sync
- Inventory quantities sync to the accounting system's item records (if the provider supports it)
- Inventory adjustments (count corrections, write-offs, scrap) logged locally and synced to accounting
- Cost tracking deferred to the accounting system — the app tracks quantities and locations, not dollar values
- Inventory valuation reports come from the accounting system, not the app

### Inventory Count (Cycle Count)
- Admin can initiate a **cycle count** for a location, area, or full inventory
- System generates a count sheet (printable) listing expected items and quantities per bin
- Worker counts actual quantities, enters results
- Discrepancies flagged for review — admin approves adjustments
- Adjustment synced to accounting system

## R&D / Internal Projects
The R&D/Tooling track and internal project workflows support non-customer-facing work — everything from new product development to routine facility tasks.

### R&D / Tooling Track
Purpose-built Kanban workflow for engineering development work:

**Stages:** Concept → Design → CAD Review → Prototype / Test → Iteration → Tooling Approval → Handoff to Production

**Key behaviors:**
- **Iteration loop** — cards can move backward from Prototype/Test to Design (or any earlier stage) without penalty. R&D is non-linear; the board supports it.
- **Customer field is optional** — R&D work may be speculative (no customer yet) or customer-driven
- **Part catalog integration** — R&D cards can create or update a part record. On "Tooling Approval" or "Handoff to Production," the associated part's status is set to Active.
- **Iteration tracking** — each time a card cycles back through prototype/test, the iteration count increments. Test notes, results, and file revisions are logged per iteration.
- **Handoff to Production** — terminal stage creates a new Production track card (or backlog item) linked to the R&D card. Full design history travels with the part.

**R&D card fields (beyond universal job card fields):**
- Target part (FK → parts catalog, nullable — created during R&D or linked to existing)
- Iteration count (auto-incremented on backward moves through test stages)
- Test results per iteration (structured notes + file attachments)
- Design notes, material experiments, tooling specs
- Estimated production cost (manual entry)
- Success criteria (freeform or checklist)

### Job Disposition
When a job is completed, the user selects a disposition — a standard manufacturing MES concept required at job close:
- **Ship to Customer** — normal order fulfillment, proceeds through shipping pipeline
- **Add to Inventory** — finished goods placed into stock (bin location selected)
- **Capitalize as Asset** — auto-creates a Tooling asset linked back to the fabrication job
- **Scrap** — job output discarded, scrap reason + notes recorded
- **Hold for Review** — output held pending QC, engineering review, or customer decision

Disposition is recorded with notes and timestamp. Shown on job detail view and as an indicator on the kanban card.

### R&D / Tooling Outcomes (4 Paths)
R&D/Tooling jobs can conclude in four ways:
1. **Internal Asset** — tool built in-house, kept on shop floor. Promoted to a Tooling asset via the "Capitalize as Asset" disposition. Linked back to the fabrication job and design part.
2. **Customer Deliverable** — tool/part built for a customer. Invoiced and shipped via the normal Sales Order → Shipment → Invoice pipeline.
3. **Customer-Funded Retained** — customer pays for tooling, but the tool stays at the facility for their production runs. Tracked as a Tooling asset with `IsCustomerOwned = true`.
4. **Dead End** — proof of concept or prototype that doesn't proceed. Job completes or is archived with no further action. No asset or inventory created.

### Tool Registry
Tooling assets are a subset of the Asset system (`AssetType = Tooling`) with additional fields:
- **CavityCount** — number of cavities (mold tooling)
- **ToolLifeExpectancy** — expected total shots/cycles before replacement
- **CurrentShotCount** — running count of shots/cycles consumed
- **IsCustomerOwned** — whether the customer funded and owns the tooling
- **SourceJobId** — FK to the fabrication job that built the tool
- **SourcePartId** — FK to the design spec / part record

Production parts reference their tooling asset via `Part.ToolingAssetId` (replaces the old free-text MoldToolRef field).

### NPI Gate (Part Status Lifecycle)
Part status lifecycle supports new product introduction (NPI):
- **Draft** — initial creation, under specification
- **Prototype** — R&D part under active development/testing. Cannot be used on production jobs.
- **Active** — released to production. "Release to Production" action flips status from Prototype to Active.
- **Obsolete** — no longer in use, retained for history

### Auto Part Numbering
Internal part numbers are auto-generated with categorical prefixes:
- **PRT-** — Part (generic manufactured part)
- **ASM-** — Assembly (multi-component assembly)
- **RAW-** — Raw Material
- **CON-** — Consumable
- **TLG-** — Tooling
- **FST-** — Fastener
- **ELC-** — Electronic
- **PKG-** — Packaging

Format: `PREFIX` + 5-digit zero-padded sequence (e.g., `PRT-00001`, `TLG-00042`). Sequence is per-prefix. An optional **external part number** field captures vendor-supplied or customer-supplied part numbers alongside the internal number.

### Internal Projects
Non-customer, non-R&D work that needs to be tracked and assigned. These are operational tasks that keep the shop running.

**Internal project types** (configured as reference data — admin can add/rename):
- Tooling development / mold maintenance
- Process improvement
- Fixture design / jig building
- Material testing
- Machine qualification
- Facility maintenance (beyond asset-specific scheduled maintenance)
- **Inventory tasks** — cycle counts, stock reorganization, bin cleanup
- **Facility tasks** — sweeping, cleaning bathrooms, vacuuming, organizing workstations, trash removal
- **Administrative tasks** — documentation updates, SOP reviews, safety audits
- Custom (admin-defined)

**How internal projects work:**
- Use the "Other" track type (Open → In Progress → Done) or a custom admin-created track
- Cards created manually or auto-generated from schedules (see below)
- No customer or accounting document association
- Assigned to user(s), tracked on the board and in planning cycles like any other card
- Time entries log work hours against internal project categories (not billable to a customer)

### Scheduled Internal Tasks
Recurring facility and operational tasks that should auto-generate cards on a schedule — same pattern as scheduled maintenance but for non-asset-specific work.

**How it works:**
- Admin creates **internal task schedules** from a settings screen
- Each schedule defines: task name, description, category (from internal project types), recurrence rule (daily, weekly, biweekly, monthly, custom interval), default assignee(s), estimated duration, track type
- **On Planning Day**: system scans internal task schedules alongside maintenance schedules. Due tasks are presented in the planning flow: "These internal tasks are due this planning cycle" with options to auto-create and assign cards
- **Between planning cycles**: if a task comes due mid-cycle, it can either wait for next Planning Day (default) or auto-create immediately (configurable per schedule)
- Cards created from schedules are linked back to the schedule record for tracking completion history

**Schedule examples:**
- "Sweep shop floor" — daily, assigned to Production Worker role
- "Deep clean bathrooms" — weekly (Friday), assigned to specific user
- "Vacuum offices" — weekly (Monday), assigned to specific user
- "Inventory cycle count — Area A" — monthly, assigned to Office Manager
- "Organize tool crib" — biweekly, assigned to specific user
- "Safety walkthrough" — weekly, assigned to Manager
- "Update SOPs" — quarterly, assigned to Engineer

**Tracking:**
- Completion history per schedule: when created, when completed, by whom, duration
- Overdue scheduled tasks surface on manager dashboard (same as overdue maintenance)
- Admin reporting: schedule adherence rate, average completion time, overdue trends

### R&D Reporting
- Iterations per project (how many cycles before production-ready)
- Concept-to-production handoff time
- R&D cards by stage, by assignee
- Active R&D projects with progress indicators
- Internal task schedule adherence rate

## UX & Visual Design
- Navigation designed for machinists and non-technical users — large touch targets (44x44px), icon + text labels on all nav items, no ambiguous UI patterns
- Sidebar always visible on desktop (collapsible but not hidden), mobile uses bottom nav or slide-out
- Maximum 2 levels of navigation depth — sub-pages use tabs within the page, not sub-menus
- **Less rounded styling** — 4px border radius default app-wide. No pill-shaped buttons, inputs, or containers. Angular Material chips are the only exception.
- Polished, professional, industrial aesthetic — clean lines, deliberate whitespace, no decorative elements
- Content centered on large screens with a max-width container (~1400px). Exception: Kanban board and shop floor display use full width.
- Minimal margin and padding — lean spacing that maximizes usable screen area. Dense tables and lists with compact row heights. Generous padding only on primary action areas.
- No full-bleed layouts that stretch across ultra-wide monitors

## Pluggable Accounting Integration
- `IAccountingService` defines the common interface for all accounting operations (customers, invoices, estimates, POs, payments, time activities, employees, vendors, items)
- **QuickBooks Online is the default** — pre-selected in the admin setup wizard, first and most complete implementation
- Additional providers (Xero, FreshBooks, Sage, etc.) can be added by implementing the same interface with their own auth flow, API client, and DTO mapping
- `AccountingServiceFactory` resolves the active provider from `system_settings.accountingProvider`
- Admin setup wizard: step 1 is provider selection (QB pre-selected), then provider-specific setup flow (OAuth, credentials, first sync)
- Admin can switch providers — triggers re-sync, old data preserved with provider tag
- **Standalone mode:** app operates fully without any accounting provider — all financial sync features degrade gracefully (no document creation, no customer sync, local-only data)
- The rest of the app never references QB directly — all accounting operations go through `IAccountingService`
- Sync queue, caching, and orphan detection work identically regardless of provider

## Admin Settings Panel

The admin settings screen is the central hub for all system configuration. It is organized into tabbed sections:

### Integrations Tab
All third-party service connections are managed from one screen with a consistent pattern: connection status indicator, credential entry, test-connection button, and disconnect option.

| Integration | Credential Type | Multi-Instance | Notes |
|---|---|---|---|
| Accounting (QB Online default) | OAuth 2.0 flow | No — single active provider | Setup wizard on first run; switch provider later |
| Shipping Carriers | API key / OAuth per carrier | Yes — multiple carriers active simultaneously | Each carrier has its own credential block; Manual mode always available |
| Email / SMTP | Host, port, username, password, sender address | No — single outbound config | Test-send button to verify; falls back to no-send mode if unconfigured |
| AI Provider (optional) | Local Ollama URL or cloud API key | No — single provider | Self-hosted Ollama default; cloud providers optional; app works fully without AI |

- **Connection status** for each integration visible at a glance (connected / disconnected / error / token expiring)
- **Credentials stored encrypted** in the database (JSONB encrypted columns, same pattern as `accounting_connection`)
- **MOCK_INTEGRATIONS=true** env var bypasses all real API calls with mock responses during development

### Branding Tab
- Company logo upload (stored in MinIO, referenced via `appLogoFileId` in `system_settings`)
- Application name (`appName` — appears in header, browser title, emails)
- Three brand color pickers: Primary, Accent, Warn — both light and dark themes auto-generated from these
- Default theme mode (light / dark) — users can override per-account
- Contrast validation warns admin if selected colors violate WCAG 3 accessibility thresholds
- Changes apply immediately at runtime — no rebuild or restart required

### Reference Data Tab
- Single management screen for all lookup/dropdown values across the application
- Add, rename, reorder, deactivate values within any group
- Add new groups as needed for custom categorization
- `code` field is immutable (used in application logic); `label` is admin-editable
- Deactivated values hidden from new records but preserved on existing records
- Groups include: expense_category, return_reason, lead_source, contact_role, job_priority, asset_type, asset_status, lead_status, part_status, qc_disposition, internal_task_type, shipping_carrier, and any admin-created groups

### User Management Tab
- **Onboarding:** Admin/Manager creates user record — no self-registration. Admin enters name, role(s), department, direct manager, email (optional), badge/scan ID (optional — for shop floor time clock). Two claim methods: **(1) On-site setup code** (default) — system generates a short code displayed to admin, employee enters name or code on a setup page and sets their password; **(2) Email invite** (optional, requires SMTP configured) — sends a one-time invite link to the employee's email. Unclaimed accounts visible to admin with option to regenerate codes or resend invites.
- **Offboarding:** Admin deactivates account — never hard-deleted. Deactivated users cannot log in, removed from assignee dropdowns and active presence. All historical records preserved. Active tasks reassigned (admin prompted during deactivation). Deactivated accounts can be reactivated. Immediate session revocation available for termination scenarios.
- **Role assignment:** Admin assigns/modifies roles at any time. Role changes take effect on next login or via session refresh.
- **Active user list** with role, last login, status indicators
- **Unclaimed accounts list** with setup codes and regenerate option

### Company Profile & Locations
- **Company profile** stored as system settings (`company.name`, `company.phone`, `company.email`, `company.ein`, `company.website`) — editable in admin settings tab
- `app.company_name` is the display name in the header; `company.name` is the legal name for documents. During initial setup both are set to the same value; admin can change independently.
- **Company locations** (`CompanyLocation` entity) — one company per install, multiple locations. Each location has name, address, phone, state, `IsDefault` flag, `IsActive` flag.
- Exactly one location must be default (enforced by unique filtered index on `IsDefault = true`)
- **Per-employee work location** — `WorkLocationId` FK on `ApplicationUser`. Determines which state's withholding form applies to that employee. If null, falls back to default location.
- **Setup wizard** captures company details on first run: Step 1 = admin account (existing), Step 2 = company name, phone, email, EIN, website + primary location (name + address via `AddressFormComponent`). Single API call on final submit.
- Most adopters will have a single location. Multi-location is for companies with employees at different sites in different states.
- Admin can CRUD locations, set default, and assign employees to locations via the user edit dialog.
- Deleting a location soft-deletes it; cannot delete the default location. Users assigned to deleted locations fall back to default.

### System Settings Tab
- Operational settings stored in `system_settings` DB table (key-value with data type)
- Planning cycle duration, planning day toggle, auto-archive days, nudge timing thresholds
- File upload size limit, storage warning threshold
- Invoice workflow mode (direct / managed)
- Default role for new users
- Backup schedule and retention
- Terminology / label overrides (relabel any concept system-wide)

## Employee Compliance Forms

> **Full spec: `docs/compliance-forms-signing.md`** — covers the complete two-phase workflow (data collection → PDF fill → DocuSeal signing), I-9 two-party signing, employer Section 2 UI, data model changes, legal basis, and build order. The notes here cover rules that apply across all form types; see the dedicated spec for form-specific flows.

Employee-facing tax and compliance forms (W-4, I-9, state withholding, direct deposit, workers' comp, handbook). Each form template is admin-managed. Employees fill out forms via the ng-dynamic-forms wizard (`ComplianceFormRendererComponent`); the backend fills the official government PDF with the submitted data and routes it through DocuSeal for legally-compliant electronic signing.

### Submission Lifecycle
- **Pending** — employee has started (draft saved) but not submitted
- **Completed** — employee has submitted and signed; `SignedAt` timestamp recorded, employee profile updated (`W4CompletedAt`, etc.)
- **Expired** — form version has been superseded (e.g., new tax year W-4)
- **I-9 has additional sub-states** — see `docs/compliance-forms-signing.md §I-9 Submission Status States`

### Post-Submission Behaviour (Non-Negotiable)
- **Completed forms show a confirmation card**, not the blank form. The user sees "This form has already been submitted" with the completion date.
- **Sensitive forms** (W-4, I-9, State Withholding — forms containing SSN or other PII) **never display previously submitted data back to the user**. The confirmation card explains this.
- **Non-sensitive forms** (Direct Deposit, Workers' Comp, Handbook) may display previously submitted data in read-only mode.
- **Resubmit option**: All completed forms offer a "Submit New Version" button. Clicking it opens a fresh blank form (for sensitive) or pre-filled form (for non-sensitive). The back button cancels resubmission and returns to the confirmation view.
- **On resubmit**, the existing submission record is updated (not a new record) — `Status` resets to `Completed` with new `SignedAt` timestamp.

### Profile Completion Bridge
- Submitting a compliance form **must** update the corresponding `EmployeeProfile` completion timestamp (e.g., `W4CompletedAt`). This is what `GetProfileCompleteness` checks.
- The `AcknowledgeFormCommand` handles this mapping. It accepts both camelCase (`stateWithholding`) and snake_case (`state_withholding`) keys for compatibility.
- All submission paths (electronic form submit, DocuSeal webhook, manual acknowledge) must call `AcknowledgeFormCommand` to keep the profile in sync.

### Template Types
| Form Type | Sensitive | Can Expire | Blocks Job Assignment | Signing |
|-----------|-----------|------------|----------------------|---------|
| W-4 | Yes (SSN) | Yes (annual) | Yes | Single-party: employee via DocuSeal |
| I-9 | Yes (SSN) | Yes (document expiration) | Yes | Two-party sequential: employee (Section 1) then employer (Section 2) |
| State Withholding | Yes (SSN) | Varies by state | Yes | Single-party: employee via DocuSeal |
| Direct Deposit | No | No | No | Acknowledgment only |
| Workers' Comp | No | No | No | Acknowledgment only |
| Handbook | No | No | No | Acknowledgment only |

### I-9 Employer Review (Admin/Manager)
The I-9 requires a second signature from an HR/Manager who physically examines the employee's identity documents. This is handled within the existing employee HR view — not a separate queue screen:

- **Employee list** gains an `I9Status` chip column (warning/error when action required)
- **Employee compliance panel** conditionally shows the Section 2 completion form when `I9Status` is `Section1Complete` or `Section2InProgress`
- **Section 2 form**: document title/authority/number/expiration entry, List A vs B+C toggle, attestation checkbox, first day of employment, employer name/address pre-filled from company profile
- **3-business-day deadline** is enforced: Hangfire job flags overdue, sends notifications to all Admin/Manager users

See `docs/compliance-forms-signing.md` for the full Section 2 UI spec, all document list types (A, B, C), deadline rules, and reverification flow.

## Shared Component Library & UI Patterns

Centralized shared Angular components eliminate per-feature HTML duplication and enforce consistent behavior across the app. Full specs in `coding-standards.md` Standards #34–37.

### Core Shared Components
- **Data Table** (`AppDataTableComponent`) — user-configurable columns (show/hide, drag-reorder, resize), per-column sort and filter (type-aware: text, range, enum), gear icon for column management, preferences persisted per user via unique `tableId`
- **Form Field Wrappers** — `AppInputComponent`, `AppSelectComponent`, `AppAutocompleteComponent`, `AppTextareaComponent`, `AppDatepickerComponent`, `AppToggleComponent` — floating label structure, reactive form integration, minimal HTML per usage
- **Validation Pattern** — no inline validation errors. Submit button disables when form is invalid. Hover popover on disabled button shows all violations. Live revalidation on any field change. Final validation gate before action execution.
- **Page Layout Shell** (`PageLayoutComponent`) — enforces standard layout: static header, scrollable content, sticky action footer with buttons right-aligned (primary furthest right)
- **Confirmation Dialog** — reusable for all destructive/significant actions with severity-based styling
- **Entity Picker** — typeahead search for any entity type (customer, user, part, job, vendor, asset)
- **File Upload Zone** — drag-and-drop with preview thumbnails, progress bars, type/size validation
- **Status Badge** — consistent status chip mapped from reference data
- **Detail Side Panel** — slide-out right panel for view/edit without full navigation
- **Avatar** — user avatar with deterministic-color initials fallback
- **Toolbar** — standardized horizontal filter/action bar with spacer alignment
- **Date Range Picker** — two-date range with preset shortcuts (Today, This Week, Last 30 Days)

### Layout Rules
- Header and footer are static (never scroll). Content area scrolls between them.
- Action buttons: lower-right, primary action furthest right, destructive actions separated on far left
- Card headers: compact (single line), always visible, card body scrolls independently
- No horizontal scrolling except Kanban board and wide data tables (which get sticky first column)
- Dialogs: standard sizes (small 400px, medium 600px, large 800px), same static-header/scroll-content/sticky-footer pattern

### User Preferences
- Centralized `user_preferences` table stores all per-user UI settings (table configs, theme, sidebar, dashboard layout, locale, notifications, default views)
- Key-pattern storage: `table:{tableId}`, `theme:mode`, `sidebar:collapsed`, etc.
- `UserPreferencesService` loads on app init, caches in memory, debounced server sync on changes
- Restored on login from any device — consistent experience across workstations

## Status Lifecycle Tracking

Polymorphic status tracking system for any entity (same pattern as FileAttachment, ActivityLog).

- **Polymorphic StatusEntry table** — `EntityType` + `EntityId` columns allow status tracking on any entity (Job, Quote, SalesOrder, PurchaseOrder, Asset, etc.)
- **Two categories:**
  - `workflow` — linear progression, only one active at a time. SetWorkflowStatus closes the previous workflow entry (sets `EndedAt`) before creating the new one.
  - `hold` — parallel overlays, multiple can be active simultaneously. AddHold prevents duplicate active holds of the same code. ReleaseHold sets `EndedAt` on a specific hold.
- **Status codes from reference_data** — admin-configurable via groups: `{entity}_workflow_status` and `{entity}_hold_type`. Allows shops to define their own workflow stages and hold reasons.
- **StatusLabel denormalized** at creation time for historical accuracy — even if admin renames a status code later, existing history entries retain their original label.
- **Full audit trail** — all transitions logged with `StartedAt`, `EndedAt`, `Notes`, `SetBy` (user FK). Duration between statuses is computable from timestamps.
- **StatusTrackingController** — 5 endpoints:
  - `GET /{entityType}/{entityId}/statuses` — full history
  - `GET /{entityType}/{entityId}/statuses/active` — current workflow status + active holds
  - `POST /{entityType}/{entityId}/statuses/workflow` — set workflow status
  - `POST /{entityType}/{entityId}/statuses/hold` — add hold
  - `DELETE /{entityType}/{entityId}/statuses/hold/{statusEntryId}` — release hold

### Default Status Code Groups (seeded)
- **Job workflow:** Created, In Progress, On Hold, Completed, Archived
- **Job holds:** Material Hold, Quality Hold, Customer Hold, Engineering Hold
- **Quote workflow:** Draft, Sent, Accepted, Rejected, Expired
- **Sales Order workflow:** Draft, Confirmed, In Progress, Fulfilled, Closed
- **Purchase Order workflow:** Draft, Submitted, Partially Received, Received, Closed
- **Asset holds:** Maintenance Due, Calibration Expired, Under Repair

### UI Components
- **StatusTimelineComponent** (shared) — reusable component showing active workflow status, active holds with release button, and full status history timeline. Integrated into job detail panel.
- **SetStatusDialogComponent** — dialog for transitioning workflow status with optional notes
- **AddHoldDialogComponent** — dialog for adding a hold with type selection and notes

## Open Source (GNU License)
- Nothing company-specific committed
- All branding, company names, logos configurable in system settings
- Default seed data is generic (not specific to any company)
- SMTP, calendar, backup targets all configurable
- Accounting integration is pluggable — QB is default, other providers supported, app works in standalone mode
- .env.example with placeholder values
