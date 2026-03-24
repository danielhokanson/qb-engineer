# Implementation Status

Tracks real implementation against all spec docs. Updated: 2026-03-23.

Legend: Done | Partial | Not Started | N/A (deferred or out of scope)

---

## Phase Status (proposal.md §8)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1 — Foundation | Docker + Kanban + Job Cards | Done |
| 2 — Engineer UX | Dashboard + Planning Day | Done |
| 3 — Accounting Bridge | QB Read/Write Integration | Done |
| 4 — Leads & Contacts | Lead-to-Customer Pipeline | Done |
| 5 — Traceability & QC | Production Lot Tracking | Done |
| 6 — Time & Workers | Time Tracking + Worker Views | Done |
| 7 — Expenses & Invoicing | Expense Capture + Invoice Workflow | Done |
| 8 — Maintenance | Asset Registry + Scheduled Maintenance | Done |
| 9 — Reporting | Operational Dashboards | Done |
| 10 — Backup & Polish | Production Hardening | Done |
| 11 — AI Assistant | Self-Hosted AI Module | Done |
| 12 — Domain AI Assistants | Configurable AI Assistants (HR, Procurement, Sales) | Done |

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
| Hangfire | architecture.md §Stack | Done | 14 recurring jobs, PostgreSQL storage, dashboard |
| Mapperly | architecture.md §Stack | Done | 6 mappers (Job, Part, Customer, Expense, Asset, Lead) in qb-engineer.api/Mappers/ |
| OpenAPI + Scalar | architecture.md §Stack | Done | API docs available |
| Docker Compose | architecture.md §Docker | Done | 6 containers running (AI optional via profile), Alpine images, non-root user, health checks, resource limits |
| CI/CD Pipeline | architecture.md §CI/CD | Done | GitHub Actions: parallel build+test (Angular + .NET), Docker image build on main push |

### Auth & Security

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| ASP.NET Identity | architecture.md §Auth | Done | Custom ApplicationUser |
| JWT bearer auth | architecture.md §Auth | Done | Access + refresh tokens |
| Refresh token rotation | architecture.md §Auth | Done | |
| Additive roles | architecture.md §Auth | Done | 6 roles seeded |
| OAuth token encryption | architecture.md §Auth | Done | Data Protection API with EF Core key storage, TokenEncryptionService |
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
| /admin/qb-setup | architecture.md §Routing | Done | Covered by IntegrationsPanelComponent in admin settings — provider selection, QB OAuth, sync status |
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
| Self-hosted AI (Ollama + RAG) | architecture.md §AI | Done | OllamaAiService, llama3.2:3b model, AiController (generate/summarize/status/search/index), Angular AiService + AiHelpPanel. RAG pipeline: DocumentEmbedding entity (pgvector vector(384)), IEmbeddingRepository, RagSearch/IndexDocument/BulkIndexDocuments handlers, DocumentIndexJob (Hangfire 30min), header search column with RAG results |
| Theming (light/dark) | architecture.md §Theming | Done | Toggle in toolbar, CSS custom properties |
| Admin brand colors | architecture.md §Theming | Done | System settings for primary/accent colors, runtime CSS variable override, public brand endpoint |
| Accessibility (WCAG 3) | architecture.md §Accessibility | Done | aria-labels on all icon buttons, focus-visible outlines, skip-to-content link, prefers-reduced-motion. axe-core tests on 10 pages (Cypress). |
| Mobile responsiveness | architecture.md §Mobile | Done | LayoutService with breakpoint detection, hamburger menu, mobile sidebar overlay. Per-page responsive grids on dashboard, parts, inventory, kanban. |
| Offline resilience / PWA | architecture.md §Offline | Done | Service Worker, IndexedDB cache, BroadcastChannel sync, OfflineQueueService (conflict signals), OfflineBannerComponent, SyncConflictDialogComponent (409 resolution) |

---

## Functional Decisions (functional-decisions.md)

### Kanban Board

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Track types (4 built-in) | functional-decisions.md §Kanban | Done | Production, R&D, Maintenance, Other |
| Custom track types | functional-decisions.md §Kanban | Done | Create/edit/delete dialog, stage management, backend CRUD |
| Card movement (forward/backward) | functional-decisions.md §Kanban | Done | Irreversible stage blocking works |
| Backward move double-confirmation (QB) | functional-decisions.md §Kanban | Done | MoveJobStage blocks backward moves from irreversible stages |
| Multi-select + bulk actions | functional-decisions.md §Kanban | Done | Ctrl+Click, floating bulk bar (Move/Assign/Priority/Archive), 4 backend handlers |
| SignalR real-time sync | functional-decisions.md §Kanban | Done | BoardHub, optimistic UI |
| Column body colored border | functional-decisions.md §Kanban | Done | Inset box-shadow per stage color |
| Hold indicators on cards | functional-decisions.md §Status Lifecycle | Done | Pause icon badge when active holds exist, matTooltip lists hold names, warning color |

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
| Accounting document refs | proposal.md §4.2 | Done | ExternalRef + AccountingDocumentType on JobListResponseModel, receipt_long icon on kanban card |
| Custom fields (per track type) | proposal.md §4.2 | Done | JSONB definitions on TrackType, values on Job, CRUD endpoints |
| R&D iteration counter/notes | proposal.md §4.2 | Done | IterationCount + IterationNotes on Job entity, UI section in job detail panel |
| Production runs tab | proposal.md §4.2 | Done | ProductionRun entity, CRUD handlers, controller endpoints |
| Job disposition | functional-decisions.md §Job Disposition | Done | DisposeJob endpoint, disposition dialog UI, kanban card indicator. Options: ShipToCustomer, AddToInventory, CapitalizeAsAsset, Scrap, HoldForReview |

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
| Accounting item linkage | proposal.md §4.3 | Done | Link/unlink Part to accounting items via provider factory. POST/DELETE endpoints, Angular UI in part detail Info tab |
| Part-to-job reference | proposal.md §4.3 | Done | JobPart entity, CRUD endpoints, search + add in job detail panel |
| Part status Prototype | functional-decisions.md §NPI Gate | Done | Prototype value added to PartStatus enum (Draft → Prototype → Active → Obsolete) for NPI gate |
| Auto part numbering | functional-decisions.md §Auto Part Numbering | Done | Categorical prefixes (PRT-, ASM-, RAW-, CON-, TLG-, FST-, ELC-, PKG-) + 5-digit zero-padded sequence. Optional external part number |
| Process Plan / Routing | functional-decisions.md §BOM-Driven Work Breakdown | Done | ProcessStep entity with ordered steps, instructions, work center assignment, QC checkpoints. CRUD endpoints on PartsController. |
| BOM Explosion | functional-decisions.md §BOM-Driven Work Breakdown | Done | ExplodeJobBom handler creates child jobs from Make entries, lists Buy/Stock items. One-level explosion, user explodes sub-assemblies individually. |
| BOM Source Type: Stock | functional-decisions.md §BOM-Driven Work Breakdown | Done | Added Stock to BOMSourceType enum alongside Make/Buy. |
| BOM Lead Time | functional-decisions.md §BOM-Driven Work Breakdown | Done | LeadTimeDays field on BOMEntry. |
| Job Parent/Child Hierarchy | functional-decisions.md §BOM-Driven Work Breakdown | Done | ParentJobId on Job, GetChildJobs endpoint, sub-jobs displayed in job detail panel. |

### CAD / STL / CAM File Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| File upload/download | proposal.md §4.4 | Done | MinIO, per-entity |
| File versioning by revision | proposal.md §4.4 | Done | PartRevisionId FK on FileAttachment, GetFilesByRevision handler, endpoint on FilesController |
| STL 3D viewer (Three.js) | proposal.md §4.4 | Done | OrbitControls, auto-center, ambient+directional lighting, responsive resize |
| Chunked upload with progress | proposal.md §4.4 | Done | FileUploadZoneComponent: auto-chunked for files > 5MB, sequential chunk upload, server-side reassembly, temp file cleanup |
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
| Accounting sync (read/write) | proposal.md §4.8 | Done | IAccountingProviderFactory resolves active provider at runtime. AccountingController: providers, employees, items, sync-status, test, disconnect endpoints. All sync jobs use factory. |

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
| Receipt upload (camera/file) | proposal.md §4.10 | Done | FileUploadZone + CameraCaptureComponent (MediaDevices API) |
| Approval workflow | proposal.md §4.10 | Done | Status field + dedicated /expenses/approval queue with review dialog and approval notes |
| Self-approval settings | proposal.md §4.10 | Done | SystemSettings: expense_self_approval, expense_auto_approve_threshold |
| Accounting sync | proposal.md §4.10 | Done | Expense sync uses IAccountingProviderFactory, provider-agnostic sync queue |
| CSV export | proposal.md §4.10 | Done | DataTableComponent has universal CSV export via papaparse (all visible columns) |
| Recurring expenses | — | Done | RecurringExpense entity, Hangfire auto-generation, classification highlighting, /expenses/upcoming ledger |

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

### Status Lifecycle Tracking

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| StatusEntry entity (polymorphic) | functional-decisions.md §Status Lifecycle | Done | EntityType/EntityId, workflow + hold categories, start/end dates, full audit trail |
| Workflow statuses (one active) | functional-decisions.md §Status Lifecycle | Done | SetWorkflowStatus closes previous entry before creating new one |
| Hold statuses (parallel) | functional-decisions.md §Status Lifecycle | Done | AddHold prevents duplicate active holds of same code, ReleaseHold sets EndedAt |
| Reference data-driven status codes | functional-decisions.md §Status Lifecycle | Done | Admin-configurable via `{entity}_workflow_status` and `{entity}_hold_type` groups |
| StatusTrackingController (5 endpoints) | functional-decisions.md §Status Lifecycle | Done | GetStatusHistory, GetActiveStatuses, SetWorkflowStatus, AddHold, ReleaseHold |
| Job holds (4 types) | functional-decisions.md §Status Lifecycle | Done | Material Hold, Quality Hold, Customer Hold, Engineering Hold |
| StatusTimelineComponent (shared) | functional-decisions.md §Status Lifecycle | Done | Active status, active holds with release, full history timeline. Integrated into job detail panel |
| SetStatusDialogComponent | functional-decisions.md §Status Lifecycle | Done | Dialog for setting workflow status with notes |
| AddHoldDialogComponent | functional-decisions.md §Status Lifecycle | Done | Dialog for adding holds with notes |

### Asset / Equipment Registry

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Asset CRUD | proposal.md §4.13 | Done | Create, update, soft-delete with ConfirmDialog |
| Maintenance card linking | proposal.md §4.13 | Done | CreateMaintenanceJob handler, MaintenanceJobId FK on schedule, auto-creates kanban job |
| Scheduled maintenance rules | proposal.md §4.13 | Done | MaintenanceSchedule + MaintenanceLog entities, CRUD + LogMaintenance handlers, auto-calculated NextDueAt |
| Machine hours tracking | proposal.md §4.13 | Done | CurrentHours on Asset entity, PATCH /api/v1/assets/{id}/hours endpoint, Angular service method |
| Downtime logging | proposal.md §4.13 | Done | DowntimeLog entity, CRUD handlers with FluentValidation, 3 controller endpoints, Angular models + service |
| Tool-specific asset fields | functional-decisions.md §Tool Registry | Done | CavityCount, ToolLifeExpectancy, CurrentShotCount, IsCustomerOwned, SourceJobId, SourcePartId on Tooling assets. Part.ToolingAssetId FK replaces free-text MoldToolRef |
| Overdue maintenance notifications | proposal.md §4.13 | Done | OverdueMaintenanceJob (Hangfire daily 2AM UTC): queries overdue schedules, notifies Admin/Manager users via SignalR, deduplicates per overdue period |

### Time Tracking

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Start/stop timer | proposal.md §4.14 | Done | TimerHub + ClockEvent |
| Manual time entry | proposal.md §4.14 | Done | Create, update, soft-delete with ConfirmDialog |
| Accounting sync (Time Activities) | proposal.md §4.14 | Done | StopTimer handler uses IAccountingProviderFactory for time activity sync |
| Same-day edit lock | proposal.md §4.14 | Done | Backend: previous-day check in update/delete handlers. Frontend: lock icon + disabled delete for past entries |
| Overlapping timer block | proposal.md §4.14 | Done | StartTimerHandler checks GetActiveTimerAsync, throws if timer already running |
| Pay period awareness | proposal.md §4.14 | Done | GetCurrentPayPeriod + UpdatePayPeriodSettings, supports weekly/biweekly/semimonthly/monthly |

### Employee Records

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Employee data from accounting | proposal.md §4.15 | Done | GetEmployeesAsync/GetEmployeeAsync on IAccountingService, GET /accounting/employees endpoint, Angular AccountingService.loadEmployees() |
| Signed documents / certifications | proposal.md §4.15 | Done | FileAttachment with DocumentType + ExpirationDate fields, GetEmployeeDocuments handler |

### Customer Returns

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Return button on completed jobs | proposal.md §4.16 | Done | CustomerReturn entity with RMA workflow (Received → Inspection → Rework → Resolved → Closed). Angular `/customer-returns` route with list + detail panel + resolve/close workflow. |
| Reason capture + auto-linked rework card | proposal.md §4.16 | Done | CreateReworkJob flag auto-creates Job + JobLink. 6 endpoints on CustomerReturnsController. `CustomerReturnDialogComponent` with EntityPicker for customer + job. |

### Guided Training System

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| First-login tour | proposal.md §4.17 | Done | TourService + driver.js, kanban + dashboard tour definitions |
| Per-feature walkthroughs | proposal.md §4.17 | Done | HelpTourService with 9 tour definitions (kanban, dashboard, parts, inventory, expenses, time-tracking, reports, admin, planning). All registered in AppComponent. |
| Help icon per page | proposal.md §4.17 | Done | PageHeader/PageLayout support helpTourId input with ? icon button |
| Tour coverage audit (CI) | proposal.md §4.17 | Done | `npm run audit:tours` script scans features for TourService/HelpTourService references |
| Admin training dashboard | proposal.md §4.17 | Done | TrainingDashboardComponent: DataTable with user progress, completion bars, per-device localStorage tracking |
| Employee Training LMS | proposal.md §4.17 | Done | Full LMS: 20 seeded modules (Article/Video/Walkthrough/QuickRef/Quiz), training paths, per-user progress tracking, `/training` library with search/filter, module detail pages with type-specific renderers, quiz scoring, My Learning + Paths tabs, admin CRUD panel |

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
| Accounting quantity sync | proposal.md §4.19 | Done | UpdateInventoryQuantityAsync on IAccountingService (QB uses InventoryAdjustment), CreatePart handler syncs via provider factory |
| Low-stock alerts | proposal.md §4.19 | Done | MinStockThreshold/ReorderPoint on Part, GetLowStockAlerts query endpoint |
| Inventory reservation | proposal.md §4.19 | Done | Reservation entity, soft reservation (ReservedQuantity on BinContent), auto-reserve on BOM explosion, manual release, on-hand vs available in views |

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
| Carrier APIs (direct) | proposal.md §4.21 | Partial | MockShippingService in place. Direct carrier integrations (UPS, FedEx, USPS, DHL) not yet implemented. Address validation split to IAddressValidationService (USPS Web Tools). Handlers: GetShippingRates, CreateShippingLabel, GetShipmentTracking. Angular: ShippingRatesDialog + TrackingTimeline components |
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
| Job disposition | functional-decisions.md §Job Disposition | Done | Disposition step at job completion (ShipToCustomer, AddToInventory, CapitalizeAsAsset, Scrap, HoldForReview). CapitalizeAsAsset auto-creates Tooling asset |
| R&D/Tooling outcome paths | functional-decisions.md §R&D Outcomes | Done | 4 paths: Internal Asset, Customer Deliverable, Customer-Funded Retained, Dead End |
| Tool registry (tooling assets) | functional-decisions.md §Tool Registry | Done | Tooling asset subset with CavityCount, ToolLifeExpectancy, CurrentShotCount, IsCustomerOwned, SourceJobId/SourcePartId |

### Admin Settings & Integration Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| User management | proposal.md §4.23 | Done | CRUD, role assignment |
| Track type management | proposal.md §4.23 | Done | Full CRUD with stage management dialog |
| Reference data management | proposal.md §4.23 | Done | Admin tab |
| Accounting setup wizard | proposal.md §4.23 | Done | IntegrationsPanelComponent: provider list, active provider selection, QB OAuth connect/disconnect, sync status, coming-soon badges for Xero/FreshBooks/Sage |
| Branding (logo, colors) | proposal.md §4.23 | Done | Brand colors + logo upload (MinIO qb-engineer-branding bucket), admin UI with upload/remove, header displays logo |
| System settings UI | proposal.md §4.23 | Done | Admin Settings tab with 10 configurable settings, upsert API |
| Company profile | Plan: Company Profile | Done | System settings key-value (company.name/phone/email/ein/website), GET/PATCH admin endpoints, profile form in admin settings tab |
| Company locations | Plan: Company Locations | Done | CompanyLocation entity + CRUD controller (6 endpoints), admin locations DataTable with create/edit/delete/set-default, CompanyLocationDialogComponent with AddressFormComponent |
| Per-employee work location | Plan: Work Location | Done | WorkLocationId FK on ApplicationUser, PATCH endpoint, work location select in user edit dialog, location options computed from active locations |
| Setup wizard — company details | Plan: Setup Wizard | Done | 2-step setup wizard: Step 1 admin account (existing), Step 2 company details + primary location. AddressFormComponent CVA. Single API call on final submit |
| Third-party integrations panel | proposal.md §4.23 | Done | IntegrationsPanelComponent scaffold with 5 integrations (QB, MinIO, SMTP, Shipping, Ollama), status indicators, grid layout |

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
| Production Worker simplified view | roles-auth.md §Worker | Done | /worker route: touch-friendly task list with overdue highlighting, sorted (overdue → due date → priority), progress bars, priority chips |
| Shop Floor Display (no-login) | roles-auth.md §Shop Floor | Done | /display/shop-floor route, AllowAnonymous API, worker presence + active jobs |
| Time Clock Kiosk (scan-based) | roles-auth.md §Shop Floor | Done | Touch-first clock UI with 3-phase barcode auth (scan → PIN → clock), auto-timeout, live clock display |
| **Tiered Auth: RFID/NFC + PIN** | roles-auth.md §Tiered Auth | Done | UserScanIdentifier entity (nfc/rfid/barcode types), NFC kiosk-login endpoint (POST /auth/nfc-login), admin CRUD for scan identifiers. ScannerService + BarcodeScanInputComponent for hardware input. |
| **Tiered Auth: Barcode + PIN** | roles-auth.md §Tiered Auth | Done | Tier 2 — POST /auth/kiosk-login (barcode + PIN → 8hr JWT), EmployeeBarcode field on user, PBKDF2 PIN hash, admin PIN reset |
| **PIN management (hash, reset)** | roles-auth.md §PIN Management | Done | POST /auth/set-pin (PBKDF2 100K iterations, SHA256, 16-byte salt), POST /admin/users/{id}/reset-pin, FluentValidation (4-8 digits) |
| **Enterprise SSO (Google)** | roles-auth.md §Enterprise SSO | Done | OAuth 2.0 challenge/callback, SsoExternalCookie scheme, GoogleId on ApplicationUser |
| **Enterprise SSO (Microsoft)** | roles-auth.md §Enterprise SSO | Done | Azure AD / Entra ID via MicrosoftAccount auth, MicrosoftId on ApplicationUser |
| **Enterprise SSO (Generic OIDC)** | roles-auth.md §Enterprise SSO | Done | Configurable Authority/ClientId/ClientSecret, OidcSubjectId + OidcProvider on ApplicationUser |
| **SSO identity linking** | roles-auth.md §Enterprise SSO | Done | Auto-link by email on first SSO login, manual link/unlink endpoints, login UI with SSO buttons |
| **Employee compliance visibility** | Plan §Phase 6 | Done | Admin users table shows compliance status (completed/total items, missing items list, canBeAssignedJobs). Batch-loaded EmployeeProfiles in GetAdminUsers handler. |
| **Job assignment blocking** | Plan §Phase 6 | Done | AssigneeComplianceCheck static helper enforces 4 blocking items (W-4, I-9, State Withholding, Emergency Contact) on CreateJob, UpdateJob, BulkAssignJob. Frontend warns in assignee dropdown. |

---

## DocuSeal Document Signing & Compliance Form Registry

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| **Core enums** | Plan §Phase 1 | Done | ComplianceFormType, ComplianceSubmissionStatus, IdentityDocumentType |
| **ComplianceFormTemplate entity** | Plan §Phase 1 | Done | 16 fields, EF config, seed data (6 templates) |
| **ComplianceFormSubmission entity** | Plan §Phase 1 | Done | TemplateId, UserId, DocuSealSubmissionId, Status, SignedAt, SignedPdfFileId |
| **IdentityDocument entity** | Plan §Phase 1 | Done | UserId, DocumentType, FileAttachmentId, VerifiedAt/By, ExpiresAt, Notes |
| **FileAttachment Sensitivity** | Plan §Phase 1 | Done | Added Sensitivity property for PII flagging |
| **IDocumentSigningService** | Plan §Phase 1 | Done | Interface + DocuSealSigningService + MockDocumentSigningService |
| **DocuSealOptions** | Plan §Phase 1 | Done | BaseUrl, ApiKey, TimeoutSeconds, WebhookSecret |
| **ComplianceFormSyncJob** | Plan §Phase 2 | Done | Hangfire weekly job: downloads PDFs, SHA-256 hash comparison, pushes to DocuSeal |
| **ComplianceFormsController** | Plan §Phase 2 | Done | 12 endpoints: template CRUD, sync, submissions, webhook, admin user detail, reminders |
| **IdentityDocumentsController** | Plan §Phase 2 | Done | 5 endpoints: employee CRUD, admin view, verify |
| **18 MediatR handlers** | Plan §Phase 2 | Done | Template CRUD (7), Submissions (4), Identity Docs (5), Admin (2) |
| **Frontend ComplianceFormService** | Plan §Phase 3 | Done | Signal-based service with templates, submissions, identityDocuments |
| **Tax form detail page** | Plan §Phase 3 | Done | Per-form route (/account/tax-forms/:formType), DocuSeal iframe, manual fallback, identity doc upload |
| **Tax forms list refactor** | Plan §Phase 3 | Done | Loads from API instead of hardcoded, links to per-form detail routes |
| **Collapsible sidebar sub-menu** | Plan §Phase 3 | Done | Tax & Compliance parent with dynamic children from templates, expand/collapse |
| **KEY_ROUTE_MAP update** | Plan §Phase 3 | Done | Per-form routes: w4→/account/tax-forms/w4, etc. |
| **Admin compliance tab** | Plan §Phase 4 | Done | ComplianceTemplatesPanelComponent (DataTable CRUD), ComplianceTemplateDialogComponent, UserCompliancePanelComponent |
| **Admin service methods** | Plan §Phase 4 | Done | Template CRUD, sync, getUserComplianceDetail, sendReminder, verifyIdentityDocument |
| **Docker DocuSeal container** | Plan §Phase 5 | Done | 8th container, profiles: [signing], docusealdata volume |
| **nginx DocuSeal proxy** | Plan §Phase 5 | Done | /docuseal/ → qb-engineer-signing:3000 |
| **appsettings DocuSeal** | Plan §Phase 5 | Done | DocuSeal section in appsettings.json + docker-compose env vars |
| **PII MinIO bucket** | Plan §Phase 1 | Done | qb-engineer-pii-docs bucket in MinioOptions |
| **Per-employee state withholding** | Plan §Phase 9 | Done | 3-tier state resolution: WorkLocation.State → default CompanyLocation → company_state setting. No-tax states auto-complete. StateWithholdingInfoModel on responses. |
| **State withholding admin banner** | Plan §Phase 9 | Done | UserCompliancePanelComponent shows state name, category, resolution source |
| **Electronic form definitions** | Plan §Phase 10 | Done | FormDefinitionJson (jsonb) + FormDefinitionRevision on ComplianceFormTemplate. Dynamic form rendering from JSON definition. |
| **Electronic form data** | Plan §Phase 10 | Done | FormDataJson (jsonb) on ComplianceFormSubmission. Save draft + submit endpoints. |
| **Dynamic form definition extraction** | Plan §Phase 10 | Done | Form definitions are dynamically extracted from PDFs via pdf.js (PuppeteerSharp). 3-phase pipeline: IPdfJsExtractorService (raw extraction) → IFormDefinitionParser (smart pattern parser) → IFormDefinitionVerifier (structural checks + AI refinement). PdfPig removed. See `docs/pdf-extraction-pipeline.md`. |
| **State withholding source URLs** | Plan §Phase 10 | Done | StateWithholdingUrls.cs: 37 official PDF download URLs seeded into reference data metadata (sourceUrl). Backfill for existing installs. |
| **pdf.js extraction pipeline** | Plan §Phase 10 | Done | Replaced PdfPig (2,874-line monolith) with pdf.js via PuppeteerSharp. 3 focused services: PdfJsExtractorService (headless Chromium + pdf.js getTextContent/getAnnotations), FormDefinitionParser (pattern-based layout inference), FormDefinitionVerifier (structural checks + Ollama AI refinement, max 3 iterations). Dockerfile changed from Alpine to Debian for Chromium support. |
| **Auto state form definition** | Plan §Phase 10 | Done | GetMyStateFormDefinition handler: 3-tier state resolution → reference data lookup → cache check → PDF download + AcroForm extraction → cache result. StateFormDefinitionCache entity (PK=StateCode). Lazy on first access. Verified: CA DE-4 (13 fields), ID W-4 (22 fields). Frontend fetches via `/compliance-forms/my-state-definition`, renders in ComplianceFormRenderer. |
| **ComplianceFormRendererComponent** | Plan §Phase 10 | Done | Tabbed multi-page form renderer. Tab navigation (prev/next + clickable tabs), per-page model maps, readonly page detection, single FormGroup spanning all pages. Conditional fields, save draft, submit. Compact font sizes matching government documents. |
| **QB Dynamic Forms Library** | Plan §Phase 10 | Done | Full ng-dynamic-forms UI wrapper: 11 control components (input, select, datepicker, textarea, toggle, checkbox, radio, group, signature, heading, paragraph), qbFormControlMapFn, DynamicQbFormControlComponent (ViewContainerRef-based container), DynamicQbFormComponent (root), complianceDefinitionToModels + sectionsToModels adapters, normalizeFormPages utility. Multi-page support via FormPage model. All controls render through QB shared wrappers for automatic design system inheritance. |
| **Admin form definition endpoints** | Plan §Phase 10 | Done | PUT /{id}/form-definition (update), POST /{id}/extract-definition (PDF extraction), auto-extract on document upload. |
| **Visual rendering comparison** | Plan §Phase 10 | Done | After extracting a form definition, PuppeteerSharp navigates to `/__render-form` Angular headless route, screenshots the rendered form, then compares against PDF page screenshots. Two tiers: structural (SkiaSharp block SSIM + content density + region detection) and semantic (Ollama vision, optional). Results stored on FormDefinitionVersion (visual_comparison_json, visual_similarity_score, visual_comparison_passed). Fire-and-forget from extraction pipeline. API: POST `/{id}/compare-visual`, GET `/versions/{id}/comparison`. Docker API container memory increased to 2GB for dual Chromium processes. |

---

## Payroll Visibility & Office Manager Access

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| **PayrollDocumentSource enum** | Plan §Phase 1 | Done | Accounting, Manual |
| **PayStubDeductionCategory enum** | Plan §Phase 1 | Done | 15 categories (FederalTax through Other) |
| **TaxDocumentType enum** | Plan §Phase 1 | Done | W2, W2c, Misc1099, Nec1099, Other |
| **PayStub entity + config** | Plan §Phase 1 | Done | BaseAuditableEntity, FK to FileAttachment (SetNull), index on UserId, unique filtered ExternalId |
| **PayStubDeduction entity + config** | Plan §Phase 1 | Done | BaseEntity, FK to PayStub (Cascade), decimal(18,2) |
| **TaxDocument entity + config** | Plan §Phase 1 | Done | BaseAuditableEntity, composite index (UserId, TaxYear), unique filtered ExternalId |
| **DbContext DbSets** | Plan §Phase 1 | Done | PayStubs, PayStubDeductions, TaxDocuments |
| **Accounting models** | Plan §Phase 1 | Done | AccountingPayStub, AccountingPayStubDeduction, AccountingTaxDocument |
| **Response/Request models** | Plan §Phase 1 | Done | PayStubResponseModel, PayStubDeductionResponseModel, TaxDocumentResponseModel, Upload request models |
| **IAccountingService payroll methods** | Plan §Phase 2 | Done | GetPayStubsAsync, GetPayStubPdfAsync, GetTaxDocumentsAsync, GetTaxDocumentPdfAsync |
| **MockAccountingService payroll** | Plan §Phase 2 | Done | 3 bi-weekly pay stubs, 1 W-2 for 2025 |
| **QuickBooksAccountingService stubs** | Plan §Phase 2 | Done | Log warning + return empty (QB Payroll API = future) |
| **PayrollController (11 endpoints)** | Plan §Phase 3 | Done | Employee self-service + Admin/OM CRUD, sync |
| **MediatR handlers (11)** | Plan §Phase 3 | Done | GetMyPayStubs, GetPayStubPdf, GetMyTaxDocuments, GetTaxDocumentPdf, GetUserPayStubs/TaxDocuments, Upload/Delete, SyncPayrollData |
| **Role broadening (compliance/identity)** | Plan §Phase 4 | Done | ComplianceFormsController + IdentityDocumentsController admin endpoints → Admin,Manager,OfficeManager |
| **Angular payroll models** | Plan §Phase 5 | Done | PayStub, PayStubDeduction, TaxDocument, PayrollDocumentSource, TaxDocumentType |
| **PayrollService (Angular)** | Plan §Phase 5 | Done | Signal-based, employee + admin methods |
| **Account Pay Stubs page** | Plan §Phase 5 | Done | DataTable, period/amount display, PDF download, source chip |
| **Account Tax Documents page** | Plan §Phase 5 | Done | DataTable, type label mapping, PDF download |
| **Account routes + sidebar** | Plan §Phase 5 | Done | /account/pay-stubs, /account/tax-documents, sidebar nav items |
| **Admin route guard broadened** | Plan §Phase 6 | Done | roleGuard('Admin', 'Manager', 'OfficeManager') |
| **Admin tab gating** | Plan §Phase 6 | Done | isAdmin() computed, non-admins see only Compliance tab, default to compliance |
| **Sidebar admin item broadened** | Plan §Phase 6 | Done | Admin nav visible to Manager, OfficeManager |
| **UserCompliancePanelComponent + payroll** | Plan §Phase 6 | Done | Pay stubs + tax documents tables, upload forms, delete for manual, PDF download |

---

## Accounting Integration (qb-integration.md)

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| IAccountingService interface | qb-integration.md §Architecture | Done | Interface + MockAccountingService |
| AccountingServiceFactory | qb-integration.md §Architecture | Done | IAccountingProviderFactory with runtime provider resolution from SystemSettings. Supports multiple providers (QB, Xero, FreshBooks, Sage). All sync jobs + handlers use factory. |
| QB Online OAuth 2.0 | qb-integration.md §QB Provider | Done | OAuth flow, token exchange, encrypted storage (Data Protection API), admin UI connect/disconnect/test |
| Standalone mode (no provider) | qb-integration.md §Architecture | Done | App works without accounting |
| Sync queue (persistent) | qb-integration.md §Sync Queue | Done | ISyncQueueRepository, SyncQueueRepository, SyncQueueProcessorJob Hangfire job every 2 min |
| Accounting read cache | qb-integration.md §Cache | Done | AccountingCacheSyncJob every 6 hours, stores last_sync and cached_customers in SystemSettings |
| Orphan detection | qb-integration.md §Orphan | Done | OrphanDetectionJob daily at 3 AM, logs warnings for unlinked customers |
| Stage-to-document mapping | qb-integration.md §Stage Mapping | Done | MoveJobStage handler creates AccountingDocument and enqueues to sync queue when target stage has AccountingDocumentType |
| Customer sync (bidirectional) | qb-integration.md §Customer Sync | Done | CustomerSyncJob every 4 hours, QB→local customer sync with create/update |
| Accounting mode gating (Angular) | qb-integration.md §Standalone Mode | Done | AccountingService.isStandalone() loaded on app init, invoices + payments show "managed by provider" banner when not standalone |
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
| ngx-translate integration | Done | @ngx-translate/core v17 + http-loader, provideTranslateService in app.config |
| Spanish language pack | Done | Full es.json with all nav, common, auth, dashboard, jobs, parts, errors keys |
| Per-user language preference | Done | LanguageService with localStorage persistence, document.lang attribute |

---

## Testing (coding-standards.md, libraries.md)

| Area | Status | Notes |
|------|--------|-------|
| Angular unit tests (Vitest) | Done | 23 spec files (330 tests): AuthService, ThemeService, FormValidationService, LoadingService, TerminologyPipe, AppComponent, SnackbarService, NotificationService, CacheService, BroadcastService, OfflineQueueService, StatusTrackingService, InventoryService, AiService, ShipmentService, KanbanService, PartsService, ExpensesService, LeadsService, CustomerService, AdminService, TimeTrackingService, AssetsService |
| .NET unit tests (xUnit) | Done | 27 test classes (214 tests): CreateJob, UpdateJob, MoveJobStage, CreatePart, StartTimer, StopTimer, CreateExpense, CreateCustomer, AdjustStock, CreateInvoiceFromJob, CreateLead, CreateVendor, CreateQuote, DisposeJob, CreateReservation, ReleaseReservation, ExplodeJobBom, SetWorkflowStatus, UploadFileChunk, CreatePayment, CreateInvoice, PlaceBinContent, CreateAsset, CreateMaintenanceSchedule, ConvertQuoteToOrder, ActivatePlanningCycle, CreateCustomerReturn |
| Integration tests | Done | 40 tests via WebApplicationFactory: health, auth, protected endpoints, POST validation (InMemory DB + Hangfire MemoryStorage) |
| E2E tests (Cypress) | Done | 18 spec files (login, dashboard, kanban, accessibility, parts, expenses, admin, inventory, shipments, quality, reports-expanded, calendar, leads, assets, time-tracking, backlog, vendors, planning), custom cy.login() command |
| axe-core accessibility tests | Done | 10 page tests (dashboard, kanban, login, parts, inventory, admin, reports, expenses, leads, time-tracking) — critical + serious violations |

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
| @ngx-translate/core | Yes | Yes (LanguageService, en.json + es.json) |
| @ngx-dropzone | No | Not Started (custom FileUploadZone built) |
| ngx-extended-pdf-viewer | Yes | Yes (PdfViewerComponent wrapper) |
| ngx-quill | Yes | Yes (RichTextEditorComponent CVA wrapper) |
| angularx-qrcode | Yes | Yes (QrCodeComponent wrapper) |
| bwip-js | Yes | Yes (LabelPrintService) |
| papaparse | Yes | Yes (DataTable CSV export) |
| @ngneat/hotkeys | N/A | Done (custom KeyboardShortcutsService instead — no dependency needed) |
| date-fns | Yes | Yes |
| @ngx-gallery/lightbox | No | Done | Custom LightboxGalleryComponent (no library dependency) |
| ngx-markdown | Yes | Yes (MarkdownViewComponent wrapper) |
| vitest | Yes | Yes (11 spec files) |
| cypress | Yes | Yes (8 E2E specs + axe-core a11y) |

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
| CsvHelper | Yes | Yes (CsvExportService) |
| QuestPDF | Yes | Yes (Invoice PDF, Packing Slip PDF) |
| ImageSharp | Yes | Yes (ImageService: thumbnails, dimensions, JPEG conversion) |
| Xabaril Health Checks | Done | PostgreSQL + Hangfire + MinIO + SignalR, detailed JSON response |
| Data Protection API (EF) | Yes | Yes (TokenEncryptionService, keys persisted to Postgres) |
| EFCore.BulkExtensions.MIT | Yes | Yes (BulkSoftDeleteAsync extension method) |
| Bogus | Yes | Yes (test data generation) |

---

## Overall Summary

| Category | Done | Partial | Not Started |
|----------|------|---------|-------------|
| Core Entities & Schema | 24/24 | — | — |
| API Controllers | 27/27 | — | — |
| MediatR Handlers | 106+ | — | — |
| Shared UI Components | 31/31 | — | — |
| Feature UIs | 20/20 | — | — |
| Auth & Security | 10 | — | — |
| **Order Management** | 12 | — | — |
| **Standalone Financial ⚡** | 18 | — | — |
| **Pricing & Quoting** | 8 | — | — |
| Accounting Integration | 9 | — | — |
| Planning Cycles | 6 | — | — |
| Production Traceability | 5 | — | — |
| Reporting | 27 | — | — |
| Notifications | 8 | — | — |
| Chat | 4 | — | — |
| Search | 1 | — | — |
| i18n | 6 | — | — |
| Testing | 5 | — | — |
| Background Jobs | 1 | — | — |
| Backup | 1 | — | — |
| AI Module | 1 | — | — |

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

---

## Batch 18 Changelog — Integration Tests, Rich Text, CSV Export & Accessibility (2026-03-14)

### .NET Integration Tests (24 tests)
- `TestWebApplicationFactory`: InMemory EF Core, Hangfire MemoryStorage, MockIntegrations=true, shared collection fixture
- `HealthEndpointTests` (2): health endpoint returns 200 + JSON
- `AuthEndpointTests` (4): login rejects invalid creds, /auth/me requires auth, public endpoints accessible
- `ApiEndpointTests` (18): 14 data endpoints + 4 admin endpoints return 401 without auth
- Added `InternalsVisibleTo` on API project, `public partial class Program` for WebApplicationFactory

### ngx-quill Rich Text Editor
- Installed `ngx-quill` + `quill`, added snow theme CSS to angular.json
- `RichTextEditorComponent` CVA wrapper at `shared/components/rich-text-editor/`
- Toolbar: bold, italic, underline, ordered/bullet lists, link, clean
- Themed with design system variables (border, font, colors)

### CsvHelper Server-Side Export
- Installed `CsvHelper` 33.1.0
- `ICsvExportService` interface in Core, `CsvExportService` implementation in API
- Methods: `Export<T>()` (byte[]) and `ExportToStream<T>()` (Stream)
- Registered as singleton in Program.cs

### axe-core Accessibility Tests
- Installed `cypress-axe` + `axe-core`
- 5 accessibility tests: dashboard, kanban, login, parts, inventory
- Filters to critical + serious impact violations only

---

## Batch 19 Changelog — i18n, PDF Viewer, Image Processing & E2E Expansion (2026-03-14)

### i18n Infrastructure
- Installed `@ngx-translate/core` v17 + `@ngx-translate/http-loader` v17
- English (`en.json`) and Spanish (`es.json`) translation files with nav, common, auth, dashboard, jobs, parts, errors keys
- `LanguageService` with signal-based state, localStorage persistence, `document.documentElement.lang` attribute
- `provideTranslateService` + `provideTranslateHttpLoader` configured in app.config.ts
- Initialized in AppComponent — TranslatePipe available for incremental adoption

### ngx-extended-pdf-viewer
- Installed `ngx-extended-pdf-viewer` with asset copy in angular.json
- Shared `PdfViewerComponent` wrapper at `shared/components/pdf-viewer/`
- Inputs: `src`, `height`, `showToolbar`, `showSidebarButton`. Print/download/zoom/paging enabled.

### ImageSharp Image Processing
- Installed `SixLabors.ImageSharp` v3.1.12
- `IImageService` interface in Core: `GenerateThumbnailAsync`, `GetDimensionsAsync`, `ConvertToJpegAsync`
- `ImageService` implementation in API using ImageSharp resize + JPEG encoding
- Registered as singleton in Program.cs

### Expanded Cypress E2E (4 new spec files)
- `parts.cy.ts` (4 tests): page display, data table, search, create button
- `expenses.cy.ts` (3 tests): page display, table/empty state, create button
- `admin.cy.ts` (3 tests): page display, tabs, user management table
- `inventory.cy.ts` (3 tests): page display, tabs, data table

---

## Batch 20 Changelog — Data Protection, Bulk Extensions, Tour Audit & Integrations Panel (2026-03-14)

### ASP.NET Data Protection API
- Installed `Microsoft.AspNetCore.DataProtection.EntityFrameworkCore`
- `AppDbContext` implements `IDataProtectionKeyContext` — keys persisted to PostgreSQL
- `ITokenEncryptionService` interface + `TokenEncryptionService` implementation using `IDataProtector`
- Purpose string `QbEngineer.OAuthTokens` for OAuth token encryption
- Configured in Program.cs with `PersistKeysToDbContext` + `SetApplicationName`

### EFCore.BulkExtensions
- Installed `EFCore.BulkExtensions.MIT` on data project
- `BulkOperationExtensions.BulkSoftDeleteAsync<T>()` — sets DeletedAt/DeletedBy on all entities and calls BulkUpdateAsync

### Tour Coverage Audit
- `scripts/audit-tours.ts` — scans features for TourService/HelpTourService references
- `npm run audit:tours` script via tsx
- Reports features with/without tours and coverage percentage

### Third-Party Integrations Panel
- `IntegrationsPanelComponent` scaffold at `admin/components/integrations-panel/`
- 5 pre-configured integrations: QuickBooks, MinIO, SMTP, Shipping, Ollama
- Status indicators (connected/disconnected/not_configured) with icons
- Grid layout with BEM naming and design system variables

---

## Batch 21 Changelog — Manufacturing Core: Disposition, Tooling, BOM, Status Tracking, AI RAG, Carrier APIs (2026-03-15)

### Job Disposition (MES Standard)
- `JobDisposition` enum: ShipToCustomer, AddToInventory, CapitalizeAsAsset, Scrap, HoldForReview
- `DisposeJob` MediatR handler: validates job not already disposed, auto-creates Tooling asset on CapitalizeAsAsset
- Job entity extended: `Disposition`, `DispositionNotes`, `DispositionAt` fields
- Angular: `DisposeJobDialogComponent` with disposition type selection + notes, icon indicator on kanban cards
- Job detail panel: disposition section with status display + Dispose action button

### Tool-Specific Asset Fields (Tool Registry)
- Asset entity extended: `IsCustomerOwned`, `CavityCount`, `ToolLifeExpectancy`, `CurrentShotCount`, `SourceJobId`, `SourcePartId`
- Part entity extended: `ToolingAssetId` FK for linked tooling asset
- Angular: conditional tooling section in asset detail/edit, entity picker for tooling asset on parts
- Response models updated with tooling fields + source names

### Part Status Prototype (NPI Gate)
- `PartStatus` enum: added `Prototype` value (Draft → Prototype → Active → Obsolete)
- Angular: Prototype status in filter options with info-colored chip

### BOM-Driven Work Breakdown
- `ProcessStep` entity: StepNumber, Title, Instructions, WorkCenterId, EstimatedMinutes, IsQcCheckpoint, QcCriteria
- `BOMSourceType`: added `Stock` value alongside Make/Buy
- `BOMEntry`: added `LeadTimeDays` field
- Job entity: added `PartId`, `ParentJobId` (self-referencing FK), `ChildJobs` navigation
- 4 ProcessStep CRUD handlers on PartsController
- `ExplodeJobBom` handler: walks BOM, creates child jobs for Make entries with bidirectional JobLinks
- `GetChildJobs` handler: returns child job tree
- Angular: `ProcessPlanComponent` (ordered step cards with QC indicators), `ProcessStepDialogComponent`

### Status Lifecycle Tracking (Polymorphic)
- `StatusEntry` entity: EntityType/EntityId polymorphism, StatusCode (reference_data driven), Category (workflow/hold)
- Workflow statuses: one active at a time with automatic EndedAt on transition
- Hold statuses: multiple parallel, manually released
- `StatusTrackingController`: 5 endpoints (history, active, set-workflow, add-hold, release-hold)
- 28 seeded reference_data entries for status codes across Jobs, Parts, Assets, POs, SOs, Quotes, Shipments
- Angular: `StatusTimelineComponent`, `SetStatusDialogComponent`, `AddHoldDialogComponent`, `StatusTrackingService`
- Integrated into job detail panel

### AI RAG Pipeline (pgvector)
- `DocumentEmbedding` entity with `Pgvector.Vector` type for vector(384) column
- `IEmbeddingRepository` + `EmbeddingRepository` with cosine distance search
- `RagSearch` handler: embed query → search similar → optionally generate answer via Ollama
- `IndexDocument` handler: extract text fields → chunk → embed → upsert
- `BulkIndexDocuments` handler: batch indexing for multiple entities
- `DocumentIndexJob`: Hangfire recurring every 30 min, indexes recent entities
- `AiHelpChat` handler enhanced with RAG context injection
- AiController: added search, index, bulk-index endpoints
- Angular: RAG results column in header AI search, AiHelpPanel with RAG-backed chat

### Carrier Shipping
- `IShippingService` interface with MockShippingService (direct carrier integrations TBD)
- Address validation decoupled: `IAddressValidationService` with `UspsAddressValidationService` (USPS Web Tools, free) + `MockAddressValidationService`
- 3 shipping handlers: GetShippingRates, CreateShippingLabel, GetShipmentTracking
- ShipmentsController endpoints
- Angular: `ShippingRatesDialogComponent` (rate comparison table), `TrackingTimelineComponent` (shipment event timeline)

### Mapper & Build Fixes
- Updated JobMapper, PartMapper, AssetMapper for new positional record parameters
- Fixed pgvector type mapping: `float[]` → `Pgvector.Vector` across entity, repository, and handlers
- Added Pgvector NuGet to core project

---

## Batch 22 Changelog — Hold Indicators, Inventory Reservation, Chunked Upload (2026-03-15)

### Hold Indicators on Kanban Cards
- `ActiveHolds` (List<string>) added to `JobListResponseModel`
- JobRepository queries StatusEntry table for active holds (EntityType=Job, Category=hold, EndedAt=null)
- Kanban card: `pause_circle` icon in header when holds active, `matTooltip` lists hold names
- BEM class `.job-card__hold-indicator` with `--warning` color

### Inventory Reservation System
- `Reservation` entity (BaseAuditableEntity): PartId, BinContentId, JobId?, SalesOrderLineId?, Quantity, Notes
- `ReservationConfiguration`: Fluent API with FK indexes
- `ReservedQuantity` field on BinContent entity
- 3 handlers: CreateReservation (validates available qty), ReleaseReservation (soft-delete + decrement), GetReservations (filterable)
- ExplodeJobBom: auto-reserves Stock items from available bin inventory, reports shortfalls
- InventoryController: 3 new reservation endpoints
- Angular: Reservations tab in inventory UI with DataTable, reserve dialog, release buttons
- Stock expand rows show On Hand / Reserved / Available columns, warning color when reserved > 0
- `BinStockResponseModel` extended with ReservedQuantity + AvailableQuantity

### Chunked File Upload
- `UploadFileChunk` handler: writes chunks to temp dir (`/tmp/qb-engineer-uploads/{uploadId}/`), concatenates on final chunk, uploads to MinIO, cleans up
- `ChunkedUploadResponseModel`: UploadId, ChunkIndex, IsComplete, FileAttachment?
- FilesController: `POST {entityType}/{entityId}/files/chunked` endpoint
- FileUploadZoneComponent: auto-detects large files (> chunkSizeMb input, default 5MB), slices with File.slice(), sequential chunk upload, progress as completedChunks/totalChunks
- Existing single-upload path unchanged for small files

---

## Batch 23 Changelog — Phase Polish (2026-03-15)

### Planning Day Tour
- New `PLANNING_TOUR` definition (5 steps: welcome, backlog panel, commit button, cycle board, lifecycle actions)
- Registered in AppComponent alongside 8 existing tours (9 total)
- Planning page header gains `helpTourId="planning"` for help icon

### Overdue Maintenance Notifications
- `OverdueMaintenanceJob` (Hangfire daily 2AM UTC): queries overdue MaintenanceSchedules, notifies Admin/Manager users via CreateNotificationCommand + SignalR
- Deduplication: skips schedules that already have a `maintenance-overdue` notification created after the schedule's NextDueAt
- Per-user try/catch prevents one failure from blocking others

### Worker View Polish
- Overdue task highlighting: red border + warning icon + "OVERDUE" label on overdue tasks
- Smart sorting: overdue first, then by due date ascending, then by priority (Critical → Low)
- `sortedTasks` computed signal replaces raw `tasks()` in template

### CI/CD Pipeline (GitHub Actions)
- `.github/workflows/ci.yml`: 5-job pipeline
- Parallel build (Angular + .NET) → Parallel test (Vitest + xUnit) → Docker image build (main push only)
- Node 22, .NET 9, actions v4

### Docker Production Optimization
- Alpine base images for API (`sdk:9.0-alpine`, `aspnet:9.0-alpine`) and UI (already Alpine)
- Non-root user in API container (`appuser`)
- Health checks on API (`/health`) and UI (`/`) in both Dockerfiles and docker-compose
- Resource limits: API 512M, UI 256M, DB 1G
- `UseAppHost=false` for smaller publish output
- `npm ci --ignore-scripts` for UI build security

---

## Batch 24 Changelog — Accessibility + Auth Completion (2026-03-15)

### RFID/NFC Tier 1 Auth (Software Layer)
- `UserScanIdentifier` entity: maps scan hardware IDs (nfc/rfid/barcode) to users, unique composite index, soft-delete
- `NfcKioskLogin` handler: `POST /auth/nfc-login` — looks up scan identifier, verifies PIN, returns 8-hour JWT with `authTier: "nfc"` claim
- Admin scan identifier management: GET/POST/DELETE `/admin/users/{userId}/scan-identifiers`
- `AddScanIdentifierRequestModel` + `ScanIdentifierResponseModel` in Core/Models
- AppDbContext: `DbSet<UserScanIdentifier>`

### Accessibility (axe-core)
- Expanded axe-core Cypress tests from 5 to 10 pages (added admin, reports, expenses, leads, time-tracking)
- Added `npm run test:a11y` script for targeted accessibility testing
- CI pipeline notes E2E + a11y tests run against Docker Compose stack

## Batch 25 Changelog — Test Expansion (2026-03-15)

### Angular Unit Tests (8 new spec files, 65 tests)
- KanbanService, PartsService, ExpensesService, LeadsService, CustomerService, AdminService, TimeTrackingService, AssetsService
- All use HttpClientTestingModule with request assertion pattern
- Total: 23 spec files, 330 tests (up from 15/195)

### .NET Unit Tests (8 new test classes, 36 tests)
- CreatePayment, CreateInvoice, PlaceBinContent, CreateAsset, CreateMaintenanceSchedule, ConvertQuoteToOrder, ActivatePlanningCycle, CreateCustomerReturn
- All use Bogus for data generation, NSubstitute for mocking
- Total: 27 test classes, 214 tests (up from 19/142)

### Integration Tests (16 new tests)
- Expanded ApiEndpointTests: 12 GET 401 tests (protected endpoints), 2 POST 400 validation tests, 2 anonymous 200 tests (health, login)
- Total: 40 integration tests (up from 24)

### Cypress E2E (6 new spec files, 28 tests)
- Leads (5), Assets (5), Time Tracking (5), Backlog (4), Vendors (4), Planning (5)
- All use cy.login() custom command, standard navigation + assertion patterns
- Total: 18 spec files (up from 12)

---

## Batch 22 Changelog — Domain-Specific AI Assistants (2026-03-12)

### AiAssistant Entity + CRUD
- `AiAssistant` entity (BaseAuditableEntity): Name, Description, Icon, Color, Category, SystemPrompt, AllowedEntityTypes (JSON), StarterQuestions (JSON), IsActive, IsBuiltIn, SortOrder, Temperature, MaxContextChunks
- `AiAssistantConfiguration`: max lengths, composite index on (IsActive, SortOrder)
- `AppDbContext`: added DbSet<AiAssistant>
- Seed data: 4 built-in assistants (General, HR, Procurement, Sales & Marketing) with domain-specific system prompts, entity type filters, and starter questions
- 6 MediatR handlers: GetAiAssistants (active), GetAllAiAssistants (admin), GetAiAssistant, CreateAiAssistant (FluentValidation), UpdateAiAssistant (protects IsBuiltIn), DeleteAiAssistant (409 on built-in)
- `AiAssistantsController`: GET/POST/PUT/DELETE with role-based auth (admin for mutations)
- Response/request models in `qb-engineer.core/Models/`

### AssistantChat Handler
- Extended `IAiService` with `GenerateTextAsync(prompt, systemPrompt, temperature, ct)` overload
- Extended `IEmbeddingRepository` with `SearchSimilarAsync` overload accepting `List<string>? entityTypeFilters`
- `OllamaAiService`: passes `system` field and `options.temperature` to Ollama API
- `MockAiService`: matching overload (ignores system prompt/temperature)
- `EmbeddingRepository`: multi-entity-type filter via `.Where(e => entityTypeFilters.Contains(e.EntityType))`
- `AssistantChat` handler: loads assistant, applies domain-scoped RAG filters, injects conversation history, calls LLM with per-assistant system prompt + temperature
- Endpoint: `POST /api/v1/ai/assistants/{assistantId}/chat` on `AiController`

### Admin UI — AI Assistants Tab
- 8th admin tab: "AI Assistants" with smart_toy icon
- `AiAssistantsPanelComponent`: DataTable with icon, name, category, entity filter count, active status, edit/delete actions
- `AiAssistantDialogComponent`: MatDialog form with Name, Category, Description, Icon (with live Material Icons preview), Color picker, System Prompt (10-row textarea), Entity Type Filters (multi-select), Starter Questions (dynamic add/remove list), Active toggle, Sort Order, collapsible Advanced section (Temperature, Max Context Chunks)
- Delete blocked for built-in assistants (button hidden)

### AI Chat Page (`/ai`)
- New feature route: `/ai/:assistantId` with redirect from `/ai` → `/ai/general`
- `AiComponent`: left sidebar (assistant list as cards with icon/color/name/description), right chat panel with header, message history, starter questions on empty state, typing indicator, clear chat
- In-memory conversation history per assistant (`Map<number, ChatMessage[]>`)
- Starter questions clickable to send immediately
- Enter to send, Shift+Enter for newline
- Mobile responsive: sidebar collapses to horizontal scroll
- Sidebar nav: "AI" entry with smart_toy icon in Management group
- Extended `AiService`: `getAssistants()` and `assistantChat()` methods

---

## Batch 26 Changelog — Admin Onboarding E2E + SubmitFormData Bug Fix (2026-03-20)

### Playwright E2E: Admin Onboarding (`admin-onboarding.spec.ts`)
- Full 9-step onboarding flow: Profile, Contact, Emergency Contact, W-4, I-9, State Withholding, Workers' Comp, Employee Handbook, Direct Deposit
- Cleaned up `page.evaluate()` debug diagnostic blocks from I-9 and State Withholding steps
- Fixed `acknowledgeForm()` to be idempotent: detects already-complete acknowledgment forms via `.form-detail__status--complete` and skips without error (handles re-runs)
- Fixed I-9 step: I-9 form was submitting to API (HTTP call reached server) but receiving 409 — see bug fix below
- Test now passes cleanly in ~47s; final screenshot shows all 6 forms completed (green checkmarks)

### Bug Fix: `ValidateRequiredFields` throws on `"required": null` in JSON
- **File:** `qb-engineer.api/Features/ComplianceForms/SubmitFormData.cs`
- **Root cause:** `I9FormDefinitionBuilder` serializes `["required"] = required` where `required` is `bool?`. Unset fields serialize as `"required": null`. `req.GetBoolean()` throws `InvalidOperationException` (not `JsonException`) on `null` values — bypassing the `catch (JsonException)` guard.
- **Fix:** Replaced `req.GetBoolean()` with `req.ValueKind != JsonValueKind.True` — only considers a field required if the JSON value is explicitly `true`.
- Applied same fix pattern to handle any other nullable boolean fields in form definitions safely.

---

## Batch 27 Changelog — Compliance PDF Download + Docs Accuracy (2026-03-21)

### Compliance Form PDF Download
- `DownloadSubmissionPdf` handler: `GET /api/v1/compliance-forms/submissions/{id}/pdf`
  - If `SignedPdfFileId` is set (DocuSeal signed) → streams stored PDF from MinIO
  - Otherwise → generates on-demand QuestPDF from `FormDefinitionVersion.FormDefinitionJson` + `FormDataJson`
  - PDF layout: form name header, submission date, labeled field/value pairs by section, page numbers
  - Access control: users see their own only; Admin/Manager/OfficeManager see any
- `ComplianceFormService.downloadSubmissionPdf()` (Angular): fetches as Blob, triggers browser download
- "Download PDF" button added to completed form card in `AccountTaxFormDetailComponent`
- i18n: `account.downloadFormCopy` added (en + es)

### Dead `src/assets/i18n/` Removed
- `qb-engineer-ui/src/assets/` was never served (angular.json assets root = `public/`)
- Deleted the duplicate `src/assets/i18n/en.json` and `src/assets/i18n/es.json`
- Canonical i18n path: `qb-engineer-ui/public/assets/i18n/`

### CLAUDE.md Documentation Accuracy Pass
- Fixed: QB Online and Ollama RAG marked "not yet implemented" → corrected to implemented with file references
- Added: Payroll, Chat, Reports (dynamic builder), AI, AI Assistants, Employee Compliance Forms, Quality, Sales Tax, Customer Returns, Production Lots, Scheduled Tasks, Notifications, Search to Features table
- Added: 12 missing entity groups to the Entity Structure section
- Added: "Planned / Partially Implemented" table replacing the single AR Aging "planned" row (AR Aging is implemented as a report; carrier APIs and alternative accounting providers correctly marked as remaining work)

---

## Batch 28 Changelog — Sales Tax UI, Customer Returns UI, Production Lots UI (2026-03-21)

### Sales Tax Admin Panel
- `SalesTaxPanelComponent` — DataTable with name/code/rate%/default/active columns, edit + delete per row
- `SalesTaxDialogComponent` — create/edit dialog with rate as % input (÷100 for API), default toggle
- Wired into admin as new `sales-tax` tab (Admin-only, placed between Teams and Compliance)
- Uses existing `AdminService.getSalesTaxRates/createSalesTaxRate/updateSalesTaxRate/deleteSalesTaxRate` methods
- i18n: `salesTax.*` section added (en + es), `admin.tabs.salesTax` added

### Customer Returns Feature
- New route `/customer-returns` — `roleGuard('Admin', 'Manager', 'PM', 'OfficeManager')`
- `CustomerReturnsComponent` — `DataTableComponent` list with status filter, `DetailSidePanelComponent` for detail
- Status chips: Received (info), ReworkOrdered (warning), InInspection (primary), Resolved (success), Closed (muted)
- Resolve action: opens inline dialog for inspection notes → `POST /{id}/resolve`
- Close action: `ConfirmDialogComponent` → `POST /{id}/close`
- `CustomerReturnDialogComponent` — `EntityPickerComponent` for customer + job, reason, notes, return date
- `CustomerReturnService` — full CRUD + resolve/close
- Sidebar nav: `assignment_return` icon in Sales group
- i18n: `customerReturns.*` section added (en + es), `nav.customerReturns` added

### Production Lots Feature
- New route `/lots` — `roleGuard('Admin', 'Manager', 'Engineer')`
- `LotsComponent` — `DataTableComponent` with lot number (mono font), part, qty, job, supplier lot, expiry
- `DetailSidePanelComponent` — full traceability panel: meta grid + chronological event timeline with type icons
- `LotDialogComponent` — part picker, quantity, supplier lot, linked job, expiration date, notes
- `LotService` — `getLots(search, partId, jobId)`, `trace(lotNumber)`, `create()`
- Sidebar nav: `batch_prediction` icon in Supply group
- i18n: `lots.*` section added (en + es), `nav.lots` added

---

## Batch 29 Changelog — Employee Training LMS (2026-03-23)

### Backend: Training Module System
- `TrainingModule` entity: title, summary, content (JSONB), contentType enum (Article/Video/Walkthrough/QuickRef/Quiz), estimatedMinutes, tags, publishedAt, sortOrder, isPublished
- `TrainingPath` entity: title, description, icon, isAutoAssigned, sortOrder; M2M `TrainingPathModule` join with order
- `TrainingProgress` entity: per-user per-module status (NotStarted/InProgress/Completed), startedAt, completedAt, lastHeartbeatAt, quizScore, quizAttempts
- `TrainingEnrollment` entity: per-user per-path enrollment with completedAt rollup
- `TrainingController` with 16 endpoints: modules list/get, progress (start/heartbeat/complete), quiz submit, enrollments, paths list/get, admin CRUD + progress summary
- 16 MediatR handlers in `Features/Training/`: GetTrainingModules, GetTrainingModule, GetTrainingModulesByRoute, CreateTrainingModule, UpdateTrainingModule, DeleteTrainingModule, RecordModuleStart, RecordProgressHeartbeat, CompleteModule, SubmitQuiz, GetMyEnrollments, GetMyProgress, EnrollUser, GetTrainingPath, GetTrainingPaths, GetAdminProgressSummary
- Seed data: 20 training modules (Article×12, Walkthrough×4, QuickRef×1, Quiz×2, Video×1) covering all major feature areas
- 2 seeded paths: "New Employee Onboarding" (7 modules, auto-assigned) + "Production Engineer Training" (8 modules, auto-assigned)
- Enrollments auto-created for all users on seed

### Frontend: Training Feature (`/training`)
- Route: `/training/:tab` (library/my-learning/paths), `/training/module/:id`, `/training/path/:id`
- `TrainingComponent`: 3-tab page (Library/My Learning/Learning Paths), search + type + learning style filters, card grid
- **Training Cards**: colored left-border type bar (Article=info, Video=purple, Walkthrough=primary, QuickRef=accent, Quiz=warning), completion/in-progress status chips, corner triangle for completed, style hint footer ("Best for: Visual / Auditory learners")
- `TrainingModuleComponent`: full module detail page with type-specific content renderer, progress timer, Mark as Complete / Back to Library footer buttons
  - **Article**: table of contents sidebar, section headings, collapsible TOC
  - **QuickRef**: tabular reference sections with Print button
  - **Video**: YouTube embed, chapters list, transcript toggle
  - **Walkthrough**: interactive tour via driver.js, step list, completion state
  - **Quiz**: question list with radio options, progress bar, submit → score card (pass/fail) with review mode + retry
- `TrainingPathComponent`: path detail with module list, per-module status chips, start/continue/review actions, progress bar
- `TrainingService`: getModules, getModule, getPath, getPaths, getMyEnrollments, recordStart, recordHeartbeat, completeModule, submitQuiz
- Models: TrainingModuleListItem, TrainingModule (full), TrainingPath, TrainingEnrollment, TrainingProgress, QuizContent, ArticleContent, VideoContent, WalkthroughContent, QuickRefContent; TrainingContentType/TrainingProgressStatus enums
- Learning style filter: maps visual/auditory/reading/kinesthetic → content types
- Sidebar nav: `school` icon in Management group

### Admin: Training Panel (Admin Settings → Training tab)
- New "Training" tab in Admin Settings
- `TrainingDashboardComponent`: 3 sub-tabs: Content, Paths, User Progress
  - **Content**: DataTable (title, type chip, time, published status, edit/delete actions), "+ New Module" button, `TrainingModuleDialogComponent`
  - **Paths**: DataTable (icon, title, description, module count, auto-assign, edit/delete), `TrainingPathDialogComponent`
  - **User Progress**: DataTable (name, role, enrolled paths, completed modules, last activity, completion %)
- `TrainingModuleDialogComponent`: full form (title, summary, content type selector, estimated minutes, tags, published toggle, JSON content editor)
- `TrainingPathDialogComponent`: title, description, icon, auto-assign toggle, module picker with drag-reorder
