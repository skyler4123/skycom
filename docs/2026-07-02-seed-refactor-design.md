# Seed Refactor: RetailInitService + RetailEnrichService

## Problem

`Seed::RetailService` is a monolithic 1600-line class that handles two distinct concerns:
1. Initializing system records (roles, categories, property_mappings, table_configs)
2. Enriching with sample business data (branches, employees, products, orders, etc.)

When a company is created in production, only Phase 1 should run (to set up the company's structure). Phase 2 is for development seeding only.

## Solution

Split into two services:

| Service | Responsibility | When It Runs |
|---------|---------------|-------------|
| `Seed::RetailInitService` | Create system records (roles, categories, PMs, TCs) | Company `after_create` + seeding |
| `Seed::RetailEnrichService` | Create sample business data (employees, products, orders) | Seeding only |

Constants that define the "what" move to `config/initializers/constants.rb` with `RETAIL_INIT_*` prefix.

## Architecture

```
Company#after_create
  └─ setup_owner_records  (unchanged: owner Role, Policy, Employee)
     └─ Seed::RetailInitService.call(company: self)
          ├─ create_roles          (Manager, Cashier, Seller, etc.)
          ├─ create_categories     (Cosmetics, Perfumes, etc.)
          ├─ create_table_configs  (visible columns per category)
          └─ setup_roles_and_permissions  (CRUD policies per role)

Seed::ApplicationService
  └─ Seed::RetailEnrichService.new(user:, ...)
       └─ seeding
            ├─ create_brands       (Phase 2 only)
            ├─ create_branches
            ├─ create_pages
            ├─ create_facilities
            ├─ create_departments
            ├─ create_employees
            ├─ create_customers
            ├─ create_inventory
            ├─ create_warehouses / stocks / transfers / imports / exports
            ├─ create_orders / invoices
            └─ create_billing_data
```

## Service APIs

### Seed::RetailInitService
```ruby
Seed::RetailInitService.call(company:)
```
- Idempotent: uses `find_or_create_by!` patterns where appropriate
- Does NOT create owner records (handled by `setup_owner_records`)
- Creates: Roles (8), Categories (~36), TableConfigs (~36), Policies (~600), PolicyAppointments (~80)

### Seed::RetailEnrichService
```ruby
Seed::RetailEnrichService.new(user:, email:, name:, company_name: ...)
```
- Same API as current `Seed::RetailService` minus Phase 1
- Same total record count as current RetailService

## Constants (config/initializers/constants.rb)

| Constant | Source | Description |
|----------|--------|-------------|
| `RETAIL_INIT_ROLES` | `RETAIL_ROLES` | Role names array |
| `RETAIL_INIT_EMPLOYEE_COUNTS` | `EMPLOYEE_COUNTS` | Counts per role |
| `RETAIL_INIT_CUSTOMER_COUNTS` | `CUSTOMER_COUNTS` | Customer counts |
| `RETAIL_INIT_POPULAR_BRANDS` | `POPULAR_BRANDS` | Brand names |
| `RETAIL_INIT_CLINIC_FACILITIES` | `CLINIC_FACILITIES` | Facility names |
| `RETAIL_INIT_CATEGORIES` | `METADATA_CATEGORIES` | Categories + properties + visible columns |
| `RETAIL_INIT_COMPANY_GROUP_BUSINESS_TYPE` | `COMPANY_GROUP_BUSINESS_TYPE` | `:retail` |

## Unchanged

- `Company#setup_owner_records` owner Role/Policy/Employee — same behavior
- `Seed::ApplicationService` — still creates 2 retail companies (same process, different service)
- `Seed::CategoryService`, `Seed::BrandService`, `Seed::BranchService`, etc. — no changes
- Total record count per company — identical

## Files Changed

| File | Action |
|------|--------|
| `config/initializers/constants.rb` | Add `RETAIL_INIT_*` constants |
| `app/services/seed/retail_init_service.rb` | **New** — Phase 1 |
| `app/services/seed/retail_enrich_service.rb` | **New** — Phase 2 (adapted from RetailService) |
| `app/models/company.rb` | Call `RetailInitService` in `setup_owner_records` |
| `app/services/seed/application_service.rb` | Reference `RetailEnrichService` |
| `app/services/seed/retail_service.rb` | **Delete** (replaced by above) |
| Specs referencing `Seed::RetailService` | Update to `Seed::RetailEnrichService` |

## CRUD Policy Creation

The complex `create_all_crud_policies` + `assign_policies_to_roles` logic (~200 lines) moves from `RetailService` into `RetailInitService` unchanged. It does not belong in a separate file — it's initialization logic specific to how roles get their permissions.
