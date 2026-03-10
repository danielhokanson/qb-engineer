# Roles & Authentication

## Auth System
- ASP.NET Identity with custom ApplicationUser
- JWT bearer tokens for Angular SPA
- Refresh token rotation (long-lived sessions for workstation use)
- Password hashing via Identity defaults (bcrypt)
- First-run: default admin account seeded, forced password change

## Tiered Authentication

The app supports three authentication tiers, optimized for different environments. Simpler tiers are designed for the shop floor kiosk where speed and simplicity matter most.

### Tier 1: RFID / NFC (Fastest — Kiosk Primary)
- Employee taps phone (NFC) or badge (RFID card) against the kiosk reader
- System identifies the user by their registered device/badge ID
- **PIN required** — after scan, user enters a short numeric PIN (4-6 digits) on screen
- PIN is stored as a hashed value on `ApplicationUser` (separate from password)
- Failed PIN attempts: lockout after 5 consecutive failures (configurable), admin reset required
- Admin registers badge/NFC IDs during user onboarding (or user self-registers on first scan with full credential login)

### Tier 2: Barcode Scan (Fast — Kiosk Fallback)
- Employee scans their personal barcode badge (keyboard wedge scanner reads as input)
- System identifies user by barcode value stored on `ApplicationUser.BadgeScanId`
- **PIN required** — same PIN prompt as Tier 1
- Barcode can be printed from admin user management screen (bwip-js)
- Workers without NFC-capable phones use this tier

### Tier 3: Username + Password (Standard — Desktop/Mobile)
- Traditional login form — username (or email) + password
- Used for desktop browser sessions, mobile app access, and as universal fallback
- Full ASP.NET Identity flow: password complexity rules, lockout on failed attempts
- Refresh token rotation for long-lived sessions

### Authentication Tier Selection
- **Kiosk display** (`/display/shop-floor/clock`): Tiers 1 and 2 are primary. Tier 3 available via "Manual Login" link.
- **Desktop/mobile app**: Tier 3 is primary. NFC/badge not applicable.
- **Admin configures available scan methods** in system settings (same as existing time clock config):
  - Barcode scanner (keyboard wedge)
  - NFC reader
  - RFID reader
  - If no scan hardware configured, kiosk defaults to Tier 3 only

### PIN Management
- User sets their own PIN during account setup (optional — required only if scan hardware is configured)
- Admin can reset a user's PIN (generates a temporary PIN, user must change on next scan)
- PIN is NOT the same as password — it's a short numeric code for quick kiosk auth only
- PIN never transmitted in URLs or logs — always hashed at rest, compared server-side

## Enterprise SSO (Cloud Deployment)

When the application is exposed to the internet (cloud deployment, VPN-accessible, etc.), enterprise SSO provides a fourth authentication tier.

### Supported Providers
- **Google** (OAuth 2.0 / OpenID Connect) — for Gmail/Workspace accounts
- **Microsoft** (Azure AD / Entra ID) — for Outlook/Microsoft 365 accounts
- **Generic OIDC** — any OpenID Connect provider (Okta, Auth0, Keycloak, etc.)

### How It Works
- Admin configures SSO provider(s) in Settings → Integrations → Authentication
- Each provider requires: Client ID, Client Secret, Authority URL (for OIDC)
- Login page shows "Sign in with Google" / "Sign in with Microsoft" buttons alongside the standard username/password form
- First SSO login: if the email matches an existing user account, the SSO identity is **linked** to that account. If no match, the login is rejected (no self-registration — admin must create the account first).
- Subsequent SSO logins: user is authenticated via the linked SSO identity, no password needed
- A user can have both a local password AND linked SSO identities — either method works
- Admin can unlink SSO identities from user management

### SSO + Local Auth Coexistence
- SSO does NOT replace local auth — it's additive
- Users without SSO still use username/password (Tier 3) or scan+PIN (Tiers 1/2)
- Kiosk/shop floor always uses scan+PIN (SSO not applicable to kiosk — no browser redirect flow)
- SSO is optional and off by default — only relevant when the app is internet-accessible

### Implementation
- ASP.NET Identity external login providers (`AddGoogle`, `AddMicrosoftAccount`, `AddOpenIdConnect`)
- `ExternalLoginInfo` linked to `ApplicationUser` via `AspNetUserLogins` table
- Angular login page conditionally shows SSO buttons based on configured providers (fetched from public endpoint)

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
- **Admin enters basic info only:** display name, role(s), department/team (optional), direct manager (optional), email (optional), badge/scan ID (optional)
- **Admin does NOT set the user's password** — admin creates the account and provides a setup token. The employee completes their own account setup.
- Two claim methods:
  - **On-site setup token (default):** system generates a short token (6-digit alphanumeric) displayed to admin. Admin gives the token to the employee (verbally, printed, etc.). Employee navigates to the setup page (`/setup`), enters the token, then completes their account: sets username, password, optional PIN (for kiosk scan auth), and any profile details.
  - **Email invite (optional):** if SMTP is configured and employee has an email, admin can send a one-time invite link instead. Link opens the same setup page with the token pre-filled. Link expiry configurable (default 7 days).
- **What admin CAN modify after creation:** display name, role(s), department, direct manager, badge/scan ID, active/inactive status
- **What admin CANNOT do:** view or set passwords, view PINs. Admin can only **reset** credentials — this generates a new setup token, invalidates the current password/PIN, and forces the employee to re-complete setup.
- Setup tokens expire after use or after a configurable window (default 7 days)
- Admin sees unclaimed accounts with the ability to regenerate tokens or resend invites
- If the shop uses accounting integration, the user record is synced as an Employee on creation

## User Offboarding
- Admin deactivates the account from User Management — **never hard-deleted**
- Deactivated users: cannot log in, removed from assignee dropdowns, removed from active worker presence list
- All historical records (time entries, task completions, expense submissions, audit trail) are preserved and attributed
- Active tasks reassigned: admin prompted to reassign or return to backlog during deactivation
- If QB-synced, employee marked inactive in QB
- **Reactivation:** admin reactivates the account from User Management — employee logs in with their existing password, no reset required. All prior history (time, tasks, expenses) is immediately visible again. If QB-synced, employee marked active in QB.
- Optional: admin can trigger credential/session revocation for immediate lockout (e.g., termination scenario). In this case, admin generates a new setup token — the employee must re-complete account setup (new password + PIN) on reactivation.

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
