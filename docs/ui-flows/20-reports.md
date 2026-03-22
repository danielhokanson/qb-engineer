# Reports (Dynamic Builder)

**Route:** `/reports`
**Access Roles:** PM, Manager, Admin (role-filtered data)
**Page Title:** reports.title

## Purpose

The Report Builder is a dynamic query engine over 28 entity sources and 350+ fields.
Users select an entity type, choose fields, apply filters, and view results as a table
or chart. Reports can be saved and accessed from a personal saved reports list.

## Detected Report Templates

- view_kanbanreports.navJobsByStage
- warningreports.navOverdueJobs
- schedulereports.navTimeByUser
- receipt_longreports.navExpenseSummary
- filter_altreports.navLeadPipeline
- trending_upreports.navCompletionTrend
- verifiedreports.navOnTimeDelivery
- hourglass_topreports.navAvgLeadTime
- groupsreports.navTeamWorkload
- businessreports.navCustomerActivity
- assignment_indreports.navMyWorkHistory
- timerreports.navMyTimeLog
- account_balancereports.navArAging
- attach_moneyreports.navRevenue
- balancereports.navProfitLoss
- receiptreports.navMyExpenses
- handshakereports.navQuoteToClose
- local_shippingreports.navShippingSummary
- hourglass_bottomreports.navTimeInStage
- person_searchreports.navEmployeeProductivity
- inventory_2reports.navInventoryLevels
- buildreports.navMaintenance
- verifiedreports.navQualityScrap
- event_repeatreports.navCycleReview
- trending_upreports.navJobMargin
- event_repeatreports.navMyCycleSummary
- leaderboardreports.navLeadSales
- sciencereports.navRdReport
- buildreports.reportBuilder


## Entity Sources (28)

Job, Part, Customer, Lead, Quote, SalesOrder, PurchaseOrder, Shipment, Invoice,
Payment, Expense, TimeEntry, Asset, Vendor, Inventory, QcInspection, PlanningCycle,
LotRecord, ChatMessage, AppNotification, ComplianceFormSubmission, PayStub,
FileAttachment, ActivityLog, StatusEntry, AuditLog, ScheduledTask, SavedReport

## Report Builder Interface

1. **Select Entity** — choose the primary data source
2. **Select Fields** — choose which columns to include
3. **Set Filters** — date range + entity-specific filters
4. **View Results** — table with export option
5. **Add Chart** — bar/line/pie visualization (ng2-charts)
6. **Save Report** — name and persist to saved reports list

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

### 📋 Top of Content Area (first rows, column headers)

- **Nav Jobs By Stage (view_kanban)** — look for the `view_kanban` icon (left side of toolbar)
- **Nav Overdue Jobs (warning)** — look for the `warning` icon (left side of toolbar)
- **Nav Time By User (schedule)** — look for the `schedule` icon (left side of toolbar)
- **Nav Expense Summary (receipt_long)** — look for the `receipt_long` icon (left side of toolbar)

### 📄 Middle of Page (main content)

- **Nav Lead Pipeline (filter_alt)** — look for the `filter_alt` icon (left side of toolbar)
- **Nav Completion Trend (trending_up)** — look for the `trending_up` icon (left side of toolbar)
- **Nav On Time Delivery (verified)** — look for the `verified` icon (left side of toolbar)
- **Nav Avg Lead Time (hourglass_top)** — look for the `hourglass_top` icon (left side of toolbar)
- **Nav Team Workload (groups)** — look for the `groups` icon (left side of toolbar)
- **Nav Customer Activity (business)** — look for the `business` icon (left side of toolbar)
- **Nav My Work History (assignment_ind)** — look for the `assignment_ind` icon (left side of toolbar)
- **Nav My Time Log (timer)** — look for the `timer` icon (left side of toolbar)
- **Nav Ar Aging (account_balance)** — look for the `account_balance` icon (left side of toolbar)
- **Nav Revenue (attach_money)** — look for the `attach_money` icon (left side of toolbar)
- **Nav Profit Loss (balance)** — look for the `balance` icon (left side of toolbar)
- **Nav My Expenses (receipt)** — look for the `receipt` icon (left side of toolbar)
- **Nav Quote To Close (handshake)** — look for the `handshake` icon (left side of toolbar)
- **Nav Shipping Summary (local_shipping)** — look for the `local_shipping` icon (left side of toolbar)
- **Export Csv (download)** — look for the `download` icon (top-right corner)
- **Manage Columns (settings)** — look for the `settings` icon (top-right corner)

### 📄 Lower Content Area

- **Nav Time In Stage (hourglass_bottom)** — look for the `hourglass_bottom` icon (left side of toolbar)
- **Nav Employee Productivity (person_search)** — look for the `person_search` icon (left side of toolbar)
- **Nav Inventory Levels (inventory_2)** — look for the `inventory_2` icon (left side of toolbar)
- **Nav Maintenance (build)** — look for the `build` icon (left side of toolbar)
- **Nav Quality Scrap (verified)** — look for the `verified` icon (left side of toolbar)
- **Nav Cycle Review (event_repeat)** — look for the `event_repeat` icon (left side of toolbar)
- **Nav Job Margin (trending_up)** — look for the `trending_up` icon (left side of toolbar)

### 🟩 Bottom Action Bar (Save / Cancel buttons)

- **Nav My Cycle Summary (event_repeat)** — look for the `event_repeat` icon (left side of toolbar)
- **Nav Lead Sales (leaderboard)** — look for the `leaderboard` icon (left side of toolbar)
- **Nav Rd Report (science)** — look for the `science` icon (left side of toolbar)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

The 28-source dynamic report builder is powerful for a job shop platform. Pre-seeded
templates reduce the learning curve significantly.

### Usability Observations

- Report sidebar shows all 28 pre-seeded templates organized by category
- Saved reports are per-user and persist via UserPreferences
- Charts update in real-time as filters change
- Export to CSV available

### Functional Gaps / Missing Features

- No scheduled report delivery (email on a cron schedule)
- No report sharing between users
- No dashboard widget from custom report (saved reports can't become dashboard widgets)
- No drill-down from chart bars to underlying data
- No pivot table mode
- Excel export (XLSX) not yet implemented (CSV only)
- No calculated fields / formulas in report builder
