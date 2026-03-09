# QB Engineer — Project Rules

> Loaded into every Claude Code session. These rules override defaults. Follow exactly.
> Full specs in `docs/`. When in doubt, check `docs/coding-standards.md` first.

## SELF-MAINTENANCE RULE

**After every session that introduces a new pattern, convention, architectural decision, or workflow change — update this file.** This is the single source of truth for project rules across sessions. If a decision is made during implementation (new shared component, naming convention, SCSS pattern, API convention, etc.), add it here before the session ends. Outdated or missing rules cause rework. Keep this file current.

Also update `docs/coding-standards.md` or the relevant doc file if the change is significant enough to be spec-level.

---

## Project Structure

```
qb-engineer-wrapper/
├── qb-engineer-ui/          # Angular 21 + Material 21
│   └── src/
│       ├── styles/           # _variables, _mixins, _shared, _reset
│       ├── styles.scss       # Material theme + overrides
│       └── app/
│           ├── shared/       # Reusable components, services, directives, pipes, utils
│           ├── features/     # Feature modules (kanban, backlog, admin, etc.)
│           └── core/         # Singleton services (layout, nav, toolbar, sidebar)
├── qb-engineer-server/       # .NET 9 solution
│   ├── qb-engineer.api/      # Controllers, Features/ (MediatR handlers), Middleware
│   ├── qb-engineer.core/     # Entities, Interfaces, Models, Enums
│   ├── qb-engineer.data/     # DbContext, Repositories, Migrations, Configuration
│   └── qb-engineer.integrations/
├── docs/                     # Specs: coding-standards, architecture, functional-decisions, ui-components, roles-auth, libraries
└── docker-compose.yml        # 7 containers: ui, api, db, storage, backup, ai (optional), backup-target
```

---

## Critical Rules

### ONE OBJECT PER FILE (Non-Negotiable)
- **Angular:** One component, service, pipe, directive, guard, interceptor, or model per file. No barrel files (`index.ts`).
- **.NET:** One class, interface, enum, or record per file. Exception: related request/response pair if < 20 lines total.
- **Never mash multiple classes, enums, services, or components into a single file.**

### Naming Conventions

**Angular (TypeScript):**

| Item | Convention | Example |
|------|-----------|---------|
| Files | kebab-case + type suffix | `job-card.component.ts`, `job.service.ts`, `job.model.ts` |
| Classes | PascalCase + type suffix | `JobCardComponent`, `JobService` |
| Variables/properties | camelCase | `jobList`, `isLoading` |
| Observables | camelCase + `$` suffix | `jobs$`, `notifications$` |
| Signals | camelCase, no suffix | `jobs`, `isLoading` |
| Constants | UPPER_SNAKE_CASE | `MAX_FILE_SIZE` |
| Enums | PascalCase name + members | `JobStatus.InProduction` |
| Interfaces | PascalCase, no `I` prefix | `Job`, `Notification` |
| CSS classes | BEM | `job-card__header--active` |
| Control flow | `@if`/`@for` | Never `*ngIf`/`*ngFor` |

**.NET (C#):**

| Item | Convention | Example |
|------|-----------|---------|
| Files | PascalCase | `JobService.cs` |
| Classes/methods/properties | PascalCase | `JobService.GetActiveJobs()` |
| Private fields | _camelCase | `_jobRepository` |
| Parameters/locals | camelCase | `jobId`, `isActive` |
| Interfaces | `I` prefix | `IJobService` |
| Constants | PascalCase | `MaxRetryCount` |
| Namespaces | `QbEngineer.{Project}.{Folder}` | `QbEngineer.Api.Controllers` |
| Models | `*ResponseModel` / `*RequestModel` | **Never "DTO"** |

**Database:** snake_case for tables/columns (auto-converted by EF Core)
**Docker:** services named `qb-engineer-*`

### Import Ordering

**TypeScript:** (1) Angular core → (2) Angular Material → (3) Third-party (rxjs, three, etc.) → (4) App shared → (5) Feature-relative. Blank line between groups.

**C#:** (1) System → (2) Microsoft → (3) Third-party (FluentValidation, MediatR, etc.) → (4) QbEngineer

### Tech Stack
- **Frontend:** Angular 21, Angular Material 21, SCSS, standalone components, zoneless (signals)
- **Backend:** .NET 9, MediatR (CQRS), FluentValidation, EF Core + Npgsql
- **Database:** PostgreSQL with `timestamptz` columns (all DateTimes must be UTC)
- **Storage:** MinIO (S3-compatible), **Auth:** ASP.NET Identity + JWT
- **Real-time:** SignalR, **Background:** Hangfire, **Mapping:** Mapperly (source-generated), **Logging:** Serilog
- **Date lib:** date-fns (tree-shakeable, official Material adapter)
- **Charts:** ng2-charts (Chart.js), **Dashboard grid:** gridstack, **Tours:** driver.js
- **PDF:** QuestPDF (server), **Barcodes:** bwip-js, **QR:** angularx-qrcode
- **Testing:** Vitest (Angular), xUnit + Bogus (.NET), Cypress (E2E)

---

## Angular Patterns

### Component Rules
- `standalone: true`, `ChangeDetectionStrategy.OnPush` on every component
- Signal-based state: `signal()`, `computed()`, `input()`, `output()`
- `inject()` for DI — never constructor injection
- No inline templates — always `.component.html` + `.component.scss`
- No inline `style="..."` — all styling via CSS classes
- No function calls in template bindings — use `computed()` signals
- Decorator order: `selector`, `standalone`, `imports`, `templateUrl`, `styleUrl`, `changeDetection`
- Max template `@if` block: ~20 lines before extracting to child component
- Smart components (features): inject services, manage state via signals
- Dumb components (shared): `input()`/`output()` only, no service injection

### Form Controls — ALWAYS Use Shared Wrappers
Never raw `<input>`, `<select>`, or `<textarea>` in feature templates.

| Component | Selector | Key Inputs |
|-----------|----------|------------|
| `InputComponent` | `<app-input>` | `label`, `type`, `placeholder`, `prefix`, `suffix`, `maxlength`, `isReadonly` |
| `SelectComponent` | `<app-select>` | `label`, `options: SelectOption[]`, `multiple`, `placeholder` |
| `TextareaComponent` | `<app-textarea>` | `label`, `rows`, `maxlength` |
| `DatepickerComponent` | `<app-datepicker>` | `label` |
| `ToggleComponent` | `<app-toggle>` | `label` |

All implement `ControlValueAccessor`. Use with `ReactiveFormsModule` (`FormGroup`/`FormControl`) — never `ngModel` / `FormsModule`.

```typescript
// SelectOption (from select.component.ts)
interface SelectOption { value: unknown; label: string; }

// Null option pattern for optional selects:
{ value: null, label: '-- None --' }
```

### Form Validation — No Inline Errors
Validation uses hover popover on submit button, not `mat-error` beneath fields. `mat-form-field` subscript wrapper is globally `display: none`.

```typescript
// Component class:
readonly violations = FormValidationService.getViolations(this.form, {
  fieldName: 'Human Label',
});

// Template — on submit button:
<button [appValidationPopover]="violations"
        [disabled]="form.invalid || saving()"
        (click)="save()">Save</button>
```

- Submit button disabled when form invalid
- Hover shows bulleted violation list
- Invalid fields get subtle visual indicator (field highlighting, not text)
- `FormValidationService` + `ValidationPopoverDirective` (in `shared/`)
- Async validators: button shows spinner icon while pending
- Server-side 400 errors: mapped to toast (form was already client-valid)

### Dialog Pattern — ALWAYS Use `<app-dialog>`
Never build custom dialog shells. Every dialog uses the shared component.

```html
<app-dialog [title]="'Create Job'" width="520px" (closed)="close()">
  <div [formGroup]="form">
    <app-input label="Title" formControlName="title" />
    <div class="dialog-row">
      <app-select label="Customer" formControlName="customerId" [options]="customerOptions" />
      <app-datepicker label="Due Date" formControlName="dueDate" />
    </div>
  </div>

  <div dialog-footer>
    <button class="action-btn" (click)="close()">Cancel</button>
    <button class="action-btn action-btn--primary"
      [appValidationPopover]="violations"
      [disabled]="form.invalid || saving()"
      (click)="save()">Save</button>
  </div>
</app-dialog>
```

- `width` input: small (420px default), medium (520px), large (800px)
- `.dialog__body` auto-applies flex column + gap to projected form containers
- `.dialog-row` = 2-column grid for side-by-side fields (1-column on mobile)
- Footer buttons: equal width, horizontal, cancel left, primary right

### Date Handling
- Angular sends dates via `toIsoDate()` from `shared/utils/date.utils.ts`
- Format: `"YYYY-MM-DDT00:00:00Z"` — full ISO with explicit UTC (never date-only strings)
- .NET `AppDbContext.NormalizeDateTimes()` converts `DateTimeKind.Unspecified` → UTC before save
- Postgres `timestamptz` always requires UTC

### Page Filter Pattern
Filters use standalone `FormControl` (not inside a `FormGroup`):

```typescript
readonly searchControl = new FormControl('');
readonly filterSignal = toSignal(this.searchControl.valueChanges, { initialValue: '' });
```

```html
<app-input label="Search" [formControl]="searchControl" />
<app-select label="Status" [formControl]="statusControl" [options]="statusOptions" />
```

### Service Conventions
- `providedIn: 'root'` (tree-shakeable singletons)
- All HTTP calls in services, never in components
- Return signals or `toSignal()` — components never call `.subscribe()` directly
- Error handling at service level — expose `error` signal
- One service per domain concern, max ~200 lines

### Error Handling (Angular)
- HTTP errors caught in services via `catchError` — services expose `error` signal
- Global `HttpErrorInterceptor`: 401 → redirect login, 403 → access denied snackbar, 500 → error toast with copy button
- No `try/catch` wrapping individual HTTP calls in components
- Form validation errors via popover (not inline `mat-error`)

### Client-Side Storage
- **IndexedDB** (wrapper service): lookup data caches (customers, parts, track types, etc.) with `last_synced` timestamp
- **localStorage**: JWT tokens, user preferences (theme, locale, sidebar state). Minimal — no large objects.
- **In-memory signals**: transient UI state (filters, scroll positions, form drafts). Lost on tab close.
- Stale cache is usable — show cached data immediately, refresh in background

### Lazy Loading & Bundles
- Every feature module lazy-loaded via `loadComponent` in route config
- Heavy libraries loaded on demand: Three.js (dynamic import), driver.js (first tour), ng2-charts (reporting)
- No feature code in main bundle — `shared/` and `core/` only
- Bundle budget: warning 500KB, error 1MB (initial)

### Folder Structure
```
shared/components/   ← reusable: dialog, input, select, datepicker, toggle, textarea, avatar, etc.
shared/services/     ← auth, theme, form-validation, toast, snackbar, cache
shared/directives/   ← validation-popover
shared/utils/        ← date.utils.ts
shared/guards/       ← auth.guard, setup.guard
shared/interceptors/ ← auth.interceptor
shared/models/       ← shared interfaces, enums
shared/pipes/        ← terminology, date-format
shared/validators/   ← shared form validators
features/{name}/     ← component + routes + models/ + services/ + components/
```

Promotion rule: used by 2+ features → move to `shared/`.

---

## SCSS Design System

### NEVER hardcode values. Always use variables/mixins.

**Spacing:** `$sp-xs: 2px` | `$sp-sm: 4px` | `$sp-md: 8px` | `$sp-lg: 16px` | `$sp-xl: 24px`

**Typography:** `$font-size-xxs: 9px` | `$font-size-xs: 10px` | `$font-size-sm: 11px` | `$font-size-base: 12px` | `$font-size-title: 13px` | `$font-size-kpi: 20px`

**Fonts:** `$font-family-primary: 'Space Grotesk'` | `$font-family-mono: 'IBM Plex Mono'`

**Borders:** `$border-width: 2px` | `$border-width-thin: 1px` | `$border-radius: 0px` (sharp corners everywhere)

**Z-index:** `$z-sticky: 100` | `$z-sidebar: 200` | `$z-dropdown: 300` | `$z-dialog: 400` | `$z-snackbar: 500` | `$z-loading: 900` | `$z-toast: 1000`

**Breakpoints:** `$breakpoint-mobile: 768px` | `$breakpoint-tablet: 1024px` | `$breakpoint-desktop: 1200px` | `$breakpoint-wide: 1400px`

**Transitions:** `$transition-fast: 150ms ease` | `$transition-normal: 250ms ease` | `$transition-sidebar: 200ms ease`

**Sizing:** `$sidebar-width-collapsed: 52px` | `$sidebar-width-expanded: 200px` | `$header-height: 44px`

### CSS Custom Properties (Theme Colors)
```
--primary, --primary-light, --primary-dark, --header
--accent, --accent-light
--success, --success-light, --info, --info-light
--warning, --warning-light, --error, --error-light
--bg, --surface, --border
--text, --text-secondary, --text-muted
```
Dark theme auto-swaps via `[data-theme='dark']` on `<html>`.

### SCSS Rules
- BEM naming: `block__element--modifier`
- Max 3 levels nesting — flatten with BEM instead of deep nesting
- No `!important` unless overriding third-party (with comment)
- Component SCSS should be thin — most styling from variables, mixins, Material
- Before writing new styles, check `_variables.scss` and `_mixins.scss` first

### Key Mixins (from `_mixins.scss`)
- `@include uppercase-label($size, $spacing, $weight)` — all-caps small labels
- `@include flex-center` / `@include flex-between` — common flex patterns
- `@include custom-scrollbar($width)` — themed scrollbar
- `@include mobile` / `@include tablet` / `@include desktop` — responsive breakpoints
- `@include truncate` — text ellipsis

### Shared Classes (from `_shared.scss`)
- `.page-header` — 48px height, `$sp-sm $sp-lg` padding, form fields zero margin
- `.action-btn` / `.action-btn--primary` / `.action-btn--sm` — 2rem height buttons
- `.icon-btn` / `.icon-btn--danger` — 24x24 icon buttons
- `.dialog-backdrop`, `.dialog`, `.dialog__header`, `.dialog__body`, `.dialog__footer`
- `.dialog-row` — 2-column grid for side-by-side dialog fields (1-column on mobile)
- `.dialog__body > *` — auto flex column + gap to projected form containers
- `.dialog__footer .action-btn` — equal-width buttons
- `.tab-bar`, `.tab`, `.tab--active`, `.tab-panel`, `.panel-header`
- `.chip` / `.chip--primary|success|warning|error|info|muted` — color-mix backgrounds
  - DB-driven colors: `[style.--chip-color]="color"`, fills column width in `<td>`
  - Dark theme: 15% opacity bg (vs 10% light)
- `.page-loading` — centered loading state
- `.snackbar--success|info|warn|error` — colored snackbar variants

### Material Theme Overrides (styles.scss)
- All shapes: 0px (sharp corners)
- Form field height: compact (40px container, 8px vertical padding)
- Density: -1
- Subscript wrapper: `display: none` globally (validation via popover, not `mat-error`)
- Error colors: mapped to `var(--error)`
- Text size: 12px, subscript: 10px

---

## .NET Patterns

### Architecture
- MediatR CQRS: Commands + Queries in `Features/` folder, one handler per file
- FluentValidation: validators alongside handlers (can share file if small)
- Repository pattern: interfaces in `Core/Interfaces/`, implementations in `Data/Repositories/`
- Global exception middleware: `KeyNotFoundException` → 404, `ValidationException` → 400, business exceptions → 409
- Controllers are thin — delegate to MediatR handlers, one controller per aggregate root
- All endpoints `[Authorize]` by default; exceptions: login, register, refresh, health, display
- No `try/catch` in controllers — middleware handles everything
- Problem Details (RFC 7807) for all error responses
- Logging via Serilog: structured, contextual (request ID, user ID, entity ID)

### C# Class Structure
- Interfaces for all services (`IJobService`, `IStorageService`)
- Abstract base classes for shared behavior:
  - `BaseEntity` — `Id`, `CreatedAt`, `UpdatedAt`, `DeletedAt`, `DeletedBy`
  - `BaseAuditableEntity` — extends BaseEntity with `CreatedBy`
- Records for models/value objects — immutable by default
- Composition over deep inheritance — max 2 levels
- Integration pattern: interface + real impl + mock impl (e.g., `IAiService` / `OllamaAiService` / `MockAiService`)
- Entity config: one `IEntityTypeConfiguration<T>` per entity, Fluent API only (no data annotations)

### Database (PostgreSQL + EF Core)
- `AppDbContext` auto-applies:
  - Snake_case naming for all tables/columns/keys/indexes
  - `SetTimestamps()` — auto-sets `CreatedAt`/`UpdatedAt` on `BaseEntity`
  - `NormalizeDateTimes()` — converts `DateTimeKind.Unspecified` to UTC before save
  - Global query filter: `DeletedAt == null` on all `BaseEntity` types
- Soft deletes only — no hard deletes (`DeletedAt` timestamp + `DeletedBy` FK)
- Fluent API in separate `IEntityTypeConfiguration<T>` classes (no data annotations)
- Foreign key indexes explicit on all FK columns
- `reference_data` table: centralized lookup/dropdown values with `group_id` grouping and immutable `code` field
- Primary keys: `id` (int, auto-increment). Foreign keys: `{table_singular}_id`

### API Conventions
- RESTful: `/api/v1/jobs`, `/api/v1/jobs/{id}`, `/api/v1/jobs/{id}/subtasks`
- Plural nouns for collections; no verbs except RPC-like (`/archive`)
- POST → 201 + Location header; DELETE/PUT no-body → 204
- `IOptions<T>` for config — never raw `IConfiguration` in services
- `MOCK_INTEGRATIONS=true` env var bypasses all external API calls with mock responses

### JSON Serialization
- `JsonStringEnumConverter` — enums serialize as strings
- CamelCase property naming (ASP.NET Core default)

### Pagination
- **Offset-based** for standard lists: `?page=1&pageSize=25&sort=createdAt&order=desc` → response: `{ data, page, pageSize, totalCount, totalPages }`
- **Cursor-based** for real-time feeds (chat, activity, notifications): `?cursor=eyJ...&limit=50`
- Default page size: 25, max: 100
- Client: small datasets (< 100) client-side filter; medium (100-1000) `mat-paginator`; large/unbounded virtual scroll
- `PaginatedDataSource<T>` shared class wraps API pagination

---

## UI Layout Rules

### Button Placement
- Action buttons in **lower-right** of page/dialog
- Primary action **furthest right**
- Secondary (Cancel) to the left
- Destructive actions separated on far left
- Order: `[Destructive]` — gap — `[Secondary]` `[Primary]`
- Dialog footer: equal-width buttons, horizontal, same row

### Page Structure
- Header (sticky top): title, breadcrumbs, optional filter bar
- Content area (scrollable): all content scrolls here
- Action bar (sticky bottom): action buttons right-aligned
- Page chrome (header, sidebar, action bar) **never scrolls**
- No horizontal scrolling except kanban board and wide data tables (sticky first column)

### Aesthetic
- Dense, compact, professional engineering tool feel
- Sharp corners: `$border-radius: 0px` everywhere (Material chips retain rounded)
- Small fonts: 12px base, 11px tables, 9-10px labels
- Minimal padding — tight but readable
- `Space Grotesk` for UI, `IBM Plex Mono` for code/data
- Content max-width: 1400px centered (except kanban + shop floor = full width)
- No full-bleed layouts on ultra-wide monitors

### Notifications: Snackbar vs Toast
- **Snackbar** (bottom-center): brief confirmations — "Job saved", "Part created. [View Part]". Single at a time. Auto-dismiss 4s (errors never).
- **Toast** (upper-right): detailed errors with copy button, stack traces, sync conflicts. Stackable (max 5). Auto-dismiss: info 8s, warning 12s, error never.
- `SnackbarService`: `.success(msg)`, `.error(msg)`, `.info(msg)`, `.successWithNav(msg, route)`
- `ToastService`: `.show({ severity, title, message, details?, autoDismissMs? })`
- Creation navigation: snackbar includes "View Job" action button when creating entities

### Loading States
- **Global overlay** via `LoadingService` — blocks all interaction, spinner + message stack, `inert` on main content. Fade in/out 300ms, min 400ms display.
- **Component-level** via `LoadingBlockDirective` — local spinner on specific sections
- **Empty states** on all list views: icon + message + optional CTA via `EmptyStateComponent`

---

## Shared Components (Built)

| Component | Path | Purpose |
|-----------|------|---------|
| `InputComponent` | `shared/components/input/` | Material text input wrapper (CVA) |
| `SelectComponent` | `shared/components/select/` | Material select wrapper (CVA) |
| `TextareaComponent` | `shared/components/textarea/` | Material textarea wrapper (CVA) |
| `DatepickerComponent` | `shared/components/datepicker/` | Material datepicker wrapper (CVA) |
| `ToggleComponent` | `shared/components/toggle/` | Material slide-toggle wrapper (CVA) |
| `DialogComponent` | `shared/components/dialog/` | Shared dialog shell (content projection) |
| `PageHeaderComponent` | `shared/components/page-header/` | Standard page header bar |
| `AvatarComponent` | `shared/components/avatar/` | User avatar with initials fallback |
| `KpiChipComponent` | `shared/components/kpi-chip/` | Compact metric display |
| `StatusBadgeComponent` | `shared/components/status-badge/` | Colored status indicator |
| `DashboardWidgetComponent` | `shared/components/dashboard-widget/` | Dashboard widget shell |
| `ToastComponent` | `shared/components/toast/` | Stackable upper-right toasts |
| `PlaceholderComponent` | `shared/components/placeholder/` | Placeholder for unbuilt features |
| `EmptyStateComponent` | `shared/components/empty-state/` | Icon + message + optional CTA for empty lists |
| `DataTableComponent` | `shared/components/data-table/` | Configurable data table (see below) |
| `ColumnFilterPopoverComponent` | `shared/components/data-table/column-filter-popover/` | Per-column filter overlay (text/number/date/enum) |
| `ColumnManagerPanelComponent` | `shared/components/data-table/column-manager-panel/` | Column visibility, reorder, reset overlay |
| `ColumnCellDirective` | `shared/directives/column-cell.directive.ts` | Tags `ng-template` by field for custom cell rendering |
| `ConfirmDialogComponent` | `shared/components/confirm-dialog/` | MatDialog-based confirmation for destructive actions |
| `DetailSidePanelComponent` | `shared/components/detail-side-panel/` | Slide-out right panel (400px, Escape/backdrop close) |
| `PageLayoutComponent` | `shared/components/page-layout/` | Standard page shell (toolbar + content + actions) |
| `EntityPickerComponent` | `shared/components/entity-picker/` | Typeahead entity search via API (CVA) |
| `FileUploadZoneComponent` | `shared/components/file-upload-zone/` | Drag-and-drop file upload with progress |
| `AutocompleteComponent` | `shared/components/autocomplete/` | mat-autocomplete form field wrapper (CVA) |
| `ToolbarComponent` | `shared/components/toolbar/` | Horizontal flex filter/action bar |
| `SpacerDirective` | `shared/directives/spacer.directive.ts` | Pushes toolbar items right (`flex: 1`) |
| `DateRangePickerComponent` | `shared/components/date-range-picker/` | Two-date picker with presets (CVA) |
| `ActivityTimelineComponent` | `shared/components/activity-timeline/` | Chronological activity feed (compact + full) |
| `ListPanelComponent` | `shared/components/list-panel/` | Scrollable list with built-in empty state |
| `KanbanColumnHeaderComponent` | `shared/components/kanban-column-header/` | Column header with WIP limits + collapse |
| `QuickActionPanelComponent` | `shared/components/quick-action-panel/` | Touch-first shop floor actions (88x88px) |
| `MiniCalendarWidgetComponent` | `shared/components/mini-calendar-widget/` | Dashboard calendar with highlight dates |
| `ValidationPopoverDirective` | `shared/directives/` | Hover popover showing form violations |
| `FormValidationService` | `shared/services/` | Derives violation messages from FormGroup |
| `UserPreferencesService` | `shared/services/` | Per-user preference storage (localStorage, API-ready) |
| `SnackbarService` | `shared/services/` | Bottom-center snackbar convenience methods |
| `ToastService` | `shared/services/` | Upper-right toast management |
| `AuthService` | `shared/services/` | Login, logout, token management |
| `ThemeService` | `shared/services/` | Light/dark theme switching |
| `LoadingService` | `shared/services/` | Global loading overlay with cause queue |
| `NotificationService` | `shared/services/` | Notification state, filtering, panel, API sync |
| `TerminologyService` | `shared/services/` | Admin-configurable label resolution |
| `TerminologyPipe` | `shared/pipes/` | `{{ 'key' \| terminology }}` label transform |
| `LoadingBlockDirective` | `shared/directives/` | `[appLoadingBlock]="isLoading"` local spinner overlay |
| `httpErrorInterceptor` | `shared/interceptors/` | Global HTTP error → snackbar/toast routing |
| `SignalrService` | `shared/services/` | Singleton connection manager for all hubs |
| `BoardHubService` | `shared/services/` | Board hub: join/leave groups, event callbacks |
| `NotificationHubService` | `shared/services/` | Notification hub: pushes to NotificationService |
| `TimerHubService` | `shared/services/` | Timer hub: start/stop event callbacks |
| `ConnectionBannerComponent` | `shared/components/connection-banner/` | Reconnecting/disconnected warning banner |
| `toIsoDate()` | `shared/utils/date.utils.ts` | Date → `YYYY-MM-DDT00:00:00Z` |

### AppDataTableComponent — Usage Guide

Reusable data table replacing all hand-rolled `<table>` markup. Features: client-side sorting (click header, Shift+click for multi-sort), per-column filtering (text/number/date/enum), pagination (25/50/100), column visibility/reorder/resize via gear icon, preference persistence via `tableId`, right-click context menu on column headers (sort asc/desc, clear sort, filter, clear filter, clear all filters, hide column, reset width).

**Converted features:** Admin, Assets, Leads, Expenses, Time Tracking, Parts, Backlog (7/8 — Inventory deferred, needs expandable row support).

**Backend:** `UserPreferencesController` (GET/PATCH/DELETE), `UserPreference` entity, MediatR handlers built. Frontend still uses localStorage (API switch pending).

```html
<!-- Basic usage -->
<app-data-table
  tableId="parts-list"
  [columns]="partColumns"
  [data]="parts()"
  [selectable]="true"
  emptyIcon="inventory_2"
  emptyMessage="No parts found"
  [rowClass]="partRowClass"
  [rowStyle]="partRowStyle"
  (rowClick)="selectPart($event)"
  (selectionChange)="onSelectionChange($event)">

  <!-- Custom cell templates (plain text columns render automatically) -->
  <ng-template appColumnCell="status" let-row>
    <span class="chip" [class]="getStatusClass(row.status)">{{ row.status }}</span>
  </ng-template>
  <ng-template appColumnCell="assignee" let-row>
    <app-avatar [initials]="row.initials" [color]="row.color" size="sm" />
  </ng-template>
</app-data-table>
```

```typescript
// Column definition
protected readonly partColumns: ColumnDef[] = [
  { field: 'partNumber', header: 'Part #', sortable: true, width: '120px' },
  { field: 'description', header: 'Description', sortable: true },
  { field: 'status', header: 'Status', sortable: true, filterable: true, type: 'enum',
    filterOptions: [
      { value: 'Active', label: 'Active' },
      { value: 'Draft', label: 'Draft' },
    ]},
  { field: 'dueDate', header: 'Due Date', sortable: true, type: 'date', width: '100px' },
];

// Dynamic row class (selected, overdue, active timer, etc.)
protected readonly partRowClass = (row: unknown) => {
  const part = row as PartListItem;
  return part.id === this.selectedPart()?.id ? 'row--selected' : '';
};

// Dynamic row inline styles (e.g., --row-tint for color-mix tinted backgrounds)
protected readonly partRowStyle = (row: unknown): Record<string, string> => {
  const part = row as PartListItem;
  return part.color ? { '--row-tint': part.color } : {};
};
```

**ColumnDef interface:** `field`, `header`, `sortable?`, `filterable?`, `type?` ('text'|'number'|'date'|'enum'), `filterOptions?` (SelectOption[]), `width?`, `visible?`, `align?` ('left'|'center'|'right')

**Key models:** `ColumnDef` in `shared/models/column-def.model.ts`, `TablePreferences`/`SortState` in `shared/models/table-preferences.model.ts`

### ConfirmDialogComponent — Usage Guide

Opens via `MatDialog`. Returns `true` (confirmed) or `false` (cancelled). Severity colors the confirm button.

```typescript
import { ConfirmDialogComponent, ConfirmDialogData } from 'shared/components/confirm-dialog/confirm-dialog.component';

// In component:
private readonly dialog = inject(MatDialog);

archiveJob(job: Job): void {
  this.dialog.open(ConfirmDialogComponent, {
    width: '400px',
    data: {
      title: 'Archive Job?',
      message: 'This will remove the job from the board. You can restore it later.',
      confirmLabel: 'Archive',
      severity: 'warn',
    } satisfies ConfirmDialogData,
  }).afterClosed().subscribe(confirmed => {
    if (confirmed) this.jobService.archive(job.id);
  });
}
```

**Data inputs:** `title` (string), `message` (string), `confirmLabel?` (default "Confirm"), `cancelLabel?` (default "Cancel"), `severity?` ('info'|'warn'|'danger', default 'info')

### DetailSidePanelComponent — Usage Guide

Slide-out right panel (400px, full-width on mobile). Backdrop click + Escape closes. Content projection for body + `[panel-actions]` slot for sticky footer buttons.

```html
<app-detail-side-panel [open]="!!selectedPart()" [title]="selectedPart()?.partNumber ?? ''" (closed)="closePart()">
  <!-- Body content (scrollable) -->
  <div class="info-grid">
    <div class="info-item">
      <span class="info-label">Status</span>
      <span class="info-value">{{ selectedPart()?.status }}</span>
    </div>
  </div>

  <!-- Sticky footer actions -->
  <div panel-actions>
    <button class="action-btn" (click)="editPart()">Edit</button>
    <button class="action-btn action-btn--primary" (click)="savePart()">Save</button>
  </div>
</app-detail-side-panel>
```

### PageLayoutComponent — Usage Guide

Standard page shell enforcing layout rules (Standard #36). Replaces ad-hoc `<app-page-header>` + manual content structure.

```html
<app-page-layout pageTitle="Parts Catalog">
  <ng-container toolbar>
    <app-input label="Search" [formControl]="searchControl" />
    <app-select label="Status" [formControl]="statusControl" [options]="statusOptions" />
    <span appSpacer></span>
    <button class="action-btn action-btn--primary" (click)="createPart()">
      <span class="material-icons-outlined">add</span> New Part
    </button>
  </ng-container>

  <ng-container content>
    <app-data-table tableId="parts" [columns]="columns" [data]="parts()" />
  </ng-container>

  <ng-container actions>
    <button class="action-btn" (click)="cancel()">Cancel</button>
    <button class="action-btn action-btn--primary" (click)="save()">Save</button>
  </ng-container>
</app-page-layout>
```

Slots: `toolbar` (header bar, optional), `content` (scrollable body), `actions` (sticky footer, optional — hidden when empty)

### EntityPickerComponent — Usage Guide

Typeahead search against API endpoints. CVA for reactive forms. Debounced 300ms search, min 2 chars.

```html
<app-entity-picker
  label="Customer"
  entityType="customers"
  displayField="name"
  [filters]="{ active: 'true' }"
  formControlName="customerId" />
```

Searches `GET /api/v1/{entityType}?search={term}&pageSize=10` + extra filters. Returns entity `id` as the form value. Expects API response shape: `{ data: [...] }`.

### FileUploadZoneComponent — Usage Guide

Drag-and-drop + click-to-browse. Per-file progress bars, type/size validation, error display.

```html
<app-file-upload-zone
  entityType="jobs"
  [entityId]="jobId"
  accept=".pdf,.step,.stl"
  [maxSizeMb]="50"
  (uploaded)="onFileUploaded($event)" />
```

Uploads to `POST /api/v1/{entityType}/{entityId}/files` as multipart. Emits `UploadedFile` on success: `{ id, fileName, contentType, size, url }`.

### AutocompleteComponent — Usage Guide

Form field wrapper for `mat-autocomplete` with local option filtering. CVA. For API-backed search, use `EntityPickerComponent` instead.

```html
<app-autocomplete
  label="Material"
  [options]="materialOptions"
  displayField="label"
  valueField="value"
  [minChars]="1"
  formControlName="material" />
```

Options: array of objects. `displayField` shown in dropdown, `valueField` used as form value. Clears value when user types (forces re-selection).

### ToolbarComponent + SpacerDirective — Usage Guide

Horizontal flex container for filter bars and action buttons. Use `appSpacer` directive to push items to the right.

```html
<app-toolbar>
  <app-input label="Search" [formControl]="searchControl" />
  <app-select label="Status" [formControl]="statusControl" [options]="statuses" />
  <span appSpacer></span>
  <button class="action-btn action-btn--primary" (click)="create()">New Job</button>
</app-toolbar>
```

Auto-removes margins from form field wrappers. Responsive wrap on mobile.

### DateRangePickerComponent — Usage Guide

Two-date picker (From/To) with optional preset buttons. CVA. Value: `{ start: Date | null, end: Date | null }`.

```html
<app-date-range-picker
  label="Date Range"
  [presets]="['Today', 'This Week', 'This Month', 'Last 30 Days']"
  formControlName="dateRange" />
```

Built-in presets: 'Today', 'This Week', 'This Month', 'Last 30 Days'. Start/end dates constrain each other (start <= end).

### ActivityTimelineComponent — Usage Guide

Chronological activity feed with avatars. Two modes: full (default) and compact (sidebar).

```html
<!-- Full mode -->
<app-activity-timeline [activities]="activityLog()" />

<!-- Compact mode (sidebar) -->
<app-activity-timeline [activities]="activityLog()" [compact]="true" />
```

**ActivityItem model** (`shared/models/activity.model.ts`): `id`, `description`, `createdAt` (ISO string), `userInitials?`, `userColor?`, `action?`

### ListPanelComponent — Usage Guide

Scrollable list container with built-in empty state. Content projects list items.

```html
<app-list-panel [empty]="subtasks().length === 0" emptyIcon="checklist" emptyMessage="No subtasks">
  @for (task of subtasks(); track task.id) {
    <div class="subtask-item">{{ task.text }}</div>
  }
</app-list-panel>
```

### KanbanColumnHeaderComponent — Usage Guide

Board column header with WIP limit enforcement, collapse toggle, and irreversible lock indicator.

```html
<app-kanban-column-header
  [name]="stage.name"
  [count]="cards.length"
  [wipLimit]="stage.wipLimit"
  [color]="stage.color"
  [isIrreversible]="stage.isIrreversible"
  [collapsed]="isCollapsed"
  (collapseToggled)="toggleCollapse()" />
```

Background turns red (`--error-light`) when count exceeds WIP limit.

### QuickActionPanelComponent — Usage Guide

Touch-first grid of large action buttons (88x88px minimum) for shop floor displays.

```html
<app-quick-action-panel
  [actions]="shopFloorActions"
  [columns]="3"
  (actionClick)="onAction($event)" />
```

```typescript
protected readonly shopFloorActions: QuickAction[] = [
  { id: 'clock-in', label: 'Clock In', icon: 'login', color: 'var(--success)' },
  { id: 'clock-out', label: 'Clock Out', icon: 'logout', color: 'var(--error)' },
  { id: 'start-task', label: 'Start Task', icon: 'play_arrow', color: 'var(--primary)' },
];
```

**QuickAction interface:** `id`, `label`, `icon`, `color?`, `disabled?`

### MiniCalendarWidgetComponent — Usage Guide

Dashboard calendar widget using `mat-calendar`. Highlights dates with events.

```html
<app-mini-calendar-widget
  [highlightDates]="dueDates()"
  (dateSelected)="onDateSelected($event)" />
```

### LoadingService — Usage Guide

Global loading overlay that blocks all interaction. Signal-based cause queue supports multiple concurrent loading sources. Integrates with `LoadingBlockDirective` for component-level loading.

```typescript
private readonly loading = inject(LoadingService);

// Track an Observable — auto starts/clears loading state
loadJobs(): void {
  this.loading.track('Loading jobs...', this.jobService.getJobs())
    .subscribe(jobs => this.jobs.set(jobs));
}

// Track a Promise
async exportReport(): Promise<void> {
  const pdf = await this.loading.trackPromise('Generating report...', this.reportService.generate());
}

// Manual control
this.loading.start('save-job', 'Saving job...');
// ... later
this.loading.stop('save-job');
```

**Signals:** `isLoading` (boolean), `message` (latest cause message), `causes` (full queue)
**Methods:** `track(message, observable)`, `trackPromise(message, promise)`, `start(key, message)`, `stop(key)`, `clear()`

### LoadingBlockDirective — Usage Guide

Component-level loading overlay. Adds a spinner overlay to the host element when the bound boolean is `true`. Uses `position: relative` on host + absolute overlay with fade transition.

```html
<!-- On a section -->
<div class="card" [appLoadingBlock]="isLoadingDetails()">
  <h3>Job Details</h3>
  <p>{{ job().description }}</p>
</div>

<!-- On a table wrapper -->
<div [appLoadingBlock]="isLoadingTable()">
  <app-data-table [columns]="columns" [data]="data()" />
</div>
```

### HttpErrorInterceptor — Usage Guide

Functional interceptor registered in app config. Handles all HTTP error responses globally — no `try/catch` needed in components.

```typescript
// app.config.ts
provideHttpClient(
  withInterceptors([authInterceptor, httpErrorInterceptor])
)
```

**Error routing:**
- `401` → Defers to auth interceptor (silent refresh)
- `403` → Snackbar: "Access denied"
- `409` → Toast warning with server message (conflict)
- `0` (network) → Toast: "Connection lost"
- `500+` → Toast error with title + details (copy button)

Parses Problem Details (RFC 7807) `title` and `detail` fields. No per-call error handling needed unless feature-specific behavior is required.

### TerminologyService + TerminologyPipe — Usage Guide

Admin-configurable label resolution. Loads terminology map from API on app init. Pipe resolves keys to labels in templates.

```typescript
// Service — load on app init (after auth)
private readonly terminology = inject(TerminologyService);
this.terminology.load();

// Service — resolve programmatically
const label = this.terminology.resolve('entity_job'); // → "Job" (or admin-configured label)

// Service — admin live preview
this.terminology.set('entity_job', 'Work Order');
```

```html
<!-- Pipe usage in templates -->
<span>{{ 'entity_job' | terminology }}</span>        <!-- "Job" -->
<span>{{ 'status_in_production' | terminology }}</span> <!-- "In Production" -->
```

**Fallback:** When key has no configured label, strips known prefixes (`entity_`, `status_`, `action_`, `field_`, `label_`) and title-cases the remainder.

**API:** `GET /api/v1/terminology` → `{ data: Record<string, string> }`

### NotificationService — Usage Guide

Unified notification state management. Signal-based with optimistic UI updates. Integrates with SignalR for real-time push.

```typescript
private readonly notifications = inject(NotificationService);

// Load on app init (after auth)
this.notifications.load();

// Push from SignalR
this.hubConnection.on('notification', (n: AppNotification) => {
  this.notifications.push(n);
});

// Read state
readonly unreadCount = this.notifications.unreadCount;
readonly filtered = this.notifications.filteredNotifications;
readonly isOpen = this.notifications.panelOpen;

// Actions
this.notifications.togglePanel();
this.notifications.setTab('alerts');
this.notifications.markAsRead(notificationId);
this.notifications.markAllRead();
this.notifications.dismiss(notificationId);
this.notifications.dismissAll();
this.notifications.togglePin(notificationId);
this.notifications.setFilter({ severity: 'critical', unreadOnly: true });
```

**Filtering:** Tab filter (`all` | `messages` | `alerts`), plus optional `source`, `severity`, `type`, `unreadOnly`. Pinned notifications always sort first, then by `createdAt` descending.

**Model:** `AppNotification` in `shared/models/notification.model.ts` — `id`, `type`, `severity`, `source`, `title`, `message`, `isRead`, `isPinned`, `isDismissed`, `entityType?`, `entityId?`, `senderInitials?`, `senderColor?`, `createdAt`

### SignalR Services — Usage Guide

**SignalrService** is the singleton connection manager. Hub-specific services (`BoardHubService`, `NotificationHubService`, `TimerHubService`) wrap it for domain-specific logic.

```typescript
// SignalrService — never used directly in features, only by hub services
// Manages HubConnection lifecycle, exposes aggregate connectionState signal
readonly connectionState: Signal<ConnectionState>; // 'disconnected' | 'connecting' | 'connected' | 'reconnecting'
getOrCreateConnection(hubPath: string): HubConnection;
startConnection(hubPath: string): Promise<void>;
stopConnection(hubPath: string): Promise<void>;
stopAll(): void;
```

**BoardHubService** — used in kanban and any board-related feature:

```typescript
private readonly boardHub = inject(BoardHubService);

// Connect + join a board group
await this.boardHub.connect();
await this.boardHub.joinBoard(trackTypeId);

// Register event callbacks
this.boardHub.onJobCreatedEvent((event) => this.reloadBoard());
this.boardHub.onJobMovedEvent((event) => this.reloadBoard());
this.boardHub.onJobUpdatedEvent((event) => this.reloadBoard());
this.boardHub.onJobPositionChangedEvent((event) => this.reloadBoard());
this.boardHub.onSubtaskChangedEvent((event) => this.reloadSubtasks());

// Switch boards / cleanup
await this.boardHub.leaveBoard();
await this.boardHub.joinBoard(newTrackTypeId);
await this.boardHub.disconnect(); // in ngOnDestroy
```

**NotificationHubService** — connected once in `AppComponent.ngOnInit()`:

```typescript
// Automatically pushes received notifications to NotificationService
await this.notificationHub.connect();
// No manual event registration needed — handled internally
```

**TimerHubService** — used in time tracking:

```typescript
private readonly timerHub = inject(TimerHubService);

await this.timerHub.connect();
this.timerHub.onTimerStartedEvent(() => this.loadEntries());
this.timerHub.onTimerStoppedEvent(() => this.loadEntries());
// ngOnDestroy: this.timerHub.disconnect();
```

**ConnectionBannerComponent** — added to `app.component.html`, no configuration needed:

```html
<app-connection-banner />
```

Shows yellow bar for `reconnecting`, red bar for `disconnected`. Auto-hides when `connected`.

**Backend hub endpoints:** `/hubs/board`, `/hubs/notifications`, `/hubs/timer`. All `[Authorize]`. JWT passed via `?access_token=` query string (WebSocket can't use headers).

**Backend broadcasting pattern** — inject `IHubContext<T>` into MediatR handlers:

```csharp
// In handler primary constructor:
IHubContext<BoardHub> boardHub

// After SaveChangesAsync:
await boardHub.Clients.Group($"board:{trackTypeId}")
    .SendAsync("jobCreated", new BoardJobCreatedEvent(...), cancellationToken);
```

### Pending Enhancements

| Enhancement | Component | Details |
|-------------|-----------|---------|
| Expandable rows | `DataTableComponent` | Optional `rowExpand` template slot for nested content (needed for Inventory stock tab — bin detail rows) |
| Switch to API | `UserPreferencesService` | Frontend currently uses localStorage. Backend API is built. Switch to `GET` on init + debounced `PATCH` on change. |
| Loading state | `DataTableComponent` | Integrate `LoadingBlockDirective` during data fetch |
| Sticky first column | `DataTableComponent` | For wide tables with horizontal scroll |

---

## Features (Implemented)

| Feature | UI Component | API Controller | Key Entities |
|---------|-------------|---------------|--------------|
| Kanban Board | `kanban/` | `JobsController` | Job, JobStage, TrackType |
| Dashboard | `dashboard/` | `DashboardController` | (aggregates) |
| Calendar | `calendar/` | — | — |
| Backlog | `backlog/` | `JobsController` | Job |
| Parts | `parts/` | `PartsController` | Part, BOMEntry |
| Inventory | `inventory/` | `InventoryController` | StorageLocation, BinContent, BinMovement |
| Leads | `leads/` | `LeadsController` | Lead |
| Expenses | `expenses/` | `ExpensesController` | Expense |
| Assets | `assets/` | `AssetsController` | Asset |
| Time Tracking | `time-tracking/` | `TimeTrackingController` | TimeEntry, ClockEvent |
| Admin | `admin/` | `AdminController` | ApplicationUser, ReferenceData |
| Auth | `auth/` (login, setup) | `AuthController` | ApplicationUser |
| File Storage | `FileUploadZoneComponent` | `FilesController` | FileAttachment |

---

## .NET Entity Structure

### Core Entities (in `qb-engineer.core/Entities/`)
```
BaseEntity (Id, CreatedAt, UpdatedAt, DeletedAt, DeletedBy)
├── Job, TrackType, JobStage, JobSubtask, JobActivityLog, JobLink
├── Customer, Contact
├── Part, BOMEntry
├── StorageLocation, BinContent, BinMovement
├── Lead, Expense, Asset
├── TimeEntry, ClockEvent
├── FileAttachment
├── ReferenceData, SystemSetting, SyncQueueEntry
```

### Enums (in `qb-engineer.core/Enums/`)
`JobPriority`, `JobLinkType`, `ActivityAction`, `PartType`, `PartStatus`, `BOMSourceType`, `LocationType`, `BinContentStatus`, `BinMovementReason`, `LeadStatus`, `ExpenseStatus`, `AssetType`, `AssetStatus`, `ClockEventType`, `SyncStatus`, `AccountingDocumentType`

---

## SignalR Conventions
- One hub per domain: `BoardHub`, `NotificationHub`, `TimerHub`, `ChatHub`
- Method naming: PascalCase server-side, camelCase client-side
- Groups: subscribe by entity — `job:{id}`, `sprint:{id}`, `user:{id}`
- Angular service handles auto-reconnect with exponential backoff
- Optimistic UI: card moves update locally immediately, server confirms/rolls back via SignalR
- Connection state exposed as signal — UI shows "reconnecting..." banner when disconnected

---

## Accessibility (WCAG 3)
- APCA-based contrast scoring, validated at theme level
- All interactive elements keyboard-navigable
- `aria-label` on icon-only buttons
- No info conveyed by color alone — always pair with icon/text
- Focus indicators visible in both themes — enhance, don't suppress
- Touch targets: minimum 44x44px on mobile (88x88px on shop floor kiosk)
- `prefers-reduced-motion` respected — disable animations when set
- axe-core integrated into E2E tests
- Admin theme color pickers validate contrast before saving

---

## Security
- CSP headers: `default-src 'self'`, `script-src 'self'` (no eval), `frame-ancestors 'none'`
- `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, HSTS in production
- Rate limiting via built-in .NET middleware (fixed window, sliding window, token bucket)
- QB OAuth tokens encrypted via ASP.NET Data Protection API (keys in Postgres)
- No sensitive data in localStorage beyond auth tokens (short-lived access + rotated refresh)
- Auth interceptor: 401 → silent refresh, queues concurrent requests during refresh

---

## Multi-Tab Handling
- Auth sync across tabs via `BroadcastChannel` / `storage` event — logout propagates to all tabs
- Theme sync via `storage` event on `themeMode` key
- Each tab opens its own SignalR connection (acceptable for < 50 concurrent users)
- IndexedDB shared per origin — no extra cache sync needed

---

## Offline Resilience
- Service worker caches app shell (HTML, JS, CSS, assets) for instant load
- IndexedDB cache serves as offline data layer — stale-while-revalidate
- Offline banner: "Connection lost. Changes will sync when reconnected."
- Action queue in IndexedDB — card moves, time entries, chat messages, form submissions queued and drained on reconnect
- Conflicts resolved last-write-wins (same as SignalR multi-user)
- No silent data loss — queued operations never silently discarded

---

## Testing Conventions

### Angular (Vitest)
- Unit tests for services and pipes (`.spec.ts` co-located)
- Component tests for smart components with meaningful logic
- No tests for trivial dumb components
- Mock HTTP via `provideHttpClientTesting`

### .NET (xUnit)
- Unit tests for MediatR handlers (business logic)
- Integration tests for API endpoints via `WebApplicationFactory`
- Bogus for test data generation
- Mock external services (QB, MinIO, SMTP) — never hit real services
- Test project mirrors source: `QbEngineer.Tests/Handlers/Jobs/CreateJobHandlerTests.cs`

### E2E (Cypress)
- Critical user journeys: login, kanban CRUD, job detail, planning, dashboard, notifications, expense, lead, parts, time tracking, search, admin
- Runs against full Docker Compose stack with `MOCK_INTEGRATIONS=true`
- API seeding for test data (not UI clicks)
- Custom commands: `cy.login(role)`, `cy.createJob()`, `cy.seedData()`
- No `cy.wait(ms)` — use built-in retry/assertions
- Specs in `cypress/e2e/` organized by feature

### E2E (Playwright — SignalR Diagnostics)
- Playwright for multi-browser context tests (required for SignalR real-time sync verification)
- Tests in `qb-engineer-ui/e2e/tests/`, helpers in `e2e/helpers/`
- Run headless: `npm run e2e` | headed: `npm run e2e:headed`
- Config: `e2e/playwright.config.ts` — Chromium only, no webServer (assumes Docker stack running)
- Auth via API helper (`e2e/helpers/auth.helper.ts`) — sets localStorage directly, no UI login
- Seeded test users: `admin@qbengineer.local` / `Admin123!`, `akim@qbengineer.local` / `Engineer123!`
- **SignalR diagnostic:** `signalr-board-sync.spec.ts` — verifies real-time board sync between two browser contexts
- **Troubleshooting SignalR:** Run `npm run e2e` from `qb-engineer-ui/` as a quick diagnostic. Creates two browser contexts, logs in both, moves a job via API, asserts the second browser updates within 5s via SignalR.

### Static Analysis
- ESLint + `@angular-eslint` + `@typescript-eslint`: unused vars, no `any`, import ordering, no `console.log`
- Prettier for formatting
- .NET Analyzers at `Medium` level + StyleCop.Analyzers
- `<Nullable>enable</Nullable>`, no warning suppression without comment

---

## Git Conventions
- Branch naming: `feature/job-card-crud`, `fix/notification-dismiss`, `chore/update-dependencies`
- Commit messages: imperative mood, < 72 chars — "Add job card CRUD endpoints"
- One logical change per commit
- PR required for main (even solo)
- No force pushes to main

---

## CI/CD Pipeline (GitHub Actions)
1. **Build** — restore, compile, lint (Angular + .NET in parallel)
2. **Unit Tests** — Vitest + xUnit in parallel
3. **Integration Tests** — .NET against test Postgres
4. **E2E Tests** — Cypress against Docker Compose
5. **Docker Build** — build and tag images
6. **Release** — push tagged images on version tags

PRs require passing CI. Test results reported as PR comments. Failed E2E includes screenshots.

---

## Versioning
- Semantic versioning from git tags: `v1.2.3`
- CI auto-increments patch on merge to main
- Version injected into Angular `environment.ts` and .NET `AssemblyVersion` at build time
- Docker images tagged with version + `latest`
- Version displayed in UI footer and API health endpoint

---

## Docker

```bash
docker compose up -d                          # Full stack
docker compose up -d --build qb-engineer-api  # Rebuild API
docker compose logs -f qb-engineer-api        # API logs
docker compose exec qb-engineer-db psql -U postgres -d qb_engineer  # DB access
```

7 containers: `qb-engineer-ui`, `qb-engineer-api`, `qb-engineer-db`, `qb-engineer-storage`, `qb-engineer-backup`, `qb-engineer-ai` (optional), `qb-engineer-backup-target` (separate compose)

---

## Pluggable Integrations

### Mock Integration Flag
- `MockIntegrations` in appsettings.json (default `false`, `true` in Development)
- `MockIntegrations=${MOCK_INTEGRATIONS:-false}` in docker-compose.yml
- Program.cs conditionally registers mock vs real services based on this flag
- All mock services log operations via `ILogger` for dev visibility

### Accounting (`IAccountingService`)
- Interface: `qb-engineer.core/Interfaces/IAccountingService.cs`
- Models: `qb-engineer.core/Models/AccountingModels.cs` (AccountingCustomer, AccountingDocument, AccountingLineItem, AccountingPayment, AccountingTimeActivity, AccountingSyncStatus)
- Mock: `qb-engineer.integrations/MockAccountingService.cs` — returns canned data matching seeded customers
- QuickBooks Online is default + primary provider (not yet implemented)
- Additional providers (Xero, FreshBooks, Sage) implement same interface
- App works fully in standalone mode (no provider) — financial features degrade gracefully
- Sync queue, caching, orphan detection are provider-agnostic

### Shipping (`IShippingService`)
- Interface: `qb-engineer.core/Interfaces/IShippingService.cs`
- Models: `qb-engineer.core/Models/ShippingModels.cs` (ShipmentRequest, ShippingAddress, ShippingPackage, ShippingRate, ShippingLabel, ShipmentTracking, TrackingEvent)
- Mock: `qb-engineer.integrations/MockShippingService.cs` — returns 3 mock carrier rates
- Pluggable carrier integration: UPS, FedEx, USPS, DHL, EasyPost (not yet implemented)
- Manual mode always available (no API, user enters tracking number)

### AI (`IAiService` — Optional)
- Interface: `qb-engineer.core/Interfaces/IAiService.cs`
- Models: `qb-engineer.core/Models/AiModels.cs` (AiSearchResult)
- Mock: `qb-engineer.integrations/MockAiService.cs` — returns canned text responses
- Self-hosted Ollama + pgvector RAG (not yet implemented)
- Use cases: smart search, job description drafting, QC anomaly detection, document Q&A
- Graceful degradation when AI container is down

### Storage (`IStorageService`)
- Interface: `qb-engineer.core/Interfaces/IStorageService.cs`
- Real: `qb-engineer.integrations/MinioStorageService.cs` (MinIO S3-compatible)
- Mock: `qb-engineer.integrations/MockStorageService.cs` — in-memory ConcurrentDictionary
- Config: `MinioOptions` in `qb-engineer.core/Models/MinioOptions.cs`

---

## Roles (Additive)

| Role | Access |
|------|--------|
| Engineer | Kanban, assigned work, files, expenses, time tracking |
| PM | Backlog, planning, leads, reporting, priority (read-only board) |
| Production Worker | Simple task list, start/stop timer, move cards, notes/photos |
| Manager | Everything PM + assign work, approve expenses, set priorities |
| Office Manager | Customer/vendor, invoice queue, employee docs |
| Admin | Everything + user management, roles, system settings, track types |

---

## Key Functional Decisions

### Kanban Board
- Track types: Production, R&D/Tooling, Maintenance, Other + custom
- Cards move backward unless QB document at that stage is irreversible (Invoice, Payment)
- Multi-select: `Ctrl+Click`, bulk actions (Move, Assign, Priority, Archive)
- SignalR real-time sync, last-write-wins, optimistic UI
- Cards archived (never deleted)
- Column body: white background (`--surface`) with 2px inset border matching stage color via `--col-tint` CSS custom property

### Production Track Stages (QB-aligned)
Quote Requested → Quoted (Estimate) → Order Confirmed (Sales Order) → Materials Ordered (PO) → Materials Received → In Production → QC/Review → Shipped (Invoice) → Invoiced/Sent → Payment Received (Payment)

### Planning Cycles
- Default 2 weeks (configurable). Day 1 = Planning Day with guided flow
- Split-panel: backlog (left) → planning cycle (right), drag to commit
- Daily prompts: Top 3 for tomorrow each evening
- End of cycle: incomplete items roll over or return to backlog

### Activity Log
- Per-entity chronological timeline (job, part, asset, lead, customer, expense)
- Batch field changes collapse into expandable entries
- Inline comments with @mentions → notification
- Filterable by action type and user. Immutable entries.

### Reference Data
- Single `reference_data` table for all lookups (expense categories, lead sources, priorities, statuses, etc.)
- Recursive grouping via `group_id`. `code` immutable, `label` admin-editable. `metadata` JSONB.
- One admin screen manages everything — no scattered lookup tables

### User Preferences
- Centralized `user_preferences` table, key-value: `table:{id}`, `theme:mode`, `sidebar:collapsed`, `dashboard:layout`
- `UserPreferencesService` loads on init, caches in memory, debounced PATCH on change
- Restored on login from any device

---

## Printing & PDF
- `@media print` stylesheet: hides nav, toolbar, sidebar, interactive controls
- Printable views: work order, packing slip, QC report, part spec, expense report
- QR/barcode labels: bwip-js + angularx-qrcode, configurable label sizes
- Server-side PDF: QuestPDF — `GET /api/v1/jobs/{id}/pdf?type=work-order`

---

## What NOT to Do

- Never use `FormsModule` / `ngModel` in features — always `ReactiveFormsModule`
- Never use raw `<input>`, `<select>`, `<textarea>` — always shared wrappers
- Never build custom dialog shells — always `<app-dialog>`
- Never hardcode colors, spacing, font sizes, border radius in component SCSS
- Never use `*ngIf` / `*ngFor` — use `@if` / `@for`
- Never use `!important` unless overriding third-party (with comment)
- Never nest SCSS more than 3 levels
- Never use "DTO" suffix — use `*ResponseModel` / `*RequestModel`
- Never send date-only strings to the API — always include time + UTC zone
- Never put multiple classes/enums/components in one file
- Never use barrel files (`index.ts`) for re-exports
- Never use inline templates or inline styles
- Never use function calls in template bindings — use computed signals
- Never use constructor injection — use `inject()`
- Never use `console.log` in production code
- Never hardcode z-index values — use `$z-*` variables
- Never use `try/catch` in controllers — middleware handles exceptions
- Never use data annotations on entities — use Fluent API configuration
- Never hard-delete records — always soft delete via `DeletedAt`
- Never use `mat-error` / inline validation — use `ValidationPopoverDirective`
- Never deep-override Material internals with CSS — build a custom component instead
- Never put HTTP calls in components — always in services
- Never use `*` or `ng-deep` to override child component styles
- Never suppress lint/analysis warnings without a comment explaining why
