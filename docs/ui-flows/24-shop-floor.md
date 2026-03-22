# Shop Floor / Worker View

**Route:** `/shop-floor`
**Access Roles:** Production Worker, Engineer (kiosk auth: RFID/NFC/barcode + PIN)
**Page Title:** Shop Floor

## Purpose

The shop floor is a touch-first kiosk display designed for large touchscreens
mounted in production areas. Workers clock in/out, start/stop job timers,
scan barcodes to pull up job info, and complete QC checkpoints.

## Kiosk Authentication

Workers authenticate using tiered credentials:
1. **Scan** RFID badge / NFC sticker / barcode label
2. **Enter PIN** (4-6 digit numeric code, separate from password)

No keyboard required for normal operation.

## Key Flows

| Flow | Description |
|:-----|:------------|
| Clock In / Out | Large touch button — records clock event, starts/stops work session |
| Start Job Timer | Scan or search job → tap Start → timer runs |
| Stop Job Timer | Tap Stop → enter notes → time saved |
| QC Checkpoint | Scan job barcode → QC form appears → fill → sign off |
| View My Work | See assigned jobs and current timer status |

## Quick Action Panel

Large 88x88px touch buttons (meets 44px minimum, exceeds for industrial use):
- Clock In
- Clock Out
- Start Task
- My Jobs
- QC Check
- Help

## Barcode Search

Full-width search bar with:
- Accepts USB barcode scanner input (keyboard wedge mode)
- Accepts NFC reader input
- Fallback: manual entry for visitors or badge failures

## Finding Controls

Use these landmarks when you need help locating a specific control.
Positions are described relative to a standard 1920×1080 desktop layout.

### 🔵 Top Header Bar (always visible, 44px strip at very top)

- **Open Chat** — look for the `chat_bubble_outline` icon (right side of toolbar)
- **Ai Assistant (smart_toy)** — look for the `smart_toy` icon (right side of toolbar)
- **Notifications bell** — look for the `notifications_none` icon (top-right corner)
- **Toggle dark/light theme** — look for the `dark_mode` icon (top-right corner)
- **User, Admin** — look for the `menu` icon (top-right corner)

### 🟦 Page Toolbar (below header — search, filters, action buttons)

- **Dismiss onboarding banner** — look for the `close` icon (top-right corner)
- **Expand sidebar** — look for the `chevron_right` icon (left sidebar)

<!-- /finding-controls -->

## UX Analysis

### Flow Quality: ★★★★☆

The shop floor kiosk UX is purpose-built for gloved hands and industrial environments.
Touch targets exceed WCAG minimums significantly.

### Usability Observations

- Ambient display mode shows overall production status on wall-mounted screens
- Clock events feed payroll time calculations
- QR/barcode labels generated from the parts module for job travelers

### Functional Gaps / Missing Features

- No multi-language support on the kiosk (critical for diverse workforces)
- No voice interaction (hands-free for safety environments)
- No job sequence display (what order should this worker tackle jobs?)
- No real-time production count display (e.g., "20/100 parts completed today")
- Safety alert broadcast (emergency stop notification) not implemented
- No shift handoff notes capture
