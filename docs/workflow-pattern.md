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

On re-entry to an in-flight or completed workflow, the same rules apply:
- Steps the user has completed are navigable
- Steps not yet completed remain locked behind their predecessor

This gives the user the wizard's hand-holding on first encounter and the random-access freedom of a process map after they know the shape. Edits to any completed step are tracked separately (audit).

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

### D4 — Express vs. Guided fork persists post-creation

Both paths edit the same data. The user's choice at creation is just the *initial* surface; they can switch any time via a header toggle on the record's detail page.

Default for new records on a per-entity-type basis:
- **Quick path**: low-friction default. Single-step. All visible fields.
- **Guided path**: revealed via "Set up step-by-step" affordance on the create flow.

Once a record exists, both paths render the same detail page in their respective shapes — the data is the data. The toggle in the header lets the user pick.

### D5 — Cost recalc (proposed, deferred to later phase)

A future *Costing Engine* phase will add:
- A `costing_calculations` history table — snapshots of inputs at calc time, the profile version used, the resulting numbers
- A "recalculate from current profile" button on cost-bearing records — produces a diff between stored and freshly-calculated values; user accepts or rejects
- Hangfire job for batch recalc across an entity type when a profile changes

This phase doesn't depend on workflow infrastructure but should be designed alongside D3 so the shape stays consistent.

## Storage schema

### `workflow_runs` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | int PK | |
| `entity_type` | varchar(64) | `'Part'`, `'Customer'`, `'Quote'`, etc. |
| `entity_id` | int | FK to the entity's table; NOT a real FK constraint because of polymorphism |
| `definition_id` | varchar(64) | which `WorkflowDefinition` this run uses (e.g., `'part-assembly-guided-v1'`) |
| `current_step_id` | varchar(64) | step the user is on |
| `step_states` | jsonb | per-step: `{started_at, completed_at, completed_by_user_id, validation_status}` |
| `mode` | varchar(16) | `'express'` \| `'guided'` (the user's most recent choice; affects which surface renders by default) |
| `started_at` | timestamptz | |
| `started_by_user_id` | int | |
| `completed_at` | timestamptz nullable | null while in flight |
| `last_activity_at` | timestamptz | for "resume" prompts |
| `row_version` | uint8[] | optimistic locking |

One row per (entity_type, entity_id) — UNIQUE constraint. A workflow is the *story* of how this record was filled in; replaying with a new definition is a separate run-history entry tied via a `superseded_by_run_id`.

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

GET    /api/v1/workflows/{runId}              Get current state
PATCH  /api/v1/workflows/{runId}/step         Save current step + advance
       body: { stepId, fields, complete: bool }
PATCH  /api/v1/workflows/{runId}/jump         Navigate to a different step
       body: { targetStepId }
       (server validates targetStepId is reachable per D2 rules)
POST   /api/v1/workflows/{runId}/complete     Mark run done; flip entity status to Active
POST   /api/v1/workflows/{runId}/abandon      Cancel and remove the draft entity
PATCH  /api/v1/workflows/{runId}/mode         Toggle express ↔ guided
GET    /api/v1/workflows/{runId}/audit        Per-step change history
GET    /api/v1/workflows/active               Current user's in-flight runs (for resume prompts)
```

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

## Implementation phases

| Phase | Deliverable |
|---|---|
| 1 | This design doc — captured |
| 2 | `workflow_runs` table + EF migration + base API resource (CRUD on workflow runs) |
| 3 | `WorkflowComponent` UI shell + step-rail + mode-toggle + resume infrastructure |
| 4 | First end-to-end vertical slice: **Part — assembly guided variant**. Validates the pattern. |
| 5 | Re-implement **Part — raw material** as the express-only sibling. Validates the spectrum. |
| 6 | `CostingProfile` resource + tier-1 (flat-rate) implementation |
| 7 | Roll out next 2-3 entity types per the rolling list — picks based on user pain points |
| 8 | (Future) Tier-2 / Tier-3 costing modes; cost-recalc tool |
| 9 | (Future) Graduation suggestions; recalc batch jobs |

Phases 1–6 establish the substrate. Phases 7+ are entity-type-by-entity-type rollouts at lower ceremony per entity once the base library is proven.

## Open questions

- **Multiple in-flight runs per entity?** A user might want two competing assembly designs side by side. The schema's UNIQUE constraint on (entity_type, entity_id) doesn't allow this. Resolution: probably yes for some entity types but not most; revisit on a per-entity basis.
- **Workflow definition versioning.** What happens when an in-flight run's definition is updated mid-flight? Current proposal: pin definition_id at start; new definitions only apply to new runs. Old runs complete on their original schema.
- **Cross-entity workflows.** Some processes span multiple entities (employee onboarding touches user record + employee profile + tax forms + training + kiosk). Is that one workflow with multiple entityIds, or N coordinated workflows? Probably the former; needs schema accommodation.
- **Audit granularity.** Per-step change-set audit, or per-field? Per-step is simpler; per-field gives precise history. Defer to existing entity-audit conventions.

## Relationship to other phases

- **Phase 4 (capability gating)**: complexity tiers (departmental, ABC costing) are capability-gated. Workflow definitions can also be capability-gated where appropriate.
- **Phase 5 (user-axis customization)**: this design lays groundwork for the "logic-API-side, semantic-verbs" architecture Phase 5 envisioned. The `WorkflowDefinition` API resource is a semantic verb in Phase 5's terms. Alternative shells (Factorio-style, savant tuple view) would consume the same API.
- **Drafts** (`DraftService`): existing draft infrastructure overlaps with workflow runs. They serve similar purposes — both persist in-progress edits across sessions. The workflow pattern formalizes what drafts handle ad-hoc. Implementation should consider: do workflow runs *replace* drafts for entities they cover, or *coexist* (drafts for express-mode partial saves, workflow runs for guided-mode multi-step)?

## Notes for the next implementation pass

- The workflow shell should mount inside the entity's own routing structure — `/parts/123` shows part 123 as a normal detail page; `/parts/123?workflow=part-assembly-guided` mounts the WorkflowComponent over the same record. URL-as-source-of-truth applies (per CLAUDE.md rule).
- Step components should be small Angular components in the entity feature module; the shell registers them by name from the `WorkflowDefinition.steps[].componentName`.
- The mode-toggle in the header should *preserve current state* — switching from guided to express mid-flow shows everything in scrollable form with the user's progress markers; switching back returns to the same step.
