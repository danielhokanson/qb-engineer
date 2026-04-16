# Shop Floor

## Overview

The shop floor feature provides full-screen kiosk displays designed for production floor use. Two distinct components serve different purposes: the **display page** (`/display/shop-floor`) is a supervisor-oriented dashboard showing all workers, their statuses, active jobs, and operational controls; the **clock page** (`/display/shop-floor/clock`) is a team-scoped time clock terminal for badge-scan or manual clock-in/out.

Both components operate in ephemeral authentication mode -- they clear any existing auth session on load and authenticate workers transiently per interaction. After each action, the session is automatically cleared and the display returns to its idle dashboard state.

Key characteristics:

- Full-screen kiosk layout with no sidebar or header chrome.
- RFID/NFC badge scan, barcode scan, and manual credential authentication.
- PIN-based auth for badge scans, password-based auth for card taps and manual login.
- Auto-dismiss timeouts to return to the idle state after inactivity.
- Theme (light/dark) and font size persistence via localStorage.
- 15-second auto-refresh for dashboard data.
- Drag-and-drop job assignment (display page only).
- Receiving and shipping workflows (display page only, role-gated).

---

## Routes

| Route | Component | Purpose |
|-------|-----------|---------|
| `/display/shop-floor` | `ShopFloorDisplayComponent` | Full supervisor display with worker grid, job management, receiving, and shipping |
| `/display/shop-floor/clock` | `ShopFloorClockComponent` | Team-scoped clock terminal with badge scan and kiosk setup |

Both routes are lazy-loaded. The clock component is loaded via dynamic import from the display routes file.

---

## Display Page

### Header

The display header contains:

- **Title** -- "Shop Floor" static label.
- **Search bar** -- `KioskSearchBarComponent`, a debounced typeahead that searches jobs and parts via `GET /api/v1/display/shop-floor/search`. Results are filtered to `Job` and `Part` entity types only. Minimum 2 characters, 300ms debounce.
- **Status summary strip** -- Four to five KPI stats:
  - **Working** (green) -- count of workers with a working status.
  - **On Break** (yellow) -- count of workers on break or lunch.
  - **Unassigned** -- count of active jobs with no assignee.
  - **Done Today** (accent) -- count of jobs completed today.
  - **Alerts** (red) -- maintenance alert count, only shown when > 0.
- **Controls** -- Font size increase/decrease buttons (12/14/16/18/20px steps), theme toggle (light/dark).
- **Clock** -- Real-time clock display updated every second.

### Worker Card Grid

All workers are displayed in a responsive grid (`sf-grid`). Each worker is rendered as a clickable button (`sf-card`) that initiates the PIN authentication flow when tapped.

Card layout:

- **Status stripe** (left edge) -- Color-coded vertical bar indicating clock status.
- **Identity row** -- Avatar (large), worker name, short status label, and elapsed time since last status change.
- **Assigned jobs list** -- Up to 4 jobs shown with stage color dot, job number, title, and active timer icon. If more than 4 assignments exist, an overflow count is displayed ("+N more").

Status CSS classes:

| Status | CSS Class | Meaning |
|--------|-----------|---------|
| Working | `sf-card--in` | Worker is clocked in and active |
| On Break | `sf-card--break` | Worker is on break or lunch |
| Clocked Out | `sf-card--out` | Worker is not clocked in |

Cards also support visual feedback states: `sf-card--feedback-success` (green flash on successful action), `sf-card--feedback-fail` (red flash on failure), and `sf-card--drop-target` (highlight when dragging a job over the card).

### Unassigned Jobs Section

Displayed below the worker grid when unassigned jobs exist. Each job card shows:

- Stage color dot, job number, title, stage name, priority label.
- A drag handle icon (`drag_indicator`).

Unassigned job cards are draggable. They can be dropped onto any worker card in the grid to assign the job to that worker. The assignment calls `POST /api/v1/display/shop-floor/assign-job`.

### Upcoming Events Section

Displayed below unassigned jobs when upcoming events exist. Events are loaded from `EventsService.getUpcomingEvents()`. Each event card shows:

- Type-specific icon (Meeting: `groups`, Training: `school`, Safety: `health_and_safety`, Other: `event`).
- Event title, formatted start time, location (if set).
- "Required" badge for mandatory events.

### Bottom Action Bar

A passive status bar at the bottom of the display with a badge scan prompt and scan feedback messages. Feedback messages auto-dismiss after 4 seconds.

---

## Clock Page

### Kiosk Setup

On first use, the clock page shows the `KioskSetupComponent` which requires:

1. **Admin login** -- An admin or manager must authenticate with email and password.
2. **Terminal configuration** -- A terminal name and team assignment. The admin can select an existing team or create a new one.

The setup generates a `deviceToken` (UUID stored in localStorage as `qbe-kiosk-device-token`) that identifies this terminal. On subsequent loads, the token is validated against `GET /api/v1/display/shop-floor/terminal?deviceToken=...`. If the terminal is deactivated or not found, the setup flow is shown again.

### Dashboard

After setup, the clock page shows a team-scoped dashboard with:

- **Team header** -- Team name with colored dot, search bar, current time and date.
- **KPI strip** -- Working, On Break, Off, Active Jobs, Done Today, and Overdue (if > 0) counts.
- **Team status section** -- Worker list grouped by status (working first, then break, then off). Working workers show their current task and time on task.
- **Active jobs section** -- List of all active jobs in shop-floor stages with stage dot, job number, title, stage, priority, and assignee avatar.

### Clock Action Bar

At the bottom of the dashboard:

- **Barcode scan input** (`BarcodeScanInputComponent`) -- Auto-focused input field for badge/barcode scanning.
- **Scan identifying spinner** -- Shown briefly while the scan type is being identified.
- **Manual login button** -- Alternative to scanning for workers without badges.

---

## Authentication Methods

### Badge/Barcode Scan (Display Page)

On the display page, the `ScannerService` operates in passive mode -- it listens for keyboard-wedge input on the `document` without requiring a focused input field. When a scan is detected in the `main` phase:

1. The scan value is sent to `POST /api/v1/display/shop-floor/identify-scan`.
2. If identified as `employee`, the worker's PIN overlay is shown.
3. If identified as `job`, a feedback message is shown.
4. If identified as `sales-order`, a shipping hint is shown.
5. If identification fails, the system falls back to treating it as a badge scan and shows the PIN overlay.

### Badge/Barcode Scan (Clock Page)

On the clock page, a focused `BarcodeScanInputComponent` captures scan input. The clock page also supports WebHID RFID relay scanning via `WebHidRfidService`.

The clock page implements a **dual-scan flow** that supports scanning employee badges and job barcodes in any order:

1. **First scan from dashboard:**
   - If identified as `employee` -- goes directly to PIN entry.
   - If identified as `job` -- stores the job context and enters the `job-scanned` phase, prompting for the employee badge next.
   - If identification fails -- falls back to treating as employee badge, goes to PIN entry.

2. **Second scan from `job-scanned` phase:**
   - Treated as the employee badge scan, goes to PIN entry with the job context preserved.

### Card Tap (Display Page)

Tapping a worker's card on the display page initiates password-based authentication (not PIN). The worker is identified by their card position, so no scan is needed. The PIN overlay prompts for the worker's full password instead.

### Manual Login (Clock Page)

The clock page provides a "Clock in manually" button that shows an email + password login form. This is the fallback for workers who do not have a badge or RFID tag.

### RFID via WebHID

The clock page connects to an RFID relay service (`WebHidRfidService`) on init. RFID tag scans are bridged into the same scan flow as barcode scans. The RFID connection is silent -- no error is shown if the relay is not running.

---

## PIN vs Password Authentication

| Auth Method | Trigger | Credential | Min Length | Max Length | API Call |
|-------------|---------|------------|------------|------------|----------|
| Badge/barcode scan | Scan detected | PIN | 4 digits | 8 digits | `AuthService.scanLogin(scanValue, pin)` |
| Card tap (display) | Worker card clicked | Password | 1 char | 128 chars | `AuthService.login({ email, password })` |
| Manual login (clock) | Manual login button | Password | 1 char | -- | `AuthService.login({ email, password })` |

PIN is a short numeric code separate from the user's password, specifically designed for kiosk authentication speed. PINs are PBKDF2 hashed on the server.

---

## Clock Actions

After successful authentication, the display page shows an **actions overlay** with the worker's current status and available actions. Actions are dynamic and driven by reference data via `ClockEventTypeService`.

### Available Actions

`ClockEventTypeService.getAvailableActions(workerStatus)` returns the appropriate actions based on the worker's current status. Each action has a code, label, icon, and color.

### Action Execution

All clock actions call `POST /api/v1/display/shop-floor/clock` with `{ userId, eventType }`.

After a successful clock-in action (event type with `statusMapping === 'In'` and `category === 'work'`), if the worker has no assignments, the system automatically transitions to the **job selection phase** after an 800ms delay.

For all other successful actions, the system shows a success feedback flash for 1500ms, then performs an ephemeral logout.

### Job Timer Actions (Display Page)

Within the actions overlay, each assigned job has timer controls:

- **Start timer** -- calls `POST /api/v1/time-tracking/timer/start` with `{ jobId }`.
- **Stop timer** -- calls `POST /api/v1/time-tracking/timer/stop`.
- **Mark complete** -- calls `POST /api/v1/display/shop-floor/complete-job` with `{ jobId }`. After completion, auto-logout after 1200ms.

### Receiving Goods (Display Page)

Role-gated to Admin, Manager, OfficeManager, Engineer, and ProductionWorker. Only available when the authenticated worker is in an active (clocked-in) status.

Flow:

1. Loads open purchase orders (status: Submitted, Acknowledged, PartiallyReceived) that have lines with remaining quantity.
2. User selects a PO, which shows receivable lines with quantity adjustment controls (increment/decrement buttons).
3. Optional bin location selection from available inventory bins.
4. "Receive All" submits receiving records for each line via `InventoryService.receiveGoods()`.
5. On success, shows feedback and auto-logouts after 1500ms.

### Shipping Goods (Display Page)

Role-gated to Admin, Manager, and OfficeManager. Only available when the authenticated worker is in an active status.

Flow:

1. Loads shipments with Pending or Packed status.
2. User selects a shipment, which shows shipment details (carrier, tracking number, line items).
3. "Print Packing Slip" opens the packing slip PDF in a new tab.
4. "Mark Shipped" calls `ShipmentService.shipShipment(id)`.
5. On success, shows feedback and auto-logouts after 1500ms.

---

## Job Selection Phase

Shown automatically after a clock-in action when the worker has no current assignments. Presents a list of unassigned jobs that the worker can pick from.

Each job shows stage color dot, job number, title, stage name, and priority. Clicking a job calls `POST /api/v1/display/shop-floor/assign-job` with `{ jobId, userId }`.

The "Skip" button allows the worker to clock in without selecting a job.

---

## Auto-Dismiss Timeouts

| Phase | Timeout | Behavior |
|-------|---------|----------|
| PIN entry (display) | 20 seconds | Returns to main dashboard |
| Job selection (display) | 15 seconds | Returns to main dashboard |
| Actions overlay (display) | 30 seconds | Ephemeral logout, returns to main |
| Clock phase (clock page) | 30 seconds | Ephemeral logout, returns to dashboard |

Any user interaction (button click, form submission, action execution) resets the auto-logout timer. The PIN phase timeout is cleared on submit.

---

## IsShopFloor Filter

Jobs displayed on the shop floor are filtered by the `IsShopFloor` flag on both `TrackType` and `JobStage` entities. This flag controls which stages represent physical production work (as opposed to administrative stages like quoting or invoicing).

The API endpoint `GET /api/v1/display/shop-floor` returns only jobs in stages where `IsShopFloor = true`. This ensures the shop floor display shows only work-in-progress items relevant to production workers.

---

## Drag-and-Drop Job Assignment

The display page supports dragging unassigned job cards onto worker cards to assign jobs:

1. **Drag start** -- Sets `draggingJobId` signal, stores job ID in `DataTransfer` as `application/x-job-id`.
2. **Drag over worker card** -- Prevents default, sets `dropTargetUserId` for visual highlight.
3. **Drop on worker card** -- Reads job ID from `DataTransfer`, calls `POST /api/v1/display/shop-floor/assign-job`.
4. **Drag end** -- Clears drag state.

This feature operates without authentication -- it is designed for supervisors viewing the display who can reassign work without clocking in.

---

## Theme and Font Size Persistence

Both settings persist to localStorage and are restored on page load:

| Setting | localStorage Key | Values |
|---------|-----------------|--------|
| Theme | `sf-theme` | `light` or `dark` |
| Font size index | `sf-font-index` | `0` through `4` (maps to 12/14/16/18/20px) |

Font size scaling is applied via CSS `zoom` on the host element, calculated as `currentFontSize / baseFontSize`. The `data-theme` attribute is bound to the host element for CSS theme switching.

---

## Kiosk Terminal Management

### Entity: `KioskTerminal`

| Field | Type | Description |
|-------|------|-------------|
| `Id` | int | Primary key |
| `Name` | string | Terminal display name (e.g., "Mill Area Clock") |
| `DeviceToken` | string | UUID generated on first setup, stored in localStorage |
| `TeamId` | int | FK to Team |
| `ConfiguredByUserId` | int | Admin who set up the terminal |
| `IsActive` | bool | Whether the terminal is active |

### Entity: `Team`

| Field | Type | Description |
|-------|------|-------------|
| `Id` | int | Primary key |
| `Name` | string | Team name |
| `Color` | string? | Hex color for display |
| `Description` | string? | Optional description |
| `IsActive` | bool | Whether the team is active |

### Entity: `UserScanIdentifier`

| Field | Type | Description |
|-------|------|-------------|
| `Id` | int | Primary key |
| `UserId` | int | FK to ApplicationUser |
| `IdentifierType` | string | Type of identifier (e.g., "rfid", "barcode") |
| `IdentifierValue` | string | The actual scan value |
| `IsActive` | bool | Whether the identifier is active |

---

## Scan Identification

`POST /api/v1/display/shop-floor/identify-scan` accepts a `{ scanValue }` payload and returns a `ScanIdentificationResult`:

| Field | Type | Description |
|-------|------|-------------|
| `scanType` | string | One of: `employee`, `job`, `part`, `sales-order`, `purchase-order`, `asset`, `storage-location`, `unknown` |
| `entityId` | int? | ID of the matched entity |
| `entityNumber` | string? | Display number (job number, part number, etc.) |
| `entityTitle` | string? | Display title |
| `stageName` | string? | Current stage name (jobs only) |
| `stageColor` | string? | Stage color hex (jobs only) |

The endpoint checks the scan value against `UserScanIdentifier` records first (employee badges), then against entity number fields (job numbers, part numbers, etc.).

---

## API Endpoints

All endpoints are under `/api/v1/display/shop-floor`.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/` | Anonymous | Get shop floor overview (active jobs, workers, completed today, maintenance alerts) |
| `GET` | `/clock-status` | Anonymous | Get all workers with clock status, assignments, and timer info |
| `GET` | `/search?q=&limit=` | Anonymous | Kiosk search (filtered to Job and Part entities only) |
| `POST` | `/identify-scan` | Anonymous | Identify a scan value (employee badge, job barcode, etc.) |
| `POST` | `/clock` | Anonymous | Record a clock event (clock in, clock out, break, etc.) |
| `POST` | `/assign-job` | Authorized | Assign a job to a user |
| `POST` | `/complete-job` | Authorized | Mark a job as complete |
| `GET` | `/teams` | Anonymous | List all teams |
| `POST` | `/teams` | Admin, Manager | Create a new team |
| `PUT` | `/teams/{id}` | Admin, Manager | Update a team |
| `DELETE` | `/teams/{id}` | Admin, Manager | Soft-delete a team |
| `GET` | `/teams/{id}/members` | Admin, Manager | List team members |
| `PUT` | `/teams/{id}/members` | Admin, Manager | Assign members to a team |
| `GET` | `/terminals` | Admin, Manager | List all kiosk terminals |
| `GET` | `/terminal?deviceToken=` | Anonymous | Get terminal config by device token |
| `POST` | `/terminal` | Admin, Manager | Set up a new kiosk terminal |

Note: Overview, clock-status, search, identify-scan, and clock endpoints are `[AllowAnonymous]` because the kiosk display operates without a persistent user session. Authentication is ephemeral and per-action.

---

## ClockEvent Entity

| Field | Type | Description |
|-------|------|-------------|
| `Id` | int | Primary key |
| `UserId` | int | FK to ApplicationUser |
| `EventType` | ClockEventType (enum) | Legacy enum-based event type |
| `EventTypeCode` | string | Reference-data-driven event type code (maps to `clock_event_type` reference data group) |
| `OperationId` | int? | Optional FK to a specific operation |
| `Reason` | string? | Optional reason text |
| `ScanMethod` | string? | How the clock event was triggered (scan, manual, etc.) |
| `Timestamp` | DateTimeOffset | When the event occurred |
| `Source` | string? | Source of the event (kiosk, web, mobile) |

---

## Data Refresh

Both the display page and clock page auto-refresh their data every 15 seconds (when in the idle/dashboard phase). The refresh loads both the overview data and clock status in a `forkJoin`. The display page also loads upcoming events in the same batch.

The real-time clock display updates every second. On the display page, worker elapsed times are recomputed every second via a `tick` signal that drives the `workerTimes` computed signal.
