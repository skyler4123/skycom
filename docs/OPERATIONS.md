# Skycom Operations System

## 1. Overview

Operations are full-screen interfaces keyed by **purpose**, not industry or
role: POS, Booking, Inventory, Reception, Kitchen, Housekeeping, Store Manager.
A hospital and a hotel use the same POS operation; their differences live in
categories, dynamic properties, location appointments, and ABAC policies.

`Operation` is company-level. Branch and warehouse connections live in atomic
appointment tables. Operation config (company-wide) wins over appointment config
(location-specific).

---

## 2. Three layers

| Layer | Table / model | Purpose |
|---|---|---|
| **Operation** | `operations` / `Operation` | One deployable purpose + resolution for a company. Seeded, never created from the UI. |
| **Branch appointment** | `branch_operation_appointments` / `BranchOperationAppointment` | Binds an Operation to a Branch with branch metadata and active/inactive status. |
| **Warehouse appointment** | `operation_warehouse_appointments` / `OperationWarehouseAppointment` | Binds an Operation to a Warehouse with warehouse metadata and active/inactive status. |

`Operation` is unique per `(company, operation_type, resolution)`. The catalog currently
seeds one `desktop` Operation per purpose.

### Config override direction

```ruby
operation.config_for(appointment)
# => (appointment.metadata || {}).deep_merge(operation.metadata || {})
```

**Operation wins.** An Operation config is company-wide and overrides every
appointment config. Appointment metadata only supplies keys the Operation does not define.
`Operation#accessible_by?` reads `operation.metadata["roles"]` only; appointment-level
roles are intentionally ignored.

---

## 3. Operation catalog

Source of truth: `OPERATION_TYPES` in `config/initializers/constants.rb`.

| `operation_type` | Label | Code prefix | Appointment scope |
|---|---|---|---|
| `pos` | POS | `POS` | branch |
| `booking` | Booking | `BKG` | branch |
| `inventory` | Inventory | `INV` | warehouse |
| `reception` | Reception | `RCP` | branch |
| `kitchen` | Kitchen | `KIT` | branch |
| `housekeeping` | Housekeeping | `HSK` | branch |
| `store_manager` | Store Manager | `MGR` | branch |

`appointment_scope` is a **seed-time hint**: branch creation creates branch
appointments for `:branch` operations; warehouse creation creates warehouse
appointments for `:warehouse` operations. It does not scope the Operation record.

Display names are the catalog labels: every business type seeds the same `POS`,
`Booking`, `Inventory`, … names.

> Every company receives the **entire** catalog on init. `business_type` never
> selects a subset of operation types, never changes display names, and never
> changes runtime behavior.

---

## 4. Seeding

`Seed::OperationService`:

```ruby
Seed::OperationService.seed_defaults!(company:)
Seed::OperationService.ensure_appointments_for_branch!(branch)
Seed::OperationService.ensure_appointments_for_warehouse!(warehouse)
Seed::OperationService.ensure_appointments_for_operation!(operation)
Seed::OperationService.create(company:, operation_type:, ...)
```

- `seed_defaults!` creates one `desktop` Operation per `OPERATION_TYPES` key for the
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
| GET | `/companies/:company_id/operations` | `Companies::OperationsController#index` | List branch + warehouse appointments |
| GET | `/companies/:company_id/operations/:id/launch` | `Companies::OperationsController#launch` | Resolve appointment and redirect |
| GET | `/companies/:company_id/operation_configs` | `Companies::OperationConfigsController#index` | List company Operation records |
| GET | `/companies/:company_id/operation_configs/:id` | `Companies::OperationConfigsController#show` | Operation config details |
| GET | `/companies/:company_id/operation_configs/:id/edit` | `Companies::OperationConfigsController#edit` | Operation config edit page |
| PATCH | `/companies/:company_id/operation_configs/:id` | `Companies::OperationConfigsController#update` | Update Operation metadata only |
| GET | `/companies/:company_id/branch_operation_appointments/:id` | `Companies::BranchOperationAppointmentsController#show` | Branch appointment details |
| GET | `/companies/:company_id/branch_operation_appointments/:id/edit` | `Companies::BranchOperationAppointmentsController#edit` | Branch appointment edit page |
| PATCH | `/companies/:company_id/branch_operation_appointments/:id` | `Companies::BranchOperationAppointmentsController#update` | Update branch metadata/status |
| GET | `/companies/:company_id/operation_warehouse_appointments/:id` | `Companies::OperationWarehouseAppointmentsController#show` | Warehouse appointment details |
| GET | `/companies/:company_id/operation_warehouse_appointments/:id/edit` | `Companies::OperationWarehouseAppointmentsController#edit` | Warehouse appointment edit page |
| PATCH | `/companies/:company_id/operation_warehouse_appointments/:id` | `Companies::OperationWarehouseAppointmentsController#update` | Update warehouse metadata/status |
| GET | `/companies/:company_id/operations/pos/:operation_id` | `Companies::Operations::PosController#show` | POS |
| GET | `/companies/:company_id/operations/booking/:operation_id` | `Companies::Operations::BookingController#show` | Placeholder |
| GET | `/companies/:company_id/operations/inventory/:operation_id` | `Companies::Operations::InventoryController#show` | Placeholder |
| GET | `/companies/:company_id/operations/reception/:operation_id` | `Companies::Operations::ReceptionController#show` | Placeholder |
| GET | `/companies/:company_id/operations/kitchen/:operation_id` | `Companies::Operations::KitchenController#show` | Placeholder |
| GET | `/companies/:company_id/operations/housekeeping/:operation_id` | `Companies::Operations::HousekeepingController#show` | Placeholder |
| GET | `/companies/:company_id/operations/store_manager/:operation_id` | `Companies::Operations::StoreManagerController#show` | Placeholder |

There is **no** create/new/show/edit/update route for `Operation` records themselves.
Operations are seeded; the UI edits config only, through the `operation_configs`
show/edit pages.

Operation routes accept `branch_id` or `warehouse_id` query params. If omitted,
the resolver falls back to the employee's branch (branch operations) or a warehouse
under that branch (warehouse operations).

`OperationLaunchService` maps an operation type to its operation route and adds the
appointment's location param.

---

## 6. Authorization

1. Outer gate: `can?(:read, Operation)` / `can?(:update, Operation)` policies.
2. Operation-level gate: `operation.accessible_by?(employee)` using
   `operation.metadata["roles"]`.
3. Owner bypasses both.
4. Appointment must be `workflow_status_active?` to launch.

Empty/missing `metadata["roles"]` means every employee with Operation read can
access the operation. Role names are stored as strings; renaming a role requires
updating operation configs.

---

## 7. Frontend

| Surface | Stimulus controller | Backend |
|---|---|---|
| Operation Appointments | `Companies_Operations_IndexController` (`companies--operations--index`) | `Companies::OperationsController#index/launch` |
| Appointment details / edit | `Companies_BranchOperationAppointments_ShowController` / `Companies_BranchOperationAppointments_EditController` (and the warehouse pair) | `BranchOperationAppointmentsController` / `OperationWarehouseAppointmentsController` |
| Operation Configs | `Companies_OperationConfigs_IndexController` (`companies--operation-configs--index`) | `Companies::OperationConfigsController#index` |
| Operation config details / edit | `Companies_OperationConfigs_ShowController` / `Companies_OperationConfigs_EditController` | `Companies::OperationConfigsController#show/edit/update` |
| POS | `Companies_Operations_Pos_ShowController` (`companies--operations--pos--show`) | `Companies::Operations::PosController#show` |
| Placeholders | `Companies_Operations_<Type>_ShowController` | `Companies::Operations::<Type>Controller#show` |

The Operations pages use **full-page show + edit** pages, never modals. The two list
pages link the row name to the show page and the edit icon to the edit page.
The Operations index has no Add button. It lists appointments; Launch is disabled
when the appointment is inactive or the employee lacks the operation role. Operation
Configs has no Add button and warns that Operation config overrides every
appointment config.

---

## 8. Adding a new operation type

A new operation type touches six layers:

1. Add the enum value to `Operation.operation_type`.
2. Add the `OPERATION_TYPES` entry (label, prefix, scope).
3. Add a `Companies::Operations::<Type>Controller` + route + policy.
4. Add the route helper to `OperationLaunchService`.
5. Add the FE Stimulus controller (or placeholder subclass).
6. **Backfill existing companies** — see `docs/TODO.md` "Operations —
   new operation_type backfill". Adding the value alone does not create Operation records
   or appointments for existing companies.

---

## 9. Database

- `operations`: unique `(company_id, operation_type, resolution)`; unique `code`.
- `branch_operation_appointments`: unique `(company_id, branch_id, operation_id)`.
- `operation_warehouse_appointments`: unique `(company_id, operation_id, warehouse_id)`.
- Both appointment tables carry the standard System Fields block and default
  `metadata = {}`.

---

*End of documentation*
