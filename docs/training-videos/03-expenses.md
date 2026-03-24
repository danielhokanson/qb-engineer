# Manuscript: Submitting Expenses Video Guide

**Module ID:** 21
**Slug:** `video-submitting-expenses`
**App Route:** `/expenses`
**Estimated Duration:** 9–11 minutes
**Generation Command:** `POST /api/v1/training/modules/21/generate-video`

---

## Purpose

Expense submission is a high-friction process in many shops because people do not know what to attach, how to categorize, or what happens after they submit. This video eliminates that friction. It is also the first touchpoint for reimbursement culture — the video's tone should reinforce that the company wants to make this easy.

### Learning Objectives
- Understand the expense dashboard layout
- Create a new expense with all required fields
- Attach a receipt (photo, file, or camera capture)
- Categorize the expense correctly
- Link an expense to a job
- Submit for approval and understand what happens next
- Track approval status
- Correct a rejected expense
- View expense history
- Manager: review and approve the queue

### Audience
All employees who incur work-related expenses. Managers reviewing and approving.

### Learning Style Coverage
- **Visual:** Spatial orientation of the expense list and status indicators
- **Auditory:** Explain the approval chain and why each step exists
- **Reading/Writing:** Detailed field-by-field walkthrough
- **Kinesthetic:** Submit a real test expense

---

## Chapter Breakdown

---

### Chapter 1 — Spatial Orientation: The Expense Dashboard
**Estimated timestamp:** 0s
**UI Element:** `app-expenses`
**Chapter label:** "Expense Dashboard"

**Narration Script:**
You are now on the Expenses page. Let's orient. The page has two main sections. On the left is a filter sidebar — you can filter your expenses by status, date range, or category. On the right is the main expense list, a table showing all your submitted expenses. Each row is one expense with a date, amount, description, category, and status. Status is the most important column: it tells you where your expense is in the approval process. Common statuses are Draft, Submitted, Pending Review, Approved, and Rejected. At the top right of the page is the New Expense button — that is where every new expense begins. Managers see an additional section called Approval Queue, which we will cover later.

**Kinesthetic prompt:** Look at the status column of your existing expenses. Identify how many are approved versus pending.

---

### Chapter 2 — Creating a New Expense
**Estimated timestamp:** 55s
**UI Element:** `app-expenses .action-btn--primary`
**Chapter label:** "New Expense"

**Narration Script:**
Click the New Expense button. A dialog opens with the expense form. Let's go through each field. Date: when the expense occurred — not when you are entering it. Amount: the exact dollar amount on your receipt. Category: this is a required dropdown — choose the type of expense such as Travel, Meals, Supplies, Tools, or Fuel. Each category maps to a budget line that finance tracks. Description: a brief note about what you bought and why. The description becomes part of the approval record, so be specific — say 'carbide end mills for job 2047' rather than just 'tools.' Merchant: the store or vendor you purchased from. This field is optional but helps managers and finance verify the expense quickly.

**Alternative paths:** If your company uses project codes or cost centers, an additional field may appear. Ask your admin if you are unsure how to fill it in.

**Kinesthetic prompt:** Open the New Expense dialog and read through every field before filling anything in. Notice which are marked required with an asterisk.

---

### Chapter 3 — Attaching a Receipt
**Estimated timestamp:** 130s
**UI Element:** `app-file-upload-zone`
**Chapter label:** "Attaching a Receipt"

**Narration Script:**
Every expense should have a receipt attached. Look for the Upload Receipt area in the expense form — it is a dashed-border drop zone near the bottom of the dialog. You have three ways to attach a receipt. One: drag a file from your computer and drop it onto the drop zone. Two: click the zone to open a file browser and select a JPG, PNG, or PDF. Three: click the camera icon to take a photo directly with your device camera — especially useful on mobile phones or tablets at a shop terminal. If your receipt is a multi-page PDF, the entire document uploads as one attachment. Multiple receipts for a single expense? Upload them all — they all attach to the same expense record.

**Alternative paths:** If you lost a receipt, note it in the description field — 'Receipt lost; amount verified by bank statement.' Some categories may have a lower threshold requiring a receipt only above a certain dollar amount. Your admin configures this.

**Kinesthetic prompt:** Attach a test image to the expense form using drag and drop. Confirm the file name appears below the drop zone.

---

### Chapter 4 — Linking an Expense to a Job
**Estimated timestamp:** 205s
**UI Element:** `app-expenses .action-btn--primary`
**Chapter label:** "Linking to a Job"

**Narration Script:**
Most expenses in a manufacturing shop are incurred for specific jobs — materials, tooling, shipping. When that is the case, link the expense to the job so the cost rolls up into that job's cost-to-date figure. In the expense form, look for the Job field — a typeahead search. Start typing the job number or customer name and matching jobs appear. Select the correct job. The expense will then appear on that job's cost summary, visible from the job detail panel on the kanban board. Job-linked expenses give managers a real picture of actual cost versus the estimate. If the expense is general overhead — like office supplies — leave the job field empty.

**Alternative paths:** An expense can only be linked to one job. If the cost needs to be split across multiple jobs, create separate expense entries, each with a partial amount, and link each to the appropriate job. Put a note in the description explaining the split.

**Kinesthetic prompt:** In the job field of your test expense, type the first three digits of a job number and observe the typeahead results.

---

### Chapter 5 — Submitting for Approval
**Estimated timestamp:** 270s
**UI Element:** `app-expenses .action-btn--primary`
**Chapter label:** "Submitting"

**Narration Script:**
When the form is complete, click the Submit button. Notice that the dialog button is labeled Submit for Approval, not just Save. This is intentional — the distinction between saving a draft and submitting for review is important. If you click Save as Draft instead, the expense is saved but not yet in the approval queue. Your manager will not see it until you submit it. Once you submit, the expense status changes to Pending Review and it appears in your manager's Approval Queue. You will see the status update in the expense list immediately. You cannot edit a submitted expense directly — to make changes after submitting, you must retract it, edit it, and resubmit.

**Alternative paths:** If your company has a two-level approval — manager plus finance — the expense moves from Pending Review to Approved by Manager, then to Approved by Finance. Your admin configures the approval chain. You will see the current level in the status.

**Kinesthetic prompt:** Submit your test expense and observe the status change in the expense list.

---

### Chapter 6 — Tracking Approval Status
**Estimated timestamp:** 340s
**UI Element:** `app-expenses app-data-table`
**Chapter label:** "Tracking Status"

**Narration Script:**
After submitting, your expense appears in the list with a Pending Review status. Each status has a color indicator. Yellow means it is in someone's queue waiting for action. Green means it is approved and ready for reimbursement. Red means it was rejected and needs your attention. When an expense is approved, you will receive a notification in the bell icon in the header. When it is rejected, you will also get a notification — and critically, the rejection will include a note from your manager explaining what needs to be fixed. Click the rejected expense to open it, read the note, retract it, fix the issue, and resubmit.

**Alternative paths:** If you submitted and never heard back, check whether your manager has seen it. Pending Review expenses that have sat for more than a configured number of days may auto-escalate or trigger a reminder notification to the approver.

**Kinesthetic prompt:** Click on one of your pending expenses. Look for the status indicator and any manager notes attached to it.

---

### Chapter 7 — Correcting a Rejected Expense
**Estimated timestamp:** 410s
**UI Element:** `app-expenses app-data-table`
**Chapter label:** "Fixing Rejections"

**Narration Script:**
Rejected expenses need your attention. When you receive a rejection notification, click it to go directly to the expense. Read the manager's note carefully — it will tell you exactly what is missing or wrong. Common reasons for rejection include: missing or unreadable receipt, amount does not match the receipt, wrong category selected, description too vague, or the expense is a personal purchase. To fix it, click the Retract button on the expense. This pulls it out of the approval queue and back to Draft status. Edit the fields that need correcting, re-attach a clearer receipt if needed, and click Submit for Approval again. The manager receives a notification that you have resubmitted.

**Alternative paths:** If you believe the rejection was an error, you can leave a comment on the expense rather than immediately retracting. The manager can see your comment and reverse their decision without you having to resubmit from scratch.

**Kinesthetic prompt:** Find a rejected expense in your list — or simulate one by asking your manager to reject your test submission. Read the rejection note and practice the retract workflow.

---

### Chapter 8 — Viewing Expense History
**Estimated timestamp:** 480s
**UI Element:** `app-expenses app-data-table`
**Chapter label:** "Expense History"

**Narration Script:**
All your submitted expenses live on this page permanently — not just current ones. Use the date filter in the left sidebar to look back at previous months or years. The category filter lets you see all your travel expenses, or all your supply purchases, grouped together. You can export your expense history as a CSV or PDF from the export button in the toolbar. This is useful at tax time or when preparing a reimbursement report. The total line at the bottom of the filtered results shows the sum of the currently visible expenses — you can filter to a specific date range to see your totals for that period.

**Alternative paths:** If your expenses sync with QuickBooks, approved expenses may appear in QB as vendor bills. You can verify this from the QB sync status icon next to each approved expense.

**Kinesthetic prompt:** Use the date filter to show only expenses from this month. Note the total amount at the bottom of the list.

---

### Chapter 9 — The Manager Approval Queue
**Estimated timestamp:** 545s
**UI Element:** `app-expenses app-data-table`
**Chapter label:** "Manager: Approval Queue"

**Narration Script:**
If you are a manager, the Expenses page has an additional section: the Approval Queue. This is a separate tab showing all expenses from your direct reports that need your review. Each row shows the employee name, date, amount, category, and a preview of the description. Click any row to open the full expense — you can see the attached receipt, read the description, and view any job linkage. To approve, click the green Approve button. To reject, click the red Reject button and write a brief note explaining why. Your note is required before rejection goes through. The employee sees it immediately in their notification feed. If you need more time, you can leave it in the queue — it stays pending until you act.

**Alternative paths:** If you are out of office, designate a backup approver in your manager profile. Pending expenses will also appear in their queue during your absence. Finance-level approvers see a second queue that only populates after manager approval.

**Kinesthetic prompt:** If you have manager access, open the Approval Queue tab. Review one expense and practice the approval action.

---

### Chapter 10 — Expense Best Practices
**Estimated timestamp:** 615s
**UI Element:** `app-expenses`
**Chapter label:** "Best Practices"

**Narration Script:**
Before we finish, a few habits that make expense management smooth for everyone. Submit expenses the same day you incur them — receipts get lost, memories fade, and your manager will have questions you cannot answer a week later. Always link expenses to a job when applicable — vague general expenses are the ones that get rejected most often. Take a photo of the receipt immediately after purchase, even before you are back at your desk — your phone camera is the fastest receipt capture tool you have. And write a specific description. Instead of saying 'supplies,' say 'angle grinder wheels, three boxes, for job 2051 production run.' Five seconds of specificity prevents five minutes of back-and-forth. These habits make you the kind of employee whose expenses get approved on the first try.

**Kinesthetic prompt:** Go back and review your most recent submitted expense. Would a manager who knows nothing about the purchase understand what it was for and why it was necessary? If not, consider adding more detail.

---

## Full Transcript

The Expenses page is divided into a filter sidebar on the left and your expense list on the right. Each expense row shows date, amount, category, and — most importantly — status: Draft, Submitted, Pending Review, Approved, or Rejected.

To create a new expense, click New Expense. Fill in the date of purchase, the exact amount, the category, and a specific description — not just 'supplies' but 'carbide end mills for job 2047.' Specificity prevents rejection. Attach your receipt using the upload zone — drag a file, browse, or take a photo with your device camera.

If the expense is for a specific job, use the Job field to link it. The cost rolls into that job's actual cost total, giving managers real cost-versus-estimate data.

When the form is complete, click Submit for Approval — not just Save. Saved drafts are invisible to your manager. Once submitted, the status becomes Pending Review in your manager's Approval Queue.

Status colors tell you where things stand: yellow means pending, green means approved, red means rejected. Rejections always include a manager note. To fix a rejection, retract the expense, make the corrections, and resubmit.

Managers see an Approval Queue tab with all pending submissions from direct reports. Each review takes seconds — open, read the receipt, and click Approve or Reject.

Three habits that prevent rejected expenses: submit the same day, always attach a receipt, and write a specific description. Employees who follow these three habits get approved on the first try, every time.

---

## Playwright Generation Spec

```json
{
  "appRoute": "/expenses",
  "embedUrl": "https://www.youtube.com/embed/YE7VzlLtp-4",
  "steps": [
    {
      "element": "app-expenses",
      "popover": {
        "title": "Expense Dashboard",
        "description": "You are on the Expenses page. Orient yourself first. On the left is a filter sidebar. On the right is the expense list — each row is one expense with date, amount, description, category, and status. Status is the most important column: Draft, Submitted, Pending Review, Approved, or Rejected. The New Expense button is in the upper right. Managers also see an Approval Queue section we will cover shortly."
      }
    },
    {
      "element": "app-expenses .action-btn--primary",
      "popover": {
        "title": "New Expense",
        "description": "Click New Expense to open the submission form. Fill in: Date — when the expense occurred, not today's date unless they match. Amount — exact dollar amount on your receipt. Category — required dropdown covering Travel, Meals, Supplies, Tools, Fuel, and more. Description — be specific, say carbide end mills for job 2047, not just tools. Merchant — optional but helps approval. Specific descriptions prevent the most common cause of rejection."
      }
    },
    {
      "element": "app-file-upload-zone",
      "popover": {
        "title": "Attaching a Receipt",
        "description": "Every expense needs a receipt. Look for the dashed-border upload zone in the expense form. Three ways to attach: drag a file from your computer and drop it, click to browse and select a JPG, PNG, or PDF, or click the camera icon to take a photo directly with your device camera. Multiple receipts for one expense can all be uploaded — they all attach to the same record. If a receipt is lost, note it in the description field."
      }
    },
    {
      "element": "app-expenses .action-btn--primary",
      "popover": {
        "title": "Linking to a Job",
        "description": "If this expense is for a specific job — materials, tooling, shipping — link it using the Job field in the form. Start typing the job number or customer name and matching jobs appear in a typeahead list. Select the correct job. The cost will roll into that job's actual cost total, visible from the kanban board. If the expense is general overhead, leave the job field empty. For expenses split across multiple jobs, create separate entries with partial amounts."
      }
    },
    {
      "element": "app-expenses .action-btn--primary",
      "popover": {
        "title": "Submitting",
        "description": "When the form is complete, click Submit for Approval. Notice the button says Submit for Approval, not just Save. Saving as a draft keeps it invisible to your manager. Once submitted, the status becomes Pending Review and it appears in your manager's queue. You will receive a notification when the status changes. You cannot edit a submitted expense directly — retract it first, then edit, then resubmit."
      }
    },
    {
      "element": "app-expenses app-data-table",
      "popover": {
        "title": "Tracking Status",
        "description": "After submitting, your expense shows Pending Review in yellow. When approved it turns green. When rejected it turns red. Rejections include a manager note explaining what needs to be fixed — you receive a notification in the header bell icon. Click a rejected expense, read the note, retract it, fix the issue, and resubmit. The manager receives a notification that you have corrected and resubmitted."
      }
    },
    {
      "element": "app-expenses app-data-table",
      "popover": {
        "title": "Fixing Rejections",
        "description": "Rejected expenses need your attention. Read the manager's rejection note carefully — common reasons are missing receipt, amount mismatch, wrong category, or vague description. Click Retract to pull the expense back to Draft status. Edit the issue, re-attach a clearer receipt if needed, and click Submit for Approval again. If you believe the rejection was an error, leave a comment on the expense and the manager can reverse the decision without requiring a full resubmission."
      }
    },
    {
      "element": "app-expenses app-data-table",
      "popover": {
        "title": "Expense History",
        "description": "All expenses live on this page permanently. Use the date filter in the left sidebar to look back at previous months or years. The category filter groups all your travel or supply expenses together. Export your history as a CSV or PDF using the export button in the toolbar — useful at tax time or for reimbursement reports. The total line at the bottom of the filtered results shows the sum of currently visible expenses."
      }
    },
    {
      "element": "app-expenses app-data-table",
      "popover": {
        "title": "Manager: Approval Queue",
        "description": "Managers see an Approval Queue tab with all pending submissions from direct reports. Each row shows employee name, date, amount, category, and a description preview. Click any row to open the full expense — you can see the attached receipt and any job linkage. Approve with the green button. Reject with the red button — a note explaining why is required before rejection goes through. The employee sees your note immediately in their notification feed."
      }
    },
    {
      "element": "app-expenses",
      "popover": {
        "title": "Best Practices",
        "description": "Three habits that eliminate rejected expenses: submit the same day you incur the expense — receipts get lost and memories fade. Always attach a receipt — take the photo immediately after purchase before you are back at your desk. Write a specific description — instead of supplies, say angle grinder wheels, three boxes, for job 2051 production run. Five seconds of specificity prevents five minutes of back-and-forth. Employees who follow these three habits get approved on the first try, every time."
      }
    }
  ],
  "chaptersJson": [
    { "timeSeconds": 0, "label": "Expense Dashboard" },
    { "timeSeconds": 55, "label": "New Expense" },
    { "timeSeconds": 130, "label": "Attaching a Receipt" },
    { "timeSeconds": 205, "label": "Linking to a Job" },
    { "timeSeconds": 270, "label": "Submitting" },
    { "timeSeconds": 340, "label": "Tracking Status" },
    { "timeSeconds": 410, "label": "Fixing Rejections" },
    { "timeSeconds": 480, "label": "Expense History" },
    { "timeSeconds": 545, "label": "Manager: Approval Queue" },
    { "timeSeconds": 615, "label": "Best Practices" }
  ]
}
```
