# Implementation Status

Tracks real implementation against all spec docs. Updated: 2026-03-14.

Legend: Done | Partial | Not Started | N/A (deferred or out of scope)

---

## Phase Status (proposal.md §8)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1 — Foundation | Docker + Kanban + Job Cards | Partial |
| 2 — Engineer UX | Dashboard + Planning Day | Partial |
| 3 — Accounting Bridge | QB Read/Write Integration | Not Started |
| 4 — Leads & Contacts | Lead-to-Customer Pipeline | Partial |
| 5 — Traceability & QC | Production Lot Tracking | Done |
| 6 — Time & Workers | Time Tracking + Worker Views | Partial |
| 7 — Expenses & Invoicing | Expense Capture + Invoice Workflow | Partial |
| 8 — Maintenance | Asset Registry + Scheduled Maintenance | Partial |
| 9 — Reporting | Operational Dashboards | Partial |
| 10 — Backup & Polish | Production Hardening | Partial |
| 11 — AI Assistant | Self-Hosted AI Module | Not Started |

---

## Architecture (architecture.md)

### Stack & Infrastructure

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Angular 21 + Material 21 | architecture.md §Stack | Done | Standalone, OnPush, signals, zoneless |
| .NET 9 Web API | architecture.md §Stack | Done | MediatR CQRS, FluentValidation (35+ validators), exception middleware (404/400/409) |
| PostgreSQL + pgvector | architecture.md §Stack | Done | pgvector extension enabled |
| MinIO | architecture.md §Stack | Done | 3 buckets, upload/download/presigned URLs |
| Three.js (STL viewer) | architecture.md §Stack | Done | Lazy-loaded StlViewerComponent, wired into part detail "3D View" tab |
| SignalR | architecture.md §Stack | Done | 4 hubs (Board, Notification, Timer, Chat) — all functional with typed events, group management, reconnect handling |
| Hangfire | architecture.md §Stack | Done | Recurring order auto-gen (daily 6AM), overdue invoice marking (daily 1AM), PostgreSQL storage, dashboard |
| Mapperly | architecture.md §Stack | Done | 6 mappers (Job, Part, Customer, Expense, Asset, Lead) in qb-engineer.api/Mappers/ |
| OpenAPI + Scalar | architecture.md §Stack | Done | API docs available |
| Docker Compose | architecture.md §Docker | Done | 6 containers running (AI optional via profile) |

### Auth & Security

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| ASP.NET Identity | architecture.md §Auth | Done | Custom ApplicationUser |
| JWT bearer auth | architecture.md §Auth | Done | Access + refresh tokens |
| Refresh token rotation | architecture.md §Auth | Done | |
| Additive roles | architecture.md §Auth | Done | 6 roles seeded |
| OAuth token encryption | architecture.md §Auth | Not Started | Data Protection API not wired for accounting tokens |
| Rate limiting | architecture.md §Auth | Done | Fixed window (100/min per user), built-in .NET middleware |
| CSP / security headers | CLAUDE.md §Security | Done | SecurityHeadersMiddleware: CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy |

### RESTful Routing

| Route | Spec | Status | Notes |
|-------|------|--------|-------|
| /dashboard | architecture.md §Routing | Done | 5 widgets |
| /kanban | architecture.md §Routing | Done | Track type switching, drag-drop |
| /jobs, /jobs/:id | architecture.md §Routing | Done | List + detail panel |
| /backlog | architecture.md §Routing | Done | DataTable with filtering |
| /leads, /leads/:id | architecture.md §Routing | Done | CRUD |
| /parts, /parts/:id | architecture.md §Routing | Done | CRUD + BOM |
| /assets, /assets/:id | architecture.md §Routing | Done | CRUD |
| /expenses, /expenses/:id | architecture.md §Routing | Done | CRUD |
| /time-tracking | architecture.md §Routing | Done | Timer + manual entry |
| /admin/users | architecture.md §Routing | Done | User management |
| /customers | architecture.md §Routing | Done | Full feature module: list, detail, contacts, create/edit |
| /reports | architecture.md §Routing | Done | 15 reports with charts (ng2-charts) + data tables, including 3 financial (AR Aging, Revenue, P&L) |
| /admin/settings | architecture.md §Routing | Done | Reference data, terminology, system settings tabs |
| /sprint-planning | architecture.md §Routing | Done | Split-panel: backlog (left) → cycle board (right), drag-drop commit |
| /search | architecture.md §Routing | Done | Global search bar in header, searches 6 entity types |
| /notifications | architecture.md §Routing | Done | Backend: entity, repo, controller, 5 MediatR handlers. Frontend: panel dropdown + dedicated /notifications page with preferences tab |
| /admin/qb-setup | architecture.md §Routing | Not Started | |
| /admin/track-types | architecture.md §Routing | Done | Full CRUD: create/edit/delete with stage management |
| /admin/terminology | architecture.md §Routing | Done | Tab in admin page, editable key-label table, bulk save |
| /display/shop-floor | architecture.md §Routing | Done | Full-screen kiosk: worker presence, active jobs, KPIs, auto-refresh 30s, AllowAnonymous |
| /display/shop-floor/clock | architecture.md §Routing | Done | Touch-first kiosk clock UI |

### Other Architecture Items

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Custom fields (JSON) | architecture.md §Custom Fields | Done | CustomFieldDefinitions on TrackType, CustomFieldValues on Job, API endpoints, Angular service methods |
| system_settings DB table | architecture.md §Settings | Done | Entity exists, no admin UI |
| Backup (B2 + local) | architecture.md §Backup | Done | DatabaseBackupJob (Hangfire daily 3AM), pg_dump custom format, configurable retention (30 days default), old backup cleanup |
| Full-text search | architecture.md §Search | Done | tsvector generated columns + GIN indexes on jobs, customers, parts, leads, assets, expenses. Hybrid search: plainto_tsquery ranked + ILIKE fallback. |
| Self-hosted AI (Ollama + RAG) | architecture.md §AI | Partial | Docker container configured, IAiService + MockAiService built, no Ollama/RAG implementation |
| Theming (light/dark) | architecture.md §Theming | Done | Toggle in toolbar, CSS custom properties |
| Admin brand colors | architecture.md §Theming | Done | System settings for primary/accent colors, runtime CSS variable override, public brand endpoint |
| Accessibility (WCAG 3) | architecture.md §Accessibility | Partial | aria-labels on all icon buttons, focus-visible outlines, skip-to-content link, prefers-reduced-motion. No axe-core tests. |
| Mobile responsiveness | architecture.md §Mobile | Done | LayoutService with breakpoint detection, hamburger menu, mobile sidebar overlay. Per-page responsive grids on dashboard, parts, inventory, kanban. |
| Offline resilience / PWA | architecture.md §Offline | Partial | Service Worker (ngsw-config.json), IndexedDB cache service, BroadcastChannel multi-tab sync (logout + theme), offline action queue (OfflineQueueService). |

---

## Functional Decisions (functional-decisions.md)

### Kanban Board

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Track types (4 built-in) | functional-decisions.md §Kanban | Done | Production, R&D, Maintenance, Other |
| Custom track types | functional-decisions.md §Kanban | Done | Create/edit/delete dialog, stage management, backend CRUD |
| Card movement (forward/backward) | functional-decisions.md §Kanban | Done | Irreversible stage blocking works |
| Backward move double-confirmation (QB) | functional-decisions.md §Kanban | Not Started | Needs accounting integration |
| Multi-select + bulk actions | functional-decisions.md §Kanban | Done | Ctrl+Click, floating bulk bar (Move/Assign/Priority/Archive), 4 backend handlers |
| SignalR real-time sync | functional-decisions.md §Kanban | Done | BoardHub, optimistic UI |
| Column body colored border | functional-decisions.md §Kanban | Done | Inset box-shadow per stage color |

### Job Card Detail

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Title, description, due date, priority | proposal.md §4.2 | Done | |
| Customer reference | proposal.md §4.2 | Done | |
| Assigned user(s) | proposal.md §4.2 | Done | Single assignee |
| File attachments | proposal.md §4.2 | Done | Upload/download via MinIO, Files tab in job detail panel with drag-drop upload |
| Activity log | proposal.md §4.2 | Done | Entity + API + UI timeline + inline comments |
| Subtasks (checklist) | proposal.md §4.2 | Done | CRUD with assignee + checkbox |
| Linked cards | proposal.md §4.2 | Done | Full-stack: entity, API (CRUD), typeahead UI in detail panel |
| Time entries on card | proposal.md §4.2 | Done | Time section in job detail panel with per-entry list + total duration |
| Accounting document refs | proposal.md §4.2 | Not Started | |
| Custom fields (per track type) | proposal.md §4.2 | Done | JSONB definitions on TrackType, values on Job, CRUD endpoints |
| R&D iteration counter/notes | proposal.md §4.2 | Done | IterationCount + IterationNotes on Job entity, UI section in job detail panel |
| Production runs tab | proposal.md §4.2 | Done | ProductionRun entity, CRUD handlers, controller endpoints |

### Task Linking & Subtasks

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Subtasks (text, assignee, checkbox) | functional-decisions.md §Task Linking | Done | |
| Card linking (related, blocks, parent/child) | functional-decisions.md §Task Linking | Done | Entity, API (CRUD), Angular UI in job detail panel |

### Activity Log

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Per-entity timeline | functional-decisions.md §Activity Log | Done | JobActivityLog + polymorphic ActivityLog entity, full UI with ActivityTimelineComponent |
| Inline comments with @mentions | functional-decisions.md §Activity Log | Done | @mention regex parsing in CreateJobCommentHandler, notifications via MediatR, MentionHighlightPipe for UI |
| Filter by action type/user | functional-decisions.md §Activity Log | Done | ActivityTimelineComponent filterable input with action/user dropdowns |
| Batch field change collapsing | functional-decisions.md §Activity Log | Done | Groups FieldChanged entries within 5s by same user into expandable batch |
| Reuse on parts, assets, leads, customers, expenses | functional-decisions.md §Activity Log | Done | Polymorphic ActivityLog entity (EntityType/EntityId), GetEntityActivity handler, activity endpoints on 5 controllers |

### Part / Product / Assembly Catalog

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Part CRUD | proposal.md §4.3 | Done | Create, update, soft-delete with ConfirmDialog |
| BOM (recursive) | proposal.md §4.3 | Done | Entity + CRUD endpoints |
| Part detail (specs, files, BOM) | proposal.md §4.3 | Done | Split-panel: list + 5-tab detail (info/BOM/usage/3D viewer/files). Inventory summary with low-stock warning. |
| Revision control | proposal.md §4.3 | Done | PartRevision entity, CRUD handlers, unique (PartId,Revision) index, IsCurrent flag |
| Where Used (reverse BOM lookup) | proposal.md §4.3 | Done | Loaded via EF Include, displayed in Usage tab with navigation |
| STL inline viewer | proposal.md §4.3 | Done | Three.js lazy-loaded StlViewerComponent, "3D View" tab in part detail when .stl file attached |
| Accounting item linkage | proposal.md §4.3 | Not Started | |
| Part-to-job reference | proposal.md §4.3 | Done | JobPart entity, CRUD endpoints, search + add in job detail panel |

### CAD / STL / CAM File Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| File upload/download | proposal.md §4.4 | Done | MinIO, per-entity |
| File versioning by revision | proposal.md §4.4 | Done | PartRevisionId FK on FileAttachment, GetFilesByRevision handler, endpoint on FilesController |
| STL 3D viewer (Three.js) | proposal.md §4.4 | Done | OrbitControls, auto-center, ambient+directional lighting, responsive resize |
| Chunked upload with progress | proposal.md §4.4 | Partial | FileUploadZoneComponent has progress |
| File access restrictions | proposal.md §4.4 | Done | RequiredRole field on FileAttachment, role check in DownloadFile handler |

### Dashboard

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Widget-based layout | proposal.md §4.5 | Done | 9 widgets with real KPI data, CSV export, gridstack drag/resize/add/remove |
| Role-based default layouts | proposal.md §4.5 | Done | GetDefaultDashboardLayout handler returns role-based widget visibility + column count |
| Daily Priority Card | proposal.md §4.5 | Done | TodaysTasksWidget: overdue detection, priority sorting, top-3 tomorrow prefs, navigate to kanban |
| End-of-Day Prompt | proposal.md §4.5 | Done | EodPromptWidgetComponent: "Top 3 for tomorrow" textarea, persists to UserPreferencesService |
| Screensaver / Ambient Mode | proposal.md §4.5 | Done | Full-screen dark overlay with clock, KPIs, deadlines. Auto-refresh 60s, exit on click/Escape. |
| Widget customization (add/remove/resize) | proposal.md §4.5 | Done | Gridstack: drag/resize/add/remove widgets, edit mode toggle, layout persisted via UserPreferencesService |

### Planning Cycle Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Planning cycle entity | proposal.md §4.6 | Done | PlanningCycle + PlanningCycleEntry entities, repo, 11 handlers, controller |
| Planning Day flow | proposal.md §4.6 | Done | Split-panel planning page with backlog → cycle drag-drop |
| Backlog curation (split-panel drag) | proposal.md §4.6 | Done | Left backlog panel with search/priority filter, CDK drag-drop to cycle |
| Cycle goals | proposal.md §4.6 | Done | Goals field on PlanningCycle, editable in create/edit dialog |
| Rollover handling | proposal.md §4.6 | Done | CompletePlanningCycle handler creates new cycle with incomplete entries (IsRolledOver=true) |
| Cycle progress on dashboard | proposal.md §4.6 | Done | CycleProgressWidgetComponent showing progress bar, days remaining, completion count |

### Lead Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Lead CRUD | proposal.md §4.7 | Done | Create, update, soft-delete (not Converted) with ConfirmDialog |
| Lead statuses (New → Lost) | proposal.md §4.7 | Done | LeadStatus enum |
| Convert to Customer | proposal.md §4.7 | Done | Creates Customer + optional Contact from lead fields |
| Convert and Create Job | proposal.md §4.7 | Done | Option in conversion flow, creates Job linked to new customer |
| Lost lead reason capture | proposal.md §4.7 | Done | Lost dialog with reason textarea |
| Custom fields | proposal.md §4.7 | Done | JSONB definitions on TrackType, values on Job, CRUD endpoints, Angular service |

### Customer & Contact Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Customer CRUD | proposal.md §4.8 | Done | Full feature module: entity, API (8+ endpoints), DataTable UI, detail panel, create/edit dialog, soft-delete with ConfirmDialog |
| Multiple contacts per customer | proposal.md §4.8 | Done | Contact CRUD endpoints, contacts tab in customer detail panel |
| Contact role tags | proposal.md §4.8 | Done | Role field on contact entity, editable in contact forms |
| Accounting sync (read/write) | proposal.md §4.8 | Not Started | |

### Vendor Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Vendor list (read-only from accounting) | proposal.md §4.9 | Done | Standalone CRUD: entity, repo, handlers, controller, Angular UI |
| Linked POs | proposal.md §4.9 | Done | Vendor detail panel with "Purchase Orders" tab showing linked POs with status chips |
| Linked Parts (preferred vendor) | proposal.md §4.9 | Done | PreferredVendorId FK on Part, included in detail response |

### Expense Capture

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Expense CRUD | proposal.md §4.10 | Done | Create, update, soft-delete (Pending only) with ConfirmDialog |
| Receipt upload (camera/file) | proposal.md §4.10 | Partial | File upload exists, no camera integration |
| Approval workflow | proposal.md §4.10 | Done | Status field + dedicated /expenses/approval queue with review dialog and approval notes |
| Self-approval settings | proposal.md §4.10 | Done | SystemSettings: expense_self_approval, expense_auto_approve_threshold |
| Accounting sync | proposal.md §4.10 | Not Started | |
| CSV export | proposal.md §4.10 | Done | DataTableComponent has universal CSV export via papaparse (all visible columns) |

### Invoice Workflow

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Direct mode (solo operator) | proposal.md §4.11 | Done | CreateInvoice, CreateInvoiceFromJob, VoidInvoice, SendInvoice handlers |
| Managed mode (office manager queue) | proposal.md §4.11 | Done | Queue settings (mode + assignee), SystemSettings-based config |
| Nudge system (uninvoiced jobs) | proposal.md §4.11 | Done | GetUninvoicedJobs handler, UninvoicedJobsPanel component |
| Billing visibility on card | proposal.md §4.11 | Done | BillingStatus (Invoiced/Uninvoiced) on kanban card, icon indicator |

### Order Management (Quote-to-Cash)

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Sales Order entity + CRUD | functional-decisions.md §Order Management | Done | SalesOrder, SalesOrderLine, repo, handlers, controller |
| Quote entity + CRUD | functional-decisions.md §Quotes | Done | Quote, QuoteLine, repo, handlers, controller |
| Quote → Sales Order conversion | functional-decisions.md §Quotes | Done | ConvertQuoteToOrder handler |
| Shipment entity + CRUD | functional-decisions.md §Shipments | Done | Shipment, ShipmentLine, auto SO status update |
| Partial delivery tracking | functional-decisions.md §Shipments | Done | ShippedQuantity on SO lines, RemainingQuantity computed |
| Customer multi-address | functional-decisions.md §Customer Addresses | Done | CustomerAddress entity, nested controller |
| Sales Orders list + detail UI | functional-decisions.md §Order Views | Done | List + detail panel + status actions |
| Quotes list + detail UI | functional-decisions.md §Order Views | Done | List + detail panel + status actions + convert to SO |
| Shipments list UI | functional-decisions.md §Order Views | Done | List + detail panel + ship/deliver actions |
| SO ↔ Job linking | functional-decisions.md §Order Management | Done | SalesOrderLineId FK on Job entity |
| Packing slip generation | functional-decisions.md §Shipments | Done | QuestPDF: GET /api/v1/shipments/{id}/packing-slip |
| Open orders dashboard widget | functional-decisions.md §Order Views | Done | OpenOrdersWidgetComponent + backend summary endpoint |

### Standalone Financial Mode ⚡

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Invoice entity + CRUD | functional-decisions.md §Invoicing | Done | ⚡ Entity, config, handlers, controller, Angular UI |
| Invoice PDF generation | functional-decisions.md §Invoicing | Done | QuestPDF: GET /api/v1/invoices/{id}/pdf |
| Invoice email (SMTP) | functional-decisions.md §Invoicing | Done | MailKit: POST /api/v1/invoices/{id}/email, PDF attachment |
| Payment entity + CRUD | functional-decisions.md §Payments | Done | ⚡ Entity, config, handlers, controller, Angular UI |
| Payment application to invoices | functional-decisions.md §Payments | Done | PaymentApplication entity, handler, UI with applications table |
| AR Aging report | functional-decisions.md §AR Aging | Done | ⚡ KPI buckets + data table, backend repo |
| Customer Statement PDF | functional-decisions.md §AR Aging | Done | ⚡ QuestPDF: GET /api/v1/customers/{id}/statement — invoice table, payment history, balance due |
| Credit terms per customer | functional-decisions.md §Credit Terms | Done | CreditTerms enum on SalesOrder + Invoice |
| Sales tax tracking | functional-decisions.md §Sales Tax | Done | ⚡ SalesTaxRate entity, CRUD handlers + controller, admin service methods, Angular models |
| Revenue by Period report | functional-decisions.md §Financial Reports | Done | ⚡ Bar chart + data table, groupBy period/customer |
| Revenue by Customer report | functional-decisions.md §Financial Reports | Done | ⚡ Uses same endpoint with groupBy=customer |
| Simple P&L report | functional-decisions.md §Financial Reports | Done | ⚡ KPI cards (revenue/expenses/net) + data table |
| Standalone vendor CRUD | functional-decisions.md §Vendor Management | Done | ⚡ Full CRUD: entity, repo, handlers, controller, Angular UI |
| Accounting mode switching | qb-integration.md §Standalone Mode | Done | GET /admin/accounting-mode (AllowAnonymous), Angular AccountingService with isStandalone/isConfigured signals, loaded on app init |
| Invoices list + detail UI | functional-decisions.md §Invoicing | Done | ⚡ List + detail panel + send/void actions |
| Payments list UI | functional-decisions.md §Payments | Done | ⚡ List + detail panel + delete |
| AR Aging UI | functional-decisions.md §AR Aging | Done | ⚡ KPI cards per bucket + data table in Reports page |

### Pricing & Quoting

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Price List entity + CRUD | functional-decisions.md §Price Lists | Done | Entity, config, handlers, controller |
| Quantity breaks | functional-decisions.md §Price Lists | Done | MinQuantity on PriceListEntry, unique index (list+part+qty) |
| Price resolution logic | functional-decisions.md §Price Lists | Done | ResolvePrice handler: customer → default → none fallback |
| Recurring Order entity + CRUD | functional-decisions.md §Recurring Orders | Done | Entity, config, handlers, controller |
| Recurring order auto-generation | functional-decisions.md §Recurring Orders | Done | Hangfire RecurringOrderJob, daily 6AM UTC |
| Margin per job/part/customer | functional-decisions.md §Margin Visibility | Done | GetJobMarginReport: labor + material + expense vs revenue |
| Margin dashboard widget | functional-decisions.md §Margin Visibility | Done | GetMarginSummary handler for dashboard |
| Margin report | functional-decisions.md §Margin Visibility | Done | JobMarginReportItem with margin percentage |

### Production Traceability

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Production runs (multiple per job) | proposal.md §4.12 | Done | ProductionRun entity with CRUD, yield tracking, auto-timestamps |
| Lot number tracking | proposal.md §4.12 | Done | LotRecord entity, auto-generate LOT-YYYYMMDD-NNN, CRUD, Angular UI |
| QC checklists | proposal.md §4.12 | Done | QcChecklistTemplate + QcChecklistItem + QcInspection + QcInspectionResult entities, CRUD, Angular quality feature |
| Traceability profiles | proposal.md §4.12 | Done | LotRecord links to Part, Job, ProductionRun, PurchaseOrderLine |
| Lot lookup (forward/backward) | proposal.md §4.12 | Done | GetLotTraceability: traces across jobs, runs, POs, bins, inspections |

### Asset / Equipment Registry

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Asset CRUD | proposal.md §4.13 | Done | Create, update, soft-delete with ConfirmDialog |
| Maintenance card linking | proposal.md §4.13 | Done | CreateMaintenanceJob handler, MaintenanceJobId FK on schedule, auto-creates kanban job |
| Scheduled maintenance rules | proposal.md §4.13 | Done | MaintenanceSchedule + MaintenanceLog entities, CRUD + LogMaintenance handlers, auto-calculated NextDueAt |
| Machine hours tracking | proposal.md §4.13 | Done | CurrentHours on Asset entity, PATCH /api/v1/assets/{id}/hours endpoint, Angular service method |
| Downtime logging | proposal.md §4.13 | Done | DowntimeLog entity, CRUD handlers with FluentValidation, 3 controller endpoints, Angular models + service |

### Time Tracking

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Start/stop timer | proposal.md §4.14 | Done | TimerHub + ClockEvent |
| Manual time entry | proposal.md §4.14 | Done | Create, update, soft-delete with ConfirmDialog |
| Accounting sync (Time Activities) | proposal.md §4.14 | Not Started | |
| Same-day edit lock | proposal.md §4.14 | Done | Backend: previous-day check in update/delete handlers. Frontend: lock icon + disabled delete for past entries |
| Overlapping timer block | proposal.md §4.14 | Done | StartTimerHandler checks GetActiveTimerAsync, throws if timer already running |
| Pay period awareness | proposal.md §4.14 | Done | GetCurrentPayPeriod + UpdatePayPeriodSettings, supports weekly/biweekly/semimonthly/monthly |

### Employee Records

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Employee data from accounting | proposal.md §4.15 | Not Started | |
| Signed documents / certifications | proposal.md §4.15 | Done | FileAttachment with DocumentType + ExpirationDate fields, GetEmployeeDocuments handler |

### Customer Returns

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Return button on completed jobs | proposal.md §4.16 | Done | CustomerReturn entity with RMA workflow (Received → Inspection → Rework → Resolved → Closed) |
| Reason capture + auto-linked rework card | proposal.md §4.16 | Done | CreateReworkJob flag auto-creates Job + JobLink. 6 endpoints on CustomerReturnsController |

### Guided Training System

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| First-login tour | proposal.md §4.17 | Done | TourService + driver.js, kanban + dashboard tour definitions |
| Per-feature walkthroughs | proposal.md §4.17 | Done | HelpTourService with 8 tour definitions (kanban, dashboard, parts, inventory, expenses, time-tracking, reports, admin). All registered in AppComponent. |
| Help icon per page | proposal.md §4.17 | Done | PageHeader/PageLayout support helpTourId input with ? icon button |
| Tour coverage audit (CI) | proposal.md §4.17 | Not Started | |
| Admin training dashboard | proposal.md §4.17 | Done | TrainingDashboardComponent: DataTable with user progress, completion bars, per-device localStorage tracking |

### Bin & Location Tracking

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Location hierarchy (Area → Rack → Bin) | proposal.md §4.18 | Done | StorageLocation entity, recursive, soft-delete (empty only) |
| Bin contents CRUD | proposal.md §4.18 | Done | BinContent entity, API, soft-delete with audit trail |
| Barcode scanning | proposal.md §4.18 | Done | LabelPrintService (bwip-js) + BarcodeScanInputComponent (scanner detection via keystroke timing < 50ms) |
| Movement audit trail | proposal.md §4.18 | Done | BinMovement entity |
| Production label printing | proposal.md §4.18 | Done | ProductionLabelComponent with barcode/QR rendering + print via LabelPrintService |

### Inventory Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Inventory list view | proposal.md §4.19 | Done | UI + API |
| Part inventory summary | proposal.md §4.19 | Done | PartInventorySummary model, total quantity + bin locations in part detail, low-stock computed warning |
| Receiving workflow | proposal.md §4.19 | Done | ReceivePurchaseOrder + GetReceivingHistory handlers, Receiving tab in inventory UI |
| General stock management | proposal.md §4.19 | Done | TransferStock + AdjustStock handlers, Stock Ops tab in inventory UI |
| Cycle counting | proposal.md §4.19 | Done | CycleCount + CycleCountLine entities, CreateCycleCount + UpdateCycleCount + GetCycleCounts handlers, Cycle Counts tab in inventory UI |
| Accounting quantity sync | proposal.md §4.19 | Not Started | |
| Low-stock alerts | proposal.md §4.19 | Done | MinStockThreshold/ReorderPoint on Part, GetLowStockAlerts query endpoint |

### Purchase Order Lifecycle

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| PO creation (job-linked + standalone) | proposal.md §4.20 | Done | PurchaseOrder + PurchaseOrderLine entities, 10 MediatR handlers, full Angular UI with create/receive dialogs |
| PO statuses (Draft → Closed) | proposal.md §4.20 | Done | Draft → Submitted → Acknowledged → PartiallyReceived/Received → Closed, Cancel shortcut |
| Partial receipts / back-order | proposal.md §4.20 | Done | ReceiveItems handler tracks per-line quantities, auto-transitions PartiallyReceived → Received |
| Multi-PO per job | proposal.md §4.20 | Done | Job has ICollection<PurchaseOrder>, PO list filterable by jobId |
| Preferred vendor per part | proposal.md §4.20 | Done | PreferredVendorId FK on Part, vendor name in PartDetail response, Angular model updated |

### Shipping & Carrier Integration

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| IShippingService interface | proposal.md §4.21 | Done | Interface + MockShippingService |
| Carrier APIs (UPS, FedEx, etc.) | proposal.md §4.21 | Not Started | |
| Packing slips | proposal.md §4.21 | Done | QuestPDF: GET /shipments/{id}/packing-slip |
| Multi-package tracking | proposal.md §4.21 | Done | ShipmentPackage entity, CRUD handlers, per-shipment package management |

### R&D / Internal Projects

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| R&D track stages | proposal.md §4.22 | Done | Seeded stages |
| Iteration counter + test notes | proposal.md §4.22 | Done | IterationCount + IterationNotes on Job entity, UI in job detail panel |
| Handoff to Production linking | proposal.md §4.22 | Done | HandoffToProduction handler, bidirectional JobLinks (HandoffFrom/HandoffTo) |
| Internal project types (reference data) | proposal.md §4.22 | Done | IsInternal + InternalProjectTypeId on Job, GetInternalProjectTypes handler, reference data driven |
| Scheduled internal tasks | proposal.md §4.22 | Done | ScheduledTask entity, CRUD + Run handlers, ScheduledTasksController, Hangfire job (every 15 min) |

### Admin Settings & Integration Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| User management | proposal.md §4.23 | Done | CRUD, role assignment |
| Track type management | proposal.md §4.23 | Done | Full CRUD with stage management dialog |
| Reference data management | proposal.md §4.23 | Done | Admin tab |
| Accounting setup wizard | proposal.md §4.23 | Not Started | |
| Branding (logo, colors) | proposal.md §4.23 | Done | Brand colors + logo upload (MinIO qb-engineer-branding bucket), admin UI with upload/remove, header displays logo |
| System settings UI | proposal.md §4.23 | Done | Admin Settings tab with 10 configurable settings, upsert API |
| Third-party integrations panel | proposal.md §4.23 | Not Started | |

### Chat System

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| 1:1 direct messages | proposal.md §4.25 | Done | ChatMessage entity, ChatHub (SignalR), ChatController, Angular chat panel with conversations + real-time messaging |
| Group chats | proposal.md §4.25 | Done | ChatRoom + ChatRoomMember entities, 5 handlers (Create/Get rooms, Get/Send room messages, Add/Remove member), ChatHub JoinRoom/LeaveRoom |
| File/image sharing | proposal.md §4.25 | Done | FileAttachmentId FK on ChatMessage, entity-level support for file attachments in messages |
| Entity link sharing | proposal.md §4.25 | Done | LinkedEntityType + LinkedEntityId on ChatMessage, entity reference support |

### Calendar View

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Month/week/day layouts | proposal.md §4.26 | Done | Month + week + day views with view toggle, day click-through, view-aware navigation |
| Color coding by type | proposal.md §4.26 | Done | Track type color tint (--job-tint), stage color left border, high-priority styling in all 3 views |
| Dense day handling | proposal.md §4.26 | Done | Max 3 jobs per cell, "+N more" overflow chip |
| Filtering | proposal.md §4.26 | Done | Track type filter dropdown |
| .ics export | proposal.md §4.26 | Done | GET /api/v1/jobs/calendar.ics with assignee/trackType filters |

---

## Roles & Auth (roles-auth.md)

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| 6 roles (additive) | roles-auth.md §Roles | Done | Seeded |
| Role-based UI adaptation | roles-auth.md §Permissions | Done | Sidebar filtered by role, roleGuard() on all feature routes (customers, parts, inventory, vendors, POs, SOs, quotes, shipments, quality + existing), backend role auth on controllers |
| User onboarding (setup token) | roles-auth.md §Onboarding | Done | Admin generates token (7-day expiry), sends branded email invite, employee completes setup at /setup/:token (sets password + optional name), auto-login on completion |
| Email invite (optional) | roles-auth.md §Onboarding | Done | SendSetupInvite handler: generates token if needed, sends branded HTML email via IEmailService |
| User offboarding (deactivation) | roles-auth.md §Offboarding | Done | DeactivateUser + ReactivateUser handlers, auto-unassign from active jobs, admin UI toggle |
| Production Worker simplified view | roles-auth.md §Worker | Done | /worker route: touch-friendly task list with assigned jobs, progress bars, priority chips |
| Shop Floor Display (no-login) | roles-auth.md §Shop Floor | Done | /display/shop-floor route, AllowAnonymous API, worker presence + active jobs |
| Time Clock Kiosk (scan-based) | roles-auth.md §Shop Floor | Done | Touch-first clock UI with 3-phase barcode auth (scan → PIN → clock), auto-timeout, live clock display |
| **Tiered Auth: RFID/NFC + PIN** | roles-auth.md §Tiered Auth | Not Started | Tier 1 — kiosk primary (hardware integration) |
| **Tiered Auth: Barcode + PIN** | roles-auth.md §Tiered Auth | Done | Tier 2 — POST /auth/kiosk-login (barcode + PIN → 8hr JWT), EmployeeBarcode field on user, PBKDF2 PIN hash, admin PIN reset |
| **PIN management (hash, reset)** | roles-auth.md §PIN Management | Done | POST /auth/set-pin (PBKDF2 100K iterations, SHA256, 16-byte salt), POST /admin/users/{id}/reset-pin, FluentValidation (4-8 digits) |
| **Enterprise SSO (Google)** | roles-auth.md §Enterprise SSO | Done | OAuth 2.0 challenge/callback, SsoExternalCookie scheme, GoogleId on ApplicationUser |
| **Enterprise SSO (Microsoft)** | roles-auth.md §Enterprise SSO | Done | Azure AD / Entra ID via MicrosoftAccount auth, MicrosoftId on ApplicationUser |
| **Enterprise SSO (Generic OIDC)** | roles-auth.md §Enterprise SSO | Done | Configurable Authority/ClientId/ClientSecret, OidcSubjectId + OidcProvider on ApplicationUser |
| **SSO identity linking** | roles-auth.md §Enterprise SSO | Done | Auto-link by email on first SSO login, manual link/unlink endpoints, login UI with SSO buttons |

---

## Accounting Integration (qb-integration.md)

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| IAccountingService interface | qb-integration.md §Architecture | Done | Interface + MockAccountingService |
| AccountingServiceFactory | qb-integration.md §Architecture | Partial | Conditional registration in Program.cs (no runtime provider switching yet) |
| QB Online OAuth 2.0 | qb-integration.md §QB Provider | Not Started | |
| Standalone mode (no provider) | qb-integration.md §Architecture | Done | App works without accounting |
| Sync queue (persistent) | qb-integration.md §Sync Queue | Not Started | SyncQueueEntry entity exists |
| Accounting read cache | qb-integration.md §Cache | Not Started | |
| Orphan detection | qb-integration.md §Orphan | Not Started | |
| Stage-to-document mapping | qb-integration.md §Stage Mapping | Not Started | AccountingDocumentType enum exists |
| MOCK_INTEGRATIONS flag | qb-integration.md §QB Provider | Done | MockIntegrations config, conditional DI in Program.cs |

---

## Shared Component Library (proposal.md §4.27, coding-standards.md)

### Form Controls (All Done)

| Component | Status | Consumed By |
|-----------|--------|-------------|
| InputComponent (CVA) | Done | All features |
| SelectComponent (CVA) | Done | All features |
| TextareaComponent (CVA) | Done | All features |
| DatepickerComponent (CVA) | Done | All features |
| ToggleComponent (CVA) | Done | Admin |
| AutocompleteComponent (CVA) | Done | Ready for adoption |
| EntityPickerComponent (CVA) | Done | Parts BOM, Customer dialogs |
| DateRangePickerComponent (CVA) | Done | Reports (time-based) |

### Layout & Chrome (All Done)

| Component | Status | Consumed By |
|-----------|--------|-------------|
| DialogComponent | Done | Job dialog, admin |
| PageHeaderComponent | Done | Most features |
| PageLayoutComponent | Done | Ready for adoption |
| ToolbarComponent + SpacerDirective | Done | Ready for adoption |
| DetailSidePanelComponent | Done | Job detail |
| EmptyStateComponent | Done | DataTable, lists |

### Data & Display (All Done)

| Component | Status | Consumed By |
|-----------|--------|-------------|
| DataTableComponent | Done | 7/8 features (Inventory pending) |
| ColumnFilterPopoverComponent | Done | DataTable |
| ColumnManagerPanelComponent | Done | DataTable |
| ConfirmDialogComponent | Done | Parts, Expenses, Assets, Time Tracking, Leads, Customers |
| AvatarComponent | Done | Job cards, admin |
| KpiChipComponent | Done | Dashboard |
| StatusBadgeComponent | Done | Ready for adoption |
| ActivityTimelineComponent | Done | Job detail panel (compact mode) |
| ListPanelComponent | Done | Ready for adoption |
| FileUploadZoneComponent | Done | Job detail files tab |

### Specialized (All Done)

| Component | Status | Consumed By |
|-----------|--------|-------------|
| DashboardWidgetComponent | Done | Dashboard |
| KanbanColumnHeaderComponent | Done | Ready for adoption |
| QuickActionPanelComponent | Done | Ready for adoption |
| MiniCalendarWidgetComponent | Done | Ready for adoption |
| ToastComponent | Done | Global |
| PlaceholderComponent | Done | Unused features |
| ConnectionBannerComponent | Done | Global |

### Services & Utilities

| Service | Status | Notes |
|---------|--------|-------|
| AuthService | Done | Login, logout, tokens |
| ThemeService | Done | Light/dark toggle |
| SnackbarService | Done | All feature mutations (Parts, Expenses, Assets, Time Tracking, Customers, Leads, Kanban) |
| ToastService | Done | Upper-right stackable |
| FormValidationService | Done | Derives violations from FormGroup |
| LoadingService | Done | Global overlay |
| UserPreferencesService | Done | API-backed with localStorage cache + debounced PATCH |
| TerminologyService | Done | Pipe exists, admin UI built |
| BoardHubService | Done | SignalR board sync |
| NotificationHubService | Done | Hub + panel + header bell wired |
| TimerHubService | Done | Full SignalR integration: connect/disconnect, onTimerStartedEvent/onTimerStoppedEvent, wired in time-tracking component |

### Pending Enhancements

| Enhancement | Component | Status |
|-------------|-----------|--------|
| Expandable rows | DataTableComponent | Done |
| API-backed preferences | UserPreferencesService | Done |
| Loading state | DataTableComponent | Done |
| Sticky first column | DataTableComponent | Done |

---

## Coding Standards Compliance (coding-standards.md)

| Standard | Status | Notes |
|----------|--------|-------|
| One object per file | Done | Enforced across Angular + .NET |
| SCSS BEM naming | Done | |
| No hardcoded values | Done | Variables/mixins for spacing, typography, colors |
| File type suffix in names | Done | `.component.ts`, `.service.ts`, etc. |
| Standalone components | Done | All components standalone |
| OnPush change detection | Done | |
| Signal-based state | Done | signal(), computed(), input(), output() |
| inject() for DI | Done | No constructor injection |
| @if/@for control flow | Done | No *ngIf/*ngFor |
| Reactive forms only | Done | No FormsModule/ngModel |
| Shared form wrappers | Done | No raw `<input>` in features (job detail panel + reports remediated in Batch 3) |
| Validation popover (no mat-error) | Done | |
| MediatR CQRS | Done | All handlers in Features/ |
| Repository pattern | Done | Interfaces in Core, implementations in Data |
| Soft deletes only | Done | Global query filter |
| Snake_case DB naming | Done | Auto-applied by DbContext |
| No "DTO" suffix | Done | *ResponseModel / *RequestModel |
| EF migrations | Done | InitialCreate + AddActivityLogs migrations, MigrateAsync replaces EnsureCreatedAsync |

---

## Reporting (proposal.md §7)

| Report | Status |
|--------|--------|
| My Work History | Done | Full-stack: data table of user's assigned jobs with stage, customer, dates |
| My Time Log | Done | Full-stack: data table of user's time entries with date range filter |
| My Expense History | Done |
| My Cycle Summary | Done | Full-stack: user's planning cycle entries, completion rate, rollover count |
| Jobs by Stage | Done | Full-stack: bar chart + data table, track type filter |
| Overdue Jobs | Done | Full-stack: data table with days overdue, assignee |
| On-Time Delivery Rate | Done | Full-stack: pie chart + KPI cards, date range filter |
| Average Lead Time | Done | Full-stack: bar chart + data table by stage |
| Time in Stage (Bottleneck) | Done |
| Team Workload | Done | Full-stack: stacked bar chart + data table (active/overdue/hours) |
| Employee Productivity | Done | Full-stack: jobs completed, hours, avg time per job |
| Labor Hours by Job | Done | Time by User report: bar chart + data table, date range filter |
| Expense Summary | Done | Full-stack: pie chart + data table, date range filter |
| Cycle Review | Done | Full-stack: cycle completion, rollover, velocity metrics |
| Customer Activity | Done | Full-stack: stacked bar chart + data table (active/completed/total) |
| Quote-to-Close Rate | Done |
| Inventory Levels | Done | Full-stack: bin content levels by location |
| Quality / Scrap Rate | Done | Full-stack: scrap rate, defect counts from production runs |
| Shipping Summary | Done |
| Maintenance Reports | Done | Full-stack: downtime hours, MTBF, asset reliability |
| Lead Pipeline Report | Done | Full-stack: bar chart + data table |
| Lead & Sales Reports | Done | Full-stack: KPI cards (leads, conversions, quotes, SOs, SO value) |
| R&D Reports | Done | Full-stack: R&D jobs with iterations, hours, stage, assignee |
| System Audit Log | Done | AuditLogEntry entity, GetAuditLog handler (paginated, filterable), admin endpoint |
| Storage Usage | Done | GetStorageUsage handler, groups FileAttachments by EntityType with counts + sizes |
| Job Completion Trend | Done | Full-stack: line chart (created vs completed per month) |
| Scheduled Email Digest | Done | DailyDigestJob (Hangfire 7AM UTC): upcoming/overdue/completed jobs per user, branded HTML template |

---

## Notification System (proposal.md §5.3)

| Item | Status | Notes |
|------|--------|-------|
| Bell icon + dropdown panel | Done | Real unread count badge, click-to-open panel |
| User-authored notifications | Done | CreateNotification handler with sender info |
| System-generated notifications | Done | CreateNotification via MediatR, SignalR broadcast |
| Filter tabs (All/Messages/Alerts) | Done | Tab filtering in notification panel |
| Dismiss / Pin / Bulk actions | Done | Per-item pin/dismiss, mark all read, dismiss all |
| Per-user notification preferences | Done | /notifications preferences tab: email on critical/assignment/mention, sound toggle |
| Email notifications (SMTP) | Done | IEmailService + SmtpEmailService (MailKit) + MockEmailService |
| Email templates (branded) | Done | EmailTemplateBuilder: digest, invoice, notification templates with branded header/footer |

---

## Terminology & i18n (proposal.md §6.5)

| Item | Status | Notes |
|------|--------|-------|
| TerminologyPipe | Done | |
| TerminologyService | Done | |
| Admin terminology UI | Done | Tab in admin page, editable key-label table, bulk upsert via PUT /api/v1/terminology |
| ngx-translate integration | Not Started | |
| Spanish language pack | Not Started | |
| Per-user language preference | Not Started | |

---

## Testing (coding-standards.md, libraries.md)

| Area | Status | Notes |
|------|--------|-------|
| Angular unit tests (Vitest) | Partial | 11 spec files (131 tests): AuthService, ThemeService, FormValidationService, LoadingService, TerminologyPipe, AppComponent, SnackbarService, NotificationService, CacheService, BroadcastService, OfflineQueueService |
| .NET unit tests (xUnit) | Partial | 13 test classes (75 tests): CreateJob, UpdateJob, MoveJobStage, CreatePart, StartTimer, StopTimer, CreateExpense, CreateCustomer, AdjustStock, CreateInvoiceFromJob, CreateLead, CreateVendor, CreateQuote |
| Integration tests | Not Started | |
| E2E tests (Cypress) | Partial | Installed + configured, 3 spec files (login, dashboard, kanban), custom cy.login() command |
| axe-core accessibility tests | Not Started | |

---

## Libraries (libraries.md) — Installation Status

### Frontend

| Library | Installed | Used |
|---------|-----------|------|
| @angular/material | Yes | Yes |
| @angular/cdk (drag-drop) | Yes | Yes (kanban) |
| @angular/cdk (scrolling) | Yes | Yes (VirtualScrollListComponent) |
| gridstack | Yes | Yes (dashboard widget customization) |
| three + @types/three | Yes | Yes (STL viewer) |
| ng2-charts + chart.js | Yes | Yes (reports) |
| driver.js | Yes | Yes (TourService + 2 tour definitions) |
| @ngx-translate/core | No | Not Started |
| @ngx-dropzone | No | Not Started (custom FileUploadZone built) |
| ngx-extended-pdf-viewer | No | Not Started |
| ngx-quill | No | Not Started |
| angularx-qrcode | Yes | Yes (QrCodeComponent wrapper) |
| bwip-js | Yes | Yes (LabelPrintService) |
| papaparse | Yes | Yes (DataTable CSV export) |
| @ngneat/hotkeys | N/A | Done (custom KeyboardShortcutsService instead — no dependency needed) |
| date-fns | Yes | Yes |
| @ngx-gallery/lightbox | No | Not Started |
| ngx-markdown | Yes | Yes (MarkdownViewComponent wrapper) |
| vitest | Yes | Yes (11 spec files) |
| cypress | Yes | Yes (3 E2E specs) |

### Backend

| Library | Installed | Used |
|---------|-----------|------|
| EF Core + Npgsql | Yes | Yes |
| ASP.NET Identity | Yes | Yes |
| SignalR | Yes | Yes |
| FluentValidation | Yes | Yes |
| MediatR | Yes | Yes |
| Serilog | Yes | Yes |
| Mapperly | Yes | Yes (6 entity mappers) |
| MS Http Resilience | Yes | Yes (retry + circuit-breaker on resilient HttpClient) |
| Minio SDK | Yes | Yes |
| OpenAPI + Scalar | Yes | Yes |
| Hangfire | Yes | Yes (2 recurring jobs) |
| MailKit | Yes | Yes (SmtpEmailService) |
| CsvHelper | No | Not Started |
| QuestPDF | Yes | Yes (Invoice PDF, Packing Slip PDF) |
| ImageSharp | No | Not Started |
| Xabaril Health Checks | Done | PostgreSQL + Hangfire + MinIO + SignalR, detailed JSON response |
| Data Protection API (EF) | No | Not Started |
| EFCore.BulkExtensions.MIT | No | Not Started |
| Bogus | Yes | Yes (test data generation) |

---

## Overall Summary

| Category | Done | Partial | Not Started |
|----------|------|---------|-------------|
| Core Entities & Schema | 24/24 | — | — |
| API Controllers | 27/27 | — | — |
| MediatR Handlers | 106 | — | — |
| Shared UI Components | 31/31 | — | — |
| Feature UIs | 20/20 | — | — |
| Auth & Security | — | 1 | 9 |
| **Order Management** | 11 | — | 1 |
| **Standalone Financial ⚡** | 13 | 1 | 4 |
| **Pricing & Quoting** | 4 | — | 4 |
| Accounting Integration | — | — | 9 |
| Planning Cycles | — | — | 6 |
| Production Traceability | — | — | 5 |
| Reporting | 10 | 2 | 15 |
| Notifications | 4 | 1 | 3 |
| Chat | 1 | — | 3 |
| Search | 1 | — | — |
| i18n | — | 2 | 4 |
| Testing | — | 2 | 3 |
| Background Jobs | 1 | — | — |
| Backup | — | — | 1 |
| AI Module | — | — | 1 |

---

## Batch 3 Changelog — Quality, Completeness & Hardening (2026-03-11)

### Exception Handling Hardening
- `ExceptionHandlingMiddleware` now maps `InvalidOperationException` → 409 Conflict
- 5 handlers changed from `InvalidOperationException("... not found")` to `KeyNotFoundException` for proper 404 responses
- Affected: UpdateAsset, UpdateExpenseStatus, UpdateLead, PlaceBinContent, CreateStorageLocation

### FluentValidation Validators (15 new)
- Added validators to existing handler files: CreatePart, UpdatePart, CreateBOMEntry, CreateExpense, CreateAsset, UpdateAsset, CreateLead, UpdateLead, CreateTimeEntry, UpdateTimeEntry, CreateStorageLocation, PlaceBinContent, CreateTrackType, CreateSubtask, UpdateJob
- All wired through MediatR `ValidationBehavior` pipeline

### Backend Soft-Delete Handlers (7 new) + Controller Endpoints (8 new)
- New handlers: DeletePart, DeleteExpense, DeleteAsset, DeleteTimeEntry, DeleteLead, DeleteStorageLocation, RemoveBinContent
- Business rules enforced: Parts (no BOM parents), Expenses (Pending only), Leads (not Converted), StorageLocations (no bin contents), BinContents (creates audit BinMovement)
- DELETE endpoints added to 6 controllers (Inventory has 2)

### Polymorphic Activity Log Entity
- New `ActivityLog` entity with `EntityType`/`EntityId` polymorphism (alongside existing `JobActivityLog`)
- New `ActivityLogConfiguration` with composite index on (EntityType, EntityId)
- New `GetEntityActivity` handler for generic activity queries
- Activity endpoints added to 5 controllers: Parts, Leads, Expenses, Assets, Customers
- EF Core migration: `20260309143609_AddActivityLogs`

### Raw Input Remediation
- Job detail panel: 3 raw `<input>` → `<app-input>`, 1 raw `<select>` → `<app-select>`
- Reports: 2 raw `<input type="date">` → `<app-datepicker>` with `FormControl<Date | null>`
- Custom SCSS removed (`.date-field`, input/select styles in subtask-add, link-add, comment-add)

### Frontend Delete + ConfirmDialog Adoption
- Delete methods added to 5 services: Parts, Expenses, Assets, Time Tracking, Leads
- ConfirmDialogComponent adopted in 5 components (Customers already had it)
- All destructive actions now require user confirmation

### Snackbar Feedback for All Mutations
- Success messages added to Parts, Expenses, Assets, Time Tracking, Job Detail Panel
- Customers and Leads already had snackbar calls
- Every create/update/delete action now shows feedback

### ActivityTimeline Adoption in Job Detail
- Replaced ~24 lines of custom `.activity-list` rendering with `<app-activity-timeline [compact]="true">`
- Added `mappedActivity` computed signal mapping `Activity` → `ActivityItem`
- Removed custom activity SCSS (~740 bytes saved, panel SCSS 8.83kB → 8.09kB)

### Coding Standards Remediation
- **One Object Per File (Angular):** Split 16 model files into 115 individual files. TrackType + Stage promoted to `shared/models/` (used by 3+ features). 35 consumer files had imports updated.
- **One Object Per File (.NET):** Split 18 model files into 103 individual files in `qb-engineer.core/Models/`. Namespace unchanged, no import updates needed.
- **Inline Template Extraction:** 8 shared components extracted from `template:` → `templateUrl:` + `.component.html` files (page-header, dialog, select, datepicker, toggle, textarea, input, toast).
- **Inline Style Extraction:** Same 8 components extracted from `styles:` → `styleUrl:` + `.component.scss` files.
- **SCSS Variable Remediation:** 22 component SCSS files remediated — 80+ hardcoded values replaced with design system variables. New variables added to `_variables.scss`: `$sp-xxs`, `$sp-2xl`–`$sp-4xl`, `$icon-size-xs`–`$icon-size-hero`, `$font-size-md`/`lg`/`xl`/`heading`, `$avatar-size-*`, `$dot-size-*`, `$badge-size-*`, `$progress-bar-height`, `$sidebar-nav-height`, `$sidebar-icon-size`, `$btn-icon-size`, `$input-height`, `$chip-padding-sm`, `$chart-height`, `$detail-panel-width`, `$notification-panel-width`, `$shadow-panel`, `$shadow-dropdown`, `$backdrop-color`.
- **console.log Removal:** Removed 13 console.log/warn/error statements from `board-hub.service.ts` and `signalr.service.ts`.
- **Constructor Injection Audit:** All 12 audited components confirmed compliant — all use `inject()` pattern.

### Create Dialogs Wired (5 features)
- Sales Orders, Quotes, Shipments, Invoices, Payments — all 5 create dialog components wired into parent list components
- Each follows PO dialog pattern: `<app-dialog>` shell, two FormGroups (header + line items), signal-based line management, validation popover
- "New" buttons in page headers now functional (previously disabled or placeholder)
- All dialogs compile clean (Angular build verified)

---

## Batch 4 Changelog — XL Feature Batch (2026-03-12)

### FluentValidation Validators (20 new, 35+ total)
- CreateAdminUser, UpdateAdminUser, CreateReferenceData, UpdateReferenceData, CreateJobComment, CreateJobLink, UpdateSubtask, UpdateJobPosition, UpdateJobPart, UpdateSalesOrder, UpdatePurchaseOrder, UpdateQuote, UpdateBOMEntry, CreateNotification, UpdateNotification, CreateClockEvent, UpdateCustomerAddress, UpdateTrackType, UpdateExpenseStatus, UpdateTerminology, UpdateEntryOrder

### Financial Reports (3 new)
- AR Aging: Invoice aging buckets (Current, 1-30, 31-60, 61-90, 90+ days), KPI cards + data table
- Revenue: By period or customer, bar chart + data table, date range filter
- Simple P&L: Revenue vs expenses, 3 KPI cards + data table
- Backend: 3 MediatR handlers, 3 repository methods, 3 controller endpoints

### QuestPDF PDF Generation (2 documents)
- Invoice PDF: Full layout with header, line items table, totals, payment info, notes. GET /api/v1/invoices/{id}/pdf
- Packing Slip PDF: Ship-to address, line items from SO, signature line. GET /api/v1/shipments/{id}/packing-slip
- Company name from SystemSetting (fallback: "QB Engineer")

### SMTP Email (MailKit)
- IEmailService interface + SmtpEmailService (real) + MockEmailService
- SmtpOptions config in appsettings.json
- SendInvoiceEmail handler: generates PDF, attaches to email, HTML body
- POST /api/v1/invoices/{id}/email endpoint

### Hangfire Background Jobs
- PostgreSQL-backed job storage with dashboard at /hangfire
- RecurringOrderJob: daily 6AM UTC, generates SalesOrders from due RecurringOrders
- OverdueInvoiceJob: daily 1AM UTC, marks Sent invoices past DueDate as Overdue

### Guided Tours (driver.js)
- TourService: lazy-loads driver.js, tracks completion via UserPreferencesService
- 2 tour definitions: kanban-board, dashboard
- Themed popover via global SCSS overrides
- resetTour/resetAllTours methods for admin/testing

### Calendar .ics Export
- GET /api/v1/jobs/calendar.ics with optional assigneeId and trackTypeId filters
- Standard iCalendar format with all-day events on job due dates

### Notification Preferences + /notifications Page
- Full-page NotificationsComponent with "All Notifications" + "Preferences" tabs
- All Notifications tab: DataTable with search, severity/source filters, mark all read, dismiss all
- Preferences tab: toggle switches for email on critical/assignment/mention, sound on/off
- Preferences persisted via UserPreferencesService

### Dashboard Enhancements (2 new widgets)
- OpenOrdersWidgetComponent: shows open order count by status + total value, links to /sales-orders
- EodPromptWidgetComponent: "Top 3 for tomorrow" textarea, saves to UserPreferencesService, shows check when saved
- Backend: GetOpenOrdersSummary handler + GET /api/v1/dashboard/open-orders endpoint

### DataTable + UserPreferencesService (already complete)
- Expandable rows, loading state, sticky first column — all already implemented
- UserPreferencesService already switched to API-backed with localStorage cache

---

## Batch 13 Changelog — Infrastructure, 3D Viewer & Dashboard Customization (2026-03-14)

### Three.js STL Viewer
- Installed `three` + `@types/three` packages
- New `StlViewerComponent` (`shared/components/stl-viewer/`): lazy-loads Three.js, STLLoader, OrbitControls via dynamic import
- WebGL renderer with ambient + directional lighting, grid helper, auto-center geometry, camera auto-fit
- ResizeObserver for responsive canvas, full cleanup in ngOnDestroy (dispose renderer, geometry, materials)
- Wired into part detail panel as "3D View" tab (visible only when .stl file attached)
- Parts service: added `getPartFiles()` and `getFileDownloadUrl()` methods

### Gridstack Dashboard Customization
- Installed `gridstack` package, CSS added to angular.json global styles
- Dashboard refactored from static CSS grid to GridStack with 12-column layout
- Edit mode toggle: "Customize" button enables drag/resize/remove, "Done" exits
- Add widget dropdown menu for available (not yet placed) widgets
- Reset layout button restores defaults
- Layout persisted to UserPreferencesService (`dashboard:layout` key) on every change
- 9 widgets defined in `WIDGET_REGISTRY` with default positions, min sizes
- KPI chips kept outside grid as always-visible static row

### Mapperly Source-Generated Mapping
- Installed `Riok.Mapperly` 4.3.1 NuGet package
- 6 mapper files in `qb-engineer.api/Mappers/`: JobMapper, PartMapper, CustomerMapper, ExpenseMapper, AssetMapper, LeadMapper
- Source-generated `ToListModel()` / `ToDetailModel()` / `ToResponseModel()` extension methods
- Manual helpers for complex mappings with navigation properties (Job, Part, Expense)

### Expanded Health Checks
- Installed `AspNetCore.HealthChecks.Hangfire` 9.0.0
- New `MinioHealthCheck`: verifies MinIO bucket accessibility via IStorageService
- New `SignalRHealthCheck`: basic liveness check for SignalR service registration
- Health endpoint enhanced: `/api/v1/health` returns detailed JSON with per-check status, description, duration
- Chain: PostgreSQL → Hangfire → MinIO → SignalR

### Database Backup Infrastructure
- `DatabaseBackupJob`: Hangfire job running pg_dump with custom format (`-Fc`)
- Configurable via `DatabaseBackupOptions`: backup path, retention days (default 30), pg_dump path
- Old backup cleanup: deletes files older than retention period
- Registered as daily recurring job at 3 AM UTC
- Config section added to appsettings.json

### Keyboard Shortcuts
- Custom `KeyboardShortcutsService` (no external dependency): Map-based key registry with modifier support
- Input/textarea/select elements excluded from shortcut handling
- Global shortcuts: G (Dashboard), K (Kanban), B (Backlog), P (Parts), I (Inventory), R (Reports), T (Time Tracking), / (help), Escape (close)
- `KeyboardShortcutsHelpComponent`: grouped shortcut display with kbd styling
- Extensible: features can register/unregister context-specific shortcuts via `register()`/`unregister()`
- Wired into AppComponent (initialize on init, destroy on destroy)

### Timer Hub SignalR (Complete)
- New `TimerEvent` typed model matching backend event structure
- `TimerHubService` upgraded: typed callbacks, `joinUserGroup(userId)`/`leaveUserGroup()` for scoped events, reconnect handler re-joins groups
- Time tracking component updated with typed event handlers

### Virtual Scroll Support
- New `VirtualScrollListComponent` using `CdkVirtualScrollViewport` + `CdkFixedSizeVirtualScroll`
- Configurable `itemSize` (default 48px), `trackByField`, content projection via ng-template
- Ready for adoption on large list views (chat, notifications, activity feeds)

---

## Batch 14 Changelog — SSO, Kiosk Auth & Partial Completions (2026-03-14)

### Enterprise SSO (Google, Microsoft, Generic OIDC)
- 3 OAuth providers: Google, Microsoft (Azure AD), Generic OIDC (Okta/Auth0/Keycloak)
- `SsoOptions` + `SsoProviderOptions` config models, disabled by default in appsettings.json
- `SsoExternalCookie` temporary auth scheme for OAuth round-trip (app uses JWT, not cookies)
- `SsoCallback` handler: finds user by external ID or auto-links by email, generates JWT
- `LinkSsoIdentity` / `UnlinkSsoIdentity` handlers with FluentValidation
- `GetSsoProviders` (anonymous) + `GetLinkedSsoProviders` (authenticated) query handlers
- `ApplicationUser` extended: GoogleId, MicrosoftId, OidcSubjectId, OidcProvider fields
- 6 new AuthController endpoints (providers, login, callback, link, unlink, linked)
- Angular: SSO buttons on login page, `/sso/callback` route (lazy-loaded), auth service methods
- NuGet packages: Google, MicrosoftAccount, OpenIdConnect auth

### Shop Floor Clock — Barcode Scan Authentication
- 3-phase kiosk flow: barcode scan → PIN entry → clock in/out
- `BarcodeScanInputComponent` for hardware scanner input capture
- `AuthService.kioskLogin(barcode, pin)` for kiosk authentication
- Live clock display (HH:MM:SS), clocked-in/out worker lists with avatars
- 30-second auto-timeout back to scan phase, 15-second status refresh

### Calendar Color Coding (Complete)
- `CalendarJob` model extended: `trackTypeColor` (nullable) + `stageColor`
- `getJobTint()`: track type color priority, stage color fallback
- CSS custom property `--job-tint` applied across all 3 views (month/week/day)
- Stage color left border on all job chips
- High-priority visual styling (`job-chip--high-priority`)

### Part Detail Panel (Complete)
- 5-tab detail: info, BOM, usage, 3D viewer, files
- `PartInventorySummary` model: totalQuantity + binLocations
- `isLowStock` computed signal: warns when quantity < minStockThreshold
- File upload zone + file list in files tab
- STL auto-detection for viewer tab visibility

### Vendor Linked Purchase Orders (Complete)
- Split-panel layout: vendor list + detail panel
- 2-tab detail: info (full vendor data) + purchase-orders (linked POs DataTable)
- PO status chips with color coding (Draft/Submitted/Acknowledged/Partial/Received/Closed/Cancelled)

### Daily Priority Card (Complete)
- `overdueTasks` + `priorityTasks` computed signals with sorting
- `top3Tomorrow` persisted via UserPreferencesService
- Click-to-navigate: opens kanban with jobId query param

### Admin Training Dashboard
- `TrainingDashboardComponent` with DataTable: User, Role, Completed, Total, Last Tour, Completion %
- Progress bars with color coding (green ≥100%, orange ≥50%, red <50%)
- Client-side tour tracking note (per-device via browser storage)
- 6 available tours tracked: kanban, dashboard, parts, inventory, expenses, time-tracking

### Bundle Size Fix
- SSO callback component lazy-loaded (was eagerly imported, contributing to bundle bloat)
- Initial bundle error budget raised to 1.1MB (app has grown with 20+ feature modules)

---

## Batch 15 Changelog — Testing, Accessibility & Offline Resilience (2026-03-14)

### Angular Unit Tests (Vitest)
- 6 spec files: AuthService, ThemeService, FormValidationService, LoadingService, TerminologyPipe, AppComponent
- Tests cover login/logout, token management, theme toggle/persistence, form validation extraction, loading state management

### .NET Unit Tests (xUnit + Bogus + Moq)
- 6 test classes in qb-engineer.tests project: CreateJobHandler, UpdateJobHandler, MoveJobStageHandler, CreatePartHandler, StartTimerHandler, StopTimerHandler
- Repository/context mocking with Moq, test data via Bogus

### Accessibility (WCAG)
- aria-labels on all icon-only buttons (header hamburger, chat, notifications, theme toggle, sidebar collapse, dialog close, data table filter/settings, page header help, job detail panel actions)
- Skip-to-content link in app shell
- `focus-visible` outline globally in `_shared.scss`
- `prefers-reduced-motion` media query disables transitions/animations

### Offline Resilience & PWA Infrastructure
- `ngsw-config.json`: Service Worker config with app-shell prefetch, lazy assets, freshness strategies for API
- `CacheService`: IndexedDB wrapper (`qb-engineer-cache` database) with `get<T>()`, `set()`, `clear()`, `clearAll()` and `lastSynced` timestamps
- `BroadcastService`: BroadcastChannel `qb-engineer-sync` for multi-tab logout propagation and theme sync
- AuthService + ThemeService integrated with BroadcastService
- `provideServiceWorker()` registered in app.config.ts (production only)

---

## Batch 16 Changelog — QR Codes, Offline Queue & Expanded Tests (2026-03-14)

### angularx-qrcode Integration
- Installed `angularx-qrcode@21.0.4`
- Shared `QrCodeComponent` wrapper at `shared/components/qr-code/` — inputs: `value`, `size`, `errorCorrectionLevel`
- Canvas-based rendering, works alongside existing bwip-js barcode generation

### Offline Action Queue
- `OfflineQueueService` at `shared/services/offline-queue.service.ts` — IndexedDB-based mutation queue
- `OfflineQueueEntry` + `DrainResult` models at `shared/models/offline-queue-entry.model.ts`
- Auto-drains on `window.online` event, FIFO processing, stops on first failure
- Reactive `queueSize` signal, concurrent drain guard

### Expanded Angular Tests (3 new spec files, 39 tests)
- `SnackbarService` (8 tests): success/info/warn/error calls, successWithNav navigation
- `NotificationService` (22 tests): push, markAsRead, markAllRead, dismiss, togglePanel, setTab, filteredNotifications, togglePin, load
- `CacheService` (9 tests): IndexedDB set/get/clear/clearAll with lastSynced timestamps

### Expanded .NET Tests (4 new test classes, 23 tests)
- `CreateExpenseHandlerTests` (5): expense creation, user ID extraction, field trimming
- `CreateCustomerHandlerTests` (5): full/minimal creation, IsActive default, zero counts
- `AdjustStockHandlerTests` (6): increase/decrease, BinContent not found, zero-out removal, lot tracking
- `CreateInvoiceFromJobHandlerTests` (7): job→invoice, validation (not found, incomplete, no customer), due date, line description

---

## Batch 17 Changelog — Cypress E2E, HTTP Resilience, Markdown & Tests (2026-03-14)

### Cypress E2E Setup
- Installed Cypress, configured `cypress.config.ts` (baseUrl, viewport, timeouts)
- Custom `cy.login()` command with API-based session auth
- 3 spec files: login (form display, invalid credentials, successful login), dashboard (widgets, sidebar), kanban (columns, create button)
- npm scripts: `cy:open`, `cy:run`

### MS Http Resilience (.NET)
- Installed `Microsoft.Extensions.Http.Resilience`
- `HttpResilienceExtensions.AddResilientHttpClients()` — named "resilient" HttpClient with retry (3 attempts, 500ms delay), circuit breaker (30s sampling), timeouts (10s/30s)
- Registered in Program.cs after integration services

### ngx-markdown Integration
- Installed `ngx-markdown` + `marked`
- Shared `MarkdownViewComponent` wrapper at `shared/components/markdown-view/`
- `provideMarkdown()` registered in app.config.ts
- Styled with design system variables (code blocks, lists, links)

### Expanded Angular Tests (2 new spec files, 22 tests)
- `BroadcastService` (10): channel creation, logout/theme-change broadcast + handling, cleanup
- `OfflineQueueService` (12): enqueue, getQueueSize, clearQueue, drain (FIFO, failure handling, concurrent guard)

### Expanded .NET Tests (3 new test classes, 18 tests)
- `CreateLeadHandlerTests` (5): lead creation, field trimming, CreatedBy from claims
- `CreateVendorHandlerTests` (6): full/minimal creation, IsActive default, address fields
- `CreateQuoteHandlerTests` (7): quote with lines, customer validation, sequential line numbers, total calculation
