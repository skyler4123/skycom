# Skycom Operating Pages System

## 1. Overview

Operating Pages are full-screen interfaces keyed by **purpose**, not industry or
role: POS, Booking, Inventory, Reception, Kitchen, Housekeeping, Store Manager.
A hospital and a hotel use the same POS page; their differences live in
categories, dynamic properties, location appointments, and ABAC policies.

`Page` is company-level. Branch and warehouse connections live in atomic
appointment tables. Page config (company-wide) wins over appointment config
(location-specific).

---

## 2. Three layers

| Layer | Table / model | Purpose |
|---|---|---|
| **Page** | `pages` / `Page` | One deployable purpose + resolution for a company. Seeded, never created from the UI. |
| **Branch appointment** | `branch_page_appointments` / `BranchPageAppointment` | Binds a Page to a Branch with branch metadata and active/inactive status. |
| **Warehouse appointment** | `page_warehouse_appointments` / `PageWarehouseAppointment` | Binds a Page to a Warehouse with warehouse metadata and active/inactive status. |

`Page` is unique per `(company, page_type, resolution)`. The catalog currently
seeds one `desktop` Page per purpose.

### Config override direction

```ruby
page.config_for(appointment)
# => (appointment.metadata || {}).deep_merge(page.metadata || {})
```

**Page wins.** A Page config is company-wide and overrides every appointment
config. Appointment metadata only supplies keys the Page does not define.
`Page#accessible_by?` reads `page.metadata["roles"]` only; appointment-level
roles are intentionally ignored.

---

## 3. Page catalog

Source of truth: `PAGE_TYPES` in `config/initializers/constants.rb`.

| `page_type` | Label | Code prefix | Appointment scope |
|---|---|---|---|
| `pos` | POS | `POS` | branch |
| `booking` | Booking | `BKG` | branch |
| `inventory` | Inventory | `INV` | warehouse |
| `reception` | Reception | `RCP` | branch |
| `kitchen` | Kitchen | `KIT` | branch |
| `housekeeping` | Housekeeping | `HSK` | branch |
| `store_manager` | Store Manager | `MGR` | branch |

`appointment_scope` is a **seed-time hint**: branch creation creates branch
appointments for `:branch` pages; warehouse creation creates warehouse
appointments for `:warehouse` pages. It does not scope the Page record.

Display names are seeded from `PAGE_LABELS_BY_BUSINESS_TYPE` (e.g. retail POS
vs front-desk POS), falling back to the catalog label.

> Every company receives the **entire** catalog on init. `business_type` only
> changes display names; it never selects a subset of page types and never
> changes runtime behavior.

---

## 4. Seeding

`Seed::PageService`:

```ruby
Seed::PageService.seed_defaults!(company:)
Seed::PageService.ensure_appointments_for_branch!(branch)
Seed::PageService.ensure_appointments_for_warehouse!(warehouse)
Seed::PageService.ensure_appointments_for_page!(page)
Seed::PageService.create(company:, page_type:, ...)
```

- `seed_defaults!` creates one `desktop` Page per `PAGE_TYPES` key for the
  company, then materializes appointments for every existing branch/warehouse.
- `Company#initialize_company` calls it for every non-system company.
- `Branch#after_create` / `Warehouse#after_create` call the matching ensure
  method, so locations added later get appointments automatically.
- Idempotent: `find_or_initialize_by` / `find_or_create_by!`.
- Code format: catalog prefix + company id short + random hex, e.g.
  `POS-abc12345-1A2B`.

All appointments start `active`. Companies disable the ones they do not use.

---

## 5. Routes and controllers

| Method | Path | Controller#action | Purpose |
|---|---|---|---|
| GET | `/companies/:company_id/pages` | `Companies::PagesController#index` | List branch + warehouse appointments |
| GET | `/companies/:company_id/pages/:id/launch` | `Companies::PagesController#launch` | Resolve appointment and redirect |
| GET | `/companies/:company_id/page_configs` | `Companies::PageConfigsController#index` | List company Page records |
| PATCH | `/companies/:company_id/page_configs/:id` | `Companies::PageConfigsController#update` | Update Page metadata only |
| PATCH | `/companies/:company_id/branch_page_appointments/:id` | `Companies::BranchPageAppointmentsController#update` | Update branch metadata/status |
| PATCH | `/companies/:company_id/page_warehouse_appointments/:id` | `Companies::PageWarehouseAppointmentsController#update` | Update warehouse metadata/status |
| GET | `/companies/:company_id/pages/pos/:page_id` | `Companies::Pages::PosController#show` | POS |
| GET | `/companies/:company_id/pages/booking/:page_id` | `Companies::Pages::BookingController#show` | Placeholder |
| GET | `/companies/:company_id/pages/inventory/:page_id` | `Companies::Pages::InventoryController#show` | Placeholder |
| GET | `/companies/:company_id/pages/reception/:page_id` | `Companies::Pages::ReceptionController#show` | Placeholder |
| GET | `/companies/:company_id/pages/kitchen/:page_id` | `Companies::Pages::KitchenController#show` | Placeholder |
| GET | `/companies/:company_id/pages/housekeeping/:page_id` | `Companies::Pages::HousekeepingController#show` | Placeholder |
| GET | `/companies/:company_id/pages/store_manager/:page_id` | `Companies::Pages::StoreManagerController#show` | Placeholder |

There is **no** create/new/show/edit/update route for Page records. Pages are
seeded; the UI edits config only.

Operation routes accept `branch_id` or `warehouse_id` query params. If omitted,
the resolver falls back to the employee's branch (branch pages) or a warehouse
under that branch (warehouse pages).

`PageLaunchService` maps a page type to its operation route and adds the
appointment's location param.

---

## 6. Authorization

1. Outer gate: `can?(:read, Page)` / `can?(:update, Page)` policies.
2. Page-level gate: `page.accessible_by?(employee)` using
   `page.metadata["roles"]`.
3. Owner bypasses both.
4. Appointment must be `workflow_status_active?` to launch.

Empty/missing `metadata["roles"]` means every employee with Page read can
access the page. Role names are stored as strings; renaming a role requires
updating page configs.

---

## 7. Frontend

| Surface | Stimulus controller | Backend |
|---|---|---|
| Page Appointments | `Companies_Pages_IndexController` (`companies--pages--index`) | `Companies::PagesController#index/launch` |
| Appointment config modal | `Companies_Pages_AppointmentConfigModalController` | `BranchPageAppointmentsController` / `PageWarehouseAppointmentsController` |
| Page Configs | `Companies_PageConfigs_IndexController` (`companies--page-configs--index`) | `Companies::PageConfigsController#index/update` |
| Page config modal | `Companies_PageConfigs_EditModalController` | `Companies::PageConfigsController#update` |
| POS | `Companies_Pages_Pos_ShowController` (`companies--pages--pos--show`) | `Companies::Pages::PosController#show` |
| Placeholders | `Companies_Pages_<Type>_ShowController` | `Companies::Pages::<Type>Controller#show` |

The Pages index has no Add button. It lists appointments; Launch is disabled
when the appointment is inactive or the employee lacks the page role. Page
Configs has no Add button and warns that Page config overrides every
appointment config.

---

## 8. Adding a new page type

A new page type touches six layers:

1. Add the enum value to `Page.page_type`.
2. Add the `PAGE_TYPES` entry (label, prefix, scope).
3. Add a `Companies::Pages::<Type>Controller` + route + policy.
4. Add the route helper to `PageLaunchService`.
5. Add the FE Stimulus controller (or placeholder subclass).
6. **Backfill existing companies** — see `docs/TODO.md` "Operation Pages —
   new page_type backfill". Adding the value alone does not create Page records
   or appointments for existing companies.

---

## 9. Database

- `pages`: unique `(company_id, page_type, resolution)`; unique `code`.
- `branch_page_appointments`: unique `(company_id, branch_id, page_id)`.
- `page_warehouse_appointments`: unique `(company_id, page_id, warehouse_id)`.
- Both appointment tables carry the standard System Fields block and default
  `metadata = {}`.

---

*End of documentation*
