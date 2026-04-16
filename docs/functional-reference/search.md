# Global Search

## Overview

Global search provides cross-entity, real-time search from the application header. It searches across six core entity types using PostgreSQL ILIKE pattern matching, with an optional AI-powered column (RAG hybrid search via Ollama + pgvector) that returns semantically relevant results and a generated natural-language answer when the AI profile is active.

Search is available on every authenticated page (except the onboarding flow) and is the primary mechanism for quick navigation to any entity in the system.

---

## UI Location

The search bar is embedded in the application header (`AppHeaderComponent`), positioned between the breadcrumb navigation and the action buttons. It spans the available horizontal space (`flex: 1`).

- **Shortcut:** `Ctrl+K` (or `Cmd+K` on macOS) focuses the search input from anywhere in the application.
- **Visibility:** Hidden on tablet and mobile breakpoints (below `$breakpoint-tablet: 1024px`) via the `.hide-tablet` class.
- **Onboarding:** The search bar is not rendered during onboarding routes (`layout.isOnboardingRoute()`).

Visual elements:

- A `search` Material icon on the left edge of the input.
- A `Ctrl+K` keyboard hint badge on the right edge.
- A primary-colored border highlight when the input is focused.

---

## Search Behavior

### Input Processing

| Parameter | Value |
|-----------|-------|
| Debounce (full-text) | 300ms |
| Debounce (AI/RAG) | 600ms |
| Minimum characters | 2 |
| Maximum results (API) | 50 (server-enforced cap) |
| Default result limit | 20 |

The search input uses two independent RxJS pipelines:

1. **Full-text pipeline** -- 300ms debounce, calls `SearchService.search()` (PostgreSQL ILIKE).
2. **AI/RAG pipeline** -- 600ms debounce, calls `AiService.ragSearch()` (pgvector cosine similarity + Ollama answer generation). This pipeline only activates when `AiService.available()` is true (the Ollama container is running).

Both pipelines use `distinctUntilChanged()` to avoid redundant requests for unchanged terms. When the input drops below 2 characters, all result signals are cleared immediately.

### Result Dropdown

The result dropdown appears below the search bar as an absolutely positioned overlay (`z-index: $z-dropdown`). It has a maximum height of 400px and scrolls vertically per column.

- **Single column layout:** When AI is unavailable, only the full-text results column is shown.
- **Two column layout:** When AI is available (`aiService.available()`), the dropdown splits into a CSS grid with two equal columns -- full-text results on the left and AI results on the right.

The dropdown closes when the input loses focus (with a 200ms delay to allow click events on results to fire).

---

## Entity Types Searched

### Full-Text Search (PostgreSQL ILIKE)

The `SearchRepository` executes a single UNION ALL query across six entity tables. Each sub-query is limited to `max(limit / 4, 3)` results, ordered by `updated_at DESC`. Only non-deleted records are returned; archived jobs are excluded.

| Entity Type | Table | Fields Searched | Title | Subtitle | Icon |
|-------------|-------|-----------------|-------|----------|------|
| Job | `jobs` | `job_number`, `title` | Job number | Title | `work` |
| Customer | `customers` | `name`, `company_name` | Name | Company name | `people` |
| Part | `parts` | `part_number`, `description` | Part number | Description | `inventory_2` |
| Lead | `leads` | `company_name`, `contact_name` | Company name | Contact name | `trending_up` |
| Asset | `assets` | `name`, `serial_number` | Name | Serial number | `precision_manufacturing` |
| Expense | `expenses` | `description`, `category` | Description | Category | `receipt_long` |

### AI/RAG Search (pgvector)

When available, the RAG pipeline searches the `document_embeddings` table using vector cosine similarity against the query embedding. It can return results for any entity type that has been indexed by the document indexing Hangfire job. Results with `entityType === 'Documentation'` are filtered out on the client side (internal documentation is not surfaced to end users).

RAG results include a relevance `score` (0.0--1.0) and optionally a `generatedAnswer` -- a natural-language summary produced by the Ollama model.

---

## Result Display

### Full-Text Results Column

Each result item renders as a clickable button with:

- **Icon** (left) -- Material icon corresponding to the entity type (e.g., `work` for jobs, `inventory_2` for parts).
- **Title** (center, bold) -- Primary identifier (job number, part number, customer name, etc.). Truncated with ellipsis if too long.
- **Subtitle** (center, below title, muted) -- Secondary descriptor. Truncated with ellipsis.
- **Entity type badge** (right) -- Uppercase label showing the entity type (e.g., "JOB", "PART").

When no full-text results match, a "No matches" empty state message is displayed.

### AI Results Column

The AI column has a distinct visual treatment:

- **Column header:** Accent-colored `auto_awesome` icon with an "AI Results" label.
- **Loading state:** A spinning `auto_awesome` icon with "Thinking..." text while the RAG query is in progress.
- **Generated answer (when present):** Highlighted block at the top with a `lightbulb` icon and the natural-language answer text. Background uses `color-mix(in srgb, var(--accent) 8%, var(--surface))`.
- **RAG result items:** Similar layout to full-text results, but with:
  - `chunkText` as the title (the matched text fragment from the embedding).
  - `sourceField` as the subtitle (which field of the entity produced the match).
  - Entity type badge plus a relevance **score percentage** (e.g., "87%") in monospace font below the type badge.
- **Empty state:** "Type to search with AI" message when no results and no answer are present.

---

## Result Actions

### Clicking a Full-Text Result

Navigating to a result uses `DetailDialogService`-compatible URL patterns:

1. The mobile menu closes (if open).
2. The dropdown closes and the search input clears.
3. The router navigates to the entity's list page with a `?detail=type:id` query parameter, which triggers the detail dialog to open automatically.

Route mapping:

| Entity Type | Route | Detail Type |
|-------------|-------|-------------|
| Job | `/kanban` | `job` |
| Customer | `/customers` | `customer` |
| Part | `/parts` | `part` |
| Lead | `/leads` | `lead` |
| Asset | `/assets` | `asset` |
| Expense | `/expenses` | (none -- navigates to list only) |
| Vendor | `/vendors` | `vendor` |
| Sales Order | `/sales-orders` | `sales-order` |
| Purchase Order | `/purchase-orders` | `purchase-order` |
| Quote | `/quotes` | `quote` |
| Shipment | `/shipments` | `shipment` |
| Invoice | `/invoices` | `invoice` |
| Payment | `/payments` | `payment` |
| Lot | `/quality` | `lot` |

For entities with a detail type mapping, the resulting URL is `/{route}?detail={detailType}:{entityId}` (e.g., `/kanban?detail=job:1055`). For entities without a detail type (like Expense), the URL is just the list route.

### Clicking an AI/RAG Result

Same navigation pattern, but the entity type is resolved from the RAG result's `entityType` field (lowercased) through the same route and detail type maps.

---

## Search Technology

### Full-Text: PostgreSQL ILIKE

The current implementation uses `ILIKE` pattern matching (`%term%`) rather than PostgreSQL's `tsvector` full-text search. This approach:

- Performs substring matching (not word-boundary matching).
- Is case-insensitive.
- Does not require `tsvector` indexes to be maintained.
- Uses parameterized queries (`NpgsqlParameter`) to prevent SQL injection.

The query is a single raw SQL statement with `UNION ALL` across all six entity tables, executed via ADO.NET (`DbConnection.CreateCommand`) for direct control. Each sub-query independently filters by `deleted_at IS NULL` and sorts by `updated_at DESC`.

### AI/RAG: pgvector + Ollama

When the AI profile is active:

1. The query text is sent to `POST /api/v1/ai/search` with `includeAnswer: true`.
2. The backend converts the query to a vector embedding via Ollama.
3. The embedding is compared against the `document_embeddings` table using pgvector's cosine similarity operator.
4. If `includeAnswer` is true, the matched chunks are fed to the Ollama model to produce a natural-language answer.
5. Results are returned with relevance scores (0.0--1.0) and the optional generated answer.

The document indexing Hangfire job runs every 30 minutes to keep the embeddings table current.

---

## API Endpoints

### Full-Text Search

```
GET /api/v1/search?q={term}&limit={limit}
Authorization: Bearer {token}
```

**Query parameters:**

| Parameter | Type | Required | Default | Max | Description |
|-----------|------|----------|---------|-----|-------------|
| `q` | string | Yes | -- | -- | Search term (minimum 2 characters) |
| `limit` | int | No | 20 | 50 | Maximum total results |

**Response:** `200 OK`

```json
[
  {
    "entityType": "Job",
    "entityId": 1055,
    "title": "JOB-1055",
    "subtitle": "CNC Housing Assembly",
    "icon": "work",
    "url": "/kanban"
  }
]
```

Returns an empty array if `q` is blank or shorter than 2 characters.

### RAG Search

```
POST /api/v1/ai/search
Authorization: Bearer {token}
Content-Type: application/json

{
  "query": "housing assembly tolerance",
  "entityTypeFilter": null,
  "includeAnswer": true
}
```

**Response:** `200 OK`

```json
{
  "results": [
    {
      "entityType": "Part",
      "entityId": 42,
      "chunkText": "Housing assembly with +/- 0.005 tolerance on bore diameter",
      "sourceField": "description",
      "score": 0.87
    }
  ],
  "generatedAnswer": "The housing assembly (Part #42) has a tolerance of +/- 0.005 on the bore diameter."
}
```

---

## Keyboard Navigation

| Key | Action |
|-----|--------|
| `Ctrl+K` / `Cmd+K` | Focus the search input from anywhere |
| `Escape` | Blur the search input, closing the results dropdown |
| Typing | Triggers debounced search after 2+ characters |

Note: Arrow key navigation within the result list and Enter-to-select are not currently implemented. Results are selected by mouse click (using `mousedown` to fire before the input's `blur` event closes the dropdown).

---

## Performance

### Query Optimization

- **Per-entity limits:** The SQL query limits each entity sub-query to `max(limit / 4, 3)` rows, preventing any single entity type from dominating results. The combined results are then trimmed to the overall `limit` via `Take(limit)`.
- **Index usage:** The `ILIKE` queries benefit from existing `updated_at` indexes for ordering. Substring `ILIKE` patterns (`%term%`) cannot use standard B-tree indexes; for high-volume deployments, trigram indexes (`pg_trgm`) could be added.
- **Server-side cap:** The controller enforces a maximum limit of 50 results (`Math.Min(limit, 50)`) regardless of what the client requests.
- **Soft-delete filter:** All sub-queries filter `deleted_at IS NULL`, leveraging the global query filter indexes.
- **Archived job exclusion:** Jobs with `is_archived = true` are excluded from results.

### Client-Side Optimizations

- **Debouncing:** 300ms for full-text, 600ms for AI/RAG -- prevents excessive API calls during rapid typing.
- **Distinct until changed:** Duplicate consecutive search terms are suppressed.
- **Immediate clear:** Dropping below 2 characters immediately clears all results without waiting for debounce.
- **Delayed dropdown close:** 200ms delay on blur allows click events on results to register before the dropdown unmounts.

### Result Limits

| Scope | Limit |
|-------|-------|
| Total full-text results | 20 (default), 50 (max) |
| Per-entity sub-query | `max(limit / 4, 3)` |
| RAG results | Determined by AI service configuration |

### Caching

No client-side result caching is implemented. Each keystroke change (after debounce + dedup) triggers a fresh API call. The search is designed for real-time relevance against the latest data.
