# Implementation Status

Tracks real implementation against all spec docs. Updated: 2026-03-11.

Legend: Done | Partial | Not Started | N/A (deferred or out of scope)

---

## Phase Status (proposal.md §8)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1 — Foundation | Docker + Kanban + Job Cards | Partial |
| 2 — Engineer UX | Dashboard + Planning Day | Partial |
| 3 — Accounting Bridge | QB Read/Write Integration | Not Started |
| 4 — Leads & Contacts | Lead-to-Customer Pipeline | Partial |
| 5 — Traceability & QC | Production Lot Tracking | Not Started |
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
| .NET 9 Web API | architecture.md §Stack | Done | MediatR CQRS, FluentValidation (15 validators), exception middleware (404/400/409) |
| PostgreSQL + pgvector | architecture.md §Stack | Done | pgvector extension enabled |
| MinIO | architecture.md §Stack | Done | 3 buckets, upload/download/presigned URLs |
| Three.js (STL viewer) | architecture.md §Stack | Not Started | No Three.js integration |
| SignalR | architecture.md §Stack | Partial | 3 hubs (Board, Notification, Timer) — Board + Notification functional, Timer skeleton |
| Hangfire | architecture.md §Stack | Not Started | No background job processing |
| Mapperly | architecture.md §Stack | Not Started | No source-generated mapping |
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
| /reports | architecture.md §Routing | Done | 6 reports with charts (ng2-charts) + data tables |
| /admin/settings | architecture.md §Routing | Done | Reference data, terminology, system settings tabs |
| /sprint-planning | architecture.md §Routing | Not Started | |
| /search | architecture.md §Routing | Done | Global search bar in header, searches 6 entity types |
| /notifications | architecture.md §Routing | Partial | Backend: entity, repo, controller, 5 MediatR handlers. Frontend: panel dropdown from header bell icon. No dedicated /notifications page. |
| /admin/qb-setup | architecture.md §Routing | Not Started | |
| /admin/track-types | architecture.md §Routing | Done | Full CRUD: create/edit/delete with stage management |
| /admin/terminology | architecture.md §Routing | Done | Tab in admin page, editable key-label table, bulk save |
| /display/shop-floor | architecture.md §Routing | Done | Full-screen kiosk: worker presence, active jobs, KPIs, auto-refresh 30s, AllowAnonymous |
| /display/shop-floor/clock | architecture.md §Routing | Not Started | |

### Other Architecture Items

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Custom fields (JSON) | architecture.md §Custom Fields | Not Started | No template/value columns, no dynamic form generator |
| system_settings DB table | architecture.md §Settings | Done | Entity exists, no admin UI |
| Backup (B2 + local) | architecture.md §Backup | Not Started | Backup container is placeholder |
| Full-text search | architecture.md §Search | Partial | ILIKE search across 6 entities via SearchController. No tsvector/GIN index yet. |
| Self-hosted AI (Ollama + RAG) | architecture.md §AI | Partial | Docker container configured, IAiService + MockAiService built, no Ollama/RAG implementation |
| Theming (light/dark) | architecture.md §Theming | Done | Toggle in toolbar, CSS custom properties |
| Admin brand colors | architecture.md §Theming | Done | System settings for primary/accent colors, runtime CSS variable override, public brand endpoint |
| Accessibility (WCAG 3) | architecture.md §Accessibility | Partial | Keyboard nav, no axe-core tests |
| Mobile responsiveness | architecture.md §Mobile | Not Started | No responsive breakpoint layouts |

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
| Custom fields (per track type) | proposal.md §4.2 | Not Started | |
| R&D iteration counter/notes | proposal.md §4.2 | Not Started | |
| Production runs tab | proposal.md §4.2 | Not Started | |

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
| Part detail (specs, files, BOM) | proposal.md §4.3 | Partial | List view done, detail panel with info/BOM/usage tabs. BOM uses EntityPicker for part search. |
| Revision control | proposal.md §4.3 | Not Started | |
| Where Used (reverse BOM lookup) | proposal.md §4.3 | Done | Loaded via EF Include, displayed in Usage tab with navigation |
| STL inline viewer | proposal.md §4.3 | Not Started | |
| Accounting item linkage | proposal.md §4.3 | Not Started | |
| Part-to-job reference | proposal.md §4.3 | Done | JobPart entity, CRUD endpoints, search + add in job detail panel |

### CAD / STL / CAM File Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| File upload/download | proposal.md §4.4 | Done | MinIO, per-entity |
| File versioning by revision | proposal.md §4.4 | Not Started | |
| STL 3D viewer (Three.js) | proposal.md §4.4 | Not Started | |
| Chunked upload with progress | proposal.md §4.4 | Partial | FileUploadZoneComponent has progress |
| File access restrictions | proposal.md §4.4 | Not Started | |

### Dashboard

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Widget-based layout | proposal.md §4.5 | Partial | 5 widgets with real KPI data, CSV export, no gridstack drag/resize |
| Role-based default layouts | proposal.md §4.5 | Not Started | |
| Daily Priority Card | proposal.md §4.5 | Partial | TodaysTasksWidget exists |
| End-of-Day Prompt | proposal.md §4.5 | Not Started | |
| Screensaver / Ambient Mode | proposal.md §4.5 | Not Started | |
| Widget customization (add/remove/resize) | proposal.md §4.5 | Not Started | No gridstack integration |

### Planning Cycle Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Planning cycle entity | proposal.md §4.6 | Not Started | No sprint/cycle model |
| Planning Day flow | proposal.md §4.6 | Not Started | |
| Backlog curation (split-panel drag) | proposal.md §4.6 | Not Started | Backlog list exists but no cycle assignment |
| Cycle goals | proposal.md §4.6 | Not Started | |
| Rollover handling | proposal.md §4.6 | Not Started | |
| Cycle progress on dashboard | proposal.md §4.6 | Not Started | |

### Lead Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Lead CRUD | proposal.md §4.7 | Done | Create, update, soft-delete (not Converted) with ConfirmDialog |
| Lead statuses (New → Lost) | proposal.md §4.7 | Done | LeadStatus enum |
| Convert to Customer | proposal.md §4.7 | Done | Creates Customer + optional Contact from lead fields |
| Convert and Create Job | proposal.md §4.7 | Done | Option in conversion flow, creates Job linked to new customer |
| Lost lead reason capture | proposal.md §4.7 | Done | Lost dialog with reason textarea |
| Custom fields | proposal.md §4.7 | Not Started | |

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
| Vendor list (read-only from accounting) | proposal.md §4.9 | Not Started | No Vendor entity or API |
| Linked POs | proposal.md §4.9 | Not Started | |
| Linked Parts (preferred vendor) | proposal.md §4.9 | Not Started | |

### Expense Capture

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Expense CRUD | proposal.md §4.10 | Done | Create, update, soft-delete (Pending only) with ConfirmDialog |
| Receipt upload (camera/file) | proposal.md §4.10 | Partial | File upload exists, no camera integration |
| Approval workflow | proposal.md §4.10 | Partial | Status field exists, no queue UI |
| Self-approval settings | proposal.md §4.10 | Not Started | |
| Accounting sync | proposal.md §4.10 | Not Started | |
| CSV export | proposal.md §4.10 | Partial | Dashboard CSV export done; expense-specific CSV not yet |

### Invoice Workflow

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Direct mode (solo operator) | proposal.md §4.11 | Not Started | |
| Managed mode (office manager queue) | proposal.md §4.11 | Not Started | |
| Nudge system (uninvoiced jobs) | proposal.md §4.11 | Not Started | |
| Billing visibility on card | proposal.md §4.11 | Not Started | |

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
| Packing slip generation | functional-decisions.md §Shipments | Not Started | QuestPDF |
| Open orders dashboard widget | functional-decisions.md §Order Views | Not Started | |

### Standalone Financial Mode ⚡

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Invoice entity + CRUD | functional-decisions.md §Invoicing | Done | ⚡ Entity, config, handlers, controller, Angular UI |
| Invoice PDF generation | functional-decisions.md §Invoicing | Not Started | QuestPDF |
| Invoice email (SMTP) | functional-decisions.md §Invoicing | Not Started | |
| Payment entity + CRUD | functional-decisions.md §Payments | Done | ⚡ Entity, config, handlers, controller, Angular UI |
| Payment application to invoices | functional-decisions.md §Payments | Done | PaymentApplication entity, handler, UI with applications table |
| AR Aging report | functional-decisions.md §AR Aging | Not Started | ⚡ standalone only |
| Customer Statement PDF | functional-decisions.md §AR Aging | Not Started | ⚡ standalone only |
| Credit terms per customer | functional-decisions.md §Credit Terms | Done | CreditTerms enum on SalesOrder + Invoice |
| Sales tax tracking | functional-decisions.md §Sales Tax | Not Started | ⚡ standalone only |
| Revenue by Period report | functional-decisions.md §Financial Reports | Not Started | ⚡ standalone only |
| Revenue by Customer report | functional-decisions.md §Financial Reports | Not Started | ⚡ standalone only |
| Simple P&L report | functional-decisions.md §Financial Reports | Not Started | ⚡ standalone only |
| Standalone vendor CRUD | functional-decisions.md §Vendor Management | Not Started | ⚡ standalone only |
| Accounting mode switching | qb-integration.md §Standalone Mode | Not Started | IsConfigured/isStandalone checks |
| Invoices list + detail UI | functional-decisions.md §Invoicing | Done | ⚡ List + detail panel + send/void actions |
| Payments list UI | functional-decisions.md §Payments | Done | ⚡ List + detail panel + delete |
| AR Aging UI | functional-decisions.md §AR Aging | Not Started | ⚡ standalone only |

### Pricing & Quoting

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Price List entity + CRUD | functional-decisions.md §Price Lists | Done | Entity, config, handlers, controller |
| Quantity breaks | functional-decisions.md §Price Lists | Done | MinQuantity on PriceListEntry, unique index (list+part+qty) |
| Price resolution logic | functional-decisions.md §Price Lists | Not Started | Customer → default → base |
| Recurring Order entity + CRUD | functional-decisions.md §Recurring Orders | Done | Entity, config, handlers, controller |
| Recurring order auto-generation | functional-decisions.md §Recurring Orders | Not Started | Hangfire job |
| Margin per job/part/customer | functional-decisions.md §Margin Visibility | Not Started | Computed from cost + revenue |
| Margin dashboard widget | functional-decisions.md §Margin Visibility | Not Started | |
| Margin report | functional-decisions.md §Margin Visibility | Not Started | |

### Production Traceability

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Production runs (multiple per job) | proposal.md §4.12 | Not Started | No ProductionRun entity |
| Lot number tracking | proposal.md §4.12 | Not Started | |
| QC checklists | proposal.md §4.12 | Not Started | |
| Traceability profiles | proposal.md §4.12 | Not Started | |
| Lot lookup (forward/backward) | proposal.md §4.12 | Not Started | |

### Asset / Equipment Registry

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Asset CRUD | proposal.md §4.13 | Done | Create, update, soft-delete with ConfirmDialog |
| Maintenance card linking | proposal.md §4.13 | Not Started | |
| Scheduled maintenance rules | proposal.md §4.13 | Not Started | |
| Machine hours tracking | proposal.md §4.13 | Not Started | |
| Downtime logging | proposal.md §4.13 | Not Started | |

### Time Tracking

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Start/stop timer | proposal.md §4.14 | Done | TimerHub + ClockEvent |
| Manual time entry | proposal.md §4.14 | Done | Create, update, soft-delete with ConfirmDialog |
| Accounting sync (Time Activities) | proposal.md §4.14 | Not Started | |
| Same-day edit lock | proposal.md §4.14 | Done | Backend: previous-day check in update/delete handlers. Frontend: lock icon + disabled delete for past entries |
| Overlapping timer block | proposal.md §4.14 | Not Started | |
| Pay period awareness | proposal.md §4.14 | Not Started | |

### Employee Records

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Employee data from accounting | proposal.md §4.15 | Not Started | |
| Signed documents / certifications | proposal.md §4.15 | Not Started | MinIO bucket exists |

### Customer Returns

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Return button on completed jobs | proposal.md §4.16 | Not Started | |
| Reason capture + auto-linked rework card | proposal.md §4.16 | Not Started | |

### Guided Training System

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| First-login tour | proposal.md §4.17 | Not Started | |
| Per-feature walkthroughs | proposal.md §4.17 | Not Started | |
| Help icon per page | proposal.md §4.17 | Not Started | |
| Tour coverage audit (CI) | proposal.md §4.17 | Not Started | |
| Admin training dashboard | proposal.md §4.17 | Not Started | |

### Bin & Location Tracking

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Location hierarchy (Area → Rack → Bin) | proposal.md §4.18 | Done | StorageLocation entity, recursive, soft-delete (empty only) |
| Bin contents CRUD | proposal.md §4.18 | Done | BinContent entity, API, soft-delete with audit trail |
| Barcode scanning | proposal.md §4.18 | Not Started | |
| Movement audit trail | proposal.md §4.18 | Done | BinMovement entity |
| Production label printing | proposal.md §4.18 | Not Started | |

### Inventory Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Inventory list view | proposal.md §4.19 | Done | UI + API |
| Part inventory summary | proposal.md §4.19 | Partial | GetPartInventory exists |
| Receiving workflow | proposal.md §4.19 | Not Started | |
| General stock management | proposal.md §4.19 | Not Started | |
| Cycle counting | proposal.md §4.19 | Not Started | |
| Accounting quantity sync | proposal.md §4.19 | Not Started | |
| Low-stock alerts | proposal.md §4.19 | Not Started | |

### Purchase Order Lifecycle

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| PO creation (job-linked + standalone) | proposal.md §4.20 | Not Started | No PO entity |
| PO statuses (Draft → Closed) | proposal.md §4.20 | Not Started | |
| Partial receipts / back-order | proposal.md §4.20 | Not Started | |
| Multi-PO per job | proposal.md §4.20 | Not Started | |
| Preferred vendor per part | proposal.md §4.20 | Not Started | |

### Shipping & Carrier Integration

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| IShippingService interface | proposal.md §4.21 | Done | Interface + MockShippingService |
| Carrier APIs (UPS, FedEx, etc.) | proposal.md §4.21 | Not Started | |
| Packing slips | proposal.md §4.21 | Not Started | |
| Multi-package tracking | proposal.md §4.21 | Not Started | |

### R&D / Internal Projects

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| R&D track stages | proposal.md §4.22 | Done | Seeded stages |
| Iteration counter + test notes | proposal.md §4.22 | Not Started | |
| Handoff to Production linking | proposal.md §4.22 | Not Started | |
| Internal project types (reference data) | proposal.md §4.22 | Not Started | |
| Scheduled internal tasks | proposal.md §4.22 | Not Started | |

### Admin Settings & Integration Management

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| User management | proposal.md §4.23 | Done | CRUD, role assignment |
| Track type management | proposal.md §4.23 | Done | Full CRUD with stage management dialog |
| Reference data management | proposal.md §4.23 | Done | Admin tab |
| Accounting setup wizard | proposal.md §4.23 | Not Started | |
| Branding (logo, colors) | proposal.md §4.23 | Partial | Brand colors via system settings, no logo upload UI yet |
| System settings UI | proposal.md §4.23 | Done | Admin Settings tab with 10 configurable settings, upsert API |
| Third-party integrations panel | proposal.md §4.23 | Not Started | |

### Chat System

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| 1:1 direct messages | proposal.md §4.25 | Not Started | No ChatHub, message entity, or UI |
| Group chats | proposal.md §4.25 | Not Started | |
| File/image sharing | proposal.md §4.25 | Not Started | |
| Entity link sharing | proposal.md §4.25 | Not Started | |

### Calendar View

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| Month/week/day layouts | proposal.md §4.26 | Partial | Month view with navigation, click-through to kanban |
| Color coding by type | proposal.md §4.26 | Partial | Job chips with border-left color |
| Dense day handling | proposal.md §4.26 | Done | Max 3 jobs per cell, "+N more" overflow chip |
| Filtering | proposal.md §4.26 | Done | Track type filter dropdown |
| .ics export | proposal.md §4.26 | Not Started | |

---

## Roles & Auth (roles-auth.md)

| Item | Spec | Status | Notes |
|------|------|--------|-------|
| 6 roles (additive) | roles-auth.md §Roles | Done | Seeded |
| Role-based UI adaptation | roles-auth.md §Permissions | Partial | Sidebar filtered by role, route guards on Admin/Leads/Assets/Reports/Planning, backend role auth on Admin/Leads/Assets controllers. Full per-feature permissions TBD. |
| User onboarding (setup token) | roles-auth.md §Onboarding | Partial | Setup page exists, no setup token flow |
| Email invite (optional) | roles-auth.md §Onboarding | Not Started | |
| User offboarding (deactivation) | roles-auth.md §Offboarding | Not Started | |
| Production Worker simplified view | roles-auth.md §Worker | Not Started | |
| Shop Floor Display (no-login) | roles-auth.md §Shop Floor | Done | /display/shop-floor route, AllowAnonymous API, worker presence + active jobs |
| Time Clock Kiosk (scan-based) | roles-auth.md §Shop Floor | Not Started | |
| **Tiered Auth: RFID/NFC + PIN** | roles-auth.md §Tiered Auth | Not Started | Tier 1 — kiosk primary |
| **Tiered Auth: Barcode + PIN** | roles-auth.md §Tiered Auth | Not Started | Tier 2 — kiosk fallback |
| **PIN management (hash, reset)** | roles-auth.md §PIN Management | Not Started | Separate from password |
| **Enterprise SSO (Google)** | roles-auth.md §Enterprise SSO | Not Started | OAuth 2.0 / OIDC |
| **Enterprise SSO (Microsoft)** | roles-auth.md §Enterprise SSO | Not Started | Azure AD / Entra ID |
| **Enterprise SSO (Generic OIDC)** | roles-auth.md §Enterprise SSO | Not Started | Okta, Auth0, Keycloak |
| **SSO identity linking** | roles-auth.md §Enterprise SSO | Not Started | Link to existing accounts |

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
| UserPreferencesService | Done | localStorage (API switch pending) |
| TerminologyService | Done | Pipe exists, admin UI built |
| BoardHubService | Done | SignalR board sync |
| NotificationHubService | Done | Hub + panel + header bell wired |
| TimerHubService | Partial | Hub exists, skeleton |

### Pending Enhancements

| Enhancement | Component | Status |
|-------------|-----------|--------|
| Expandable rows | DataTableComponent | Not Started |
| API-backed preferences | UserPreferencesService | Not Started (backend built) |
| Loading state | DataTableComponent | Not Started |
| Sticky first column | DataTableComponent | Not Started |

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
| My Expense History | Not Started |
| My Cycle Summary | Not Started |
| Jobs by Stage | Done | Full-stack: bar chart + data table, track type filter |
| Overdue Jobs | Done | Full-stack: data table with days overdue, assignee |
| On-Time Delivery Rate | Done | Full-stack: pie chart + KPI cards, date range filter |
| Average Lead Time | Done | Full-stack: bar chart + data table by stage |
| Time in Stage (Bottleneck) | Not Started |
| Team Workload | Done | Full-stack: stacked bar chart + data table (active/overdue/hours) |
| Employee Productivity | Not Started |
| Labor Hours by Job | Done | Time by User report: bar chart + data table, date range filter |
| Expense Summary | Done | Full-stack: pie chart + data table, date range filter |
| Cycle Review | Not Started |
| Customer Activity | Done | Full-stack: stacked bar chart + data table (active/completed/total) |
| Quote-to-Close Rate | Not Started |
| Inventory Levels | Not Started |
| Quality / Scrap Rate | Not Started |
| Shipping Summary | Not Started |
| Maintenance Reports | Not Started |
| Lead Pipeline Report | Done | Full-stack: bar chart + data table |
| Lead & Sales Reports | Not Started |
| R&D Reports | Not Started |
| System Audit Log | Not Started |
| Storage Usage | Not Started |
| Job Completion Trend | Done | Full-stack: line chart (created vs completed per month) |
| Scheduled Email Digest | Not Started |

---

## Notification System (proposal.md §5.3)

| Item | Status | Notes |
|------|--------|-------|
| Bell icon + dropdown panel | Done | Real unread count badge, click-to-open panel |
| User-authored notifications | Done | CreateNotification handler with sender info |
| System-generated notifications | Done | CreateNotification via MediatR, SignalR broadcast |
| Filter tabs (All/Messages/Alerts) | Done | Tab filtering in notification panel |
| Dismiss / Pin / Bulk actions | Done | Per-item pin/dismiss, mark all read, dismiss all |
| Per-user notification preferences | Not Started | |
| Email notifications (SMTP) | Not Started | |
| Email templates (branded) | Not Started | |

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
| Angular unit tests (Vitest) | Not Started | No .spec.ts files |
| .NET unit tests (xUnit) | Not Started | Test project empty |
| Integration tests | Not Started | |
| E2E tests (Cypress) | Not Started | |
| axe-core accessibility tests | Not Started | |

---

## Libraries (libraries.md) — Installation Status

### Frontend

| Library | Installed | Used |
|---------|-----------|------|
| @angular/material | Yes | Yes |
| @angular/cdk (drag-drop) | Yes | Yes (kanban) |
| @angular/cdk (scrolling) | Yes | No (virtual scroll) |
| gridstack | No | Not Started |
| three + @types/three | No | Not Started |
| ng2-charts + chart.js | Yes | Yes (reports) |
| driver.js | No | Not Started |
| @ngx-translate/core | No | Not Started |
| @ngx-dropzone | No | Not Started (custom FileUploadZone built) |
| ngx-extended-pdf-viewer | No | Not Started |
| ngx-quill | No | Not Started |
| angularx-qrcode | No | Not Started |
| bwip-js | No | Not Started |
| papaparse | No | Not Started |
| @ngneat/hotkeys | No | Not Started |
| date-fns | Yes | Yes |
| @ngx-gallery/lightbox | No | Not Started |
| ngx-markdown | No | Not Started |
| vitest | Yes | No tests written |
| cypress | No | Not Started |

### Backend

| Library | Installed | Used |
|---------|-----------|------|
| EF Core + Npgsql | Yes | Yes |
| ASP.NET Identity | Yes | Yes |
| SignalR | Yes | Yes |
| FluentValidation | Yes | Yes |
| MediatR | Yes | Yes |
| Serilog | Yes | Yes |
| Mapperly | No | Not Started |
| MS Http Resilience | No | Not Started |
| Minio SDK | Yes | Yes |
| OpenAPI + Scalar | Yes | Yes |
| Hangfire | No | Not Started |
| MailKit | No | Not Started |
| CsvHelper | No | Not Started |
| QuestPDF | No | Not Started |
| ImageSharp | No | Not Started |
| Xabaril Health Checks | Partial | PostgreSQL only |
| Data Protection API (EF) | No | Not Started |
| EFCore.BulkExtensions.MIT | No | Not Started |
| Bogus | No | Not Started |

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
| **Order Management** | 9 | — | 3 |
| **Standalone Financial ⚡** | 5 | — | 12 |
| **Pricing & Quoting** | 3 | — | 5 |
| Accounting Integration | — | — | 9 |
| Planning Cycles | — | — | 6 |
| Production Traceability | — | — | 5 |
| Reporting | 7 | 2 | 18 |
| Notifications | — | — | 8 |
| Chat | — | — | 4 |
| Search | 1 | — | — |
| i18n | — | 2 | 4 |
| Testing | — | — | 5 |
| Background Jobs | — | — | 1 |
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
