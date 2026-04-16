# Employee Onboarding

## Overview

The onboarding system provides a guided multi-step wizard for new employees to complete required compliance paperwork, personal information, and payroll setup. The wizard collects data for W-4 federal withholding, state withholding, I-9 employment eligibility, direct deposit, and employer acknowledgments. Completed forms are submitted to DocuSeal for e-signature and stored as compliance form submissions.

The system also tracks profile completeness and displays a "Getting Started" banner on the dashboard until the employee has finished all required steps.

## Routes

| Route | Component | Description |
|-------|-----------|-------------|
| `/onboarding` | `OnboardingWizardComponent` | The main onboarding wizard. |
| `/onboarding?step=0` | Same | Step 1: Personal Information (step is URL query param, 0-indexed). |
| `/onboarding?step=1` | Same | Step 2: Address. |
| `/onboarding?step=2` | Same | Step 3: W-4 Federal Withholding. |
| `/onboarding?step=3` | Same | Step 4: State Withholding. |
| `/onboarding?step=4` | Same | Step 5: I-9 Employment Eligibility. |
| `/onboarding?step=5` | Same | Step 6: Direct Deposit. |
| `/onboarding?step=6` | Same | Step 7: Acknowledgments. |

The `?step=N` query parameter is the URL source of truth for the current step. Browser back/forward navigates between steps naturally. Invalid step values (< 0 or > 6) default to step 0.

## Wizard Steps

### Step 1: Personal Information (`step=0`)

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| First Name | `<app-input>` | Yes | `Validators.required` |
| Middle Name | `<app-input>` | No | -- |
| Last Name | `<app-input>` | Yes | `Validators.required` |
| Other Last Names | `<app-input>` | No | Previous/maiden names. |
| Date of Birth | `<app-datepicker>` | Yes | `Validators.required` |
| Social Security Number | `<app-input mask="ssn">` | Yes | `Validators.required`, pattern `^\d{3}-?\d{2}-?\d{4}$` |
| Email | `<app-input type="email">` | Yes | `Validators.required`, `Validators.email` |
| Phone | `<app-input mask="phone">` | Yes | `Validators.required` |

**Prefill behavior:**
- First Name, Last Name, and Email are prefilled from the authenticated user's profile.
- Phone and Date of Birth are prefilled from the `EmployeeProfile` if the admin already entered them.
- Address fields (Step 2) are prefilled from `EmployeeProfile` if available.
- A saved draft in `localStorage` (key: `qbe-onboarding-draft`) takes priority over admin prefill.

### Step 2: Address (`step=1`)

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| Street Address | `<app-input>` | Yes | `Validators.required` |
| Street Address 2 | `<app-input>` | No | -- |
| City | `<app-input>` | Yes | `Validators.required` |
| State | `<app-select>` | Yes | `Validators.required`. Dropdown of all 50 US states + DC. |
| ZIP Code | `<app-input mask="zip">` | Yes | `Validators.required`, pattern `^\d{5}(-\d{4})?$` |

**State-dependent behavior:** The selected state determines whether Step 4 (State Withholding) is required or can be skipped. States with no income tax (AK, FL, NV, SD, TN, TX, WA, WY) display a message indicating no state withholding form is needed.

### Step 3: W-4 Federal Withholding (`step=2`)

Mirrors the IRS Form W-4 structure.

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| Filing Status | `<app-select>` | Yes | `Validators.required`. Options: Single / Married Filing Jointly / Head of Household. |
| Multiple Jobs | `<app-toggle>` | No | Check if employee holds more than one job. |
| Qualifying Children (3a) | `<app-input type="number">` | Yes | `Validators.required`, `Validators.min(0)`. Count of qualifying children; multiplied by $2,000. |
| Other Dependents (3b) | `<app-input type="number">` | Yes | `Validators.required`, `Validators.min(0)`. Count of other dependents; multiplied by $500. |
| Total Dependents (3a + 3b) | Computed display | -- | Auto-calculated: `(qualifyingChildren * $2,000) + (otherDependents * $500)`. |
| Other Income (4a) | `<app-input type="number">` | No | `Validators.min(0)`. Non-job income. |
| Deductions (4b) | `<app-input type="number">` | No | `Validators.min(0)`. Deductions beyond standard. |
| Extra Withholding (4c) | `<app-input type="number">` | No | `Validators.min(0)`. Additional per-paycheck withholding. |
| Exempt from Withholding | `<app-toggle>` | No | If true, no federal income tax withheld. |

### Step 4: State Withholding (`step=3`)

State-specific withholding form. Skipped (no validation) for states with no income tax.

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| State Filing Status | `<app-select>` | Conditional | Required unless `stateExempt` is true. Options: Single / Married / MFJ / Head of Household. |
| Allowances | `<app-input type="number">` | No | Number of state allowances. |
| Additional Withholding | `<app-input type="number">` | No | Additional per-paycheck state withholding. |
| Exempt from State Withholding | `<app-toggle>` | No | If true, removes `required` from Filing Status. |

### Step 5: I-9 Employment Eligibility (`step=4`)

Mirrors USCIS Form I-9 Section 1.

**Section 1: Employee Information**

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| Citizenship Status | `<app-select>` | Yes | `Validators.required`. Options: US Citizen / Noncitizen National / Lawful Permanent Resident / Alien Authorized to Work. |
| Alien Registration Number | `<app-input>` | Conditional | Shown when status is 3 (LPR) or 4 (alien). |
| I-94 Admission Number | `<app-input>` | Conditional | Shown when status is 3 or 4. |
| Foreign Passport Number | `<app-input>` | Conditional | Shown when status is 3 or 4. |
| Foreign Passport Country | `<app-input>` | Conditional | Shown when status is 3 or 4. |
| Work Authorization Expiry | `<app-datepicker>` | Conditional | Shown when status is 3 or 4. |
| Prepared by Preparer/Translator | `<app-toggle>` | No | If true, shows preparer fields. |
| Preparer First Name | `<app-input>` | Conditional | Shown when `preparedByPreparer` is true. |
| Preparer Last Name | `<app-input>` | Conditional | Shown when `preparedByPreparer` is true. |
| Preparer Address | `<app-input>` | Conditional | Shown when `preparedByPreparer` is true. |
| Preparer City | `<app-input>` | Conditional | Shown when `preparedByPreparer` is true. |
| Preparer State | `<app-input>` | Conditional | Shown when `preparedByPreparer` is true. |
| Preparer ZIP | `<app-input>` | Conditional | Shown when `preparedByPreparer` is true. |

**Document Verification**

The employee must choose between List A (one document proving both identity and work authorization) or List B + C (one document from each list).

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| Document Choice | Radio: `A` or `BC` | Yes | `Validators.required` |

**List A Documents** (shown when choice is `A`):

| Field | Control | Required |
|-------|---------|----------|
| Document Type | `<app-select>` | Yes |
| Document Number | `<app-input>` | Yes |
| Issuing Authority | `<app-input>` | Yes |
| Expiration Date | `<app-datepicker>` | No |
| Document Upload | File upload | Yes |

List A type options: U.S. Passport, U.S. Passport Card, Permanent Resident Card (I-551), Employment Authorization Document (I-766), Foreign Passport with I-94, Foreign Passport with I-551 Stamp.

**List B Documents** (shown when choice is `BC`):

| Field | Control | Required |
|-------|---------|----------|
| Document Type | `<app-select>` | Yes |
| Document Number | `<app-input>` | Yes |
| Issuing Authority | `<app-input>` | Yes |
| Expiration Date | `<app-datepicker>` | No |
| Document Upload | File upload | Yes |

List B type options: Driver's License, State ID Card, School ID with Photo, Voter Registration Card, Military ID, Native American Tribal Document.

**List C Documents** (shown when choice is `BC`):

| Field | Control | Required |
|-------|---------|----------|
| Document Type | `<app-select>` | Yes |
| Document Number | `<app-input>` | Yes |
| Issuing Authority | `<app-input>` | Yes |
| Expiration Date | `<app-datepicker>` | No |
| Document Upload | File upload | Yes |

List C type options: Social Security Card, Birth Certificate, U.S. Citizen ID Card (I-197), Native American Tribal Document, Employment Authorization Document (DHS-issued).

### Step 6: Direct Deposit (`step=5`)

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| Bank Name | `<app-input>` | Yes | `Validators.required` |
| Routing Number | `<app-input>` | Yes | `Validators.required`, pattern `^\d{9}$` (exactly 9 digits). |
| Account Number | `<app-input>` | Yes | `Validators.required` |
| Account Type | `<app-select>` | Yes | `Validators.required`. Options: Checking / Savings. Default: Checking. |
| Voided Check Upload | File upload | Yes | `Validators.required`. Image of voided check for verification. |

### Step 7: Acknowledgments (`step=6`)

| Field | Control | Required | Validation |
|-------|---------|----------|------------|
| Workers' Compensation Acknowledgment | `<app-toggle>` | Yes | `Validators.requiredTrue`. Must be checked. |
| Employee Handbook Acknowledgment | `<app-toggle>` | Yes | `Validators.requiredTrue`. Must be checked. |

## Submission Flow

### Per-Form Review Flow

After completing all wizard steps, the submission follows a per-form review process:

1. **Save Data** (`POST /api/v1/onboarding/save`) -- Persists all profile data, identity documents, and acknowledgments. Returns a list of compliance forms that need signing (e.g., W-4, I-9, state withholding).

2. **Preview PDF** (`POST /api/v1/onboarding/preview-pdf`) -- For each form, the server fills the government PDF template with the employee's data and returns a base64-encoded PDF for inline browser preview. The employee reviews the filled form before signing.

3. **Sign Form** (`POST /api/v1/onboarding/sign-form`) -- Creates a DocuSeal signing submission for the form. Returns a signing URL that is embedded in an iframe for e-signature. The employee signs each form individually.

4. **Completion** -- After all forms are signed, the system updates `profileComplete` on the user and redirects to the dashboard.

### Review Phase States

The wizard tracks three phases internally:
- `idle` -- Normal wizard step navigation.
- `preview` -- Showing a filled PDF for review (embedded `<embed>` viewer).
- `signing` -- DocuSeal iframe is displayed for e-signature.

## Draft Persistence

The wizard auto-saves form data to `localStorage` under the key `qbe-onboarding-draft`. On return visits:
1. Draft data is restored first (takes priority over admin prefill).
2. If no draft exists, fields are prefilled from the authenticated user and their `EmployeeProfile`.

## Onboarding Status

The `OnboardingStatus` model tracks completion of individual items:

| Field | Type | Description |
|-------|------|-------------|
| `w4Complete` | `boolean` | W-4 federal withholding form signed. |
| `i9Complete` | `boolean` | I-9 employment eligibility form signed. |
| `stateWithholdingComplete` | `boolean` | State withholding form signed. |
| `directDepositComplete` | `boolean` | Direct deposit information submitted. |
| `workersCompComplete` | `boolean` | Workers' comp acknowledgment checked. |
| `handbookComplete` | `boolean` | Handbook acknowledgment checked. |
| `allComplete` | `boolean` | All items complete. |
| `canBeAssigned` | `boolean` | Whether the user can be assigned to jobs (may be true even if not all items are complete, e.g., after bypass). |

## Getting Started Banner

The `OnboardingBannerComponent` (`shared/components/onboarding-banner/`) displays a persistent banner across the application when:

1. The user is authenticated.
2. The user's `profileComplete` flag is false.
3. The user is not on the `/account/*` or `/onboarding` routes.
4. The banner has not been dismissed in the current session.

### Banner Features

- Shows the count of incomplete onboarding items.
- **"Complete Setup"** button navigates to the first incomplete route.
- **"Dismiss"** button hides the banner for the current session (not persistent).
- **"Skip Onboarding"** option with confirmation -- calls the bypass endpoint.

### Bypass Flow

The bypass endpoint (`POST /api/v1/onboarding/bypass`):
1. Creates an `EmployeeProfile` if one does not exist.
2. Sets `OnboardingBypassedAt` timestamp on the profile.
3. Marks the user's profile as complete, allowing job assignment.
4. Does not create compliance form submissions -- the employee is considered self-certified.

## API Endpoints

Base path: `/api/v1/onboarding`

All endpoints require authentication (`[Authorize]`).

### Get Onboarding Status

```
GET /api/v1/onboarding/status
```

Returns the current user's onboarding completion status.

**Response:** `200 OK` with `OnboardingStatusModel`

### Submit Onboarding (Legacy)

```
POST /api/v1/onboarding/submit
```

Full wizard submission. Fills government PDFs, submits all forms to DocuSeal, persists profile data, and marks acknowledgments complete.

**Request body:** `OnboardingSubmitRequestModel` (see below).

**Response:** `200 OK` with `OnboardingSubmitResultModel`

| Field | Type | Description |
|-------|------|-------------|
| `requiresSigning` | `boolean` | Whether DocuSeal signing is required. |
| `signingUrls` | `OnboardingSigningUrl[]` | List of signing URLs for each form. |
| `i9EmployerDocuSealSubmitterId` | `number?` | DocuSeal submitter ID for I-9 employer section (if applicable). |

### Save Onboarding Data

```
POST /api/v1/onboarding/save
```

Persists profile data without initiating DocuSeal signing. Returns the list of forms that need to be signed.

**Request body:** `OnboardingSubmitRequestModel`

**Response:** `200 OK` with `SaveOnboardingResultModel`

| Field | Type | Description |
|-------|------|-------------|
| `formsToSign` | `OnboardingFormToSignItem[]` | Ordered list of forms requiring review/signing. Each item: `formType`, `formName`, `hasTemplate`. |

### Preview PDF

```
POST /api/v1/onboarding/preview-pdf
```

Fills a compliance form PDF with the employee's data and returns it for preview.

**Request body:**

| Field | Type | Description |
|-------|------|-------------|
| `formData` | `OnboardingSubmitRequest` | The employee's complete form data. |
| `formType` | `string` | The form type to preview (e.g., `w4`, `i9`, `state-withholding`). |

**Response:** `200 OK` with `PreviewOnboardingPdfResultModel`

| Field | Type | Description |
|-------|------|-------------|
| `hasTemplate` | `boolean` | Whether a PDF template exists for this form. |
| `pdfBase64` | `string?` | Base64-encoded filled PDF. Null if no template. |

### Sign Form

```
POST /api/v1/onboarding/sign-form
```

Creates a DocuSeal signing submission for a single form.

**Request body:**

| Field | Type | Description |
|-------|------|-------------|
| `formData` | `OnboardingSubmitRequest` | The employee's complete form data. |
| `formType` | `string` | The form type to sign. |

**Response:** `200 OK` with `SignOnboardingFormResultModel`

| Field | Type | Description |
|-------|------|-------------|
| `signingUrl` | `string` | DocuSeal embed URL for the signing iframe. |
| `submissionId` | `number` | DocuSeal submission ID. |
| `isMock` | `boolean` | Whether mock signing is active (no real DocuSeal). |

### Upload I-9 Document

```
POST /api/v1/onboarding/i9-document
Content-Type: multipart/form-data
```

Pre-uploads an I-9 identity document before wizard submission.

**Form fields:**
- `file` -- The document image/PDF.
- `documentList` -- Which list the document belongs to (`A`, `B`, or `C`).

**Response:** `200 OK` with `{ fileAttachmentId, fileName }`

### Upload Voided Check

```
POST /api/v1/onboarding/voided-check
Content-Type: multipart/form-data
```

Uploads a voided check image for direct deposit verification.

**Form fields:**
- `file` -- The voided check image.

**Response:** `200 OK` with `{ fileAttachmentId, fileName }`

### Bypass Onboarding

```
POST /api/v1/onboarding/bypass
```

Self-service bypass. Marks the user as onboarded without completing the wizard.

**Response:** `204 No Content`

## Full Request Model (`OnboardingSubmitRequestModel`)

This model is used by both the `submit` and `save` endpoints.

| Field | Type | Step | Description |
|-------|------|------|-------------|
| `firstName` | `string` | 1 | Legal first name. |
| `middleName` | `string?` | 1 | Middle name. |
| `lastName` | `string` | 1 | Legal last name. |
| `otherLastNames` | `string?` | 1 | Other last names used. |
| `dateOfBirth` | `string` | 1 | ISO date string. |
| `ssn` | `string` | 1 | Social Security Number. |
| `email` | `string` | 1 | Email address. |
| `phone` | `string` | 1 | Phone number. |
| `street1` | `string` | 2 | Street address line 1. |
| `street2` | `string?` | 2 | Street address line 2. |
| `city` | `string` | 2 | City. |
| `addressState` | `string` | 2 | State code (2-letter). |
| `zipCode` | `string` | 2 | ZIP code. |
| `w4FilingStatus` | `string` | 3 | W-4 filing status. |
| `w4MultipleJobs` | `boolean` | 3 | Multiple jobs checkbox. |
| `w4ClaimDependentsAmount` | `number` | 3 | Total dependents dollar amount. |
| `w4OtherIncome` | `number` | 3 | Other income (4a). |
| `w4Deductions` | `number` | 3 | Deductions (4b). |
| `w4ExtraWithholding` | `number` | 3 | Extra withholding (4c). |
| `w4ExemptFromWithholding` | `boolean` | 3 | Exempt from federal withholding. |
| `stateFilingStatus` | `string?` | 4 | State filing status. |
| `stateAllowances` | `number?` | 4 | State allowances. |
| `stateAdditionalWithholding` | `number?` | 4 | State additional withholding. |
| `stateExempt` | `boolean?` | 4 | Exempt from state withholding. |
| `i9CitizenshipStatus` | `string` | 5 | Citizenship status code (1-4). |
| `i9AlienRegNumber` | `string?` | 5 | Alien Registration Number. |
| `i9I94Number` | `string?` | 5 | I-94 Admission Number. |
| `i9ForeignPassportNumber` | `string?` | 5 | Foreign passport number. |
| `i9ForeignPassportCountry` | `string?` | 5 | Foreign passport country. |
| `i9WorkAuthExpiry` | `string?` | 5 | Work authorization expiry date. |
| `i9PreparedByPreparer` | `boolean` | 5 | Whether a preparer/translator assisted. |
| `i9PreparerFirstName` | `string?` | 5 | Preparer first name. |
| `i9PreparerLastName` | `string?` | 5 | Preparer last name. |
| `i9PreparerAddress` | `string?` | 5 | Preparer address. |
| `i9PreparerCity` | `string?` | 5 | Preparer city. |
| `i9PreparerState` | `string?` | 5 | Preparer state. |
| `i9PreparerZip` | `string?` | 5 | Preparer ZIP. |
| `i9DocumentChoice` | `string?` | 5 | `A` or `BC`. |
| `i9ListAType` | `string?` | 5 | List A document type. |
| `i9ListADocNumber` | `string?` | 5 | List A document number. |
| `i9ListAAuthority` | `string?` | 5 | List A issuing authority. |
| `i9ListAExpiry` | `string?` | 5 | List A expiration date. |
| `i9ListAFileAttachmentId` | `number?` | 5 | List A uploaded file ID. |
| `i9ListBType` | `string?` | 5 | List B document type. |
| `i9ListBDocNumber` | `string?` | 5 | List B document number. |
| `i9ListBAuthority` | `string?` | 5 | List B issuing authority. |
| `i9ListBExpiry` | `string?` | 5 | List B expiration date. |
| `i9ListBFileAttachmentId` | `number?` | 5 | List B uploaded file ID. |
| `i9ListCType` | `string?` | 5 | List C document type. |
| `i9ListCDocNumber` | `string?` | 5 | List C document number. |
| `i9ListCAuthority` | `string?` | 5 | List C issuing authority. |
| `i9ListCExpiry` | `string?` | 5 | List C expiration date. |
| `i9ListCFileAttachmentId` | `number?` | 5 | List C uploaded file ID. |
| `bankName` | `string` | 6 | Bank name for direct deposit. |
| `routingNumber` | `string` | 6 | Bank routing number (9 digits). |
| `accountNumber` | `string` | 6 | Bank account number. |
| `accountType` | `string` | 6 | `Checking` or `Savings`. |
| `voidedCheckFileAttachmentId` | `number?` | 6 | Uploaded voided check file ID. |
| `acknowledgeWorkersComp` | `boolean` | 7 | Workers' comp acknowledgment. |
| `acknowledgeHandbook` | `boolean` | 7 | Handbook acknowledgment. |

## Known Limitations

1. **No multi-page I-9 Section 2 (Employer).** The employer portion of I-9 (document verification by authorized representative) is referenced (`i9EmployerDocuSealSubmitterId`) but the full employer workflow (verifying original documents in person) is not automated in the UI.
2. **US-only.** State dropdown, SSN format, ZIP code validation, and tax forms (W-4, state withholding) are US-specific. No international employee support.
3. **Single bank account.** Direct deposit supports one account only. No split-deposit between multiple accounts.
4. **Draft storage is localStorage.** The `qbe-onboarding-draft` key uses localStorage, not the more robust `DraftService`/IndexedDB system. It does not support cross-tab sync, TTL, or post-login recovery prompts.
5. **No progress indicator in URL.** While `?step=N` tracks the current step, there is no URL-level indication of which steps are complete. Refreshing after completing steps 0-3 will show step 0 again if the user manually navigated there.
6. **Bypass has no admin control.** Any authenticated user can bypass onboarding. There is no admin setting to disable the bypass option for specific roles.
7. **DocuSeal dependency.** The signing flow requires DocuSeal integration. When `MOCK_INTEGRATIONS=true`, signing is simulated but no real signatures are captured.
8. **No re-signing workflow.** Once forms are signed, there is no mechanism to re-sign (e.g., after a name change or address update). The employee would need admin intervention.
