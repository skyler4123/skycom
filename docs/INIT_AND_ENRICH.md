# Skycom Company Initialization & Enrichment

## Overview

Skycom has a two-phase company setup:

| Phase | Service | What It Creates | When It Runs |
|-------|---------|-----------------|-------------|
| **Init** | `Seed::RetailInitService` | Roles, Categories, PropertyMappings, TableConfigs, CRUD Policies | Automatically on company creation (`after_create`) |
| **Enrich** | `Seed::RetailEnrichService` | Brands, Branches, Employees, Customers, Products, Stocks, Orders, Invoices | Explicitly during development seeding |

## Init Phase (Production + Development)

When a user creates a new company (either via signup or during seeding), the `Company` model's `after_create :setup_owner_records` callback fires. This callback:

1. Creates owner Role, Policy, Employee (existing behavior)
2. Creates a BillingContract (free tier)
3. Calls `Seed::RetailInitService.call(company:)`

`Seed::RetailInitService` creates the system records needed for the company to function:

| Record | Count | Purpose |
|--------|-------|---------|
| Roles | 8 | Manager, Cashier, Seller, Security, Admin, Doctor, Therapist, Consultant |
| Categories | ~36 | Per-resource groupings (Cosmetics, Flagship Store, Operations, etc.) |
| PropertyMappings | ~36 | Dynamic property labels per category |
| TableConfigs | ~36 | Visible column configuration per category |
| Policies | ~600 | CRUD policies for all resource x action combinations |
| PolicyAppointments | ~80 | Role-to-policy assignments with active/inactive status |

After init, the company is ready to use — users can navigate dashboards, create records, and manage the business.

## Enrich Phase (Development Only)

During development seeding, `Seed::RetailEnrichService` adds sample business data to make the company ready for testing:

| Record | Count (per company) |
|--------|-------------------|
| Brands | 50 |
| Branches | 2 |
| Pages | 4 (2 per branch) |
| Departments | 4 |
| Employees | ~76 (across 2 branches) |
| Customers | 100 (50 per branch) |
| Products | 28 (14 per branch) |
| Services | 10 (5 per branch) |
| Stocks | ~28 |
| Stock Transfers/Imports/Exports | ~48 |
| Orders + OrderAppointments | ~10 + ~30 |
| Invoices | ~10 |
| Billing Data | 7 days of metrics + 2 invoices |

## Seeding Flow

```
Seed::ApplicationService.run
  |- Create global data (System, PaymentMethods, BillingResources, Users)
  |- Create 3 company_owner users + addresses
  |
  |- Init Company 1 (Grocery 1)
  |   +- Company.create! -> after_create -> RetailInitService -> roles, categories, etc.
  |- Init Company 2 (Grocery VN)
  |   +- Company.create! -> after_create -> RetailInitService -> roles, categories, etc.
  |- Init Company 3
  |   +- Company.create! -> after_create -> RetailInitService -> roles, categories, etc.
  |
  |- Enrich Company 1 (RetailEnrichService)
  |   +- Brands, branches, employees, products, orders...
  |- Enrich Company 2 (RetailEnrichService)
  |   +- Brands, branches, employees, products, orders...
  |
  +- Company 3: init only -- no enrichment
```

Future business types (Restaurant, Hospital, Education) will follow the same pattern
with their own `*InitService` and `*EnrichService`.

## Key Benefits

- **Production**: New companies are immediately usable with proper roles, categories, and permissions
- **Development**: Sample data can be added selectively to companies that need it
- **Testing**: Companies with only init data (no enrichment) provide a clean baseline for testing
- **Extensible**: Each business type (retail, restaurant, hospital) gets its own init/enrich pair
