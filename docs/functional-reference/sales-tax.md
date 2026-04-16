# Sales Tax -- Functional Reference

## Overview

The Sales Tax module manages tax rates by jurisdiction (US state) for invoice calculations. Rates are stored per state with effective date ranges, allowing scheduled rate changes. A default rate can be designated as a fallback. When generating invoices, the system looks up the applicable rate based on the customer's billing address state.

This feature is **backend API only** -- there is no dedicated UI page. Tax rates are managed via API and consumed by the invoicing system. Admin UI for rate management may be accessed through the Admin settings area.

**Accounting Boundary:** This is a standalone-mode feature. Sales tax tracking is a simplified per-state rate system -- it does not handle complex multi-jurisdiction tax (county, city, special district) or automated tax calculation services (Avalara, TaxJar). When an accounting provider is connected, tax calculations may defer to that provider.

## Routes

No dedicated UI routes. Backend API only.

## API Endpoints

### Sales Tax Controller (`/api/v1/sales-tax-rates`)

Base authorization: any authenticated user can read. Write operations require elevated roles.

| Method | Path | Auth | Description | Request Body | Response |
|--------|------|------|-------------|--------------|----------|
| `GET` | `/api/v1/sales-tax-rates` | Any authenticated | List all tax rates | -- | `List<SalesTaxRateResponseModel>` |
| `GET` | `/api/v1/sales-tax-rates/for-customer/{customerId}` | Any authenticated | Get effective rate for a customer (by billing state) | -- | `SalesTaxRateResponseModel` or 204 |
| `POST` | `/api/v1/sales-tax-rates` | Admin, Manager | Create a new tax rate | `CreateSalesTaxRateRequestModel` | 201 + `SalesTaxRateResponseModel` |
| `PUT` | `/api/v1/sales-tax-rates/{id}` | Admin, Manager | Update an existing rate | `CreateSalesTaxRateRequestModel` | `SalesTaxRateResponseModel` |
| `DELETE` | `/api/v1/sales-tax-rates/{id}` | Admin | Soft-delete a tax rate | -- | 204 No Content |

## Entities

### SalesTaxRate

| Property | Type | Description |
|----------|------|-------------|
| `Id` | `int` | Primary key |
| `Name` | `string` | Display name (e.g., "California Sales Tax") |
| `Code` | `string` | Short code (e.g., "CA-SALES") |
| `StateCode` | `string?` | 2-letter US state code (e.g., "CA"). Null = general/default rate |
| `Rate` | `decimal` | Combined tax rate as decimal fraction (e.g., 0.0725 = 7.25%) |
| `EffectiveFrom` | `DateTimeOffset` | When this rate takes effect (UTC) |
| `EffectiveTo` | `DateTimeOffset?` | When this rate expires (UTC). Null = currently active |
| `IsDefault` | `bool` | If true, used as fallback when no state-specific rate matches |
| `IsActive` | `bool` | Soft active flag (default true) |
| `Description` | `string?` | Optional description/notes |

Inherits from `BaseAuditableEntity`.

## Enums

No feature-specific enums.

## Request/Response Models

### CreateSalesTaxRateRequestModel

```json
{
  "name": "California Sales Tax",
  "code": "CA-SALES",
  "stateCode": "CA",
  "rate": 0.0725,
  "effectiveFrom": "2026-01-01T00:00:00Z",
  "isDefault": false,
  "description": "CA combined state + avg local rate"
}
```

- `effectiveFrom` defaults to current time if not provided
- `isDefault` should be true for exactly one rate (the fallback)

### SalesTaxRateResponseModel

```json
{
  "id": 1,
  "name": "California Sales Tax",
  "code": "CA-SALES",
  "stateCode": "CA",
  "rate": 0.0725,
  "effectiveFrom": "2026-01-01T00:00:00Z",
  "effectiveTo": null,
  "isDefault": false,
  "isActive": true,
  "description": "CA combined state + avg local rate"
}
```

## Customer Tax Rate Lookup Logic

The `GET /for-customer/{customerId}` endpoint:

1. Looks up the customer's default billing address to determine the state code
2. Finds a `SalesTaxRate` where `StateCode` matches, `IsActive` is true, `EffectiveFrom <= now`, and `EffectiveTo` is null or in the future
3. Falls back to the rate marked `IsDefault` if no state-specific rate exists
4. Returns 204 (No Content) if no rate is configured at all

## Integration Points

- **Invoices**: Invoice generation applies the customer's tax rate to taxable line items. The `Invoice` entity stores the calculated tax amount.
- **Customers**: Customer billing address provides the state code for rate lookup
- **Customer Addresses**: The `CustomerAddress` entity with `AddressType.Billing` determines which state code is used
- **Quotes / Estimates**: Tax rate can be previewed on quotes for customer-facing pricing

## Known Limitations

- Rates are per-state only; county, city, and special district taxes are not modeled separately. Admins are expected to enter the combined effective rate for their nexus jurisdictions.
- No integration with automated tax calculation services (Avalara, TaxJar, Vertex). This is a simple lookup table.
- No tax exemption tracking per customer (e.g., resale certificates, government exemptions). Exempt customers would need their rate manually set to 0 or the tax line removed from invoices.
- No automatic rate update mechanism; admins must manually update rates when state tax laws change.
- Only US states are supported via the `StateCode` field (2-letter codes). International/Canadian tax jurisdictions are not modeled.
- The `EffectiveFrom`/`EffectiveTo` date range mechanism allows scheduling future rate changes, but there is no UI to visualize the rate change timeline.
- Rate history is preserved via soft deletes and `EffectiveTo` dating, but there is no dedicated "rate history" API endpoint.
