# Leave Management -- Functional Reference

## Overview

The Leave Management module handles employee time-off policies, balance tracking, and leave request submission/approval. Administrators define leave policies with accrual rates, balance caps, carry-over limits, and waiting periods. Employees submit leave requests against policies they are enrolled in, and managers approve or deny them. Balances are tracked per user per policy.

This feature is **backend API only** -- there is no dedicated UI page for leave management. Leave requests may be submitted and managed through the employee account area or integrated into other features.

## Routes

No dedicated UI routes. Backend API only.

## API Endpoints

### Leave Controller (`/api/v1/leave`)

Base authorization: any authenticated user. Admin-only endpoints noted below.

#### Policies

| Method | Path | Auth | Description | Request Body | Response |
|--------|------|------|-------------|--------------|----------|
| `GET` | `/api/v1/leave/policies?activeOnly={bool}` | Any authenticated | List leave policies | Query: `activeOnly` (default true) | `List<LeavePolicyResponseModel>` |
| `POST` | `/api/v1/leave/policies` | Admin | Create a new leave policy | `CreateLeavePolicyRequestModel` | 201 + `LeavePolicyResponseModel` |

#### Balances

| Method | Path | Auth | Description | Response |
|--------|------|------|-------------|----------|
| `GET` | `/api/v1/leave/balances/{userId}` | Any authenticated | Get leave balances for a user | `List<LeaveBalanceResponseModel>` |

#### Requests

| Method | Path | Auth | Description | Request Body | Response |
|--------|------|------|-------------|--------------|----------|
| `GET` | `/api/v1/leave/requests?userId={id}&status={status}` | Any authenticated | List leave requests with optional filters | Query params | `List<LeaveRequestResponseModel>` |
| `POST` | `/api/v1/leave/requests` | Any authenticated | Submit a leave request | `CreateLeaveRequestModel` | 201 + `LeaveRequestResponseModel` |
| `POST` | `/api/v1/leave/requests/{id}/approve` | Admin, Manager | Approve a leave request | -- | 204 No Content |
| `POST` | `/api/v1/leave/requests/{id}/deny` | Admin, Manager | Deny a leave request | `DenyLeaveRequestBody?` | 204 No Content |

## Entities

### LeavePolicy

Defines a type of leave with accrual and balance rules.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `Name` | `string` | Policy name (e.g., "Vacation", "Sick Leave", "PTO") |
| `AccrualRatePerPayPeriod` | `decimal` | Hours accrued each pay period |
| `MaxBalance` | `decimal?` | Maximum balance cap (null = unlimited) |
| `CarryOverLimit` | `decimal?` | Max hours carried over at year end (null = unlimited) |
| `AccrueFromHireDate` | `bool` | Whether accrual starts from hire date (default true) |
| `WaitingPeriodDays` | `int?` | Days before accrual begins (e.g., 90-day waiting period) |
| `IsPaidLeave` | `bool` | Whether this is paid time off (default true) |
| `IsActive` | `bool` | Whether the policy is currently active |

Inherits from `BaseAuditableEntity`.

### LeaveBalance

Tracks an individual user's leave balance for a specific policy.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `UserId` | `int` | FK to ApplicationUser |
| `PolicyId` | `int` | FK to LeavePolicy |
| `Balance` | `decimal` | Current available balance (hours) |
| `UsedThisYear` | `decimal` | Hours used in the current year |
| `AccruedThisYear` | `decimal` | Hours accrued in the current year |
| `LastAccrualDate` | `DateTimeOffset` | When the last accrual was applied |

Inherits from `BaseEntity`.

### LeaveRequest

An employee's request to take time off.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `UserId` | `int` | FK to ApplicationUser (requestor) |
| `PolicyId` | `int` | FK to LeavePolicy |
| `StartDate` | `DateOnly` | First day of leave |
| `EndDate` | `DateOnly` | Last day of leave |
| `Hours` | `decimal` | Total hours requested |
| `Status` | `LeaveRequestStatus` | Current status |
| `ApprovedById` | `int?` | FK to user who approved/denied |
| `DecidedAt` | `DateTimeOffset?` | When the decision was made |
| `Reason` | `string?` | Employee's reason for the request |
| `DenialReason` | `string?` | Manager's reason for denial |

Inherits from `BaseAuditableEntity`.

## Enums

### LeaveRequestStatus

| Value | Description |
|-------|-------------|
| `Pending` | Submitted, awaiting manager decision |
| `Approved` | Approved by manager |
| `Denied` | Denied by manager |
| `Cancelled` | Cancelled by the employee |

## Status Lifecycle

### Leave Request: `Pending` --> `Approved` or `Denied` or `Cancelled`

1. **Submit**: Employee creates a leave request specifying policy, date range, and hours. Status starts as `Pending`.
2. **Approve**: Manager or Admin approves via `POST /{id}/approve`. Status changes to `Approved`. Balance is deducted.
3. **Deny**: Manager or Admin denies via `POST /{id}/deny` with an optional denial reason. Status changes to `Denied`.
4. **Cancel**: The `Cancelled` status exists for employee-initiated cancellation (the cancel endpoint may not be exposed yet).

## Request/Response Models

### CreateLeavePolicyRequestModel

```json
{
  "name": "Vacation",
  "accrualRatePerPayPeriod": 4.0,
  "maxBalance": 160.0,
  "carryOverLimit": 40.0,
  "accrueFromHireDate": true,
  "waitingPeriodDays": 90,
  "isPaidLeave": true
}
```

### CreateLeaveRequestModel

```json
{
  "policyId": 1,
  "startDate": "2026-05-01",
  "endDate": "2026-05-05",
  "hours": 40.0,
  "reason": "Family vacation"
}
```

Note: `startDate` and `endDate` use `DateOnly` format (no time component).

### DenyLeaveRequestBody

```json
{
  "reason": "Insufficient coverage during that week. Please reschedule."
}
```

### LeavePolicyResponseModel

```json
{
  "id": 1,
  "name": "Vacation",
  "accrualRatePerPayPeriod": 4.0,
  "maxBalance": 160.0,
  "carryOverLimit": 40.0,
  "accrueFromHireDate": true,
  "waitingPeriodDays": 90,
  "isPaidLeave": true,
  "isActive": true
}
```

### LeaveBalanceResponseModel

```json
{
  "id": 1,
  "userId": 5,
  "policyId": 1,
  "policyName": "Vacation",
  "balance": 80.0,
  "usedThisYear": 24.0,
  "accruedThisYear": 64.0,
  "lastAccrualDate": "2026-04-01T00:00:00Z"
}
```

### LeaveRequestResponseModel

```json
{
  "id": 10,
  "userId": 5,
  "userName": "Hartman, Daniel J",
  "policyId": 1,
  "policyName": "Vacation",
  "startDate": "2026-05-01",
  "endDate": "2026-05-05",
  "hours": 40.0,
  "status": "Pending",
  "approvedById": null,
  "approvedByName": null,
  "decidedAt": null,
  "reason": "Family vacation",
  "denialReason": null,
  "createdAt": "2026-04-16T10:00:00Z"
}
```

## Integration Points

- **Users / Employees**: Leave balances and requests are per-user. The `UserId` FK references `ApplicationUser`.
- **Payroll**: Approved leave hours feed into payroll calculations. The `IsPaidLeave` flag on the policy determines whether hours are compensated.
- **Time Tracking**: Leave hours may need to be reconciled with time tracking entries to prevent double-counting of absent days.
- **Approvals Module**: Leave requests could optionally route through the Approvals module for multi-step approval workflows, though the current implementation has a direct approve/deny flow.
- **Events/Calendar**: Approved leave could be surfaced on the company calendar and shop floor scheduling.
- **Notifications**: Submission, approval, and denial of leave requests generate notifications.

## Known Limitations

- No dedicated UI page for leave management; API-only at this time
- No employee self-service cancel endpoint (the `Cancelled` status exists in the enum but no API route to set it)
- Accrual processing is not automated via a background job; `LastAccrualDate` and `AccruedThisYear` need to be updated by a scheduled task that is not yet implemented
- No holiday calendar integration -- the system does not subtract company holidays from leave hour calculations
- No half-day or partial-day leave support beyond manually adjusting the `Hours` field
- No blackout date enforcement (preventing leave during critical production periods)
- No team calendar view showing who is out on a given day
- No automatic balance rollover at year-end; carry-over processing would need to be triggered manually or via a future Hangfire job
- The balance deduction on approval and restoration on cancellation/denial logic depends on the handler implementation
- No policy assignment to specific users or groups; all users presumably have access to all active policies (enrollment mechanism not exposed via API)
- No distinction between exempt and non-exempt employees for leave accrual rules
