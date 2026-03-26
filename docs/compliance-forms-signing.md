# Compliance Form PDF Fill & DocuSeal Signing

## Overview

Compliance form collection has two distinct phases, decoupled by design:

1. **Data Collection** — Employee fills the form via the `ComplianceFormRendererComponent` (ng-dynamic-forms wizard). Data is validated and persisted as `FormDataJson` on `ComplianceFormSubmission`. The wizard UX is optimised for clarity: plain-English labels, validation popover, multi-page tab navigation.

2. **PDF Fill + Signing** — After data collection, the backend fills the official government PDF template (AcroForm fields) with the submitted data, then submits the filled (unsigned) PDF to DocuSeal. DocuSeal handles the signing ceremony. The signed, tamper-evident PDF is returned via webhook, stored in MinIO, and the submission record is updated.

This mirrors the approach used by Gusto, Rippling, and BambooHR: the wizard is the UX, the government PDF is the compliance record.

---

## Legal Basis

| Form | Governing Authority | Electronic Signature Authority |
|------|--------------------|---------------------------------|
| W-4 | IRS | Rev. Proc. 2017-47 — explicitly authorises electronic W-4 systems with audit trail |
| State Withholding | State DOR/DFR | Each state models rules on IRS guidance; none are more restrictive |
| I-9 | USCIS / DHS | 8 CFR 274a.2 — electronic I-9 systems permitted with specific audit/retention requirements |

**E-SIGN Act (federal) / UETA (state):** Electronic signatures are legally equivalent to wet signatures for all three form types. The critical requirement is *intent to sign that specific document*, not the method of signature capture.

**Paper alternative (non-negotiable):** All forms must offer the option to download the blank PDF and submit a paper version. The UI must make this option discoverable.

---

## PDF Fill Technology

Government tax forms (W-4, I-9, state withholding) are AcroForm PDFs — they have named form fields that can be programmatically filled. **QuestPDF is not the right tool here** (it generates new PDFs from scratch). The correct approach is:

- **Library:** `PdfSharp` (MIT licence) for reading and filling AcroForm fields, or `itext7` (AGPL).
- **Process:** Enumerate AcroForm field names → map from `FormDataJson` fields → fill → flatten (remove interactive fields, lock content) → send to DocuSeal.
- **Flatten before DocuSeal:** Yes. The filled data should be non-editable before DocuSeal receives it. DocuSeal then adds only the signature annotation. This is standard practice (DocuSign, HelloSign, DocuSeal all do this).

### AcroForm Field Mapping

Each `ComplianceFormTemplate` should store a `AcroFieldMapJson` (jsonb) column that maps `FormDataJson` keys → AcroForm field names in the PDF. This mapping is established once per template version during the admin form setup flow (extracted from the PDF via the existing pdf.js pipeline, or entered manually).

Example W-4 mapping excerpt:
```json
{
  "firstName":        "topmostSubform[0].Page1[0].f1_1[0]",
  "lastName":         "topmostSubform[0].Page1[0].f1_2[0]",
  "ssn":              "topmostSubform[0].Page1[0].f1_3[0]",
  "filingStatus":     "topmostSubform[0].Page1[0].c1_1[0]",
  "additionalAmount": "topmostSubform[0].Page1[0].f1_4[0]",
  "signatureDate":    "topmostSubform[0].Page1[0].f1_5[0]"
}
```

---

## Signing Flow by Form Type

### W-4 (Federal Withholding)

**Submitters:** 1 (employee only)

**Flow:**
```
Employee completes wizard
  → Review page: shows all entered values
  → "Sign & Submit" button
  → Backend fills W-4 PDF with AcroForm field map
  → Flatten PDF
  → Create DocuSeal submission (1 submitter: employee)
  → Return DocuSeal signing URL to frontend
  → Employee signs in embedded DocuSeal iframe
  → DocuSeal webhook fires on completion
  → Signed PDF stored in MinIO (PII bucket)
  → ComplianceFormSubmission.Status → Completed
  → ComplianceFormSubmission.SignedAt → timestamp
  → EmployeeProfile.W4CompletedAt → timestamp
  → AcknowledgeFormCommand called to sync profile
```

**IRS Requirements Met:**
- Employee sees final form data before signing (review page)
- Instructions are accessible (link to IRS publication from the wizard)
- Paper alternative offered on the form detail page
- Electronic submission is equivalent to paper (confirmed by E-SIGN attestation on review page)
- Audit trail: `ComplianceFormSubmission.Id`, `UserId`, `SignedAt`, DocuSeal `DocuSealSubmissionId`

---

### State Withholding

**Submitters:** 1 (employee only)

**Flow:** Identical to W-4. The filled PDF is the state-specific form identified by the employee's work location state (3-tier resolution: `WorkLocation.State` → default `CompanyLocation` → `company_state` setting).

**Note:** State form versions change on varying schedules. The `ComplianceFormSyncJob` (Hangfire, weekly) detects version changes via SHA-256 hash comparison and triggers re-signing when a new version is adopted. Employees are notified to re-sign when a new version supersedes their current submission.

---

### I-9 (Employment Eligibility Verification)

**Submitters:** 2, sequential — Employee then Employer

**This is the most legally sensitive form.** DHS requires an audit trail, tamper-evident storage, and the ability to produce legible copies on demand for inspection. DocuSeal's sequential signing, combined with MinIO storage and the `ComplianceFormSubmission` audit record, satisfies all DHS requirements under 8 CFR 274a.2.

#### I-9 Submission Status States

```
NotStarted
  │
  ▼
Section1InProgress       ← employee has saved a draft but not submitted
  │
  ▼
Section1Complete         ← employee signed Section 1 via DocuSeal
  │                         (triggers employer notification)
  ▼
Section2InProgress       ← employer opened Section 2 but hasn't signed
  │
  ▼
Complete                 ← employer signed Section 2 via DocuSeal
  │
  ├── ReverificationDue  ← computed state: work auth document expiring within 90 days
  └── ReverificationOverdue ← document has expired (must re-verify)

Special:
  Section2Overdue        ← Section 1 complete but Section 2 not signed within 3 business days of start date
```

These states are computed from the stored timestamps and document expiration data, not a stored enum (except `Section2Overdue` which is flagged by a Hangfire job).

#### I-9 Signing Flow — Detailed

```
EMPLOYEE (Section 1):
  Employee completes I-9 Section 1 wizard
    → Attests citizenship/work authorization status
    → Uploads supporting identity documents (existing IdentityDocument flow)
    → Review page
    → "Sign Section 1" button
    → Backend fills I-9 PDF (Section 1 fields only via AcroForm map)
    → Create DocuSeal submission (2 submitters: employee order=1, employer order=2)
    → Employee signs Section 1 in embedded DocuSeal iframe
    → DocuSeal fires Section1Complete event (or webhook)
    → ComplianceFormSubmission.I9Section1SignedAt → timestamp
    → Notification sent to assigned HR/Manager (or all Admin/Manager users)

EMPLOYER (Section 2):
  HR/Manager opens employee profile in admin view
    → I-9 chip on employee list shows "⚠ Sign Required" (or "✗ Overdue")
    → Opens employee compliance panel
    → Section 2 completion form is displayed:
        - Employee's name, DOB, first day of employment
        - List A document  OR  List B + List C documents
        - For each document: Document Title, Issuing Authority, Document Number, Expiration Date
        - "I attest, under penalty of perjury, that I have examined the document(s) presented
          by the above-named employee, that the above-listed document(s) appear to be genuine
          and to relate to the employee named, and that to the best of my knowledge the
          employee is authorised to work in the United States." [checkbox — required]
        - Employer name, title, business address (pre-filled from company profile)
    → HR fills in examined documents, checks attestation
    → "Sign Section 2" button
    → Backend fills I-9 PDF Section 2 fields (AcroForm map)
    → DocuSeal continuation: employer signs as second submitter
    → DocuSeal webhook fires on full completion
    → Signed PDF stored in MinIO (PII bucket)
    → ComplianceFormSubmission.I9Section2SignedAt → timestamp
    → ComplianceFormSubmission.I9EmployerUserId → signing manager's userId
    → ComplianceFormSubmission.Status → Completed
    → EmployeeProfile.I9CompletedAt → timestamp
    → AcknowledgeFormCommand called
```

#### I-9 Deadlines (Non-Negotiable)

| Deadline | Rule | Enforcement |
|----------|------|-------------|
| Section 1 | On or before employee's first day of work | Warning shown on wizard if start date is today |
| Section 2 | Within 3 business days of first day of work | Hangfire job flags `Section2Overdue`; error chip on employee list; notification to Admin |
| Re-verification | Before work authorisation document expiry | Hangfire job fires notification 90 days before expiry, again at 30 days, again at expiry |

**Business day calculation:** Excludes weekends. Does not (currently) exclude federal holidays — acceptable for a small-business tool.

#### I-9 Document Lists

**List A** (establishes both identity and work authorisation — use ONE):
- U.S. Passport or U.S. Passport Card
- Permanent Resident Card (Form I-551)
- Foreign passport with I-551 stamp or I-94 with re-entry notation
- Employment Authorisation Document (Form I-766)
- Foreign passport with Form I-94 or I-94A (for nonimmigrant aliens)
- Passport from the Federated States of Micronesia, Republic of the Marshall Islands, or Palau

**List B** (establishes identity only — use WITH a List C document):
- Driver's licence or ID card issued by a state
- ID card issued by federal, state, or local government agencies
- School ID card with photograph
- Voter's registration card
- U.S. military card or draft record
- Military dependent's ID card
- U.S. Coast Guard Merchant Mariner Card
- Native American tribal document
- Driver's licence issued by a Canadian government authority
- (Minors under 18 unable to present List B: school record, report card, doctor/hospital/clinic record)
- (Special: individual with a disability: special education record, progress report)

**List C** (establishes work authorisation only — use WITH a List B document):
- U.S. Social Security Account Number card (unrestricted)
- Certification of Report of Birth (Form DS-1350)
- Original or certified copy of birth certificate
- Native American tribal document
- U.S. Citizen ID Card (Form I-197)
- Identification Card for Use of Resident Citizen (Form I-179)
- Employment authorisation document issued by DHS (not included in List A)

The UI must present List A as an exclusive option versus List B+C. If the employee presents a List A document, List B and C fields should be disabled/hidden.

---

## Data Model Changes Required

### `ComplianceFormTemplate` additions
```
AcroFieldMapJson        jsonb       null    -- maps FormDataJson keys → PDF AcroForm field names
                                            -- null until admin configures/extracts the mapping
FilledPdfTemplateId     int?        FK      -- FileAttachment: the official PDF template used for filling
                                            -- (distinct from DocuSeal's internal template copy)
```

### `ComplianceFormSubmission` additions
```
FilledPdfFileId         int?        FK(FileAttachment)  -- pre-filled (unsigned) PDF stored in MinIO
I9Section1SignedAt      timestamptz null                -- I-9 only: when employee signed Section 1
I9Section2SignedAt      timestamptz null                -- I-9 only: when employer signed Section 2
I9EmployerUserId        int?        FK(ApplicationUser) -- I-9 only: which manager completed Section 2
I9DocumentListType      varchar(1)  null                -- 'A' or 'BC' (I-9 only)
I9DocumentDataJson      jsonb       null                -- List A/B/C document entries (I-9 only)
I9Section2OverdueAt     timestamptz null                -- set by Hangfire when 3 business days exceeded
I9ReverificationDueAt   date        null                -- earliest expiry date from I-9 documents
```

### `AdminUserResponseModel` additions
```csharp
I9Status                I9ComplianceStatus  // NotStarted | Section1InProgress | Section1Complete |
                                            // Section2InProgress | Complete | Section2Overdue |
                                            // ReverificationDue | ReverificationOverdue
I9Section1SignedAt      DateTime?
I9Section2SignedAt      DateTime?
I9ReverificationDueAt   DateOnly?
```

This status is computed server-side from the `ComplianceFormSubmission` record for the I-9 template, not stored as a separate column.

---

## Employee List Indicator

The admin/manager employee list (existing DataTable in the admin compliance view) gains an `I9Status` chip column alongside the existing compliance percentage chip.

| Status | Chip | Colour |
|--------|------|--------|
| Not Started | — | (no chip / muted "Not Started") |
| Section 1 In Progress | Draft | muted |
| Section 1 Complete | Sign Required | warning (amber) |
| Section 2 In Progress | Sign Required | warning (amber) |
| Complete | I-9 Complete | success (green) |
| Section 2 Overdue | Overdue | error (red) |
| Reverification Due | Reverify Soon | warning (amber) |
| Reverification Overdue | Reverify Now | error (red) |

The column is sortable so managers can surface all outstanding items quickly.

---

## Employer Section 2 UI — Component Spec

**Location:** Within `UserCompliancePanelComponent`, conditionally rendered when `I9Status` is `Section1Complete` or `Section2InProgress`.

**Visibility:** Admin and Manager roles only (existing role gate).

**Layout:**
```
I-9 Employment Eligibility Verification
─────────────────────────────────────────────────────────────────────
Section 1 — Employee Information (read-only)
  Name: Johnson, Sarah K    DOB: --/--/----    First Day: 04/01/2026
  Citizenship Status: A citizen of the United States
  Section 1 Signed: 03/28/2026

Section 2 — Employer Review ⚠ Due by 04/04/2026
  ┌─ Document presented ────────────────────────────────────────────┐
  │  [○ List A — single document]  [○ List B + List C — two docs]   │
  │                                                                  │
  │  List A Document:                                                │
  │  [Document Title        ▼]  [Issuing Authority       ]          │
  │  [Document Number          ]  [Expiration Date        ]          │
  └──────────────────────────────────────────────────────────────────┘

  Employee's first day of employment: [04/01/2026      ]

  ☐ I attest, under penalty of perjury, that I have examined the
    document(s) presented by the above-named employee, that the
    above-listed document(s) appear to be genuine and to relate to
    the employee named, and that to the best of my knowledge the
    employee is authorised to work in the United States.

  Employer/Authorised Rep: [Auto-filled: current user name + title ]
  Business name/address:   [Auto-filled from company profile        ]

  [Sign Section 2]  ← disabled until attestation checked
```

**Validation:**
- At least one document set must be entered
- Attestation checkbox required
- First day of employment required
- Each document requires: title, issuing authority, document number (expiration optional for non-expiring docs but shown)

**On "Sign Section 2":**
1. POST `/api/v1/compliance-forms/{submissionId}/i9-section2` with document data
2. Backend fills Section 2 fields on the already-partially-filled PDF
3. Backend triggers DocuSeal employer signing step
4. Returns DocuSeal signing URL
5. Frontend opens DocuSeal iframe for employer signing
6. On completion: chip updates to Complete, Section 2 form collapses

---

## Backend Services Required

### `IPdfFormFillService`
```csharp
public interface IPdfFormFillService
{
    Task<Stream> FillFormAsync(
        Stream pdfTemplate,
        Dictionary<string, string> fieldValues,
        bool flatten,
        CancellationToken cancellationToken);

    Task<IReadOnlyDictionary<string, string>> GetAcroFieldNamesAsync(
        Stream pdf,
        CancellationToken cancellationToken);
}
```

Implemented by `PdfSharpFormFillService`. Mock: `MockPdfFormFillService` (returns the template unmodified).

### Updated `IDocumentSigningService`

Add overloads to support submitting a raw PDF (not a pre-registered DocuSeal template):

```csharp
Task<string> CreateSubmissionFromPdfAsync(
    string employeeEmail,
    string employeeName,
    Stream pdfDocument,
    string documentName,
    SequentialSubmitter[]? additionalSubmitters,
    CancellationToken cancellationToken);

record SequentialSubmitter(string Email, string Name, string Role, int Order);
```

### New MediatR Handlers
- `FillAndSubmitFormForSigning` — fills the PDF, uploads to MinIO, creates DocuSeal submission, returns signing URL. Called after employee completes wizard.
- `CompleteI9Section2` — records document examination data, fills Section 2 fields, triggers DocuSeal employer signing step.
- `HandleDocuSealWebhook` (update existing) — handle I-9-specific completion: distinguish Section1Complete from both-signed states.
- `CheckI9Overdue` — Hangfire job, runs daily, flags overdue Section 2s, sends notifications.
- `CheckI9Reverification` — Hangfire job, runs weekly, checks `I9ReverificationDueAt` against today.

---

## New API Endpoints

```
POST /api/v1/compliance-forms/{id}/fill-and-sign
  → Fills PDF with FormDataJson, creates DocuSeal submission
  → Returns { signingUrl: string, submissionId: int }
  → Auth: employee (their own submission) or Admin/Manager

POST /api/v1/compliance-forms/{submissionId}/i9-section2
  → Records List A/B/C document data, triggers employer DocuSeal signing
  → Body: I9Section2RequestModel
  → Returns { signingUrl: string }
  → Auth: Admin, Manager, OfficeManager only

GET  /api/v1/compliance-forms/i9-pending
  → Returns list of employees with I-9 requiring Section 2 completion
  → Auth: Admin, Manager, OfficeManager only
  → Used to populate the I9Status field on AdminUserResponseModel
```

---

## Notifications

| Trigger | Recipient | Message |
|---------|-----------|---------|
| Employee completes I-9 Section 1 | All Admin + Manager users | "{Employee} has signed I-9 Section 1. Section 2 must be completed by {deadline}." |
| Section 2 deadline T-1 business day | All Admin + Manager users | "I-9 Section 2 for {Employee} is due tomorrow." |
| Section 2 becomes overdue | All Admin + Manager users | "I-9 Section 2 for {Employee} is overdue. Complete immediately." |
| Reverification due in 90 days | All Admin + Manager users | "{Employee}'s work authorisation document expires on {date}." |
| Reverification due in 30 days | All Admin + Manager users | "Urgent: {Employee}'s work authorisation expires in 30 days." |
| Document has expired | All Admin + Manager users | "Action required: {Employee}'s work authorisation document has expired." |

All notifications use the existing `NotificationService` + `AppNotification` entity + SignalR push.

---

## Build Order

1. **Data model migration** — `AcroFieldMapJson` on `ComplianceFormTemplate`; I-9 fields on `ComplianceFormSubmission`
2. **`IPdfFormFillService` + `PdfSharpFormFillService`** — AcroForm fill + flatten
3. **`MockPdfFormFillService`** — pass-through (used when `MockIntegrations=true`)
4. **`IDocumentSigningService` overload** — `CreateSubmissionFromPdfAsync`
5. **`FillAndSubmitFormForSigning` handler** — called after wizard completion for W-4, state withholding
6. **W-4 / state withholding signing wired in frontend** — post-wizard → fill-and-sign → DocuSeal iframe
7. **I-9 two-party DocuSeal flow** — Section 1 fill → DocuSeal with 2 sequential submitters
8. **`CompleteI9Section2` handler + endpoint** — employer document entry + Section 2 signing
9. **`I9Status` computed field on `AdminUserResponseModel`** — derive from submission record
10. **Employee list I-9 chip** — add column to existing DataTable in admin compliance view
11. **Section 2 employer UI in `UserCompliancePanelComponent`** — conditional render, document entry form, attestation, DocuSeal iframe
12. **`CheckI9Overdue` Hangfire job** — daily, 3-business-day rule
13. **`CheckI9Reverification` Hangfire job** — weekly, 90/30/0 day notifications
14. **Notifications for all I-9 triggers** — integrate with existing `NotificationService`

---

## Not In Scope

- **I-9 Section 3 (Re-verification/Rehire)** — tracked via `I9ReverificationDueAt` notification, but the re-verification signing workflow is future scope. Current scope: flag it, notify, instruct HR to handle.
- **E-Verify integration** — separate federal system, optional for most employers. Not part of the electronic I-9 workflow.
- **Remote hire I-9 authorised representative** — the system supports the employer signing as an authorised representative but does not manage the third-party authorised representative flow.
- **I-9 audit export** — the ability to produce an indexed set of I-9 records for a DHS audit is noted as future scope (search + bulk PDF download).
