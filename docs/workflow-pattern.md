# Workflow Pattern Design

A reusable creation/editing pattern for entities that span a spectrum of complexity — from quick one-shot adds to multi-step guided flows with sub-concepts that deserve focused screens. Picks per-record, switchable post-creation, persistent across sessions.

## Goal

One pattern, one infrastructure, applied across many entity types (parts, customers, vendors, quotes, sales orders, work orders, employees, assets, compliance forms, …) so the user gets consistent behavior and the codebase has one well-understood implementation instead of N bespoke wizards.

## Constraints that shaped the design

- **Solo / small-team operator.** Friction matters more than feature richness. Every flow needs a low-friction default; complexity is opt-in.
- **Existing entity tables are the source of truth.** A workflow is metadata about *how* a user is filling a record in, not a parallel staging schema.
- **Resumability is non-negotiable.** Users leave and come back hours or days later. Drafts already have an existing pattern (`DraftService`); workflow state extends it.
- **No tooling lock-in.** The shell is generic; per-entity definitions plug in.

## Decisions

Codified from the design conversation 2026-04-29.

### D1 — Storage model: entity-from-step-1, `status='Draft'`

The entity row exists from the moment the workflow starts. Each step writes incrementally to the entity's existing tables. A `status='Draft'` flag (or equivalent per-entity) tells the rest of the application "ignore this for now."

Pros:
- The in-flight record can be referenced by other in-flight records (a quote can reference a draft assembly without staging duplication)
- Audit history works naturally — every change is a real DB write
- Edits and creates use the same code paths

Cons:
- Other code must respect the draft filter (mirrors how `DeletedAt IS NULL` global filters already work in this codebase)
- Cancellation must explicitly delete the draft (or roll forward to a `Cancelled` status)

**Rejected alternative**: stage step inputs in `workflow_runs.step_states` jsonb and commit to the entity only on completion. Cleaner separation, but unfriendly to the cross-record-reference case and duplicates the data model.

### D2 — Step ordering: hybrid (linear forward, navigable back)

First run through is **linear** — step N+1 is disabled until step N is complete. Once step N is complete, a left-hand step guide enables click-back to any earlier completed step.

**Step rail clickability rules:**
- Step is **clickable** if it is the **current step** OR a **completed step** (anything to the left of current in the linear flow)
- Step is **locked (non-clickable)** if it is a **future step** (anything to the right of current that hasn't yet been reached)

On re-entry to an in-flight or completed workflow, the same rules apply. The user can navigate back to any completed step at any time. Re-edits trigger entity-audit rows in the normal way.

This gives the user the wizard's hand-holding on first encounter and the random-access freedom of a process map after they know the shape.

### D3 — Financial complexity: three layers of inheritance, last one wins

The costing-mode discriminator (Tier 1 flat / Tier 2 departmental / Tier 3 ABC) is resolvable at three layers, with the most specific winning:

1. **Install default**: the active `CostingProfile.mode` for the install (Tier 1 by default for new installs).
2. **Per-entity-type default**: optional override per entity type — e.g., "all assemblies on this install use Tier 2 even though the install default is Tier 1." Stored as a setting keyed by entity type.
3. **Per-record override**: optional override on the individual record — e.g., "this specific assembly uses Tier 1 because it's so simple, even though all other assemblies use Tier 2." Stored as a nullable column on the entity (`costing_mode_override`).

Resolution order at calc time:
```
record.costing_mode_override
  ?? entity_type_default_costing_mode  
  ?? active_profile.mode
```

UI implication: the costing step of an entity's workflow shows a radio/dropdown:
- **Use default** (shows what the inherited tier resolves to)
- **Tier 1 — Flat rate**
- **Tier 2 — Departmental rates** (only if `CAP-COSTING-DEPARTMENTAL` enabled)
- **Tier 3 — Activity-based costing** (only if `CAP-COSTING-ABC` enabled)

Each entity type has a sensible default complexity level. Users can override at the record level when they need more detail than the default offers, or simpler than the default imposes.

| Entity type | Default | Override path |
|---|---|---|
| Quote | Derived (auto-roll-up from contained assemblies) | Manual override at line-item level |
| Estimate | Manual entry of input-expense buckets | Auto-derive when the source job/assembly has enough data |
| Part — raw material | Static price | Switch to costing profile / dynamic |
| Part — assembly | Costing profile (rolled up from BOM + routing + overhead) | Manual price override on the assembly |
| Sales Order | Roll-up from contained quote/parts | Manual line override |
| Work Order | Inherit from part costing | Manual labor / material override |

**Auto-graduation principle**: when associated entities accumulate enough data (e.g., three production runs of a part with measured actuals), the system *suggests* graduating the record from static to dynamic costing. User accepts or declines; if accepted, the next render presents the dynamic surface.

**Schema for per-record override** (per affected entity type):
```
ALTER TABLE parts ADD COLUMN costing_mode_override varchar(16) NULL
  CHECK (costing_mode_override IN ('flat','departmental','abc') OR costing_mode_override IS NULL);
```
Same column added to other cost-bearing entities (sales-order line, work order, etc.) where per-record override makes sense. The audit log captures who set the override and when, so cost variance investigation has a forensic trail.

### D4 — Express vs. Guided fork persists post-creation, available throughout

Both paths edit the same data. The user's choice at creation is just the *initial* surface; they can switch **at any point — including mid-workflow** — via a header toggle on the record's detail page.

Default for new records on a per-entity-type basis:
- **Quick path**: low-friction default. Single-step. All visible fields.
- **Guided path**: revealed via "Set up step-by-step" affordance on the create flow.

**Mid-flow switching is intentional.** A user halfway through a guided assembly setup can toggle to express, see all fields at once (preview-style), and switch back. Visual transition may feel jarring on first use but the value of letting users *preview* the data-heavy edit shape outweighs the consistency cost — and over time the user builds intuition for both shapes.

Once a record exists, both paths render the same detail page in their respective shapes — the data is the data. The toggle in the header lets the user pick.

### D6 — Entity readiness is the source of truth for completeness; workflow steps reference it

**The split:**

| Concept | Owns |
|---|---|
| **Entity status** (`Draft` / `Active` / etc.) | Whether the entity is functionally complete |
| **Entity readiness validators** | Defined at the entity level. List of named conditions that must pass to leave Draft. |
| **Workflow steps** | Guided UX path to fill the entity to a state where readiness passes. **References** entity readiness gates by name; doesn't define its own predicates. |

This separation matters because:
- **"This needs attention" is broader than workflow.** A user can promote `Draft → Active` from the entity detail page directly without ever opening a workflow. The workflow is one way to fill the entity in; not the only way.
- **Status is the source of truth.** A Part is complete iff its readiness validators pass and the user (or the workflow) has promoted it. List pages filter by status; they never need to evaluate workflow-level predicates.
- **Pre-existing entities are unambiguous.** They're already `Active`. They satisfied readiness when they got promoted. The workflow concept doesn't touch them.

**Entity readiness validators are stored as data in the database**, not hardcoded. This lets workflows be reauthored without code releases and lets the same DSL evaluator drive every entity type.

```sql
CREATE TABLE entity_readiness_validators (
  entity_type           varchar(64),
  validator_id          varchar(64),       -- 'hasBom'
  predicate             jsonb,             -- the DSL expression
  display_name_key      varchar(128),      -- i18n key — canonical noun ("BOM")
  missing_message_key   varchar(128),      -- i18n key — failure phrasing ("BOM not yet defined")
  PRIMARY KEY (entity_type, validator_id)
);

CREATE TABLE workflow_definitions (
  id              varchar(64) PK,           -- 'part-assembly-guided-v1'
  entity_type     varchar(64),
  default_mode    varchar(16),
  steps           jsonb,                    -- ordered list with completionGates references
  express_template_component varchar(128)
);
```

`display_name_key` is the validator's canonical noun (used in admin listings, generic listings); `missing_message_key` is the failure phrasing (used in status-promotion error responses, row-level enrichment "Draft — missing BOM"). Workflow steps have their OWN `labelKey` in the workflow definition, separate from the validator's display name — same validator can appear under different step labels in different workflow variants.

**Predicate DSL** (data-form, evaluated by a shared interpreter on each tier):



```typescript
// Defined on or near the entity model
const partReadiness = {
  hasBasics: {
    code: (p) => !!(p.name && p.type && p.material),
    missingMessage: 'workflow.parts.readiness.basicsMissing',
  },
  hasBom: {
    code: (p) => p.bomEntries?.length > 0,
    missingMessage: 'workflow.parts.readiness.bomMissing',
  },
  hasRouting: {
    code: (p) => p.operations?.length > 0,
    missingMessage: 'workflow.parts.readiness.routingMissing',
  },
  hasCost: {
    code: (p) => p.manualCostOverride != null || p.currentCostCalculationId != null,
    missingMessage: 'workflow.parts.readiness.costMissing',
  },
};

// Used by entity-level "promote to Active" gate
function canPromoteToActive(part) {
  return Object.values(partReadiness).every(v => v.code(part));
}
```

**Workflow steps reference these validators by name:**

```typescript
interface StepDefinition {
  id: string;
  i18nKey: string;
  componentName: string;
  required: boolean;
  // The step is "complete" when these named entity validators all pass.
  // No predicate defined here — just a reference into the entity's
  // readiness map. Single source of truth.
  completionGates: string[];   // e.g., ['hasBasics']
}

// Example for part-assembly-guided-v1:
{ id: 'basics',     completionGates: ['hasBasics'],   ... },
{ id: 'bom',        completionGates: ['hasBom'],      ... },
{ id: 'routing',    completionGates: ['hasRouting'],  ... },
{ id: 'costing',    completionGates: ['hasCost'],     ... },
{ id: 'alternates', completionGates: [],   required: false, ... },  // optional
```

**Where validators evaluate:**

| Case | Where | API roundtrip? |
|---|---|---|
| Workflow component (single record loaded) | UI-tier (TS validators) | No |
| Entity detail page rendering "promote eligible?" badge | UI-tier (TS validators) | No |
| List page filtering / "needs attention" | Server-side (filter by `status='Draft'`) | One — the list query itself |
| `POST /entities/{id}/promote-status` enforcement | Server-tier (C# twin validators) | Yes — authoritative gate |

**No SQL fragment, no bulk progress endpoint, no list-level predicate evaluation.** Status is enough for the list-page case; it always was.

**workflow_runs is still needed** — but only for user experience metadata:
- `mode` — current presentation choice (express vs. guided)
- `current_step_id` — resume target
- `last_activity_at` — resume affordances and TTL cleanup
- Abandonment tracking
- The few optional steps with no data side-effect (e.g., "review and acknowledge")

**Mark Complete in a workflow** is sugar for "promote entity status." Same validation, different UX entry point. The workflow's completion button calls the entity's promotion API; if validators pass → `status='Active'`. If they don't → workflow shows "Missing: BOM, routing" with jump-to links to the offending steps.

### D5 — Cost recalc (proposed, deferred to later phase)

A future *Costing Engine* phase will add:
- A `costing_calculations` history table — snapshots of inputs at calc time, the profile version used, the resulting numbers
- A "recalculate from current profile" button on cost-bearing records — produces a diff between stored and freshly-calculated values; user accepts or rejects
- Hangfire job for batch recalc across an entity type when a profile changes

This phase doesn't depend on workflow infrastructure but should be designed alongside D3 so the shape stays consistent.

## Storage schema

### `workflow_runs` (new) — UX metadata only

Per D6, step completion is derived from entity data, not stored. `workflow_runs` only tracks user-experience metadata.

| Column | Type | Notes |
|---|---|---|
| `id` | int PK | |
| `entity_type` | varchar(64) | `'Part'`, `'Customer'`, `'Quote'`, etc. |
| `entity_id` | int | FK to the entity's table; NOT a real FK constraint because of polymorphism |
| `definition_id` | varchar(64) | which `WorkflowDefinition` this run uses (pinned at start, e.g., `'part-assembly-guided-v1'`) |
| `current_step_id` | varchar(64) nullable | last step the user was on (resume target) |
| `mode` | varchar(16) | `'express'` \| `'guided'` (current presentation choice) |
| `started_at` | timestamptz | |
| `started_by_user_id` | int | |
| `completed_at` | timestamptz nullable | null while in flight; auto-derives from "all required predicates pass" but user must explicitly mark complete |
| `abandoned_at` | timestamptz nullable | TTL-driven or user-initiated cleanup |
| `abandoned_reason` | varchar(64) nullable | `'expired'`, `'user'`, `'definition-deprecated'`, etc. |
| `last_activity_at` | timestamptz | for "resume" prompts and TTL cleanup |
| `row_version` | uint8[] | optimistic locking |

One row per (entity_type, entity_id) — UNIQUE constraint. Pre-existing entities have NO workflow_run row (and don't need one — predicates work on raw data state).

### `costing_profiles` (new — for D3 / D5)

| Column | Type | Notes |
|---|---|---|
| `id` | int PK | |
| `code` | varchar(64) | stable identifier (e.g., `default`, `precision-shop-2026`) |
| `mode` | varchar(16) | `'flat'` \| `'departmental'` \| `'abc'` |
| `flat_rate_pct` | decimal(7,4) nullable | for `flat` mode |
| `departmental_rates` | jsonb nullable | `[{cost_center_id, rate_pct}]` for `departmental` |
| `pools` | jsonb nullable | `[{pool_id, name, total_amount, driver, allocation}]` for `abc` |
| `effective_from` | date | versioning — multiple profiles can coexist with non-overlapping date ranges |
| `effective_to` | date nullable | |
| audit cols | | |

Active profile resolved by date; calc snapshots the profile id+version they used.

## API resource

### `WorkflowDefinition` (static, code-defined)

A record describes the steps for a given entity type's flow. Lives in the codebase (TypeScript / C# constants) — not in the DB — because steps are tightly coupled to UI components.

```typescript
interface WorkflowDefinition {
  id: string;                   // 'part-assembly-guided-v1'
  entityType: 'Part' | 'Customer' | ...;
  steps: StepDefinition[];
  defaultMode: 'express' | 'guided';
  expressTemplateComponent: string;  // 'PartExpressFormComponent'
}

interface StepDefinition {
  id: string;                   // 'basics', 'bom', 'routing', 'pricing'
  i18nKey: string;              // 'workflow.parts.steps.basics'
  componentName: string;        // 'PartBasicsStepComponent'
  required: boolean;            // can this step be skipped?
  validatesEntityFields: string[];  // for cross-step coherence
}
```

### Endpoints

```
POST   /api/v1/workflows                      Start a new run
       body: { entityType, definitionId, mode, initialEntityData? }
       returns: { runId, entityId, currentStepId }

GET    /api/v1/workflows/{runId}              Get current state + computed step progress
PATCH  /api/v1/workflows/{runId}/step         Save current step's fields, advance pointer
       body: { stepId, fields }
       (step "completion" is derived per D6; advancing the pointer just
        moves current_step_id and validates prior step's predicate passes)
PATCH  /api/v1/workflows/{runId}/jump         Navigate to a different step
       body: { targetStepId }
       (server validates targetStepId is current OR an earlier completed
        step per D2 rules — derived predicates re-evaluated)
POST   /api/v1/workflows/{runId}/complete     Mark run done; flip entity status Draft → Active
                                               (server verifies all required steps' predicates pass)
POST   /api/v1/workflows/{runId}/abandon      Cancel and remove the draft entity
PATCH  /api/v1/workflows/{runId}/mode         Toggle express ↔ guided
GET    /api/v1/workflows/active               Current user's in-flight runs (for resume prompts)

# Entity-level promotion (the actual completion gate — not a workflow concern)
POST   /api/v1/parts/{id}/promote-status      Promote Draft → Active (or other transitions)
       (server runs entity readiness validators; returns 200 + new status on pass,
        409 + missing-validator list on fail. The workflow's "Mark Complete"
        button delegates to this endpoint; no separate completion enforcement.)
```

List pages don't need progress — `status='Draft'` is sufficient. The entity layer's status filter answers "what needs attention."

## UI shell

### `WorkflowComponent`

Generic shell that takes a `WorkflowDefinition` and the current run state, renders:

- **Top header bar**: entity title, current step, mode toggle (Express ↔ Guided), Close
- **Left rail (guided mode only)**: step guide with completion indicators; clickable for completed steps, locked for upcoming
- **Center pane**: the current step's component (provided by the entity feature module)
- **Footer**: Save/Continue/Back; Skip (when step is `required: false`)

Express mode hides the left rail and renders all steps stacked in a single scrollable form.

### Per-entity feature modules provide:

- `WorkflowDefinition` (one or more variants per entity type — e.g., `part-raw-material-express`, `part-assembly-guided`)
- Per-step component implementations
- Per-entity express-form component

The shell stays generic; the entity provides the content.

### Resume affordances

- Dashboard widget: "X drafts in progress" with quick-jump to most recent
- Notification on entity-list pages: "You have an in-flight assembly setup — Resume?"
- After login: if any drafts have `last_activity_at` within 7 days, soft-prompt to resume

## Overhead model (proposal — see D5)

### Three tiers, ordered by sophistication

**Tier 1 — Flat rate** (default for new installs)
- One number: `overhead_rate_pct` in `system_settings` or `costing_profiles[mode='flat']`
- Applied uniformly: `overhead = direct_cost × rate`
- Setup time: <1 minute
- Accuracy: business-wide average; fine for small shops

**Tier 2 — Departmental rates**
- Per-cost-center percentage applied based on routing
- Stored in `costing_profiles[mode='departmental']`
- Setup time: an hour to enumerate cost centers and rates
- Accuracy: meaningful for shops with mixed labor pools

**Tier 3 — Activity-based costing (ABC)**
- Cost pools (rent, utilities, supervision, depreciation) allocated by drivers (square footage, kWh, machine hours, labor hours)
- Stored in `costing_profiles[mode='abc']` with `pools` jsonb
- Setup time: a day; sometimes ongoing as drivers shift
- Accuracy: the standard answer for >50-person operations

**Graduation path**: install starts at Tier 1. When the system observes enough variance between tier-1-derived cost and tier-2/3-suggested cost, the dashboard surfaces a "consider activating departmental rates" recommendation. User-initiated, never automatic.

### Capability gating

Treat tier 2 and tier 3 as **capabilities** in the Phase 4 sense:
- `CAP-COSTING-DEPARTMENTAL` (default-off; admin enables when ready)
- `CAP-COSTING-ABC` (default-off; admin enables when ready)

Tier 1 has no capability — it's the always-available baseline. Disabling tier-2/3 falls back gracefully to tier-1.

## Entity types — rolling list

Status legend: ⚪ not designed · 🟡 designing · 🟢 designed · 🔵 implementing · ✅ implemented

| Entity | Status | Express variant | Guided variant | Notes |
|---|---|---|---|---|
| Part — raw material | ⚪ | quick-add | (none — express only) | low complexity, no sub-concepts |
| Part — assembly | ⚪ | quick-add | basics → BOM → routing → costing → alternates | the trigger case |
| Customer | ⚪ | quick-add | basics → addresses → contacts → terms → pricing | enterprise customers benefit |
| Vendor | ⚪ | quick-add | basics → addresses → contacts → terms → banking → approval | similar to customer |
| Quote | ⚪ | quick-add | header → lines → roll-up review → send | financial roll-up at "review" |
| Estimate | ⚪ | quick-add | header → input expenses → margin → present | manual financial entry |
| Sales Order | ⚪ | quick-from-quote | header → lines → terms → fulfillment plan | quote-to-SO is its own flow |
| Work Order / Job | ⚪ | quick-add | basics → routing → labor plan → material plan | inherits from part |
| Employee onboarding | ⚪ | (none — guided only) | identity → tax forms → benefits → compliance training → kiosk credentials | already wizard-shaped |
| Asset commissioning | ⚪ | quick-add | basics → location → maintenance plan → depreciation | depreciation only when capability on |
| Compliance form | ⚪ | (none — guided only) | already a workflow; integrate with this pattern | W-4, I-9, state withholding |
| Setup wizard | ✅ | — | already a workflow | adapt to new shell? lower priority |

## Worked example: `part-assembly-guided-v1`

To concretize the abstract design, here's how Part-Assembly creation maps end-to-end.

**Entity readiness validators (stored in `entity_readiness_validators`, seeded once):**

```jsonc
// (entity_type='Part', validator_id='hasBasics')
{ "type": "all", "of": [
    {"type":"fieldPresent","field":"name"},
    {"type":"fieldPresent","field":"type"},
    {"type":"fieldPresent","field":"material"}
]}

// (entity_type='Part', validator_id='hasBom')
{ "type": "relationExists", "relation": "bomEntries", "minCount": 1 }

// (entity_type='Part', validator_id='hasRouting')
{ "type": "relationExists", "relation": "operations", "minCount": 1 }

// (entity_type='Part', validator_id='hasCost')
{ "type": "any", "of": [
    {"type":"fieldPresent","field":"manualCostOverride"},
    {"type":"fieldPresent","field":"currentCostCalculationId"}
]}
```

**WorkflowDefinition (references the readiness gates by name):**
```typescript
{
  id: 'part-assembly-guided-v1',
  entityType: 'Part',
  defaultMode: 'guided',  // for assemblies; raw materials default 'express'
  expressTemplateComponent: 'PartExpressFormComponent',
  steps: [
    { id: 'basics',     completionGates: ['hasBasics'],  componentName: 'PartBasicsStepComponent',     required: true },
    { id: 'bom',        completionGates: ['hasBom'],     componentName: 'PartBomStepComponent',        required: true },
    { id: 'routing',    completionGates: ['hasRouting'], componentName: 'PartRoutingStepComponent',    required: true },
    { id: 'costing',    completionGates: ['hasCost'],    componentName: 'PartCostingStepComponent',    required: true },
    { id: 'alternates', completionGates: [],             componentName: 'PartAlternatesStepComponent', required: false },
  ],
}
```

**Lifecycle of one part:**

1. User clicks "New Assembly" on /parts list page
2. UI calls `POST /api/v1/workflows` with `{entityType: 'Part', definitionId: 'part-assembly-guided-v1', mode: 'guided', initialEntityData: {...}}`
3. Server creates `parts` row with `status='Draft'` and `workflow_runs` row with `current_step_id='basics'`
4. UI navigates to `/parts/{id}?workflow=part-assembly-guided-v1` and mounts WorkflowComponent
5. User fills basics fields → `PATCH /api/v1/workflows/{runId}/step` with `{stepId: 'basics', fields: {...}}` → server saves to `parts` table
6. User clicks "Next" → server re-evaluates `basics.completionPredicate`, confirms it passes, advances `current_step_id='bom'`
7. User builds out BOM via the BOM step component (which writes to `bom_entries`)
8. User clicks back to "basics" via the step rail (allowed — completed step). Edits a field. Saves. Step rail still shows basics complete (predicate still passes).
9. User reaches costing, picks "Tier 1 — Flat rate" override + types a price
10. User reaches alternates, skips (optional)
11. User clicks "Mark Complete" → workflow component delegates to `POST /api/v1/parts/{id}/promote-status` → server runs entity readiness validators → all required pass → flips `status='Active'`, sets `workflow_runs.completed_at`
12. Part now appears in the live /parts list, available for use in quotes / sales orders / etc.

**Alternative: user promotes status directly without a workflow.** A user editing an existing draft entity (perhaps imported from CSV with all required fields) can click "Promote to Active" on the detail page. Same readiness validators run; same outcome. No workflow involved.

**Meanwhile, the /parts list page renders 50 parts:** filters by `status` (drafts vs active separately), no per-row predicate evaluation. Status alone tells the user which records need attention.

## Implementation phases

| Phase | Deliverable |
|---|---|
| 1 | This design doc — captured |
| 2 | Schema: `workflow_runs` (UX metadata only per D6), `workflow_run_entities` junction (per Q3), `costing_profiles`, `cost_calculations`, `cost_calculation_inputs`. EF migration. Per-entity `manual_cost_override` + `current_cost_calculation_id` columns on cost-bearing entities. `status='Draft'` enum value. |
| 3 | Base API resource — workflow CRUD. Per-entity readiness validators (TS for UI; C# twin for server `promote-status` enforcement). Cross-language drift test asserts both agree on known inputs. No bulk progress endpoint — list pages filter by status. |
| 4 | `WorkflowComponent` UI shell — step-rail with D2 clickability rules, mode-toggle (D4 always-available), resume infrastructure. |
| 5 | First end-to-end vertical slice: **Part — assembly guided variant**. Validates the pattern. Per-step components for parts: basics, BOM, routing, costing (tier-1 only), alternates. |
| 6 | **Part — raw material** as the express-only sibling. Validates that `mode='express'` against the same WorkflowDefinition works correctly. |
| 7 | `CostingProfile` API + tier-1 (flat-rate) costing applied during assembly creation. Manual override UX. |
| 8 | Drafts ↔ workflow_runs handoff. Express-form draft → entity creation → workflow_run takeover, draft cleanup. |
| 9 | Roll out next 2-3 entity types per the rolling list — picks based on user pain points (likely customer or quote next). |
| 10 | (Future) Tier-2 / Tier-3 costing modes; cost-recalc tool (D5 implementation populates the `cost_calculations` interface already in place). |
| 11 | (Future) Graduation suggestions; recalc batch jobs. TTL cleanup Hangfire job. |

Phases 1–8 establish the substrate. Phase 9+ are entity-type-by-entity-type rollouts at lower ceremony per entity once the base library is proven.

## D3 ↔ D5 interface (lock-in)

D5 (cost recalc engine) will eventually drive D3 (which numbers display per part / quote / etc.). The interface contract is locked in NOW so D5 work later just *populates* the contract instead of reshaping the data model.

**Contract**: cost-bearing entities read their current cost from a `CostCalculation` snapshot if one exists, else fall back to a manually-entered value.

**Schema additions made now** (table empty until D5 lands):

```sql
CREATE TABLE cost_calculations (
  id               int PK,
  entity_type      varchar(64),       -- 'Part', 'Quote.line', 'WorkOrder', etc.
  entity_id        int,
  profile_id       int FK costing_profiles,
  profile_version  int,                -- snapshot of profile at calc time
  result_amount    decimal(18,4),
  result_breakdown jsonb,              -- direct material, direct labor, overhead
  calculated_at    timestamptz,
  calculated_by    int nullable,       -- user (manual) or null (job-driven)
  is_current       bool                -- true on the latest per entity
);

-- Inputs get their own normalized table with structured columns for the
-- common cases plus jsonb for tier-3 ABC / custom drivers. This avoids
-- a single jsonb blob that becomes hard to query / index / migrate.
CREATE TABLE cost_calculation_inputs (
  id                       int PK,
  cost_calculation_id      int FK cost_calculations UNIQUE,
  -- Common structured inputs (most calculations use these)
  direct_material_cost     decimal(18,4) nullable,
  direct_labor_hours       decimal(10,2) nullable,
  direct_labor_cost        decimal(18,4) nullable,
  machine_hours            decimal(10,2) nullable,
  overhead_amount          decimal(18,4) nullable,
  overhead_rate_pct        decimal(7,4)  nullable,
  -- Tier-3 ABC pools, custom drivers, future expansion
  custom_inputs            jsonb         nullable
);

ALTER TABLE parts
  ADD COLUMN current_cost_calculation_id int NULL FK cost_calculations,
  ADD COLUMN manual_cost_override        decimal(18,4) NULL;

-- (similar additions to other cost-bearing entities)
```

**Read logic** (D3, today and forever):
```
displayed_cost(record) =
  record.manual_cost_override          (user pinned a value)
  ?? cost_calculations[current_cost_calculation_id].result_amount  (D5)
  ?? null                              (no calc yet — show "Set price" / "Recalculate")
```

Manual override always wins (per-record D3 freedom). Until D5 ships, only `manual_cost_override` is ever populated. After D5, recalcs populate `cost_calculations` rows and update `current_cost_calculation_id`.

## Resolved questions (formerly open)

### Q1 — Multiple in-flight runs per entity?

**Resolved: NO. One run per entity (UNIQUE constraint stays).**

Competing designs use the existing "alternates" relationship — two parts, marked as alternates, each with its own workflow_run. Branched drafts on a single entity would require diff/merge UI for which there's no demand.

### Q2 — Workflow definition versioning

**Resolved: pin definition_id at run start; new definitions affect only new runs.**

`WorkflowDefinition.id` includes a version suffix (`part-assembly-guided-v1`, `-v2`). In-flight runs stay on their pinned definition until completed or abandoned. Migrating an in-flight run to a new definition requires explicit user action (audit-trailed).

### Q3 — Cross-entity workflows

**Resolved: one workflow_run with multiple entity refs via junction table.**

```sql
CREATE TABLE workflow_run_entities (
  run_id      int FK workflow_runs,
  entity_type varchar(64),
  entity_id   int,
  role        varchar(32),         -- 'primary', 'tax-form', 'training', ...
  PRIMARY KEY (run_id, entity_type, entity_id)
);
```

Steps reference `(entity_type, entity_id)` from this junction. The primary entity stays on the `workflow_runs` main row for the common single-entity case; the junction lets multi-entity flows (employee onboarding, quote-to-SO conversion) declare additional bound entities.

### Q4 — Audit granularity

**Resolved: split into two complementary lenses.**

- **Workflow audit** = step-level events (started, completed, jumped, mode-toggled, abandoned). Stored as `eventType='WorkflowStep…'` rows in the existing `audit_log_entries` table.
- **Entity audit** = per-row-write events. Already covered by Phase 4's existing audit infrastructure (WU-A2). Entity-row audit rows that originate from inside a workflow get a `workflow_run_id` and `step_id` attribution so cost-variance investigation can trace back: "this BOM row was added during step 3 of the part-assembly-guided workflow on Apr 29 by Jane."

The two audits link via `workflow_run_id`. No duplication; complementary lenses.

### Q5 — Drafts (`DraftService`) vs workflow_runs

**Resolved: coexist with sharp role boundaries.**

- **DraftService = form-state autosave for unsubmitted state.** Open dialog, user types, hasn't clicked Submit. Persists in IndexedDB / via existing draft pattern. Has a TTL. Disappears once submitted or explicitly discarded. **No DB row in workflow_runs** until the user submits.
- **workflow_runs = persisted workflow state for entities that have been *started*.** "Started" = user clicked Create (express) or Begin (guided), the entity now has a `Draft` row, the workflow run is tracking progress.

**Transition**: a draft autosave becomes a workflow run when the user clicks the form's primary action. The draft entry is deleted; the workflow_run takes over. This preserves the express path's lazy-commit UX (no DB pollution from abandoned what-ifs) while using the unified workflow model once the user commits.

## Relationship to other phases

- **Phase 4 (capability gating)**: complexity tiers (departmental, ABC costing) are capability-gated. Workflow definitions can also be capability-gated where appropriate.
- **Phase 5 (user-axis customization)**: this design lays groundwork for the "logic-API-side, semantic-verbs" architecture Phase 5 envisioned. The `WorkflowDefinition` API resource is a semantic verb in Phase 5's terms. Alternative shells (Factorio-style, savant tuple view) would consume the same API.
- **Drafts** (`DraftService`): existing draft infrastructure overlaps with workflow runs. They serve similar purposes — both persist in-progress edits across sessions. The workflow pattern formalizes what drafts handle ad-hoc. Implementation should consider: do workflow runs *replace* drafts for entities they cover, or *coexist* (drafts for express-mode partial saves, workflow runs for guided-mode multi-step)?

## Notes for the next implementation pass

- The workflow shell should mount inside the entity's own routing structure — `/parts/123` shows part 123 as a normal detail page; `/parts/123?workflow=part-assembly-guided` mounts the WorkflowComponent over the same record. URL-as-source-of-truth applies (per CLAUDE.md rule).
- Step components should be small Angular components in the entity feature module; the shell registers them by name from the `WorkflowDefinition.steps[].componentName`.
- The mode-toggle in the header should *preserve current state* — switching from guided to express mid-flow shows everything in scrollable form with the user's progress markers; switching back returns to the same step.
