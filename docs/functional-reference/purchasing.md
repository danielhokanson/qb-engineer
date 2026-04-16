# Purchasing (RFQ Management) -- Functional Reference

## Overview

The Purchasing module manages the Request for Quote (RFQ) workflow for sourcing parts from vendors. It covers the complete procurement cycle from creating an RFQ for a part, sending it to multiple vendors, collecting and comparing vendor responses (price, lead time, MOQ, tooling costs), awarding the RFQ to the best vendor, and automatically generating a Purchase Order from the awarded response.

This is distinct from the Purchase Orders module (`/api/v1/purchase-orders`) which handles PO lifecycle after creation. The Purchasing module focuses on the pre-PO sourcing decision process.

This feature has **both a UI and a backend API**.

## Routes

| Route | Component | Description |
|-------|-----------|-------------|
| `/purchasing` | `PurchasingComponent` | RFQ list with search, status filter, and detail dialogs |

Single-page layout (no tabs). RFQ detail opens via `DetailDialogService` with `?detail=rfq:{id}` URL parameter.

## API Endpoints

### Purchasing Controller (`/api/v1/purchasing`)

All endpoints require `Admin`, `Manager`, or `OfficeManager` role.

| Method | Path | Description | Request Body | Response |
|--------|------|-------------|--------------|----------|
| `GET` | `/api/v1/purchasing/rfqs?status={status}&search={term}` | List RFQs with optional filters | Query params | `List<RfqResponseModel>` |
| `POST` | `/api/v1/purchasing/rfqs` | Create a new RFQ | `CreateRfqRequestModel` | 201 + `RfqResponseModel` |
| `GET` | `/api/v1/purchasing/rfqs/{id}` | Get RFQ with full vendor responses | -- | `RfqDetailResponseModel` |
| `PUT` | `/api/v1/purchasing/rfqs/{id}` | Update an RFQ (draft only) | `CreateRfqRequestModel` | 204 No Content |
| `POST` | `/api/v1/purchasing/rfqs/{id}/send` | Send RFQ to selected vendors | `SendRfqToVendorsRequestModel` | 204 No Content |
| `POST` | `/api/v1/purchasing/rfqs/{id}/responses` | Record a vendor's response | `RecordVendorResponseRequestModel` | 204 No Content |
| `GET` | `/api/v1/purchasing/rfqs/{id}/compare` | Compare all vendor responses side-by-side | -- | `List<RfqVendorResponseModel>` |
| `POST` | `/api/v1/purchasing/rfqs/{id}/award/{responseId}` | Award RFQ to a vendor (creates PO) | -- | 201 + `{ purchaseOrderId }` |

## Entities

### RequestForQuote

The core RFQ record.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `RfqNumber` | `string` | Auto-generated identifier (e.g., "RFQ-2026-0042") |
| `PartId` | `int` | FK to Part being sourced |
| `Quantity` | `decimal` | Quantity needed |
| `RequiredDate` | `DateTimeOffset` | When the material is needed |
| `Status` | `RfqStatus` | Current lifecycle status |
| `Description` | `string?` | Additional description of requirements |
| `SpecialInstructions` | `string?` | Special vendor instructions |
| `ResponseDeadline` | `DateTimeOffset?` | Deadline for vendor responses |
| `SentAt` | `DateTimeOffset?` | When the RFQ was sent to vendors |
| `AwardedAt` | `DateTimeOffset?` | When the RFQ was awarded |
| `AwardedVendorResponseId` | `int?` | FK to the winning vendor response |
| `GeneratedPurchaseOrderId` | `int?` | FK to the PO created on award |
| `Notes` | `string?` | Internal notes |

Inherits from `BaseAuditableEntity`.

### RfqVendorResponse

A vendor's response to an RFQ invitation.

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `RfqId` | `int` | FK to RequestForQuote |
| `VendorId` | `int` | FK to Vendor |
| `ResponseStatus` | `RfqResponseStatus` | Pending, Received, Declined, Awarded, NotAwarded |
| `UnitPrice` | `decimal?` | Quoted unit price |
| `LeadTimeDays` | `int?` | Quoted lead time in days |
| `MinimumOrderQuantity` | `decimal?` | Vendor's minimum order quantity |
| `ToolingCost` | `decimal?` | One-time tooling/setup cost |
| `QuoteValidUntil` | `DateTimeOffset?` | Quote expiration date |
| `Notes` | `string?` | Vendor notes/conditions |
| `InvitedAt` | `DateTimeOffset?` | When the vendor was invited |
| `RespondedAt` | `DateTimeOffset?` | When the vendor responded |
| `IsAwarded` | `bool` | True if this response won |
| `DeclineReason` | `string?` | Why the vendor declined |

Inherits from `BaseAuditableEntity`.

## Enums

### RfqStatus

| Value | Description |
|-------|-------------|
| `Draft` | Created but not sent to any vendors |
| `Sent` | Sent to one or more vendors |
| `Receiving` | At least one response has been received |
| `EvaluatingResponses` | All responses in, under evaluation |
| `Awarded` | Vendor selected and PO generated |
| `Cancelled` | RFQ cancelled |
| `Expired` | Response deadline passed without award |

### RfqResponseStatus

| Value | Description |
|-------|-------------|
| `Pending` | Vendor invited but hasn't responded |
| `Received` | Vendor submitted a quote |
| `Declined` | Vendor declined to quote |
| `Awarded` | This vendor won the RFQ |
| `NotAwarded` | Another vendor was selected |

## Status Lifecycle

### RFQ: `Draft` --> `Sent` --> `Receiving` --> `EvaluatingResponses` --> `Awarded` (or `Cancelled`/`Expired`)

1. **Draft**: RFQ created with part, quantity, and requirements. Can be edited.
2. **Sent**: RFQ sent to selected vendors via `POST /{id}/send`. Vendor response records created with `Pending` status.
3. **Receiving**: At least one vendor has submitted a response.
4. **EvaluatingResponses**: All invited vendors have responded (or deadline passed). Responses can be compared side-by-side.
5. **Awarded**: A vendor response is selected via `POST /{id}/award/{responseId}`. A Purchase Order is automatically created from the winning quote. The awarded response gets `IsAwarded = true`; others get `NotAwarded`.

### Vendor Response: `Pending` --> `Received` or `Declined` --> `Awarded` or `NotAwarded`

## Request/Response Models

### CreateRfqRequestModel

```json
{
  "partId": 42,
  "quantity": 500,
  "requiredDate": "2026-05-15T00:00:00Z",
  "description": "Steel brackets per drawing REV-C",
  "specialInstructions": "Material cert required. No substitutions.",
  "responseDeadline": "2026-04-25T00:00:00Z"
}
```

### SendRfqToVendorsRequestModel

```json
{
  "vendorIds": [10, 15, 22]
}
```

### RecordVendorResponseRequestModel

```json
{
  "vendorId": 15,
  "unitPrice": 4.50,
  "leadTimeDays": 14,
  "minimumOrderQuantity": 100,
  "toolingCost": 500.00,
  "quoteValidUntil": "2026-06-01T00:00:00Z",
  "notes": "Price includes material cert. FOB origin."
}
```

### RfqResponseModel (list item)

```json
{
  "id": 1,
  "rfqNumber": "RFQ-2026-0042",
  "partId": 42,
  "partNumber": "BRK-001",
  "partDescription": "Steel Bracket",
  "quantity": 500,
  "requiredDate": "2026-05-15T00:00:00Z",
  "status": "Receiving",
  "description": "Steel brackets per drawing REV-C",
  "specialInstructions": "Material cert required",
  "responseDeadline": "2026-04-25T00:00:00Z",
  "sentAt": "2026-04-10T12:00:00Z",
  "awardedAt": null,
  "awardedVendorResponseId": null,
  "generatedPurchaseOrderId": null,
  "notes": null,
  "vendorResponseCount": 3,
  "receivedResponseCount": 1,
  "createdAt": "2026-04-09T08:00:00Z"
}
```

### RfqDetailResponseModel

Same as `RfqResponseModel` but includes a `vendorResponses` array of `RfqVendorResponseModel` objects.

### RfqVendorResponseModel

```json
{
  "id": 5,
  "rfqId": 1,
  "vendorId": 15,
  "vendorName": "Acme Metals",
  "responseStatus": "Received",
  "unitPrice": 4.50,
  "leadTimeDays": 14,
  "minimumOrderQuantity": 100,
  "toolingCost": 500.00,
  "quoteValidUntil": "2026-06-01T00:00:00Z",
  "notes": "Price includes material cert. FOB origin.",
  "invitedAt": "2026-04-10T12:00:00Z",
  "respondedAt": "2026-04-12T09:30:00Z",
  "isAwarded": false,
  "declineReason": null
}
```

## UI Components

### PurchasingComponent (main page)
- Page header with search input and status filter dropdown
- RFQ list rendered by `RfqListComponent`
- "New RFQ" button opens `RfqDialogComponent` for creation
- Clicking an RFQ opens `RfqDetailDialogComponent` via `DetailDialogService` (URL: `?detail=rfq:{id}`)

### RfqDialogComponent
- Create/edit form for RFQs
- Fields: Part (entity picker), Quantity, Required Date, Description, Special Instructions, Response Deadline

### RfqDetailDialogComponent
- Full RFQ detail with vendor response list
- Actions: Send to Vendors, Record Response, Compare Responses, Award
- Side-by-side vendor comparison view

## Integration Points

- **Parts**: Each RFQ is for a specific Part (`PartId` FK)
- **Vendors**: Vendors are invited to respond; the system uses the `Vendor` entity
- **Purchase Orders**: Awarding an RFQ automatically generates a Purchase Order from the winning vendor response
- **MRP**: MRP planned orders of type `Purchase` can trigger the RFQ process for sourcing decisions (manual workflow)
- **Entity Links**: RFQ detail uses `EntityLinkComponent` for cross-references to parts and generated POs

## Known Limitations

- RFQ invitations are recorded in the system but actual email/notification sending to vendors depends on SMTP configuration and notification system setup
- No portal for vendors to submit responses online; responses are recorded manually by purchasing staff
- The compare endpoint returns raw data; weighted scoring or total-cost-of-ownership calculations are not built into the API
- No automatic RFQ generation from MRP planned orders; the MRP-to-RFQ workflow is manual
- No RFQ templates for recurring parts purchases
- No attachment support on RFQ records (drawings/specs would be attached to the Part record instead)
- The award action creates a PO immediately; there is no intermediate "award pending approval" step (though the Approvals module could be integrated separately)
