# Employee Account

Functional reference for the employee self-service account feature at `/account`.

---

## 1. Overview

The Account feature is the employee self-service hub. It provides a sidebar-navigated, multi-page layout where authenticated users manage their personal profile, contact information, emergency contacts, compliance forms, payroll documents, security settings, display preferences, and external integrations.

The account layout uses `AccountLayoutComponent` as a shell with a persistent left sidebar (`AccountSidebarComponent`) and a `<router-outlet>` for the active page. On mobile, the layout stacks vertically. The `EmployeeProfileService` is loaded once at the layout level (`ngOnInit`) and shared across all child pages.

---

## 2. Routes

All routes are children of `/account` and lazy-loaded via `loadComponent`.

| Route | Component | Description |
|-------|-----------|-------------|
| `/account` | redirects to `/account/profile` | Default landing page |
| `/account/profile` | `AccountProfileComponent` | Personal info, avatar, name |
| `/account/contact` | `AccountContactComponent` | Phone, email, mailing address |
| `/account/emergency` | `AccountEmergencyComponent` | Emergency contact details |
| `/account/tax-forms` | `AccountTaxFormsComponent` | All compliance form list |
| `/account/tax-forms/:formType` | `AccountTaxFormDetailComponent` | Individual form detail/fill |
| `/account/documents` | `AccountDocumentsComponent` | Personal document uploads |
| `/account/pay-stubs` | `AccountPayStubsComponent` | Pay stub history (DataTable) |
| `/account/tax-documents` | `AccountTaxDocumentsComponent` | W-2, 1099 documents (DataTable) |
| `/account/security` | `AccountSecurityComponent` | Password, PIN, MFA |
| `/account/customization` | `AccountCustomizationComponent` | Theme, font scale, draft TTL |
| `/account/integrations` | `AccountIntegrationsComponent` | External service connections |

The sidebar also links to `/onboarding` (the guided onboarding wizard, which is a separate feature).

---

## 3. Sidebar Navigation

`AccountSidebarComponent` renders a vertical nav with completion status indicators.

### Navigation Items (Top Section)

| Item | Route | Icon | Completion Tracking |
|------|-------|------|---------------------|
| Profile | `profile` | `person` | None |
| Contact | `contact` | `home` | Key: `address` |
| Emergency | `emergency` | `emergency` | Key: `emergency_contact` |

### Onboarding Link

A link to `/onboarding` appears after the top section. Shows a green check when `onboardingStatus.allComplete` is true, or a warning icon when incomplete.

### Tax & Compliance (Collapsible)

Visible only after onboarding is complete. Contains:

- **All Forms** link to `/account/tax-forms`
- Dynamic child links from `ComplianceFormService.templates()`, one per template
  - Wizard-managed forms (W-4, I-9, State Withholding, Direct Deposit, Workers' Comp, Handbook) link to `/onboarding`
  - Other forms link to `/account/tax-forms/:profileCompletionKey`
- Completion keys: `w4`, `i9`, `state_withholding`, `direct_deposit`, `workers_comp`, `handbook`
- Section-level completion: all six keys must be complete for the green check

### Navigation Items (Bottom Section)

| Item | Route | Icon | Completion Tracking |
|------|-------|------|---------------------|
| Documents | `documents` | `folder` | None |
| Pay Stubs | `pay-stubs` | `payments` | None |
| Tax Documents | `tax-documents` | `receipt_long` | None |
| Security | `security` | `lock` | None |
| Customization | `customization` | `palette` | None |
| Integrations | `integrations` | `extension` | None |

### Completion Indicators

Each nav item and child item shows one of:
- Green `check_circle` icon when the associated profile completeness item is complete
- Orange `warning` icon when incomplete
- No icon when the item has no completion tracking

The completion data comes from `EmployeeProfileService.completeness()`, which calls `GET /api/v1/employee-profile/completeness`.

### Back Button

A back button at the top navigates to `/dashboard`.

---

## 4. Profile Page

**Route:** `/account/profile`
**Component:** `AccountProfileComponent`

Displays the user's avatar, email, roles, and editable personal information.

### Layout

Two-card grid:
1. **Left card** -- avatar preview, email display, role badges, and form fields
2. **Right card** -- avatar color picker grid

### Form Fields

| Field | Control | FormControl | Validators | Notes |
|-------|---------|-------------|------------|-------|
| First Name | `<app-input>` | `firstName` | `required`, `maxLength(100)` | Saved to auth profile |
| Last Name | `<app-input>` | `lastName` | `required`, `maxLength(100)` | Saved to auth profile |
| Initials | `<app-input>` | `initials` | `maxLength(3)` | Placeholder: "e.g. DH" |
| Date of Birth | `<app-datepicker>` | `dateOfBirth` | None | Saved to employee profile |
| Gender | `<app-select>` | `gender` | None | Options: None, Male, Female, Non-binary, Prefer not to say |
| Avatar Color | Color swatch grid | `avatarColor` | None | 12 preset colors |

### Avatar Color Picker

A grid of 12 color swatches. Clicking a swatch selects it (shows a checkmark) and updates the `avatarColor` form control. Colors:

```
#6366f1, #8b5cf6, #ec4899, #ef4444, #f97316,
#eab308, #22c55e, #14b8a6, #06b6d4, #3b82f6,
#64748b, #78716c
```

### Save Behavior

The Save button triggers two parallel API calls:

1. `PUT /api/v1/auth/profile` -- updates `firstName`, `lastName`, `initials`, `avatarColor` on the auth user
2. `PUT /api/v1/employee-profile` -- updates `dateOfBirth`, `gender` (plus all existing profile fields preserved)

On success, `AuthService.refreshUser()` updates the in-memory user for immediate sidebar/header reflection, and a success snackbar appears.

### Validation

Uses `ValidationPopoverDirective` on the Save button. Violations shown on hover when form is invalid.

---

## 5. Contact Page

**Route:** `/account/contact`
**Component:** `AccountContactComponent`

### Form Fields

| Field | Control | FormControl | Validators | Notes |
|-------|---------|-------------|------------|-------|
| Phone Number | `<app-input>` | `phoneNumber` | `phoneValidator` | Mask: `phone` -- formats `(XXX) XXX-XXXX` |
| Personal Email | `<app-input>` | `personalEmail` | `email`, `maxLength(200)` | Type: `email` |
| Mailing Address | `<app-address-form>` | `address` | None | CVA wrapper, fixed country: US |

### Address Form Sub-Fields

The `AddressFormComponent` provides:
- Street 1, Street 2, City, State (dropdown), ZIP Code, Country (fixed to US)
- Optional address verification via USPS API

### Save Behavior

Calls `EmployeeProfileService.updateProfile()` which sends `PUT /api/v1/employee-profile`. All existing profile fields not on this form are preserved by reading current profile state.

---

## 6. Emergency Contact Page

**Route:** `/account/emergency`
**Component:** `AccountEmergencyComponent`

### Form Fields

| Field | Control | FormControl | Validators | Notes |
|-------|---------|-------------|------------|-------|
| Contact Name | `<app-input>` | `emergencyContactName` | `required`, `maxLength(200)` | |
| Contact Phone | `<app-input>` | `emergencyContactPhone` | `required`, `phoneValidator` | Mask: `phone` |
| Relationship | `<app-select>` | `emergencyContactRelationship` | None | Options: i18n-driven list |

### Relationship Options

| Value | Label Key |
|-------|-----------|
| `null` | `account.relationshipSelect` (-- Select --) |
| `Spouse` | `account.relationshipSpouse` |
| `Parent` | `account.relationshipParent` |
| `Sibling` | `account.relationshipSibling` |
| `Child` | `account.relationshipChild` |
| `Friend` | `account.relationshipFriend` |
| `Other` | `account.relationshipOther` |

### Save Behavior

Same pattern as Contact page: preserves all other profile fields, calls `PUT /api/v1/employee-profile`.

---

## 7. Security Page

**Route:** `/account/security`
**Component:** `AccountSecurityComponent`

Three card sections arranged in a grid.

### 7.1 Change Password

| Field | Control | FormControl | Validators |
|-------|---------|-------------|------------|
| Current Password | `<app-input>` type=password | `currentPassword` | `required` |
| New Password | `<app-input>` type=password | `newPassword` | `required`, `minLength(8)` |
| Confirm Password | `<app-input>` type=password | `confirmPassword` | `required` |

**Mismatch check:** A `computed()` signal compares `newPassword` and `confirmPassword`. If they differ, a warning message appears and the button is disabled.

**API:** `POST /api/v1/auth/change-password` with `{ currentPassword, newPassword }`.

### 7.2 Kiosk PIN

For shop floor kiosk authentication (RFID/barcode + PIN flow).

| Field | Control | FormControl | Validators |
|-------|---------|-------------|------------|
| PIN | `<app-input>` type=password | `pin` | `required`, `pattern(/^\d{4,8}$/)` |
| Confirm PIN | `<app-input>` type=password | `confirmPin` | `required` |

**Hint text:** Explains this PIN is used for shop floor kiosk sign-in, separate from the account password.

**PIN mismatch:** Same pattern as password mismatch.

**API:** `POST /api/v1/auth/set-pin` with `{ pin }`. PIN is PBKDF2 hashed server-side.

### 7.3 Two-Factor Authentication (MFA)

Loaded on `ngOnInit` via `MfaService.getStatus()`.

**When MFA is enabled:**
- Green status badge: "Two-factor authentication is **enabled**"
- Policy enforcement notice if `isEnforcedByPolicy` is true
- Registered devices list showing:
  - Device icon (`phone_android` for TOTP, `key` for others)
  - Device name (or type as fallback)
  - Last used date
  - "Default" chip for default device
  - Delete button (red icon-btn) per device
- Recovery codes remaining count
- Action buttons:
  - **Add Device** -- opens `MfaSetupDialogComponent`
  - **New Recovery Codes** -- opens `MfaRecoveryCodesDialogComponent`
  - **Disable MFA** -- confirmation dialog, hidden when policy-enforced

**When MFA is disabled:**
- Shield icon: "Two-factor authentication is **not enabled**"
- Policy enforcement warning if required by policy
- Hint text explaining the benefit
- **Enable Two-Factor Authentication** button -- opens `MfaSetupDialogComponent`

### MFA Setup Dialog

`MfaSetupDialogComponent` -- 480px dialog with a multi-step flow:

1. **Loading** -- calls `POST /api/v1/auth/mfa/setup` to get setup data
2. **Scan** -- displays QR code (via `QrCodeComponent`) with the TOTP URI. Optional "Show manual key" toggle for clipboard copy.
3. **Verify** -- 6-digit code input (pattern: `/^\d{6}$/`). Calls `POST /api/v1/auth/mfa/verify-setup` with `{ deviceId, code }`.
4. **Complete** -- success confirmation, dialog closes with `true` result

### MFA Recovery Codes Dialog

`MfaRecoveryCodesDialogComponent` -- generates new recovery codes via `POST /api/v1/auth/mfa/recovery-codes`. Returns a list of one-time-use codes for the user to save.

### Device Removal

Confirmation dialog (severity: `danger`) before calling `DELETE /api/v1/auth/mfa/devices/{deviceId}`. Warns if it is the only device.

### Disable MFA

Confirmation dialog (severity: `danger`) before calling `DELETE /api/v1/auth/mfa/disable`. Warns about removing all devices and recovery codes. Not available when MFA is enforced by organization policy.

---

## 8. Customization Page

**Route:** `/account/customization`
**Component:** `AccountCustomizationComponent`

Three card sections.

### 8.1 Color Theme

Toggle between Light and Dark themes. Visual preview swatches show a simplified representation of each theme. Active theme has a highlighted border.

- Calls `ThemeService.toggle()` which sets `[data-theme]` attribute on `<html>` and persists to localStorage
- Syncs across tabs via `storage` event

### 8.2 Display Preferences (Font Scale)

Four radio-style buttons:

| Value | Label Key | Base Size |
|-------|-----------|-----------|
| `default` | `account.fontScaleDefault` | 12px |
| `comfortable` | `account.fontScaleComfortable` | 14px |
| `large` | `account.fontScaleLarge` | 16px |
| `xl` | `account.fontScaleXl` | 18px |

Each button shows a label, hint size, and "Aa" sample text. Calls `ThemeService.setFontScale(scale)`.

### 8.3 Draft Retention (TTL)

Controls how long unsaved form drafts are kept before expiration. Options come from `DRAFT_TTL_OPTIONS` constant (defined in `shared/models/draft-ttl.model.ts`). Typical options: 1 day, 3 days, 1 week, 2 weeks.

Saved to `UserPreferencesService` under key `draft:ttlMs`. Used by `DraftRecoveryService` for TTL cleanup.

---

## 9. Tax & Compliance Forms

### 9.1 Forms List Page

**Route:** `/account/tax-forms`
**Component:** `AccountTaxFormsComponent`

Displays all compliance form templates loaded from `GET /api/v1/compliance-forms`.

**Onboarding banner:** When `onboardingStatus.allComplete` is false, a prominent banner links to `/onboarding` encouraging the user to complete the guided workflow.

**Form list:** Each template renders as a clickable card showing:
- Template icon (or green `check_circle` if complete)
- Template name and description
- "Completed in onboarding wizard" badge for wizard-managed forms that are not yet complete
- Completion date (from `EmployeeProfile.*CompletedAt` fields)
- "Required" badge for forms that block job assignment (`blocksJobAssignment`)
- Chevron icon for navigation

**Wizard-managed form types** (W4, I9, StateWithholding, DirectDeposit, WorkersComp, Handbook) link to `/onboarding`. Other forms link to `/account/tax-forms/:profileCompletionKey`.

### 9.2 Form Detail Page

**Route:** `/account/tax-forms/:formType`
**Component:** `AccountTaxFormDetailComponent`

Complex page handling multiple form flows depending on template configuration.

**Redirect behavior:** If the form type is wizard-managed AND not yet complete, the component redirects to `/onboarding` via an `effect()`.

**Data loading:** On form type change, loads templates, submissions, and profile completeness. For state withholding, also loads the state-specific form definition from `GET /api/v1/compliance-forms/my-state-definition`.

#### Completed State

When the form is complete (and not resubmitting):
- Green status bar with completion date
- For wizard-managed forms: summary card with non-sensitive field summaries
  - **W-4:** Filing Status, Multiple Jobs, Exempt
  - **I-9:** Citizenship Status, Documents Verified count
  - **State Withholding:** Filing Status, Allowances, Additional Withholding, Exempt
  - **Direct Deposit:** Bank Name, Account Type, Routing (last 4), Account (last 4) -- masked
- Download PDF button (from `GET /api/v1/compliance-forms/submissions/{id}/pdf`)
- Update/Resubmit button (not available for I-9 -- locked after completion per legal requirements)

#### Active Form (Electronic)

When a `formDefinition` is available and the form is not complete (or user chose to resubmit):
- Renders `ComplianceFormRendererComponent` -- a dynamic form renderer driven by `ComplianceFormDefinition` JSON
- Save Draft button: `PUT /api/v1/compliance-forms/{templateId}/form-data`
- Submit button: `POST /api/v1/compliance-forms/{templateId}/submit-form`
- For I-9: identity document management dialog (see below)

#### Fill-and-Sign Flow

When template has `acroFieldMapJson` and `filledPdfTemplateId`:
1. User fills the electronic form
2. On submit, server fills the actual PDF via AcroForm field mapping
3. DocuSeal signing ceremony URL is returned
4. Signing iframe displayed for employee signature

#### DocuSeal E-Sign (No Form Definition)

When template has `docuSealTemplateId` but no form definition:
- Start E-Sign button creates a submission via `POST /api/v1/compliance-forms/{templateId}/submit`
- DocuSeal signing iframe embedded for the user to complete

#### PDF Viewer Fallback

When no electronic form or DocuSeal:
- Embedded PDF viewer for admin-uploaded files (via `<iframe>`)
- Download link for external URLs (e.g., IRS forms that block iframe embedding)
- Acknowledge button at bottom to mark form as complete

#### Pending Setup State

When the template should have an electronic definition but admin has not extracted it yet, a "pending setup" banner is displayed.

#### Identity Documents (I-9)

When `template.requiresIdentityDocs` is true, a "Supporting Identity Documents" button opens a dialog with:
- List of already-uploaded documents (with verified/pending status)
- Upload zones for List A, List B, and List C documents
- Validation: requires either one List A document OR one List B + one List C document

**Document upload:** `POST /api/v1/identity-documents/me?fileAttachmentId={id}` with `{ documentType, expiresAt }`
**Document deletion:** `DELETE /api/v1/identity-documents/me/{id}`

#### Sensitive Forms

Forms of type W4, I9, and StateWithholding are marked as sensitive. When resubmitting a completed sensitive form, previous data is not pre-filled (to avoid displaying SSN etc.).

---

## 10. Documents Page

**Route:** `/account/documents`
**Component:** `AccountDocumentsComponent`

Simple file upload zone for personal employee documents.

- Entity type: `employee-docs`
- Entity ID: current user's ID
- Accepted file types: `.pdf, .jpg, .jpeg, .png, .doc, .docx`
- Max file size: 25 MB
- Uploads to `POST /api/v1/employee-docs/{userId}/files`

---

## 11. Pay Stubs Page

**Route:** `/account/pay-stubs`
**Component:** `AccountPayStubsComponent`

DataTable listing the employee's pay stubs.

### DataTable Columns

| Field | Header | Type | Sortable | Width | Align | Custom Template |
|-------|--------|------|----------|-------|-------|-----------------|
| `payDate` | Pay Date | `date` | Yes | 120px | | `MM/dd/yyyy` format |
| `period` | Period | -- | No | 200px | | `payPeriodStart - payPeriodEnd` date range |
| `grossPay` | Gross Pay | `number` | Yes | 120px | right | Currency format |
| `netPay` | Net Pay | `number` | Yes | 120px | right | Currency format |
| `totalDeductions` | Deductions | `number` | Yes | 120px | right | Currency format |
| `source` | Source | -- | Yes | 100px | | Chip: "Synced" (info) or "Manual" (muted) |
| `actions` | -- | -- | -- | 60px | | Download PDF icon button |

### API

- Load: `GET /api/v1/payroll/pay-stubs/me`
- Download PDF: Opens `GET /api/v1/payroll/pay-stubs/{id}/pdf` in a new tab (redirects to file attachment)

### Pay Stub Model

```typescript
interface PayStub {
  id: number;
  userId: number;
  payPeriodStart: Date;
  payPeriodEnd: Date;
  payDate: Date;
  grossPay: number;
  netPay: number;
  totalDeductions: number;
  totalTaxes: number;
  fileAttachmentId: number | null;
  source: 'Accounting' | 'Manual';
  externalId: string | null;
  deductions: PayStubDeduction[];
}
```

---

## 12. Tax Documents Page

**Route:** `/account/tax-documents`
**Component:** `AccountTaxDocumentsComponent`

DataTable listing the employee's tax documents (W-2, 1099, etc.).

### DataTable Columns

| Field | Header | Type | Sortable | Width | Custom Template |
|-------|--------|------|----------|-------|-----------------|
| `taxYear` | Tax Year | -- | Yes | 100px | Raw value |
| `documentType` | Document Type | -- | Yes | 160px | Mapped labels (see below) |
| `employerName` | Employer | -- | Yes | -- | Falls back to em dash |
| `source` | Source | -- | Yes | 100px | Chip: "Synced" or "Manual" |
| `actions` | -- | -- | -- | 60px | Download PDF icon button |

### Document Type Labels

| Value | Display |
|-------|---------|
| `W2` | W-2 |
| `W2c` | W-2c (Corrected) |
| `Misc1099` | 1099-MISC |
| `Nec1099` | 1099-NEC |
| `Other` | Other |

### API

- Load: `GET /api/v1/payroll/tax-documents/me`
- Download PDF: Opens `GET /api/v1/payroll/tax-documents/{id}/pdf` in a new tab

---

## 13. Integrations Page

**Route:** `/account/integrations`
**Component:** `AccountIntegrationsComponent`

Manages per-user external service connections grouped by category.

### Categories

| Category | Label | Icon |
|----------|-------|------|
| `calendar` | Calendar | `event` |
| `messaging` | Messaging | `chat` |
| `storage` | Cloud Storage | `cloud` |
| `other` | Other | `extension` |

### Connected Integrations

Each connected integration shows:
- Provider icon and label
- Display name (if set)
- Active/Inactive status badge
- Last sync timestamp
- Last error message (if any)
- Test connection button (spins while testing)
- Disconnect button (danger icon-btn, confirmation dialog)

### Available Providers

Providers not yet connected appear as clickable cards. Clicking opens `ConnectIntegrationDialogComponent` to enter credentials and connect.

### API

- Load connected: `GET /api/v1/user-integrations`
- Load providers: `GET /api/v1/user-integrations/providers`
- Connect: `POST /api/v1/user-integrations` with `CreateIntegrationRequest`
- Disconnect: `DELETE /api/v1/user-integrations/{id}` (confirmation dialog)
- Test: `POST /api/v1/user-integrations/{id}/test`
- Update credentials: `PUT /api/v1/user-integrations/{id}/credentials`
- Update config: `PUT /api/v1/user-integrations/{id}/config`

---

## 14. API Endpoints

### Auth (Account-Related)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `PUT` | `/api/v1/auth/profile` | User | Update name, initials, avatar color |
| `POST` | `/api/v1/auth/change-password` | User | Change password (requires current) |
| `POST` | `/api/v1/auth/set-pin` | User | Set/update kiosk PIN |
| `GET` | `/api/v1/auth/me` | User | Get current user info |
| `POST` | `/api/v1/auth/mfa/setup` | User | Begin TOTP device setup |
| `POST` | `/api/v1/auth/mfa/verify-setup` | User | Verify TOTP code for new device |
| `GET` | `/api/v1/auth/mfa/status` | User | Get MFA status, devices, recovery count |
| `DELETE` | `/api/v1/auth/mfa/disable` | User | Remove all MFA devices/codes |
| `DELETE` | `/api/v1/auth/mfa/devices/{id}` | User | Remove specific MFA device |
| `POST` | `/api/v1/auth/mfa/recovery-codes` | User | Generate new recovery codes |

### Employee Profile

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/employee-profile` | User | Get own employee profile |
| `PUT` | `/api/v1/employee-profile` | User | Update own employee profile |
| `GET` | `/api/v1/employee-profile/completeness` | User | Get profile completeness checklist |
| `POST` | `/api/v1/employee-profile/acknowledge/{formType}` | User | Mark a compliance form acknowledged |

### Compliance Forms

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/compliance-forms` | User | List all active templates |
| `GET` | `/api/v1/compliance-forms/submissions/me` | User | List own submissions |
| `GET` | `/api/v1/compliance-forms/submissions/me/{formType}` | User | Get own submission by form type |
| `GET` | `/api/v1/compliance-forms/my-state-definition` | User | Get state-specific form definition |
| `POST` | `/api/v1/compliance-forms/{id}/submit` | User | Create a new submission (DocuSeal) |
| `PUT` | `/api/v1/compliance-forms/{id}/form-data` | User | Save form draft data |
| `POST` | `/api/v1/compliance-forms/{id}/submit-form` | User | Submit completed form data |
| `GET` | `/api/v1/compliance-forms/submissions/{id}/pdf` | User | Download submission PDF |

### Identity Documents

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/identity-documents/me` | User | List own identity documents |
| `POST` | `/api/v1/identity-documents/me` | User | Upload identity document |
| `DELETE` | `/api/v1/identity-documents/me/{id}` | User | Delete identity document |

### Payroll

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/payroll/pay-stubs/me` | User | List own pay stubs |
| `GET` | `/api/v1/payroll/pay-stubs/{id}/pdf` | User | Download pay stub PDF |
| `GET` | `/api/v1/payroll/tax-documents/me` | User | List own tax documents |
| `GET` | `/api/v1/payroll/tax-documents/{id}/pdf` | User | Download tax document PDF |

### User Integrations

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/v1/user-integrations` | User | List own integrations |
| `GET` | `/api/v1/user-integrations/providers` | User | List available providers |
| `POST` | `/api/v1/user-integrations` | User | Create integration |
| `DELETE` | `/api/v1/user-integrations/{id}` | User | Disconnect integration |
| `POST` | `/api/v1/user-integrations/{id}/test` | User | Test connection |
| `PUT` | `/api/v1/user-integrations/{id}/credentials` | User | Update credentials |
| `PUT` | `/api/v1/user-integrations/{id}/config` | User | Update config |

---

## 15. Entity Models

### EmployeeProfile Entity

```csharp
public class EmployeeProfile : BaseAuditableEntity
{
    int UserId;
    // Personal
    DateTimeOffset? DateOfBirth;
    string? Gender;
    // Address
    string? Street1, Street2, City, State, ZipCode, Country;
    // Contact
    string? PhoneNumber, PersonalEmail;
    // Emergency
    string? EmergencyContactName, EmergencyContactPhone, EmergencyContactRelationship;
    // Employment (admin-editable)
    DateTimeOffset? StartDate;
    string? Department, JobTitle, EmployeeNumber;
    PayType? PayType;
    decimal? HourlyRate, SalaryAmount;
    // Compliance completion tracking (dates only)
    DateTimeOffset? W4CompletedAt, StateWithholdingCompletedAt, I9CompletedAt;
    DateTimeOffset? I9ExpirationDate, DirectDepositCompletedAt;
    DateTimeOffset? WorkersCompAcknowledgedAt, HandbookAcknowledgedAt;
    DateTimeOffset? OnboardingBypassedAt;
}
```

### Profile Completeness

```typescript
interface ProfileCompleteness {
  isComplete: boolean;
  canBeAssignedJobs: boolean;
  totalItems: number;
  completedItems: number;
  items: ProfileCompletenessItem[];
}

interface ProfileCompletenessItem {
  key: string;        // e.g., 'address', 'emergency_contact', 'w4'
  label: string;
  isComplete: boolean;
  blocksJobAssignment: boolean;
}
```

### Key-to-Route Mapping

The `EmployeeProfileService` maps completion keys to account routes:

| Key | Route |
|-----|-------|
| `address` | `/account/contact` |
| `emergency_contact` | `/account/emergency` |
| `w4` | `/account/tax-forms/w4` |
| `i9` | `/account/tax-forms/i9` |
| `stateWithholding` | `/account/tax-forms/stateWithholding` |
| `directDeposit` | `/account/tax-forms/directDeposit` |
| `workersComp` | `/account/tax-forms/workersComp` |
| `handbook` | `/account/tax-forms/handbook` |

`firstIncompleteRoute` signal returns the route for the first incomplete item, used for directing users to what needs attention.

---

## 16. Services

### AccountService

- `updateProfile(request)` -- `PUT /api/v1/auth/profile`
- `changePassword(request)` -- `POST /api/v1/auth/change-password`

### EmployeeProfileService

Singleton service managing employee profile state:
- `profile` signal -- current `EmployeeProfile`
- `completeness` signal -- current `ProfileCompleteness`
- `isComplete` computed -- true when all items complete
- `incompleteCount` computed -- number of incomplete items
- `canBeAssignedJobs` computed -- from completeness
- `firstIncompleteRoute` computed -- route for first incomplete item
- `load()` -- fetches both profile and completeness
- `updateProfile(data)` -- updates profile and refreshes completeness
- `acknowledgeForm(formType)` -- marks a form acknowledged and refreshes

### ComplianceFormService

Manages compliance form templates, submissions, and identity documents:
- `templates` signal -- loaded from `GET /api/v1/compliance-forms`
- `submissions` signal -- loaded from `GET /api/v1/compliance-forms/submissions/me`
- `identityDocuments` signal -- loaded from `GET /api/v1/identity-documents/me`
- Template/submission CRUD methods
- `downloadSubmissionPdf(id)` -- returns blob for file download

### MfaService

Manages MFA setup and login flow:
- `beginSetup(deviceName?)` -- starts TOTP setup
- `verifySetup(deviceId, code)` -- verifies TOTP code
- `disable()` / `removeDevice(id)` -- device management
- `getStatus()` -- returns MFA status with device list
- `generateRecoveryCodes()` -- generates new recovery codes
- Login flow: `createChallenge()`, `validateChallenge()`, `validateRecovery()`

### PayrollService

Self-service and admin payroll document management:
- `payStubs` / `taxDocuments` signals
- `loadMyPayStubs()` / `loadMyTaxDocuments()` -- employee self-service
- `downloadPayStubPdf(id)` / `downloadTaxDocumentPdf(id)` -- opens in new tab
- Admin methods: `getUserPayStubs()`, `uploadPayStub()`, etc.

### UserIntegrationService

Per-user external integration management:
- `integrations` / `providers` / `loading` signals
- CRUD operations for connecting/disconnecting services
- `testConnection(id)` -- verifies connectivity

---

## 17. Known Limitations

1. **No active sessions management.** The security page does not show or allow revocation of active sessions/tokens. Session management is limited to logout (current session).

2. **No profile photo upload.** Avatar is initials + color only. There is no image upload capability for profile pictures.

3. **Compliance form completeness is date-only tracking.** The `EmployeeProfile` stores only completion timestamps, not the actual tax data (SSN, withholding amounts, etc.). Actual form data is stored in `ComplianceFormSubmission.formDataJson`.

4. **I-9 cannot be resubmitted.** Per legal requirements, I-9 forms are locked after completion. The `canResubmit` computed returns false for `i9` form type. Contact HR for corrections.

5. **Gender options are hardcoded.** The gender select options (Male, Female, Non-binary, Prefer not to say) are defined as a constant array in the component, not loaded from the database.

6. **Category options on integrations are hardcoded.** The four categories (Calendar, Messaging, Cloud Storage, Other) are defined in the component.

7. **Pay stubs and tax documents are read-only for employees.** Upload and delete operations require Admin, Manager, or Office Manager roles. The employee view is self-service display only.

8. **Font scale is applied globally.** Changing font scale affects the entire application, not just the account pages.

9. **Draft TTL changes apply to all forms.** The draft retention setting is global for all forms across the application, not per-form configurable.
