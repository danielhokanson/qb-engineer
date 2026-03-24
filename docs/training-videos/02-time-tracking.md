# Manuscript: Time Tracking Video Guide

**Module ID:** 20
**Slug:** `video-time-tracking-guide`
**App Route:** `/time-tracking`
**Estimated Duration:** 9–11 minutes
**Generation Command:** `POST /api/v1/training/modules/20/generate-video`

---

## Purpose

Time tracking underpins job costing, payroll, and billing accuracy. This video gives every user — from shop floor workers to engineers to managers — the confidence to log hours correctly and review their data. Errors here have downstream financial consequences, so building good habits early matters.

### Learning Objectives
- Understand the time tracking dashboard layout spatially
- Start and stop a timer from multiple entry points
- Switch between jobs without losing time
- Create a manual entry for forgotten time
- Edit and delete entries
- Read the weekly summary
- Understand the clock-in / clock-out system vs. job timers
- Export time for payroll or reporting

### Audience
All roles. Especially critical for Engineers and Production Workers.

### Learning Style Coverage
- **Visual:** Show the dashboard layout and entry rows before explaining actions
- **Auditory:** Explain why accurate time tracking matters for job costing
- **Reading/Writing:** Chapter-level descriptions that stand alone as written instructions
- **Kinesthetic:** Each chapter ends with a specific action to complete

---

## Chapter Breakdown

---

### Chapter 1 — Spatial Orientation: The Time Tracking Dashboard
**Estimated timestamp:** 0s
**UI Element:** `app-time-tracking`
**Chapter label:** "Dashboard Overview"

**Narration Script:**
You are now on the Time Tracking page. Let's orient before we do anything. The page is organized vertically. At the top you will see a toolbar with date navigation and a New Entry button. Below the toolbar is the main content area. It is divided into sections by day — today at the top, then yesterday, then earlier in the week. Within each day section you will see individual time entry rows. Each row represents a block of time you logged against a specific job. At the very bottom of the page is a weekly summary showing your total hours for the current week. The goal of this page is simple: every hour you work should have a corresponding row here. If it does not, job costs will be wrong and your timesheet will be incomplete.

**Kinesthetic prompt:** Without clicking anything, count how many time entries are visible for today in the current view.

---

### Chapter 2 — Starting a Timer from the Dashboard Widget
**Estimated timestamp:** 55s
**UI Element:** `app-time-tracking app-toolbar`
**Chapter label:** "Starting a Timer"

**Narration Script:**
The fastest way to start tracking time is from your main dashboard — not from this page. On the dashboard you will find a Today's Tasks widget that lists your assigned jobs. Each job has a play button — a triangle icon — next to it. Click that play button and a timer starts immediately, linked directly to that job. You will see the timer counting in the header bar of the application, so you always know whether a timer is running. The timer persists even if you navigate to other pages. Only one timer can run at a time. Starting a new timer automatically stops the previous one, which saves the elapsed time as a completed entry. You never lose time by switching jobs.

**Alternative paths:** The play button also appears on job cards on the kanban board — open any card and look for the timer icon in the detail panel header. Both entry points create identical time entries.

**Kinesthetic prompt:** Navigate to your dashboard, find a task in Today's Tasks, and start a timer. Watch the header to confirm it is counting.

---

### Chapter 3 — Starting a Timer from the Kanban Board
**Estimated timestamp:** 125s
**UI Element:** `app-time-tracking .action-btn--primary`
**Chapter label:** "Timer from a Job Card"

**Narration Script:**
You can also start a timer directly from the kanban board without going to the dashboard first. Open any job card by clicking on it. In the detail panel that slides out on the right, look near the top for a timer icon next to the job number. Click it. The icon animates to show the timer is running and the header count starts. This is useful when you are already on the board reviewing jobs and want to start tracking time without navigating away. The entry created here will appear on the Time Tracking page in real time — refresh is not needed. When you start a different timer or manually stop this one, the elapsed duration is saved automatically.

**Kinesthetic prompt:** Go to the kanban board, open a job card, and start a timer from the detail panel.

---

### Chapter 4 — Logging Manual Time
**Estimated timestamp:** 200s
**UI Element:** `app-time-tracking .action-btn--primary`
**Chapter label:** "Manual Entry"

**Narration Script:**
Sometimes you forget to start a timer. That is normal. Use the New Entry button on this page to log time after the fact. The manual entry form has four fields: Job — search by job number or customer name. Date — defaults to today, but you can change it to any past date. Start Time — when did you begin work. End Time — when did you stop. The system calculates the duration automatically from the start and end times. You do not need to enter hours directly — enter wall clock times and let the math happen. After saving, the entry appears in the correct day section on this page. Managers can see all manual entries and whether they are flagged for review.

**Alternative paths:** If you need to log time across midnight — for example a shift that starts at 11 PM and ends at 1 AM — enter the end time as-is and the system handles the date rollover. Entries cannot be back-dated more than 14 days without manager approval, depending on your company's settings.

**Kinesthetic prompt:** Create a manual entry for 2 hours of work on any job. Set the start time to 9:00 AM and end time to 11:00 AM and verify the duration calculates correctly.

---

### Chapter 5 — Editing and Deleting Entries
**Estimated timestamp:** 270s
**UI Element:** `app-time-tracking app-data-table`
**Chapter label:** "Editing Entries"

**Narration Script:**
Click any row in the time entry list to open the edit dialog. From here you can change the job, the date, or the start and end times. Click Save to apply changes. The duration recalculates automatically. To delete an entry, open it and click the Delete button — a confirmation dialog will appear. Once deleted, the entry is gone and the hours are removed from your total. Note that entries submitted to payroll — which show a different status indicator — may be locked from editing. If you need to correct a locked entry, contact your manager who has override access. Managers see an additional field showing whether each entry has been approved for payroll.

**Alternative paths:** Entries that are part of an approved timesheet appear with a checkmark status. These cannot be self-edited — this protects payroll accuracy. Managers can still edit or override approved entries from the Admin panel.

**Kinesthetic prompt:** Click on a time entry you created and change the end time by 15 minutes. Save and observe the duration update.

---

### Chapter 6 — Reading the Weekly Summary
**Estimated timestamp:** 335s
**UI Element:** `app-time-tracking app-data-table`
**Chapter label:** "Weekly Summary"

**Narration Script:**
Scroll to the bottom of the time entry list. You will see a weekly summary bar. It shows your total hours logged for the current week, broken out by day. Green days mean you met your expected hours. Yellow means slightly under. Red means significantly under or that you have no entries for that day. This is your daily self-check — before you leave for the day, glance at this bar and make sure today is not red. If it is, either log the missing time now or notify your manager. The summary bar also shows a total hours count for the week — useful for contract workers or hourly employees who need to confirm they have hit their required hours before the week closes.

**Alternative paths:** The expected hours per day depends on your work schedule as configured in your employee profile. Full-time employees typically see 8 hours as the target. Part-time or flex schedules may show different thresholds. If your schedule is wrong, contact your admin to update it.

**Kinesthetic prompt:** Look at your weekly summary. Is today green, yellow, or red? What would you need to add to make it green?

---

### Chapter 7 — Clock-In vs. Job Timer (What is the Difference?)
**Estimated timestamp:** 400s
**UI Element:** `app-time-tracking app-toolbar`
**Chapter label:** "Clock-In vs Timer"

**Narration Script:**
There are two distinct concepts in time tracking that often confuse new users: clocking in and timers. Clocking in records your daily attendance — the moment you arrive and when you leave. It is a single daily record. A job timer records how long you spent on a specific task. You can have many timer entries in one day across many jobs. Think of it this way: clocking in proves you were at work. Job timers prove what you worked on and for how long. Both are required. Clock in when you arrive at the shop. Then start job timers as you move from task to task throughout the day. Clock out when you leave. Job timers stop automatically when you clock out.

**Alternative paths:** Shop floor workers using the kiosk display have a combined flow — clocking in at the kiosk also allows them to immediately start a job timer in the same screen. Desk workers typically clock in via the dashboard and start job timers separately.

**Kinesthetic prompt:** Look at today's entries. Can you identify which is the clock-in entry versus the job timer entries?

---

### Chapter 8 — What Happens If You Forget to Clock Out?
**Estimated timestamp:** 470s
**UI Element:** `app-time-tracking app-toolbar`
**Chapter label:** "Missed Clock-Out"

**Narration Script:**
It happens to everyone eventually — you forget to clock out. When you log in the next morning and the system detects an open clock-in from the previous day, it will prompt you to confirm when you actually left. A dialog appears asking for your clock-out time from yesterday. Enter the correct time and the record is fixed. If you are not sure exactly when you left, enter your best estimate and add a note. Your manager will see flagged entries — ones where the system detected a likely error or where the shift was unusually long. These show a yellow warning badge on the entry row. The manager can confirm or correct them from the admin panel.

**Alternative paths:** If no action is taken on a missed clock-out within 24 hours, the entry may be auto-closed at a configurable default time (usually end of shift) with a flag for manager review. Your admin sets this behavior in system settings.

**Kinesthetic prompt:** On the Time Tracking page, look for any entries with a warning badge. If none exist, ask your manager what a flagged entry looks like.

---

### Chapter 9 — Manager View: Team Time Summary
**Estimated timestamp:** 540s
**UI Element:** `app-time-tracking app-data-table`
**Chapter label:** "Manager View"

**Narration Script:**
If you have Manager or Admin role, the Time Tracking page shows an additional view: the team summary. At the top of the page you will see a toggle to switch between My Time and Team Time. In Team Time mode, the page shows all entries for all employees. You can filter by person to drill into a specific employee's week. The summary bar at the bottom updates to show team-wide totals — useful for payroll processing or billing clients by team hours. From this view you can approve entries, flag them for correction, or leave comments visible only to the employee. Approved entries become locked and contribute to the payroll run.

**Alternative paths:** Office Manager role also has access to Team Time view, specifically for payroll processing. Engineers and Production Workers only see their own entries.

**Kinesthetic prompt:** If you have manager access, switch to Team Time view. Filter to show entries for one employee and note their weekly total.

---

### Chapter 10 — Exporting Time Data
**Estimated timestamp:** 610s
**UI Element:** `app-time-tracking app-toolbar`
**Chapter label:** "Exporting Time"

**Narration Script:**
To export time data, use the Export button in the toolbar — it looks like a download arrow. A dialog lets you choose the export format: CSV for spreadsheet analysis, or PDF for a formatted timesheet report. You can export your own time, or managers can export for any employee or the entire team. The date range defaults to the current week, but you can adjust it to any range. The CSV output includes: job number, customer, task description, date, start time, end time, and duration in decimal hours — ready to import into Excel or payroll software. The PDF version formats as a professional timesheet with your name, the date range, daily totals, and a weekly grand total.

**Alternative paths:** Time data is also available through the Report Builder (the Reports page) for more advanced filtering and grouping — for example, time by customer to calculate billable hours per account, or time by job to calculate actual versus estimated hours on a project.

**Kinesthetic prompt:** Export your current week's time as a CSV. Open the file and verify the decimal hours column matches what you see on screen.

---

## Full Transcript

Welcome to the time tracking page. Let's orient ourselves first. At the top you have a toolbar with date navigation and a New Entry button. Below it, time entries are grouped by day — today at the top, earlier days below. At the very bottom is your weekly summary bar. Every hour you work should have a corresponding row here. If it does not, job costs will be wrong.

The fastest way to start tracking time is from your dashboard. In the Today's Tasks widget, each job has a play button. One click starts a timer, linked to that job. The timer count appears in the header bar. Only one timer runs at a time — starting a new one auto-stops the previous one and saves the elapsed time. You never lose a minute.

You can also start a timer from any job card on the kanban board. Open the card and click the timer icon in the detail panel. Same result.

If you forget to log time, use the New Entry button. Fill in the job, date, start time, and end time. The duration calculates automatically. No mental math required.

Click any entry to edit it — change the job, times, or date. Delete with the delete button. Entries submitted to payroll are locked; contact your manager for corrections.

Scroll to the weekly summary at the bottom. Green days mean you met your expected hours. Yellow means slightly under. Red means missing entries. Check this before you leave every day.

Remember the distinction between clocking in — proving you were at work — and job timers — proving what you worked on. Both are required. Clock in when you arrive, start job timers as you move through tasks, clock out when you leave.

Managers see a Team Time view to review all employees' entries, approve them for payroll, and export formatted timesheets. The Export button creates a CSV or PDF for any date range or employee.

---

## Playwright Generation Spec

```json
{
  "appRoute": "/time-tracking",
  "embedUrl": "https://www.youtube.com/embed/YE7VzlLtp-4",
  "steps": [
    {
      "element": "app-time-tracking",
      "popover": {
        "title": "Dashboard Overview",
        "description": "You are on the Time Tracking page. Orient yourself before acting. At the top is a toolbar with date navigation and a New Entry button. Below it, entries are grouped by day — today at the top. At the very bottom is your weekly summary bar. Every hour you work should appear as a row here. If it does not, job costs will be wrong and your timesheet will be incomplete."
      }
    },
    {
      "element": "app-time-tracking app-toolbar",
      "popover": {
        "title": "Starting a Timer",
        "description": "The fastest way to start tracking time is from your main dashboard, not this page. In the Today's Tasks widget, each job has a play button. Click it and a timer starts immediately, linked to that job. The timer appears in the application header bar so you always know whether one is running. Only one timer runs at a time — starting a new one automatically stops the current one and saves the elapsed time as a completed entry. You never lose time by switching jobs."
      }
    },
    {
      "element": "app-time-tracking .action-btn--primary",
      "popover": {
        "title": "Timer from a Job Card",
        "description": "You can also start a timer directly from the kanban board. Open any job card and look in the detail panel for the timer icon near the top. Click it. The icon animates and the header count starts. This is useful when you are already reviewing jobs on the board. The entry appears on this page in real time. When you start a different timer or stop this one manually, the duration saves automatically."
      }
    },
    {
      "element": "app-time-tracking .action-btn--primary",
      "popover": {
        "title": "Manual Entry",
        "description": "Forgot to start a timer? Use New Entry to log time after the fact. Fill in the job, date, start time, and end time. The duration calculates automatically from your start and end times — no mental math. The entry appears in the correct day section. Entries cannot be back-dated more than 14 days without manager approval. If you worked across midnight, enter the real end time and the system handles the date rollover."
      }
    },
    {
      "element": "app-time-tracking app-data-table",
      "popover": {
        "title": "Editing Entries",
        "description": "Click any row to open the edit dialog. Change the job, date, or start and end times. Duration recalculates on save. To delete, open the entry and click Delete — a confirmation will appear. Entries submitted to payroll show a locked indicator and cannot be self-edited. If you need to correct a locked entry, contact your manager who has override access. Managers see an approval status field on every entry."
      }
    },
    {
      "element": "app-time-tracking app-data-table",
      "popover": {
        "title": "Weekly Summary",
        "description": "Scroll to the bottom of the list to see your weekly summary bar. Green days mean you met your expected hours. Yellow means slightly under. Red means significantly under or no entries that day. Check this bar before you leave each day. If today is red, either log the missing time now or notify your manager. The bar also shows your total weekly hours — important for hourly employees confirming they have met their required hours."
      }
    },
    {
      "element": "app-time-tracking app-toolbar",
      "popover": {
        "title": "Clock-In vs Timer",
        "description": "Two distinct concepts: clocking in records your daily attendance — when you arrive and leave, one record per day. Job timers record how long you spent on specific tasks — many per day. Think of it this way: clocking in proves you were at work, job timers prove what you worked on. Both are required. Clock in when you arrive. Start job timers as you move from task to task. Clock out when you leave. Job timers stop automatically when you clock out."
      }
    },
    {
      "element": "app-time-tracking app-toolbar",
      "popover": {
        "title": "Missed Clock-Out",
        "description": "If you forget to clock out, the system detects an open clock-in when you log in next morning and prompts you to confirm your actual departure time. Enter your best estimate and add a note if unsure. Your manager will see flagged entries — shown with a yellow warning badge. If no action is taken within 24 hours, the entry may be auto-closed at a configurable default time with a flag for manager review."
      }
    },
    {
      "element": "app-time-tracking app-data-table",
      "popover": {
        "title": "Manager View",
        "description": "Managers and Admins see a Team Time toggle at the top of the page. Switching to Team Time shows all entries for all employees. Filter by person to drill into one employee's week. The summary bar updates to show team-wide totals — useful for payroll processing. From this view you can approve entries, flag them for correction, or leave comments visible only to the employee. Approved entries become locked and contribute to the payroll run."
      }
    },
    {
      "element": "app-time-tracking app-toolbar",
      "popover": {
        "title": "Exporting Time",
        "description": "Click the Export button — a download arrow icon — to export time data. Choose CSV for spreadsheet analysis or PDF for a formatted timesheet. Adjust the date range from the current week to any custom range. The CSV includes job number, customer, description, date, start time, end time, and decimal hours — ready for Excel or payroll software. The PDF formats as a professional timesheet with daily totals and a weekly grand total. Managers can export for any employee or the entire team."
      }
    }
  ],
  "chaptersJson": [
    { "timeSeconds": 0, "label": "Dashboard Overview" },
    { "timeSeconds": 55, "label": "Starting a Timer" },
    { "timeSeconds": 125, "label": "Timer from a Job Card" },
    { "timeSeconds": 200, "label": "Manual Entry" },
    { "timeSeconds": 270, "label": "Editing Entries" },
    { "timeSeconds": 335, "label": "Weekly Summary" },
    { "timeSeconds": 400, "label": "Clock-In vs Timer" },
    { "timeSeconds": 470, "label": "Missed Clock-Out" },
    { "timeSeconds": 540, "label": "Manager View" },
    { "timeSeconds": 610, "label": "Exporting Time" }
  ]
}
```
