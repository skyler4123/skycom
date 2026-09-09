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
| Categories | ~40 | Per-resource groupings (Cosmetics, Flagship Store, Operations, Stocks, Warehouses, etc.) |
| PropertyMappings | ~40 | Dynamic property labels per category |
| TableConfigs | ~40 | Visible column configuration per category |
| Policies | ~600 | CRUD policies for all resource x action combinations |
| PolicyAppointments | ~80 | Role-to-policy assignments with active/inactive status |

After init, the company is ready to use — users can navigate dashboards, create records, and manage the business.

**Stocks are their own taxonomy (2026-09-09).** A `Stock` record belongs to a `stocks`-resource
category (not its product's category) — `Seed::StockService` assigns one and `CategoryConcern`
falls back to a default `stocks` category. This lets the Stocks index render + search/filter its
own dynamic columns like every other table (`docs/DYNAMIC_TABLE.md` §8).

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
  |   +- Brands, branches, employees, products, stocks, orders...
  |- Enrich Company 2 (RetailEnrichService)
  |   +- Brands, branches, employees, products, stocks, orders...
  |
  +- Enrich Company 3 (HospitalEnrichService)
      +- Branches, departments, facilities, employees, patients, services,
         pharmacy products, warehouses, stocks, transfers/imports/exports,
         shifts + attendance, credit data
```

Future business types (Restaurant, Education) will follow the same pattern
with their own `*InitService` and `*EnrichService`.

### Seeding naming convention — "number name" fallback

When a seeded record's semantic label is hard to pin down for the business type
(e.g. a clinic warehouse, or an arbitrary dynamic property slot), use a
**numbered name** instead of inventing a fake-meaning label or pulling a random
Faker phrase:

| Case | Pattern | Examples |
|------|---------|----------|
| Record name with unclear semantics | `"<Resource> N"` | `"Warehouse 1"`, `"Warehouse 2"`, `"Product 3"` |
| Property label with unclear semantics | `"<Type> Name N"` | `"String Name 1"`, `"Integer Name 2"`, `"Datetime Name 4"` |

Use meaningful names wherever the domain is genuinely clear (`"Distribution Center"`,
`"Skin Type Suitability"`, `"Supplier Purchase"`); the numbered form is only the
fallback so seeded data stays honest about what the seeder actually knows.

### Category assignment — round-robin, not random

Enrich services assign record categories with **`categories[i % categories.length]`**
(`round_robin` helper in `RetailEnrichService` / `HospitalEnrichService`), never
`random_for` — sparse resources (warehouses, stock transfers/imports/exports,
invoices, facilities, orders) would otherwise land in a random subset and leave the
**first** category empty; every index page defaults to that first category
(`docs/DYNAMIC_TABLE.md` §3), so a seed-lucky empty default shows "no records".
Round-robin guarantees every category (including the first) gets data whenever the
resource has at least as many records as categories. Dense resources
(products/customers/employees/brands) keep `random_for` — with 20+ records they
cover all categories in practice.

Hospital enrich also creates pharmacy **invoices** (round-robin across the 3
hospital invoice categories) alongside appointments.

## Key Benefits

- **Production**: New companies are immediately usable with proper roles, categories, and permissions
- **Development**: Sample data can be added selectively to companies that need it
- **Testing**: Companies with only init data (no enrichment) provide a clean baseline for testing
- **Extensible**: Each business type (retail, restaurant, hospital) gets its own init/enrich pair
