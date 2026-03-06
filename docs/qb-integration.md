# Accounting Integration

## Architecture
The accounting integration is **pluggable**. All accounting operations go through `IAccountingService` — a common interface that defines operations for customers, invoices, estimates, POs, payments, time activities, employees, vendors, and items.

**QuickBooks Online is the default and primary provider.** Additional providers (Xero, FreshBooks, Sage, etc.) can be added by implementing the same interface. The app also works in **standalone mode** with no accounting provider configured.

`AccountingServiceFactory` resolves the active provider from `system_settings.accountingProvider`. Each provider owns its auth flow, API client, and DTO mapping — the rest of the app only sees `IAccountingService`.

## QuickBooks Online Provider (Default)
- QB Online REST API via OAuth 2.0
- Single shared company-level connection (one admin authorizes, all users benefit)
- App avoids data duplication — reads/writes QB for financial entities
- Mock layer: MOCK_INTEGRATIONS=true swaps HTTP client to return local JSON fixtures

## Adding a New Accounting Provider
1. Create a new folder under `Integrations/Accounting/Providers/{ProviderName}/`
2. Implement `IAccountingService` with provider-specific API calls
3. Implement the provider's auth flow (OAuth, API key, etc.)
4. Map provider-specific DTOs to/from the common accounting models
5. Register the provider in the DI container with a provider key
6. Add provider-specific setup steps to the admin wizard UI

## What Lives in QB (read/write via API)
- Customers
- Vendors
- Items (products/services)
- Estimates
- Sales Orders
- Purchase Orders
- Invoices
- Payments
- Employee records
- Time Activities (drives payroll)

## What Lives in Our App Only
- Kanban board state (stage, position, track type)
- Job card operational fields (assignee, priority, due date, machine)
- File attachments and revision history
- Activity log / status change history
- R&D iterations and test notes
- Leads (pre-customer, not in QB until conversion)
- Assets/equipment registry
- Maintenance cards
- Planning cycle/backlog management
- Dashboard preferences and daily priorities
- User accounts and roles
- Production traceability (lot tracking, QC records)
- Custom track types and custom fields

## Accounting Identifier Storage
Every entity with an accounting system counterpart stores:
- `external_id` (string) — the provider's unique identifier (QB ListID/TxnID, Xero ContactID, etc.)
- `external_ref` (string) — human-readable reference (QB FullName/RefNumber, Xero contact name, etc.)
- `provider` (string) — which accounting provider this ID belongs to

## Sync Queue
- All accounting write operations go through a persistent queue
- Queue processes immediately when the accounting system is available
- If the accounting system is down, operations queue up, app continues working
- Retries with backoff, flags failures in system health panel after X attempts
- Queue record: entity type, entity ID, operation, payload, status, attempt count, error, timestamp

## Accounting Read Cache
- Accounting data cached locally in Postgres with last_synced timestamp
- App reads from cache first, background sync refreshes periodically
- If the accounting system is down, cached data is stale but usable
- Cache staleness shown in system health panel

## Orphan Detection
- Background job runs periodically (configurable: hourly/daily)
- Compares QB lists against stored IDs
- Orphaned references flagged in system health panel
- Resolution: re-link, archive, or dismiss

## OAuth Token Management
- Access token expires hourly — auto-refresh
- Refresh token expires after 100 days — system health warning before expiry
- Admin re-authenticates when refresh token expires
- Tokens stored encrypted in database

## Stage-to-Accounting Document Mapping (QuickBooks Online)
| Stage | QB Document |
|---|---|
| Quoted | Estimate |
| Order Confirmed | Sales Order |
| Materials Ordered | Purchase Order(s) |
| Shipped | Invoice |
| Payment Received | Payment |

## Card Movement + Accounting Rules
- Forward moves into accounting-linked stages trigger API calls via `IAccountingService`
- Backward moves check for irreversible accounting documents downstream
- Irreversible: Invoice, Payment — drag blocked
- Reversible: Estimate, Sales Order, unfulfilled PO — double confirmation to void
- Voiding confirmation shows: document type, ref number, customer, dollar amount
- In standalone mode (no accounting provider): all card movements are free, no document creation

## Billing Visibility (read-only)
- Job card shows collapsed "Billing Status" section
- Deposits received, progress billed, remaining balance, payment status
- All read from QB cache, no edit capability
