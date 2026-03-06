# Roles & Authentication

## Auth System
- ASP.NET Identity with custom ApplicationUser
- JWT bearer tokens for Angular SPA
- Refresh token rotation (long-lived sessions for workstation use)
- Password hashing via Identity defaults (bcrypt)
- First-run: default admin account seeded, forced password change

## Roles (Additive — users can hold multiple)

| Role | Access |
|---|---|
| Engineer | Kanban board, assigned work, file attachments, expense logging, daily prompts, time tracking |
| PM | Backlog curation, Planning Day, lead management, reporting, priority setting (read-only board) |
| Production Worker | Simplified task list, start/stop timer, move cards within production stages, add notes/photos |
| Manager | Everything PM + assign work, approve expenses, set priorities for others |
| Office Manager | Customer/vendor management, invoice workflow queue, employee docs |
| Admin | Everything + user management, role assignment, system settings, track type config |

## Permissions
- Roles are not mutually exclusive — stored as multiple AspNetUserRoles entries
- Permissions are the union of all assigned roles
- UI adapts: nav items, dashboard sections, available actions all based on role set
- [Authorize(Roles = "...")] on API endpoints

## User-Level Settings
- canSelfApproveExpenses: boolean (default false)
- selfApprovalLimit: decimal | null (null = unlimited when self-approve is on)
- Default dashboard view preference
- Notification preferences (per notification type: in-app only or in-app + email)
- QB linked flag + OAuth tokens (if per-user linking used)

## User Onboarding
- **Admin/Manager initiates** — no self-registration; admin creates a user record from the User Management screen
- Admin enters: name, role(s), department/team (optional), direct manager (optional), email (optional), badge/scan ID (optional — barcode, NFC, or card ID for shop floor time clock)
- Two claim methods:
  - **On-site setup code (default):** system generates a short code (e.g., 6-digit alphanumeric) displayed to admin. Employee navigates to setup page, enters their name or setup code, sets their own password.
  - **Email invite (optional):** if SMTP is configured and employee has an email, admin can send a one-time invite link instead. Link expiry configurable (default 7 days).
- Setup codes / invite links expire after use or after a configurable window (default 7 days)
- Admin sees unclaimed accounts with the ability to regenerate codes or resend invites
- If the shop uses QB integration, the user record is synced to QB as an Employee on creation

## User Offboarding
- Admin deactivates the account from User Management — **never hard-deleted**
- Deactivated users: cannot log in, removed from assignee dropdowns, removed from active worker presence list
- All historical records (time entries, task completions, expense submissions, audit trail) are preserved and attributed
- Active tasks reassigned: admin prompted to reassign or return to backlog during deactivation
- If QB-synced, employee marked inactive in QB
- **Reactivation:** admin reactivates the account from User Management — employee logs in with their existing password, no reset required. All prior history (time, tasks, expenses) is immediately visible again. If QB-synced, employee marked active in QB.
- Optional: admin can trigger credential/session revocation for immediate lockout (e.g., termination scenario). In this case, a password reset is required on reactivation.

## Initial Setup
- Seed roles on first run
- Seed default admin account — credentials in console logs, forced password change
- QB OAuth connection wizard after first login

## Production Worker Experience
- Login → simple task list (not Kanban)
- Big start/stop timer button per task
- Move card to next production stage
- Add notes/photos
- No nav menu, dashboards, settings, or admin features

## Shop Floor Display
- Dedicated route /display/shop-floor — no login required
- Read-only, trusted LAN, kiosk mode browser
- Shows: active jobs, machine status, worker presence/current task, cycle progress
