# Manuscript: Shop Floor Kiosk Video Guide

**Module ID:** 24
**Slug:** `video-shop-floor-kiosk`
**App Route:** `/shop-floor`
**Estimated Duration:** 10–12 minutes
**Generation Command:** `POST /api/v1/training/modules/24/generate-video`

---

## Purpose

The shop floor kiosk is the touchpoint for production workers who do not use a computer during the day. This video is their primary onboarding tool — it must be clear enough to watch once and walk away ready to use the kiosk confidently. The tone is direct and practical. Assume zero prior software experience.

### Learning Objectives
- Understand what the shop floor kiosk is and why it exists
- Identify the physical components (screen, badge reader, optional PIN pad)
- Authenticate with a badge scan and PIN
- Clock in and clock out
- Start a job timer
- Find a job by number or barcode scan
- Move a job to the next production stage
- Add a note or photo to a job
- Read the current shop overview display
- Know what to do when something goes wrong

### Audience
Production Workers. Secondary: managers setting up kiosks.

### Learning Style Coverage
- **Visual:** Describe the physical terminal layout before the software
- **Auditory:** Explain the purpose and value of each action
- **Reading/Writing:** Step-by-step instructions for each major workflow
- **Kinesthetic:** Walk up to the kiosk and try each action described

---

## Chapter Breakdown

---

### Chapter 1 — Spatial Orientation: What Is the Kiosk?
**Estimated timestamp:** 0s
**UI Element:** `app-shop-floor-display`
**Chapter label:** "What Is the Kiosk?"

**Narration Script:**
The shop floor kiosk is a touchscreen terminal mounted in your production area. You are not expected to have a computer login to use it. The kiosk is purpose-built for workers who spend their day on the shop floor, not at a desk. What you see on the screen right now is the kiosk display. At the top is the current date and time in large, easy-to-read text — you can always find the time without looking for a clock. Below the time is the kiosk's current state — either an idle screen waiting for a badge scan, or an authenticated screen showing quick actions. The entire interface is designed for gloved hands and fast interactions. Every button is large. Every action is immediate. If you can tap, you can use this.

**Kinesthetic prompt:** Look at the screen. What is the current time? What is the current state of the kiosk — idle or active?

---

### Chapter 2 — The Badge and PIN System
**Estimated timestamp:** 55s
**UI Element:** `app-kiosk-search-bar`
**Chapter label:** "Badge and PIN"

**Narration Script:**
To use the kiosk, you need two things: your employee badge and your PIN. Your badge is a physical card or fob with a barcode or NFC chip programmed with your employee ID. It was given to you when you were set up as a user — if you do not have one, ask your manager. Your PIN is a four to six digit numeric code. You set it yourself in your account settings on the first login. If you have never set a PIN, or if you have forgotten it, your admin can reset it for you — it is a three-second process from the admin panel. The PIN exists separately from your password. It is short and numeric so you can enter it quickly at the terminal even with gloves on.

**Alternative paths:** Some kiosks are configured for PIN-only entry — no badge required. In this mode, a numeric keypad appears on screen when you tap Clock In. Type your employee ID number followed by your PIN. Your admin configures which authentication method the terminal uses.

**Kinesthetic prompt:** Locate your employee badge. Find the barcode or NFC symbol on it. This is what the kiosk reader responds to.

---

### Chapter 3 — Clocking In
**Estimated timestamp:** 130s
**UI Element:** `app-quick-action-panel`
**Chapter label:** "Clocking In"

**Narration Script:**
Walk up to the kiosk terminal. Hold your badge near the badge reader — either scan the barcode or tap the NFC reader, depending on which your terminal uses. The screen responds immediately and prompts you for your PIN. Tap the digits on the screen keypad. If you make a mistake, tap the backspace key. When the PIN is correct, the kiosk shows your name and a set of quick action buttons. Tap the Clock In button — it is large and green, in the upper area of the action grid. The system records your exact clock-in time and displays a confirmation on screen. You will hear a brief chime if the terminal has a speaker. From this moment, your attendance record begins for the day.

**Alternative paths:** If the kiosk shows an error after scanning your badge — like Employee Not Found — ask your manager to verify your badge is registered in the system. A badge can be re-enrolled in seconds from the Admin panel. If you accidentally clock in twice, the second scan will prompt you to clock out instead, since you are already clocked in.

**Kinesthetic prompt:** Walk up to the kiosk. Scan your badge and enter your PIN. Confirm your name appears on screen after authentication.

---

### Chapter 4 — Starting a Job Timer
**Estimated timestamp:** 205s
**UI Element:** `app-quick-action-panel`
**Chapter label:** "Starting a Timer"

**Narration Script:**
After clocking in, you will see a set of quick action buttons. To log time against a specific job, tap Start Job Timer. The kiosk shows a search field. If you know the job number, type it in and tap the job when it appears in the results. If you have a barcode label attached to the physical job — which your shop may print and attach to travelers or work orders — scan it with the kiosk's barcode reader and the job populates automatically. No typing needed. Once the job is selected, tap Confirm to start the timer. The kiosk shows the timer running next to the job number. If you move to a different job during the day, tap Start Job Timer again, scan the new job, and the previous timer stops and saves automatically.

**Alternative paths:** If you cannot find the job by number or scan, ask your engineer or manager — the job may not exist in the system yet, or the barcode label may be misprinted. Do not start a timer on the wrong job — it affects that job's actual cost data.

**Kinesthetic prompt:** Tap Start Job Timer. Search for the job number you are working on today. Start the timer and confirm it appears as active on screen.

---

### Chapter 5 — Switching Between Jobs
**Estimated timestamp:** 280s
**UI Element:** `app-quick-action-panel`
**Chapter label:** "Switching Jobs"

**Narration Script:**
Production workers often move between jobs throughout the day — finishing one operation and moving to the next. Switching jobs is straightforward. While a timer is running, tap Start Job Timer again. You do not need to stop the current timer first — starting a new timer stops the old one automatically and saves the elapsed time. Scan or search for the new job. Tap Confirm. The new timer starts and the previous one is saved as a completed entry. If you finish a job entirely and need to wait for material or your next assignment, you can stop the current timer without starting a new one by tapping the Stop Timer button. The elapsed time saves. No timer runs until you start another.

**Kinesthetic prompt:** While your current timer is running, practice switching to a different job. Watch the original timer stop and the new one begin.

---

### Chapter 6 — Moving a Job to the Next Stage
**Estimated timestamp:** 355s
**UI Element:** `app-quick-action-panel`
**Chapter label:** "Moving a Job"

**Narration Script:**
When you complete an operation and the job is ready to move to the next production stage, you can move it directly from the kiosk. Authenticate if you are not already, then tap Move Job. Search for the job or scan its label. The current stage displays on screen, along with the next stage in sequence. Tap Move Forward to advance the job to the next stage. A confirmation dialog shows what the stage change will be — for example, from In Production to QC Review. Tap Confirm to complete the move. The kanban board on any desk or monitor in the shop updates in real time. The job's engineer and manager may receive a notification that the job advanced.

**Alternative paths:** If the job should not move — for example, it failed QC and needs rework — do not move it. Instead, add a note explaining the issue (covered in the next section) and notify your engineer. Moving a job forward when it should not go forward creates confusion and may trigger premature invoicing.

**Kinesthetic prompt:** Find a job that is genuinely ready to move to the next stage. Use the kiosk to advance it and verify the change appears on the kanban board.

---

### Chapter 7 — Adding a Note or Photo
**Estimated timestamp:** 430s
**UI Element:** `app-quick-action-panel`
**Chapter label:** "Notes and Photos"

**Narration Script:**
The kiosk lets you add notes and photos to a job without leaving the shop floor. Authenticate, tap Add Note, and search for or scan the job. A text entry field appears with a large keyboard — tap to type your note. Notes appear immediately in the job's activity log on the kanban board, visible to engineers and managers. Use notes for things like: quality observations, material substitutions, damage reports, or questions for the engineer. To attach a photo — for example, to document a finished part or a quality issue — tap Add Photo instead. The kiosk activates the device camera. Frame your subject, tap the shutter button, and the photo uploads directly to the job's file attachments.

**Alternative paths:** If the kiosk does not have a camera, the Add Photo option may not appear. Some terminals are camera-equipped specifically for documentation purposes — check with your admin. Text notes are always available regardless of camera availability.

**Kinesthetic prompt:** Add a test note to a job — type something like inspection complete, surface finish acceptable. Open the kanban board on any device and verify the note appears in the job's activity log.

---

### Chapter 8 — Clocking Out
**Estimated timestamp:** 505s
**UI Element:** `app-quick-action-panel`
**Chapter label:** "Clocking Out"

**Narration Script:**
At the end of your shift, clock out at the kiosk. Scan your badge and enter your PIN. The kiosk shows your name and your shift summary — how many hours you have worked and which jobs you logged time against. Review the summary to confirm it looks correct. Tap Clock Out. The system records your clock-out time. Any running job timer stops automatically at the moment you clock out, and the elapsed time is saved. The kiosk returns to its idle state, ready for the next person. If you are the last person out and the terminal should go into night mode — a reduced display showing only the clock — it does so automatically after a configurable idle timeout.

**Alternative paths:** If you forgot to clock out yesterday, the kiosk will prompt you to enter yesterday's departure time before proceeding with today's clock-in. Enter your best estimate and add a note. Your manager reviews flagged entries in the Admin panel.

**Kinesthetic prompt:** Clock out at the kiosk. Verify the shift summary shows the correct hours and jobs before tapping confirm.

---

### Chapter 9 — The Shop Floor Overview Display
**Estimated timestamp:** 580s
**UI Element:** `app-shop-floor-display`
**Chapter label:** "Overview Display"

**Narration Script:**
Some kiosk installations are configured in display-only mode — a large screen showing the current production status for the entire shop, like a scoreboard. In this mode the screen shows a grid of active jobs: their current stage, assigned worker, time in stage, and any hold flags. This is visible to everyone in the shop without authentication. It creates shared situational awareness — every worker can glance at the board and know where everything stands. Jobs approaching their due date show a yellow or red indicator. Jobs on hold show a pause icon. Jobs currently being worked with an active timer show a pulsing activity indicator. The display refreshes automatically every few seconds. No interaction is needed.

**Alternative paths:** The overview display can also show aggregate metrics — total jobs in each stage, on-time percentage, or current shop utilization. Your admin configures what appears. If you need something added to the display, ask your admin to customize it.

**Kinesthetic prompt:** Look at the shop floor overview display without touching anything. Identify the job that has been in its current stage the longest.

---

### Chapter 10 — Troubleshooting Common Issues
**Estimated timestamp:** 655s
**UI Element:** `app-shop-floor-display`
**Chapter label:** "Troubleshooting"

**Narration Script:**
A few common issues and how to handle them. Badge not recognized: your badge may not be registered. Ask your admin to add it from the Admin panel — takes less than a minute. PIN rejected after correct entry: your PIN may have been reset. Ask your admin to reset it and set a new one in your account settings. Job not found by scan: the barcode may be damaged or misprinted. Type the job number manually instead. Timer did not save after shift ended: if the kiosk lost power or internet during your shift, your time entry may not have synced. Check with your manager — the system queues pending saves and retries when connection is restored, so entries are rarely lost. Screen frozen or unresponsive: touch the screen firmly in the center and wait five seconds. If no response, ask your admin — a simple browser refresh on the kiosk device resolves most freezes without losing data.

**Kinesthetic prompt:** Find the network indicator on the kiosk display. Verify it shows connected. If it shows disconnected, notify your admin before starting your shift.

---

## Full Transcript

The shop floor kiosk is a touchscreen terminal for production workers who do not use a computer during their shift. It is purpose-built for gloved hands and fast interactions. Every button is large. Every action is immediate.

To use the kiosk, you need your employee badge — a card with a barcode or NFC chip — and your PIN, a four to six digit numeric code you set yourself. Hold your badge near the reader, enter your PIN, and the kiosk authenticates you in seconds.

Tap Clock In to start your shift. The time is recorded immediately. Tap Start Job Timer and search for or scan the job you are working on. The timer starts and tracks your time against that specific job. If you move to a different job, tap Start Job Timer again — starting a new timer automatically stops and saves the previous one. You never lose time by switching.

When a job is complete and ready for the next operation, tap Move Job, find it, and tap Move Forward. The kanban board updates in real time. Engineers and managers see the move immediately.

Need to document something? Tap Add Note to type an observation or tap Add Photo to capture a quality image. Both attach directly to the job and appear in the activity log on the kanban board.

At end of shift, scan your badge, review the shift summary showing your total hours and jobs, and tap Clock Out. Any running timer stops automatically.

In display mode, the kiosk shows the whole shop's production status — a scoreboard visible to everyone without authentication.

Troubleshooting: badge not recognized means it needs to be registered by your admin. PIN rejected means it was reset — ask your admin. Job not found by scan — type the number manually. Frozen screen — firm center touch, wait five seconds, then notify admin.

---

## Playwright Generation Spec

```json
{
  "appRoute": "/shop-floor",
  "embedUrl": "https://www.youtube.com/embed/YE7VzlLtp-4",
  "steps": [
    {
      "element": "app-shop-floor-display",
      "popover": {
        "title": "What Is the Kiosk?",
        "description": "The shop floor kiosk is a touchscreen terminal for production workers who do not use a computer during their shift. What you see now is the kiosk display. At the top is the current date and time in large, readable text — always visible without searching for a clock. Below is the current kiosk state: idle waiting for a badge scan, or active showing quick action buttons. The entire interface is designed for gloved hands. Every button is large. Every action is immediate."
      }
    },
    {
      "element": "app-kiosk-search-bar",
      "popover": {
        "title": "Badge and PIN",
        "description": "To use the kiosk you need two things: your employee badge and your PIN. Your badge is a card or fob with a barcode or NFC chip programmed with your employee ID — given to you during setup. Your PIN is a four to six digit numeric code that you set yourself in account settings. If you have never set a PIN or forgot it, your admin can reset it in seconds from the Admin panel. The PIN is separate from your password — short and numeric so you can enter it quickly with gloves on."
      }
    },
    {
      "element": "app-quick-action-panel",
      "popover": {
        "title": "Clocking In",
        "description": "Walk to the kiosk and hold your badge near the reader — scan the barcode or tap the NFC chip. The screen responds immediately and prompts for your PIN. Tap the digits on the screen keypad. Use backspace for mistakes. When correct, your name appears and the quick action buttons display. Tap the large green Clock In button. The system records your exact clock-in time and displays a confirmation. Your attendance record for the day begins at this moment."
      }
    },
    {
      "element": "app-quick-action-panel",
      "popover": {
        "title": "Starting a Timer",
        "description": "After clocking in, tap Start Job Timer. A search field appears. Type the job number and tap the result, or scan the barcode label attached to the physical job — the job populates automatically with no typing needed. Tap Confirm to start the timer. The kiosk shows the timer running next to the job number. If you move to a different job, tap Start Job Timer again — starting a new timer stops and saves the previous one automatically. You never lose time by switching jobs."
      }
    },
    {
      "element": "app-quick-action-panel",
      "popover": {
        "title": "Switching Jobs",
        "description": "Production workers often move between jobs throughout the day. Switching is simple: while a timer is running, tap Start Job Timer again. You do not need to stop the current one first. Scan or search for the new job and tap Confirm. The new timer starts and the previous entry saves automatically. To stop without starting another, tap Stop Timer — the elapsed time saves and no timer runs until you start again. Your manager sees every entry with its exact start and stop times."
      }
    },
    {
      "element": "app-quick-action-panel",
      "popover": {
        "title": "Moving a Job",
        "description": "When you complete an operation and the job is ready for the next stage, tap Move Job. Search or scan the job. The current stage and the next stage both display on screen. Tap Move Forward. A confirmation dialog shows the stage change — for example, from In Production to QC Review. Tap Confirm to complete it. The kanban board on every device in the shop updates in real time. Do not advance a job that failed QC — add a note instead and notify your engineer."
      }
    },
    {
      "element": "app-quick-action-panel",
      "popover": {
        "title": "Notes and Photos",
        "description": "Tap Add Note to attach text to a job — quality observations, material substitutions, damage reports, questions for the engineer. A large keyboard appears for typing. The note appears immediately in the job activity log on the kanban board. Tap Add Photo to use the kiosk camera — frame your subject and tap the shutter button. The photo uploads directly to the job's file attachments. Both notes and photos are visible to engineers and managers in real time without anyone needing to check the kiosk."
      }
    },
    {
      "element": "app-quick-action-panel",
      "popover": {
        "title": "Clocking Out",
        "description": "At the end of your shift, scan your badge and enter your PIN. The kiosk shows your shift summary: total hours worked and which jobs you logged time against. Review the summary to confirm it looks correct. Tap Clock Out. Your exact departure time is recorded. Any running job timer stops automatically at this moment and saves the elapsed time. The kiosk returns to its idle state for the next person. If you forgot to clock out yesterday, the kiosk prompts you to enter yesterday's departure time before proceeding."
      }
    },
    {
      "element": "app-shop-floor-display",
      "popover": {
        "title": "Overview Display",
        "description": "Some kiosk screens are configured in display-only mode — a production scoreboard visible to everyone without authentication. It shows active jobs with their current stage, assigned worker, time in stage, and any hold or overdue flags. Jobs near their due date show yellow or red indicators. Jobs with active timers show a pulsing activity icon. The display refreshes automatically every few seconds. No interaction is needed. This creates shared situational awareness — every worker in the shop can glance and know the current production state."
      }
    },
    {
      "element": "app-shop-floor-display",
      "popover": {
        "title": "Troubleshooting",
        "description": "Common issues: Badge not recognized — it may not be registered; ask your admin to add it, takes under a minute. PIN rejected — it may have been reset; ask your admin and set a new one in account settings. Job not found by scan — barcode may be damaged; type the job number manually instead. Timer did not save after a power loss — the system queues pending saves and retries when connection restores, so entries are rarely truly lost; check with your manager. Screen frozen — touch the center firmly and wait five seconds; a browser refresh resolves most freezes without losing data."
      }
    }
  ],
  "chaptersJson": [
    { "timeSeconds": 0, "label": "What Is the Kiosk?" },
    { "timeSeconds": 55, "label": "Badge and PIN" },
    { "timeSeconds": 130, "label": "Clocking In" },
    { "timeSeconds": 205, "label": "Starting a Timer" },
    { "timeSeconds": 280, "label": "Switching Jobs" },
    { "timeSeconds": 355, "label": "Moving a Job" },
    { "timeSeconds": 430, "label": "Notes and Photos" },
    { "timeSeconds": 505, "label": "Clocking Out" },
    { "timeSeconds": 580, "label": "Overview Display" },
    { "timeSeconds": 655, "label": "Troubleshooting" }
  ]
}
```
