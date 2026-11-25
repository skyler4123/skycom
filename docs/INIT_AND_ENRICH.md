# Skycom Company Initialization & Enrichment

## Overview

Skycom has a two-phase company setup:

| Phase | Service | What It Creates | When It Runs |
|-------|---------|-----------------|-------------|
| **Init** | `Seed::RetailInitService` | Roles, Categories, PropertyMappings, TableConfigs, CRUD Policies, one neutral tax code | Automatically on company creation (`after_create`) |
| **Enrich** | `Seed::RetailEnrichService` | Brands, Branches, Employees, Customers, Products, Services, Stocks, Orders, Invoices, tax profiles | Explicitly during development seeding |

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
| TaxCodes | 1 | `NO_TAX` — a 0% neutral code (`vat` for VN, `sales` otherwise). Not set as the default. |

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
| Suppliers | 12 (retail) / 8 (hospital enrich) |
| Branches | 2 |
| Operations | 7 (full purpose catalog per company) + branch/warehouse appointments |
| Operation appointments | Branch creation creates one per branch-scoped Operation; warehouse creation creates one for Inventory |
| Departments | 4 |
| Employees | ~76 (across 2 branches) |
| Compensation / teams | Every employee: salary, allowance, company-aligned `currency`, contract `expiration_date`; branch teams + Leadership `EmployeeGroup` with `employee_groups.manager_id`; owner attached to the first branch |
| Leave balances + requests | 1 paid-leave balance per employee (14 days) + approved/pending `AttendanceLeave` rows |
| Company announcement | 1 published `Document` (`business_type: announcement`) linked to every employee |
| Customers | 100 (50 per branch) |
| Products | 28 (14 per branch) |
| Services | 10 (5 per branch), each with a demo price in the company currency |
| Tax codes | 2 profile codes per company (product + service), assigned to seeded items; the product code becomes the default |
| Stocks | ~28 |
| Stock Transfers/Imports/Exports | ~48 (each with line rows summing to the header; every 3rd doc splits into 2 lines) |
| Stock Adjustments | ≤3 (increase + decreases, with line rows; lines only, no ledger — seeded quantities were written directly) |
| Orders + OrderAppointments | ~10 + ~30 |
| Invoices | ~10 |
| Tickets + TicketComments | ~6 tickets per company (with comments; workflow states across phases) |
| Billing Data | 7 days of metrics + 2 invoices |

After all four enrich services finish, `Seed::ApplicationService` runs these
cross-company demo steps so the owner's own screens are populated:

| Step | What It Guarantees |
|------|--------------------|
| `Seed::ExamSampleService.seed_for` | 12 numbered questions across the question categories, five exams covering `draft`/`published`/`archived`, assignments, attempts across `assigned`/`in_progress`/`submitted`/`graded`/`expired`, and a computed `ExamSummary` per exam. The owner gets one exam in each My Exams tab. |
| `Seed::PayrollService.ensure_current_month!` | Every active employee (owner included) has a current-month `AttendanceMonth` and draft `Payroll`. Uses resolved attendance when present; otherwise seeds a month-to-date fallback summary. |
| `Seed::KpiService.create_samples!` | One active company-wide **Orders sold** `KpiConfig` (target 5). The owner gets one paid order per branch in the current month; staff orders are distributed round-robin, and one order stays unattributed so the leaderboard banner remains visible. |

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
   |- Init Company 3 (Smile Dental Center)
   |   +- Company.create! -> after_create -> HospitalInitService -> roles, categories, etc.
   |- Init Company 4 (Sunrise Hotel)
   |   +- Company.create! -> after_create -> HotelInitService -> roles, categories, etc.
   |
   |- Enrich Company 1 (RetailEnrichService)
   |   +- Brands, branches, employees, compensation/teams, leave,
   |      announcement, products, stocks, orders...
   |- Enrich Company 2 (RetailEnrichService)
   |   +- Brands, branches, employees, compensation/teams, leave,
   |      announcement, products, stocks, orders...
   |
   +- Enrich Company 3 (HospitalEnrichService)
       +- Branches, departments, facilities, employees, compensation/teams,
          leave, announcement, patients, services, pharmacy products,
          warehouses, stocks, transfers/imports/exports, shifts + attendance,
          credit data
   |
   +- Enrich Company 4 (HotelEnrichService)
       +- Branches, departments, facilities, employees, compensation/reporting
          lines, leave, announcement, guests, accommodation services, minibar
          products, warehouses, stocks, transfers/imports/exports, stay orders +
          folios, bookings, purchases, discounts, shifts + attendance, credit data
   |
   +- Demo exams for all 4 companies
       +- Seed::ExamSampleService.seed_for
   +- Demo payroll + KPI for all 4 companies
       +- Seed::PayrollService.ensure_current_month!
       +- Seed::KpiService.create_samples!
   +- Every enrich service ends with Seed::TaxService.enrich!
       +- Adds the company profile and assigns product/service codes
```

All three enrich services call `Seed::CompensationService`,
`Seed::LeaveService`, and `Seed::AnnouncementService` after employees exist.
Compensation also attaches the owner to the first branch and includes the
owner in shift/attendance seeding, so the owner demo login gets payroll data
too. Attendance samples cover the last 35 days **including today**, so a
weekday seed run always creates a current-month attendance day. Payroll drafts
for the current and previous month are then generated from salary + attendance
by `Payrolls::GenerateService`; `Seed::PayrollService.ensure_current_month!`
backfills a month-to-date rollup when the run happens before any weekday has
elapsed, so the owner's current-month payroll page is never empty.

The owner employee is also appended to each enrich service's `@employees`
collection after the regular employees are created. That makes owner records
participate in the same downstream sample data as everyone else — department
assignment, retail employee profiles/subprofiles, event hosts, customer/order
employee appointments, and attendance-request samples — instead of leaving the
owner's own screens empty.

Future business types (Restaurant, Education) will follow the same pattern
with their own `*InitService` and `*EnrichService`.

### Tax seeding (`Seed::TaxService`)

Init creates only `NO_TAX`, a 0% neutral code, and does not set it as the
default. Production companies therefore start with an empty default, exactly
where the owner must choose their rate.

Development enrich adds the demo profiles below, assigns the codes to seeded
products and services that have no code yet, and sets the product code as the
default only when the company has no default. Existing code attributes,
assignments, and defaults are never overwritten. Orders and invoices are not
recalculated, so existing seeded invoices keep their zero-tax state.

| Seeded company | Product code | Service code | Default |
|---|---|---|---|
| Grocery 1 — retail, US | `SALES_825` — Sales tax 8.25%, added | `SALES_0_SERVICE` — Sales tax 0% (services), added | Product code |
| Grocery VN — retail, VN | `VAT_10` — VAT 10%, included | `VAT_8` — VAT 8%, included | Product code |
| Smile Dental Center — hospital, VN | `VAT_5_PHARMACY` — VAT 5% (pharmacy), included | `VAT_0_MEDICAL` — VAT 0% (medical services), included | Product code |
| Sunrise Hotel — hotel, VN | `VAT_10_MINIBAR` — VAT 10% (minibar), included | `VAT_5_ACCOMMODATION` — VAT 5% (accommodation & services), included | Product code |

These are demo profiles, not legal advice. Each seeded code is marked
`metadata: { "seeded" => true }` and its description says to review it before
production use.

The three enrich services call `Seed::TaxService.enrich!(company:)` after their
inventory exists. For existing dev data, run it directly:

```ruby
Seed::TaxService.enrich!(company: Company.find_by(name: "Grocery 1"))
Seed::TaxService.enrich_all!
```

`enrich_all!` skips system companies. It is idempotent, so re-running it after a
partial seed is safe.

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

## Company#business_type

`Company#business_type` does not change runtime business logic. Skycom is a
dynamic system built from atomic resources: categories, dynamic properties,
pairwise appointments, and ABAC policies. Two companies with different
`business_type` values run the same code paths.

At this time `business_type` only matters for seed defaults for modules that still
use it.

Do not introduce runtime `if company.business_type_*?` branching for
operational behavior. Model the difference with categories, properties,
appointments, or policies instead.

## Key Benefits

- **Production**: New companies are immediately usable with proper roles, categories, and permissions
- **Development**: Sample data can be added selectively to companies that need it
- **Testing**: Companies with only init data (no enrichment) provide a clean baseline for testing
- **Extensible**: Each business type (retail, restaurant, hospital) gets its own init/enrich pair
