# Profile / SubProfile Pattern

Generic extension buckets for `Employee` and `Customer` so per-domain details
(hospital check-up history, split customer personas, etc.) never bloat the
base tables.

## Resources

| Model | Table | Parent | Profile FK |
|---|---|---|---|
| `EmployeeProfile` | `employee_profiles` | `employee_id!` | — |
| `EmployeeSubprofile` | `employee_subprofiles` | `employee_id!` (denormalized) | `employee_profile_id!` |
| `CustomerProfile` | `customer_profiles` | `customer_id!` | — |
| `CustomerSubprofile` | `customer_subprofiles` | `customer_id!` (denormalized) | `customer_profile_id!` |

All four are full-dynamic resources: `CategoryConcern`,
`PropertyMappingConcern`, `DynamicSearchConcern`, `TagConcern`,
`Discard::Model`, 60 `property_*` columns, `TableConfig` + Meilisearch
via `*::SearchQueryService`. Flat routes:

```
/companies/:company_id/employee_profiles
/companies/:company_id/employee_subprofiles(?employee_id=&employee_profile_id=)
/companies/:company_id/customer_profiles
/companies/:company_id/customer_subprofiles(?customer_id=&customer_profile_id=)
```

## Rules

1. **Profile has many subprofiles** (`dependent: :destroy`).
2. **Parent has many profiles** (`Employee has_many :employee_profiles`, etc.).
3. **Subprofile keeps direct parent id** for fast queries even though it is
   reachable via profile. Validated: `sub.employee_id == profile.employee_id`
   and same `company_id` (see `EmployeeSubprofile#employee_matches_profile_employee`,
   `CustomerSubprofile#customer_matches_profile_customer`).
4. Name uniqueness is scoped to the parent (`scope: :employee_id` /
   `:customer_id` / `:employee_profile_id`), so every parent can have
   "Profile 1".

## Seeding

`Seed::EmployeeProfileService` / `EmployeeSubprofileService` /
`CustomerProfileService` / `CustomerSubprofileService` (`.new`/`.create`,
`**extra` property passthrough preserved across `PropertyPopulator`).
`RetailEnrichService#create_profiles_for_parents` gives every employee and
customer "Profile 1/2" each with "Subprofile 11/12/21/22".

## Reusing for a new resource

1. Migration: copy `20261014000001_create_employee_profiles.rb` (full-dynamic
   columns + `company`, `branch?`, `category!`, `property_mapping!`, parent FKs).
2. Model: copy `app/models/employee_profile.rb` (concerns order per
   `docs/MODEL_STRUCTURE.md`, `general/special` business_type or your own).
3. `Company has_many`, parent `has_many`, `SearchQueryService` subclass,
   controller copied from `Companies::EmployeeProfilesController`,
   policy, routes, `url_helpers.js`, `sidebar_items.js`.
4. 16 Stimulus files: copy `app/javascript/controllers/companies/employee_profiles/`,
   rename class + helpers + `singular[` field names, keep enum fallbacks
   (`docs/FLAKY_TESTS.md` §6) and `poll()` render (`§7`).
5. Specs: model spec + request spec (shared `dynamic search index controller`
   + CRUD with forgery-protection `around` block) + 4 `js: true` feature specs.
