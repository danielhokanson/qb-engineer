# Approvals -- Functional Reference

## Overview

The Approvals module provides a configurable multi-step approval workflow engine for any entity type in the system. Administrators define approval workflows with ordered steps, each assigned to a specific user, role, or the submitter's direct manager. The system supports auto-approval below configurable thresholds, delegation, escalation after timeout, and a full audit trail of decisions.

This feature has **both a UI and a backend API**.

## Routes

| Route | Component | Description |
|-------|-----------|-------------|
| `/approvals` | Redirects to `/approvals/inbox` | Default tab |
| `/approvals/inbox` | `ApprovalsComponent` | Pending approval requests for the current user |
| `/approvals/workflows` | `ApprovalsComponent` | Workflow configuration (Admin/Manager only) |

Tabs: `inbox`, `workflows`

## API Endpoints

### Approvals Controller (`/api/v1/approvals`)

Base authorization: any authenticated user. Admin-only endpoints noted below.

#### Approval Requests

| Method | Path | Auth | Description | Request Body | Response |
|--------|------|------|-------------|--------------|----------|
| `GET` | `/api/v1/approvals/pending` | Any authenticated | Get pending approvals for the current user | -- | `List<ApprovalRequestResponseModel>` |
| `GET` | `/api/v1/approvals/history/{entityType}/{entityId}` | Any authenticated | Get approval history for an entity | -- | `List<ApprovalRequestResponseModel>` |
| `POST` | `/api/v1/approvals/submit` | Any authenticated | Submit an entity for approval | `SubmitApprovalRequestModel` | 201 + `ApprovalRequestResponseModel` or `{ approvalRequired: false }` |
| `POST` | `/api/v1/approvals/{requestId}/approve` | Any authenticated | Approve a pending request | `ApprovalActionRequestModel?` | `ApprovalRequestResponseModel` |
| `POST` | `/api/v1/approvals/{requestId}/reject` | Any authenticated | Reject a pending request | `ApprovalActionRequestModel` | `ApprovalRequestResponseModel` |
| `POST` | `/api/v1/approvals/{requestId}/delegate` | Any authenticated | Delegate to another user | `DelegateApprovalRequestModel` | 204 No Content |

#### Workflow Administration

| Method | Path | Auth | Description | Request Body | Response |
|--------|------|------|-------------|--------------|----------|
| `GET` | `/api/v1/approvals/workflows` | Admin, Manager | List all approval workflows | -- | `List<ApprovalWorkflowResponseModel>` |
| `POST` | `/api/v1/approvals/workflows` | Admin | Create a new workflow | `CreateApprovalWorkflowRequestModel` | 201 + `ApprovalWorkflowResponseModel` |
| `PUT` | `/api/v1/approvals/workflows/{id}` | Admin | Update a workflow | `CreateApprovalWorkflowRequestModel` | `ApprovalWorkflowResponseModel` |

## Entities

### ApprovalWorkflow

Defines a reusable approval process for a specific entity type.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `Name` | `string` | Workflow name (e.g., "Expense Approval > $500") |
| `EntityType` | `string` | Which entity type this workflow applies to (e.g., "expense", "purchase-order", "leave-request") |
| `IsActive` | `bool` | Whether this workflow is currently active |
| `Description` | `string?` | Optional description |
| `ActivationConditionsJson` | `string?` | JSON conditions for when this workflow triggers (e.g., amount thresholds) |

Inherits from `BaseAuditableEntity`.

### ApprovalStep

A single step within an approval workflow.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `WorkflowId` | `int` | FK to ApprovalWorkflow |
| `StepNumber` | `int` | Order within the workflow (1, 2, 3...) |
| `Name` | `string` | Step name (e.g., "Manager Review") |
| `ApproverType` | `ApproverType` | Who approves: SpecificUser, Role, or Manager |
| `ApproverUserId` | `int?` | FK to user (when ApproverType = SpecificUser) |
| `ApproverRole` | `string?` | Role name (when ApproverType = Role) |
| `UseDirectManager` | `bool` | If true, routes to submitter's direct manager |
| `AutoApproveBelow` | `decimal?` | Auto-approve if amount is below this threshold |
| `EscalationHours` | `int?` | Hours before escalating to next step/level |
| `RequireComments` | `bool` | Whether approver must provide comments |
| `AllowDelegation` | `bool` | Whether this step can be delegated (default true) |

### ApprovalRequest

An instance of an entity submitted for approval.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `WorkflowId` | `int` | FK to ApprovalWorkflow |
| `EntityType` | `string` | Entity type being approved |
| `EntityId` | `int` | ID of the entity being approved |
| `CurrentStepNumber` | `int` | Which step is currently active |
| `Status` | `ApprovalRequestStatus` | Overall request status |
| `RequestedById` | `int` | User who submitted for approval |
| `RequestedAt` | `DateTimeOffset` | When submitted |
| `Amount` | `decimal?` | Dollar amount (for threshold checks) |
| `EntitySummary` | `string?` | Human-readable description of the entity |
| `CompletedAt` | `DateTimeOffset?` | When fully approved or rejected |
| `EscalatedAt` | `DateTimeOffset?` | When escalation occurred |

### ApprovalDecision

A record of an individual step decision.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `RequestId` | `int` | FK to ApprovalRequest |
| `StepNumber` | `int` | Which step this decision was for |
| `DecidedById` | `int` | User who made the decision |
| `Decision` | `ApprovalDecisionType` | Approve, Reject, Delegate, Escalate |
| `Comments` | `string?` | Approver comments |
| `DecidedAt` | `DateTimeOffset` | When the decision was made |
| `DelegatedToUserId` | `int?` | If delegated, the new approver |

## Enums

### ApprovalRequestStatus

| Value | Description |
|-------|-------------|
| `Pending` | Awaiting decision at the current step |
| `Approved` | All steps approved |
| `Rejected` | Rejected at any step |
| `Escalated` | Escalated due to timeout |
| `Cancelled` | Submitter cancelled the request |
| `AutoApproved` | Amount below auto-approve threshold |

### ApproverType

| Value | Description |
|-------|-------------|
| `SpecificUser` | A named user must approve |
| `Role` | Any user with the specified role can approve |
| `Manager` | The submitter's direct manager |

### ApprovalDecisionType

| Value | Description |
|-------|-------------|
| `Approve` | Step approved |
| `Reject` | Step rejected (terminates the workflow) |
| `Delegate` | Reassigned to another user |
| `Escalate` | Escalated (typically due to timeout) |

## Status Lifecycle

### Request: `Pending` --> `Approved` or `Rejected` or `Escalated` or `AutoApproved` or `Cancelled`

1. **Submit**: Entity submitted via `POST /submit`. System finds matching active workflow by entity type and evaluates activation conditions.
   - If no workflow matches, returns `{ approvalRequired: false }` -- the action can proceed without approval.
   - If the amount is below the first step's `AutoApproveBelow` threshold, status is set to `AutoApproved` immediately.
2. **Pending**: Request is at step N. The designated approver (user, role member, or manager) sees it in their inbox.
3. **Approve**: If the current step is the last step, the request moves to `Approved`. Otherwise, it advances to the next step (`CurrentStepNumber` increments).
4. **Reject**: At any step, rejection terminates the workflow immediately with status `Rejected`.
5. **Delegate**: The current approver reassigns to another user. The step remains the same but the approver changes.
6. **Escalate**: If `EscalationHours` is set and the step has not been decided within that time, it escalates (potentially to the next step or a fallback approver).

### Multi-Step Flow Example

```
Expense $2,500 submitted
  Step 1: Manager Review (AutoApproveBelow: $500) --> Amount exceeds threshold, requires decision
  Step 1: Manager approves
  Step 2: Finance Director Review (ApproverType: Role "Admin")
  Step 2: Admin user approves
  Request status: Approved
```

## Request/Response Models

### SubmitApprovalRequestModel

```json
{
  "entityType": "expense",
  "entityId": 42,
  "amount": 2500.00,
  "entitySummary": "Hotel stay - Client visit (Chicago)"
}
```

### ApprovalActionRequestModel

```json
{
  "comments": "Approved. Please ensure receipts are attached."
}
```

### DelegateApprovalRequestModel

```json
{
  "delegateToUserId": 15,
  "comments": "I'm OOO this week, delegating to VP."
}
```

### CreateApprovalWorkflowRequestModel

```json
{
  "name": "Expense Approval",
  "entityType": "expense",
  "description": "Two-step approval for expenses over $500",
  "activationConditionsJson": "{\"minAmount\": 500}",
  "steps": [
    {
      "stepNumber": 1,
      "name": "Manager Review",
      "approverType": "Manager",
      "approverUserId": null,
      "approverRole": null,
      "useDirectManager": true,
      "autoApproveBelow": 500,
      "escalationHours": 48,
      "requireComments": false,
      "allowDelegation": true
    },
    {
      "stepNumber": 2,
      "name": "Finance Review",
      "approverType": "Role",
      "approverUserId": null,
      "approverRole": "Admin",
      "useDirectManager": false,
      "autoApproveBelow": null,
      "escalationHours": 72,
      "requireComments": true,
      "allowDelegation": true
    }
  ]
}
```

### ApprovalRequestResponseModel

```json
{
  "id": 1,
  "workflowName": "Expense Approval",
  "entityType": "expense",
  "entityId": 42,
  "entitySummary": "Hotel stay - Client visit",
  "amount": 2500.00,
  "currentStepNumber": 2,
  "currentStepName": "Finance Review",
  "status": "Pending",
  "requestedByName": "Hartman, Daniel J",
  "requestedAt": "2026-04-15T09:00:00Z",
  "completedAt": null,
  "decisions": [
    {
      "id": 1,
      "stepNumber": 1,
      "stepName": "Manager Review",
      "decidedByName": "Smith, John A",
      "decision": "Approve",
      "comments": "Looks good",
      "decidedAt": "2026-04-15T14:00:00Z",
      "delegatedToUserName": null
    }
  ]
}
```

## UI Components

### Inbox Tab (default)
- Shows all pending approval requests for the current user
- `ApprovalInboxComponent` renders the list
- Each item shows: workflow name, entity type, entity summary, amount, current step, requested by, requested date
- Actions per item: Approve, Reject, Delegate

### Workflows Tab (Admin/Manager only)
- `ApprovalWorkflowEditorComponent` for CRUD on workflows
- Workflow list with steps configuration
- Visible only to users with Admin or Manager role

## Integration Points

- **Any Entity**: The approval system is polymorphic -- it can attach to any entity type via the `EntityType`/`EntityId` pattern. Common use cases:
  - **Expenses**: Expense approval above a threshold
  - **Purchase Orders**: PO approval for high-value orders
  - **Leave Requests**: Leave approval routing
  - **Time Corrections**: Manager approval for time entry changes
- **Users / Roles**: Approver routing uses `ApproverType` to find the right person (specific user, anyone in a role, or direct manager)
- **Notifications**: Approval requests and decisions generate notifications (via the NotificationService/SignalR)

## Known Limitations

- Activation conditions are stored as JSON but the condition evaluation engine's supported operators are basic (primarily amount thresholds); complex boolean expressions or field-level conditions are not yet supported
- No parallel approval steps (all steps are sequential); two approvers at the same level would need to be modeled as two separate steps
- No "any of" approval for role-based steps -- only one user in the role needs to approve, but there is no explicit quorum/voting mechanism
- Escalation runs on a time-based check but requires a background job (Hangfire) to be configured to periodically scan for overdue steps
- No recall/cancel endpoint for the submitter to withdraw a pending request (the `Cancelled` status exists but there is no API to set it)
- The workflow editor does not validate that referenced users/roles exist at creation time
- No approval delegation calendar (out-of-office auto-delegation)
