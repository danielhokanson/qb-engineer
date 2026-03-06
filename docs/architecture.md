# Architecture & Tech Stack

## Stack
- Frontend: Angular 21 + Angular Material (zoneless, Signal Forms, Vitest)
- Backend: .NET 9 Web API
- Database: PostgreSQL + pgvector extension
- File Storage: MinIO (local S3-compatible)
- 3D Viewer: Three.js (STL inline rendering)
- Real-time: SignalR (pub-sub for board sync + notifications)
- Background Jobs: Hangfire + Hangfire.PostgreSql
- Object Mapping: Mapperly (source-generated)
- API Docs: OpenAPI + Scalar
- Containerization: Docker Compose
- AI (optional): Ollama + pgvector RAG

See `docs/libraries.md` for the complete library reference.

## Docker Compose -- 7 Containers (AI optional)
1. qb-engineer-ui -- Nginx + Angular build
2. qb-engineer-api -- .NET 9 Web API
3. qb-engineer-db -- PostgreSQL + pgvector with persistent volume
4. qb-engineer-storage -- MinIO with persistent volume
5. qb-engineer-backup -- Scheduled backup jobs (Hangfire)
6. qb-engineer-ai -- Ollama LLM runtime (optional)
7. qb-engineer-backup-target -- MinIO replica on secondary machine (separate compose)

## Auth
- ASP.NET Identity with custom ApplicationUser
- JWT bearer auth for Angular SPA
- Refresh token rotation
- Roles are additive (user can have multiple)
- Accounting provider OAuth tokens stored on shared AccountingConnection (single company-level connection)
- Token encryption via ASP.NET Data Protection API (keys in Postgres)

## Pluggable Accounting Integration
- `IAccountingService` common interface — customers, invoices, estimates, POs, payments, time activities, employees, vendors, items
- QuickBooks Online is the default and primary provider — pre-selected in admin setup
- Additional providers (Xero, FreshBooks, Sage) implement the same interface
- `AccountingServiceFactory` resolves the active provider from `system_settings.accountingProvider`
- Each provider owns: auth flow, API client, DTO mapping to/from common models
- Sync queue, caching, and orphan detection are provider-agnostic — work identically for any provider
- App works in standalone mode (no provider) — financial features degrade gracefully

## RESTful Routing

### Angular (UI)
All major UI states are URL-addressable and render in that state on direct navigation:

```
/dashboard
/kanban
/kanban?track=production
/jobs
/jobs/:id
/jobs/:id/files
/jobs/:id/runs
/sprint-planning
/sprint-planning/:sprintId
/backlog
/leads
/leads/:id
/parts
/parts/:id
/parts/:id/bom
/assets
/assets/:id
/expenses
/expenses/:id
/time-tracking
/admin/users
/admin/settings
/admin/qb-setup
/admin/track-types
/admin/terminology
/search?q=query
/notifications
/display/shop-floor
/display/shop-floor/clock    ← time clock kiosk (scan in/out, quick actions)
```

Deep linking works -- sharing a URL opens the exact state. Browser back/forward navigates correctly. Route params drive data loading.

### API (.NET)
RESTful resource naming with versioning:

```
/api/v1/jobs
/api/v1/jobs/:id
/api/v1/jobs/:id/subtasks
/api/v1/jobs/:id/files
/api/v1/jobs/:id/runs
/api/v1/jobs/:id/activity
/api/v1/parts
/api/v1/parts/:id
/api/v1/parts/:id/bom
/api/v1/notifications
/api/v1/search?q=query
/api/v1/admin/settings
```

Plural nouns for collections. No verbs in URLs except RPC-like actions (`/api/v1/jobs/:id/archive`).

## Custom Fields System (JSON-based)
- Reusable across track types, leads, customers
- custom_fields_template JSONB column defines field schema
- custom_field_values JSONB column stores values
- Supported types: text, number, boolean, date, select, multiselect, textarea
- Angular dynamic form generator renders from template
- Searchable via Postgres JSONB operators

## Settings
- appsettings.json: infrastructure (connection strings, JWT key, MOCK_INTEGRATIONS, CORS, logging)
- system_settings DB table: operational settings changed at runtime (file limits, invoice workflow mode, planning cycle duration, nudge timing, etc.)
- .NET uses IOptions<T> pattern -- strongly typed config, never raw IConfiguration in services

## Backup Strategy
- Primary: Backblaze B2 (off-site) -- daily pg_dump + rclone sync for MinIO
- Secondary: Local machine replication (on-site) -- MinIO bucket replication + DB dumps
- Retention: 7 daily, 4 weekly, 3 monthly
- Backup status visible in system health panel

## Search
- Postgres full-text search with tsvector + GIN index
- JSONB custom fields included in search vectors
- Single /api/v1/search endpoint, results grouped by entity type
- Global search bar with Ctrl+K shortcut (@ngneat/hotkeys)
- AI-enhanced natural language search (optional, when AI container available)

## Self-Hosted AI (Optional)
- Ollama Docker container running open-source LLMs locally
- pgvector Postgres extension for embedding/vector storage (no separate vector DB)
- RAG pipeline: index local data -> retrieve relevant docs -> LLM answers grounded in production data
- Manufacturing base knowledge from open-source training data, augmented with local data
- Re-indexing via Hangfire background job on data changes
- Same mockable service pattern: IAiService with OllamaAiService + MockAiService
- Graceful degradation: AI features fall back to manual workflows when container is down

## Theming
- User-selectable light/dark mode toggle in toolbar, preference saved per-user
- Admin controls 3 brand colors (primary, accent, warn) via admin settings — runtime, no rebuild
- Contrast validation warns admin if selected colors violate WCAG 3 accessibility thresholds
- Colors applied via CSS custom properties — both light and dark themes auto-generated from the 3 base colors
- Logo and app name configurable in admin settings

## Accessibility
- Target: WCAG 3 compliance
- APCA-based contrast scoring enforced at the theming level
- Reduced motion support (`prefers-reduced-motion`)
- axe-core integrated into E2E tests for automated screen reader verification
- Minimum 44x44px touch targets on mobile

## Mobile
- Responsive Angular -- same build, different layouts by viewport
- Below 768px: simplified bottom nav, subset of views only
- Available on mobile: daily priorities, timer, card detail (read), expense capture, notifications, production run logging, maintenance reporting
- Desktop-only: Kanban board, Planning Day, reporting, admin, configuration
