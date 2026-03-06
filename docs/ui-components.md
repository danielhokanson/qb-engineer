# UI Components — Shared Patterns & Specs

Companion to `coding-standards.md` Standards #34–37. This document covers reusable component patterns that appear across multiple features but are not yet spec'd in the shared component library. Each component below follows the same principles: lives in `shared/components/`, uses CSS variables and BEM, and has a well-defined public API.

Reference mockups: `mockups/02-compact-bold*.html`

---

## 1. Dashboard Widget Shell (`DashboardWidgetComponent`)

Generic wrapper for all dashboard widgets. Provides standardized header chrome with filter/sort/customize actions while the inner component owns the content and action behavior.

### Structure

```
┌─────────────────────────────────────────────────┐
│ [icon] TITLE  count-badge   [filter][sort][tune] │  ← header (static, never scrolls)
├─────────────────────────────────────────────────┤
│                                                 │
│  <ng-content>  ← inner widget component         │  ← body (scrollable)
│                                                 │
└─────────────────────────────────────────────────┘
```

### Usage

```html
<app-dashboard-widget
  title="Today's Tasks"
  icon="today"
  [count]="taskCount()"
  [widgetKey]="'todays-tasks'"
  [accent]="true">
  <app-todays-tasks-widget />
</app-dashboard-widget>
```

### Inputs

| Input | Type | Description |
|---|---|---|
| `title` | `string` | Header title text (uppercase, letter-spaced) |
| `icon` | `string` | Material icon name for the header |
| `count` | `number \| null` | Optional badge count displayed after title |
| `widgetKey` | `string` | Unique key for preference persistence |
| `accent` | `boolean` | If true, header uses `--header` background (dark bar). If false, uses `--surface` with `--border` bottom. Default: `false` |

### IoC Contract — `WidgetActionProvider`

Inner components optionally implement `WidgetActionProvider` to register contextual actions. The shell queries the projected content component for this interface on init.

```typescript
interface WidgetActionProvider {
  /** Available filter definitions. Empty array = no filter button shown. */
  filters: Signal<WidgetFilter[]>;

  /** Available sort fields. Empty array = no sort button shown. */
  sortFields: Signal<WidgetSortField[]>;

  /** Customization options. Null = no customize button shown. */
  customizeOptions: Signal<WidgetCustomizeConfig | null>;

  /** Called when user applies a filter */
  onFilterChange(filters: WidgetFilterState): void;

  /** Called when user changes sort */
  onSortChange(sort: WidgetSortState): void;

  /** Called when user applies customization */
  onCustomizeChange(config: WidgetCustomizeState): void;

  /** Optional extra header actions (e.g., "Cal" button on Today's Tasks) */
  headerActions?: Signal<WidgetHeaderAction[]>;
}

interface WidgetFilter {
  key: string;
  label: string;
  type: 'select' | 'multiselect' | 'date-range' | 'toggle';
  options?: { value: string; label: string }[];
}

interface WidgetSortField {
  key: string;
  label: string;
  defaultDirection?: 'asc' | 'desc';
}

interface WidgetHeaderAction {
  icon: string;
  label?: string;
  tooltip: string;
  action: () => void;
}
```

### Behavior

- If the inner component does not implement `WidgetActionProvider`, no action buttons render — just the title bar.
- If `filters` signal returns an empty array, the filter button is hidden. Same for `sortFields` and `customizeOptions`.
- Filter/sort open a dropdown overlay anchored to the button. Customize opens a side panel or dialog (contextual to the widget).
- Active filter state shown as a subtle indicator on the filter icon (dot or count).
- All filter/sort/customize state persisted per-user via `UserPreferencesService` keyed by `widget:{widgetKey}`.
- The shell provides the scroll container — inner widgets should not add their own overflow handling.

### Visual Variants

- **Accent header** (`accent="true"`): dark `--header` background, white text, accent-colored count badge. Used for hero widgets (Today's Tasks).
- **Standard header** (`accent="false"`): `--surface` background, `--text-secondary` text, `--border` bottom. Used for secondary panels (Jobs by Stage, Team Load, Activity, Deadlines).

---

## 2. List Panel (`ListPanelComponent`)

Scrollable list pattern used across dashboard widgets, notification feeds, activity logs, and detail panels. Provides the scroll container with optional empty state.

### Usage

```html
<app-list-panel [items]="tasks()" emptyIcon="task_alt" emptyMessage="No tasks today">
  <ng-template #item let-task>
    <app-task-list-item [task]="task" />
  </ng-template>
</app-list-panel>
```

### Inputs

| Input | Type | Description |
|---|---|---|
| `items` | `T[]` | Data array to iterate |
| `emptyIcon` | `string` | Material icon for empty state |
| `emptyMessage` | `string` | Text for empty state |
| `trackBy` | `TrackByFunction<T>` | Optional trackBy for ngFor |
| `dividers` | `boolean` | Show border-bottom between items (default: `true`) |

### Behavior

- Renders items via `ng-template` outlet — the parent owns the item template.
- When `items` is empty, shows centered empty state (icon + message).
- Scroll container uses `flex: 1; overflow-y: auto` to fill available height within a flex parent.
- Bottom border on every item including last (no `:last-child` removal — per design decision).
- Pairs with `DashboardWidgetComponent` body slot or any flex column container.

---

## 3. KPI Chip (`KpiChipComponent`)

Compact metric display card. Shows a value, label, and optional change indicator.

### Usage

```html
<app-kpi-chip
  [value]="'23'"
  label="Active"
  [change]="'+3'"
  changeDirection="up" />

<app-kpi-chip
  [value]="'4'"
  [valueColor]="'warn'"
  label="Overdue"
  [change]="'+2'"
  changeDirection="down" />
```

### Inputs

| Input | Type | Description |
|---|---|---|
| `value` | `string` | Display value (pre-formatted — allows "312h", "4", "$1.2k") |
| `label` | `string` | Uppercase label text |
| `change` | `string \| null` | Change indicator text ("+3", "On track", "-2%") |
| `changeDirection` | `'up' \| 'down' \| 'neutral'` | Colors the change text: up = `--success`, down = `--warn`, neutral = `--text-muted` |
| `valueColor` | `'default' \| 'warn' \| 'success' \| 'primary'` | Override color for the value text |

### Visual

- `--surface` background, `--border` 2px border
- Value: 20px bold, label: 9px uppercase `--text-secondary`, change: 10px colored
- Horizontal layout: value left, label + change stacked right
- Used in KPI stack (vertical column on dashboard) or inline in page headers

---

## 4. Activity Timeline (`ActivityTimelineComponent`)

Shared renderer for chronological activity feeds. Used on the dashboard Activity widget AND on per-entity detail views (job, part, asset, lead activity logs).

### Usage

```html
<!-- Dashboard widget mode (compact) -->
<app-activity-timeline
  [entries]="recentActivity()"
  variant="compact" />

<!-- Entity detail mode (full) -->
<app-activity-timeline
  [entries]="jobActivity()"
  variant="full"
  [filterable]="true"
  [commentable]="true"
  (commentSubmitted)="onComment($event)" />
```

### Inputs

| Input | Type | Description |
|---|---|---|
| `entries` | `ActivityEntry[]` | Chronological list (newest first) |
| `variant` | `'compact' \| 'full'` | Compact = icon + text + time (dashboard). Full = avatar + text + timestamp + old→new values (detail view). |
| `filterable` | `boolean` | Show filter controls (by action type, by user). Default: `false` |
| `commentable` | `boolean` | Show inline comment input. Default: `false` |

### ActivityEntry Model

```typescript
interface ActivityEntry {
  id: string;
  type: 'stage_move' | 'field_change' | 'file_attached' | 'comment' | 'assigned' | 'created' | 'system';
  icon: string;
  iconColor: string;
  text: string;            // rendered as HTML (bold entity refs)
  timestamp: Date;
  user?: { displayName: string; initials: string; color: string };
  isSystem: boolean;
  details?: { field: string; oldValue: string; newValue: string }[];  // for field_change
}
```

### Behavior

- **Compact variant**: flat list, icon + text + relative time. No avatars, no expand, no comments. Used in dashboard widget.
- **Full variant**: vertical timeline with user avatars, absolute timestamps, expandable batch edits ("Daniel updated 4 fields"), inline comment input, filter bar.
- Both variants use the same `ActivityEntry` model — compact simply renders fewer fields.
- System events render with a system icon and lighter styling.

---

## 5. Kanban Column Header (`KanbanColumnHeaderComponent`)

Header bar for each kanban board column. Follows the same action-button pattern as the dashboard widget shell but adds WIP limit awareness and column collapse.

### Usage

```html
<app-kanban-column-header
  [stage]="stage"
  [count]="cards().length"
  [wipLimit]="stage.wipLimit"
  [collapsed]="isCollapsed()"
  (toggleCollapse)="toggleCollapse()"
  (filterChange)="onColumnFilter($event)"
  (sortChange)="onColumnSort($event)" />
```

### Inputs

| Input | Type | Description |
|---|---|---|
| `stage` | `Stage` | Stage definition (name, color, icon) |
| `count` | `number` | Current card count in column |
| `wipLimit` | `number \| null` | WIP limit. When count >= wipLimit, header shows warning indicator |
| `collapsed` | `boolean` | Whether column is collapsed to a vertical bar |

### Visual

- Stage color bar on left edge (3px, same as mockup sidebar active indicator)
- Title: stage name, uppercase, letter-spaced
- Count badge (with WIP warning state: turns `--warn` when at/over limit)
- Action buttons: filter, sort (same icon pattern as dashboard panels)
- Collapse button: triple chevron (`‹‹‹` / `›››`)
- Collapsed state: rotated vertical text, count badge, expand button only

---

## 6. Status Badge (`StatusBadgeComponent`) — Extended Spec

Extends the brief spec in `coding-standards.md` Standard #34 with the design decisions from the mockup iteration.

### Visual Rules

- Fixed width: `48px`, `text-align: center` — ensures vertical alignment in lists regardless of text length ("Active" vs "Next" vs "Late")
- Font: 9px bold uppercase, 0.3px letter-spacing
- Border: 1px solid, color matches the text color (not the background)
- Background: light variant of the status color (`--success-light`, `--warn-light`, `--bg`)

### Status-to-Style Mapping

Resolved from reference data. Each status in the `reference_data` table has a `metadata.color` field that maps to a CSS variable group:

| Status Category | Text Color | Background | Border |
|---|---|---|---|
| Active / In Progress | `--success` | `--success-light` | `--success` |
| Upcoming / Pending | `--text-muted` | `--bg` | `--text-muted` |
| Overdue / Late / Blocked | `--warn` | `--warn-light` | `--warn` |
| Completed / Done | `--primary` | `--primary-light` | `--primary` |

### Dark Theme

Same variable names resolve to brighter 400-weight variants automatically. No per-badge dark mode overrides needed.

---

## 7. Quick Action Panel (`QuickActionPanelComponent`)

Touch-first action interface for the shop floor kiosk and Production Worker view. Large buttons optimized for gloved hands and dirty screens.

### Usage

```html
<app-quick-action-panel
  [worker]="currentWorker"
  [actions]="availableActions()"
  (actionSelected)="onAction($event)" />
```

### Inputs

| Input | Type | Description |
|---|---|---|
| `worker` | `Worker` | Current worker (for greeting, avatar) |
| `actions` | `QuickAction[]` | Available actions for current context |

### QuickAction Model

```typescript
interface QuickAction {
  key: string;
  icon: string;
  label: string;
  description?: string;
  color: 'primary' | 'success' | 'warn' | 'default';
  disabled?: boolean;
}
```

### Visual Rules

- Buttons: minimum 88x88px (double the 44px WCAG minimum — shop floor needs even larger targets)
- Grid layout: 2 columns on narrow kiosk, 3 on wider screens
- Large icon (32px) above bold label text (14px)
- High contrast: solid colored backgrounds, white text
- No hover effects — touch-only. Active state via press feedback (scale transform).
- Auto-return to idle after configurable timeout (default 30s)

---

## 8. Mini Calendar Widget (`MiniCalendarWidgetComponent`)

Dashboard-sized calendar for the calendar dashboard widget. Shows a month grid with event density per day.

### Usage

```html
<app-mini-calendar
  [events]="calendarEvents()"
  [month]="currentMonth()"
  (dayClicked)="onDayClicked($event)"
  (monthChanged)="onMonthChanged($event)" />
```

### Inputs

| Input | Type | Description |
|---|---|---|
| `events` | `CalendarEvent[]` | Events for the visible month |
| `month` | `Date` | Currently displayed month |

### Visual

- Compact month grid fitting within a dashboard widget panel (~140px–300px height)
- Day cells show colored dots for event density (1–3 dots, then a count)
- Today highlighted with `--primary` background
- Days with overdue items get `--warn` indicator
- Navigation: `‹` / `›` arrows in header to change month
- Click a day → emits `dayClicked` event (parent navigates to calendar day view or opens popover)
- Planning cycle boundaries shown as a subtle teal underline on start/end days

---

## Cross-Cutting Patterns

### Preference Persistence

All components with user-configurable state (column visibility, sort order, filter selections, collapsed state) persist via `UserPreferencesService`:

- Key pattern: `{componentType}:{instanceKey}` (e.g., `widget:todays-tasks`, `kanban-column:production`)
- Loaded on component init, saved with debounce on change
- Defaults defined by component, overridden by saved preferences

### Empty States

Every component that renders a list or data set must handle the empty case:

- Centered icon (24px, `--text-muted`)
- Message text (11px, `--text-secondary`)
- Optional call-to-action button
- Shared `EmptyStateComponent` for consistency (already spec'd in coding-standards.md)

### Scroll Containers

- Parent provides the height constraint (via flex layout)
- Component uses `flex: 1; overflow-y: auto` for its scrollable body
- Headers are `flex-shrink: 0` — always visible above scrolling content
- Bottom borders on all list items including last (no `:last-child` removal)
- Custom scrollbar styling via `_mixins.scss` scrollbar mixin (thin, themed)

### Header Action Buttons

Two visual variants used consistently across the app:

1. **Accent header buttons** (on `--header` background): transparent background, white text, `rgba(255,255,255,0.2)` border. Used on DashboardWidgetComponent with `accent="true"`.
2. **Panel header buttons** (on `--surface` background): 22x22px icon-only buttons, `--text-muted` color, hover to `--text` with `--bg` background (light) or `rgba(255,255,255,0.05)` (dark). Used on standard panels.
