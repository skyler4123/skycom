# Skycom Operations System

> **Adding a new operation type?** Read `docs/OPERATION_PAGES.md` first — it is
> the executable, end-to-end procedure. This document explains the domain.

## 1. Overview

Operations are full-screen interfaces keyed by **purpose**, not industry or
role: POS, Booking, Inventory, Reception, Store Manager.
A hospital and a hotel use the same POS operation; their differences live in
categories, dynamic properties, location appointments, and ABAC policies.

`Operation` is company-level. Branch and warehouse connections live in atomic
appointment tables. Operation config (company-wide) wins over appointment config
(location-specific).

---

## 2. Three layers

| Layer | Table / model | Purpose |
|---|---|---|
| **Operation** | `operations` / `Operation` | One deployable purpose for a company. Seeded, never created from the UI. |
| **Branch appointment** | `branch_operation_appointments` / `BranchOperationAppointment` | Binds an Operation to a Branch with branch metadata and active/inactive status. |
| **Warehouse appointment** | `operation_warehouse_appointments` / `OperationWarehouseAppointment` | Binds an Operation to a Warehouse with warehouse metadata and active/inactive status. |

`Operation` is unique per `(company, operation_type)`. The catalog currently
seeds one Operation per purpose.

### Config override direction

```ruby
operation.config_for(appointment)
# => (operation.metadata || {}).deep_merge(appointment.metadata || {})
```

**Appointment wins locally.** Every appointment is created with a deep copy of the
Operation metadata. Saving the Operation config copies the new metadata onto every
branch/warehouse appointment (`update_all`), so local-only keys are discarded and
each local row starts from the new company config. An appointment may then override
keys locally until the next company save.

`roles` is constrained. `Operation#effective_roles(appointment)` uses the local
roles when present (intersected with the Operation roles) and falls back to the
Operation roles when local roles are empty. Appointment roles are validated as a
subset of the Operation roles — or of the company roles when the Operation allows
all roles. Local roles can therefore narrow access but never widen it. At the
Operation level, empty roles means “all roles”; at the appointment level, empty
local roles inherit the Operation roles.

---

## 3. Operation catalog

Source of truth: `OPERATION_TYPES` in `config/initializers/constants.rb`.

| `operation_type` | Label | Code prefix | Appointment scope |
|---|---|---|---|
| `pos` | POS | `POS` | branch |
| `booking` | Booking | `BKG` | branch |
| `inventory` | Inventory | `INV` | warehouse |
| `reception` | Reception | `RCP` | branch |
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
Seed::OperationService.ensure_appointments_for!(
  location:, appointment_class:, operation_scope:, foreign_key:
)
Seed::OperationService.ensure_appointments_for_operation!(operation)
Seed::OperationService.create(company:, operation_type:, ...)
```

- `seed_defaults!` creates one Operation per `OPERATION_TYPES` key for the
  company, then materializes appointments for every existing branch/warehouse.
- `Company#initialize_company` calls it for every non-system company.
- `Branch` and `Warehouse` include `OperationAppointmentConcern`; its `after_create`
  calls `Seed::OperationService.ensure_appointments_for!` with the location model's
  atomic appointment class, operation scope, and foreign key. A future location model
  opts in with one `operation_appointments_for` declaration.
- New appointments start with a deep copy of the Operation metadata (see §2).
- Idempotent: `find_or_initialize_by` / `find_or_create_by!`.
- Code format: catalog prefix + company id short + random hex, e.g.
  `POS-abc12345-1A2B`.

All appointments start `active`. Companies disable the ones they do not use.

---

## 5. Routes and controllers

| Method | Path | Controller#action | Purpose |
|---|---|---|---|
| GET | `/companies/:company_id/operations` | `Companies::OperationsController#index` | List branch + warehouse appointments (filters: `q`, `operation_type`, `workflow_status`, `location`; 1-day cache) |
| GET | `/companies/:company_id/operations/:id/launch` | `Companies::OperationsController#launch` | Resolve appointment and redirect |
| GET | `/companies/:company_id/operation_configs` | `Companies::OperationConfigsController#index` | List company Operation records (filters: `q`, `operation_type`, `workflow_status`; 1-day cache) |
| GET | `/companies/:company_id/operation_configs/:id` | `Companies::OperationConfigsController#show` | Operation config details |
| GET | `/companies/:company_id/operation_configs/:id/edit` | `Companies::OperationConfigsController#edit` | Operation config edit page |
| PATCH | `/companies/:company_id/operation_configs/:id` | `Companies::OperationConfigsController#update` | Update Operation metadata only |
| GET | `/companies/:company_id/branch_operation_appointments/:id` | `Companies::BranchOperationAppointmentsController#show` | Branch appointment details |
| GET | `/companies/:company_id/branch_operation_appointments/:id/edit` | `Companies::BranchOperationAppointmentsController#edit` | Branch appointment edit page |
| PATCH | `/companies/:company_id/branch_operation_appointments/:id` | `Companies::BranchOperationAppointmentsController#update` | Update branch metadata/status |
| GET | `/companies/:company_id/operation_warehouse_appointments/:id` | `Companies::OperationWarehouseAppointmentsController#show` | Warehouse appointment details |
| GET | `/companies/:company_id/operation_warehouse_appointments/:id/edit` | `Companies::OperationWarehouseAppointmentsController#edit` | Warehouse appointment edit page |
| PATCH | `/companies/:company_id/operation_warehouse_appointments/:id` | `Companies::OperationWarehouseAppointmentsController#update` | Update warehouse metadata/status |
| GET | `/companies/:company_id/operations/pos/:operation_id` | `Companies::Operations::PosController#show` | POS (server cents, tax, selling stock, payment methods, locked state) |
| GET | `/companies/:company_id/operations/pos/:operation_id/catalog` | `Companies::Operations::PosController#catalog` | POS search/gallery refresh (Meilisearch `q`) |
| GET | `/companies/:company_id/operations/pos/:operation_id/customer_lookup` | `Companies::Operations::PosController#customer_lookup` | POS customer lookup |
| POST | `/companies/:company_id/operations/pos/:operation_id/lock` | `Companies::Operations::PosController#lock` | Server-enforced terminal lock |
| POST | `/companies/:company_id/operations/pos/:operation_id/unlock` | `Companies::Operations::PosController#unlock` | Password unlock |
| GET | `/companies/:company_id/operations/booking/:operation_id` | `Companies::Operations::BookingController#show` | Booking console (Events/Facilities, real counts, caps, server `now`) |
| GET | `/companies/:company_id/operations/booking/:operation_id/customers` | `Companies::Operations::BookingController#customers` | Customer typeahead (Meilisearch, ≤10) |
| POST | `/companies/:company_id/operations/booking/:operation_id/reservations` | `Companies::Operations::BookingController#create_reservation` | Create a conflict-checked reservation Event + facility/host/customer links |
| POST | `/companies/:company_id/operations/booking/:operation_id/reservations/:reservation_id/extend` | `Companies::Operations::BookingController#extend_reservation` | +30 minutes with next-booking conflict check |
| POST | `/companies/:company_id/operations/booking/:operation_id/reservations/:reservation_id/end` | `Companies::Operations::BookingController#finish_reservation` | End & release (in-progress ends now; stock holds released) |
| POST | `/companies/:company_id/operations/booking/:operation_id/reservations/:reservation_id/cancel` | `Companies::Operations::BookingController#cancel_reservation` | Cancel a booking and free its time |
| GET | `/companies/:company_id/operations/inventory/:operation_id` | `Companies::Operations::InventoryController#show` | Inventory console (warehouse ledger, KPIs, inbound/outbound, counts) |
| GET | `/companies/:company_id/operations/inventory/:operation_id/ledger` | `Companies::Operations::InventoryController#ledger` | Server-paged ledger search/filter (50 rows) |
| GET | `/companies/:company_id/operations/inventory/:operation_id/export` | `Companies::Operations::InventoryController#export` | CSV of the current ledger search + filter |
| POST | `/companies/:company_id/operations/inventory/:operation_id/receipts` | `Companies::Operations::InventoryController#create_receipt` | Receive into the warehouse |
| POST | `/companies/:company_id/operations/inventory/:operation_id/receipts/:receipt_id/post` | `Companies::Operations::InventoryController#post_receipt` | Resume an open import |
| POST | `/companies/:company_id/operations/inventory/:operation_id/transfers` | `Companies::Operations::InventoryController#create_transfer` | Create + initiate a transfer |
| POST | `/companies/:company_id/operations/inventory/:operation_id/transfers/:transfer_id/receive` | `Companies::Operations::InventoryController#receive_transfer` | Destination marks in-transit goods received |
| POST | `/companies/:company_id/operations/inventory/:operation_id/exports` | `Companies::Operations::InventoryController#create_export` | Export goods out of the company |
| POST | `/companies/:company_id/operations/inventory/:operation_id/adjustments` | `Companies::Operations::InventoryController#create_adjustment` | Set a new on hand with a reason |
| POST | `/companies/:company_id/operations/inventory/:operation_id/reorder` | `Companies::Operations::InventoryController#create_reorder` | Create/reuse a purchase draft |
| POST | `/companies/:company_id/operations/inventory/:operation_id/counts` | `Companies::Operations::InventoryController#start_count` | Start a cycle count |
| GET | `/companies/:company_id/operations/inventory/:operation_id/counts/:count_id` | `Companies::Operations::InventoryController#show_count` | Load an open count with lines |
| PATCH | `/companies/:company_id/operations/inventory/:operation_id/counts/:count_id` | `Companies::Operations::InventoryController#update_count` | Save counted progress |
| POST | `/companies/:company_id/operations/inventory/:operation_id/counts/:count_id/submit` | `Companies::Operations::InventoryController#submit_count` | Post variances and complete the count |
| GET | `/companies/:company_id/operations/reception/:operation_id` | `Companies::Operations::ReceptionController#show` | Reception console (guest-linked visits, parcels, rooms, appointments, shift) |
| POST | `/companies/:company_id/operations/reception/:operation_id/check_in` | `Companies::Operations::ReceptionController#check_in` | Walk-in Customer + lobby visit (+ optional host/room/VIP) |
| POST | `/companies/:company_id/operations/reception/:operation_id/pre_register` | `Companies::Operations::ReceptionController#pre_register` | Expected visit Event from a branch-local date/time |
| POST | `/companies/:company_id/operations/reception/:operation_id/advance` | `Companies::Operations::ReceptionController#advance` | Arrive / mark inside / check out / reopen |
| POST | `/companies/:company_id/operations/reception/:operation_id/parcels` | `Companies::Operations::ReceptionController#create_parcel` | Log a held parcel Event |
| POST | `/companies/:company_id/operations/reception/:operation_id/parcels/:parcel_id/notify` | `Companies::Operations::ReceptionController#notify_parcel` | Direct notification to the recipient + `notified_at` |
| POST | `/companies/:company_id/operations/reception/:operation_id/parcels/:parcel_id/pick_up` | `Companies::Operations::ReceptionController#pick_up_parcel` | Complete the parcel Event |
| POST | `/companies/:company_id/operations/reception/:operation_id/notify_host` | `Companies::Operations::ReceptionController#notify_host` | Direct notification to the host + `host_notified_at` |
| GET | `/mobile/companies/:company_id/operations/reception/:operation_id` | `Mobile::Companies::Operations::ReceptionController#show` | Mobile/tablet Shell-First mount point |
| GET | `/companies/:company_id/operations/store_manager/:operation_id` | `Companies::Operations::StoreManagerController#show` | Store Manager console (Orders/Stocks/Employees) |

Both index payloads are cached per company in `Rails.sync_cache` for
`OPERATIONS_CACHE_EXPIRY` (1 day). `OperationPageCacheConcern` deletes the keys on
Operation, appointment, Branch, and Warehouse saves/destroys, so the TTL is only a
backstop. The employee-specific `accessible` flag is computed after the cache read.

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
2. Appointment-level gate: `operation.accessible_by?(employee, appointment:)` using
   `effective_roles(appointment)`.
3. Owner bypasses both.
4. Appointment must be `workflow_status_active?` to launch.

Empty/missing Operation `metadata["roles"]` means every employee with Operation read
can access it. Appointment local roles may only narrow that set: they must be company
roles and, when the Operation defines roles, a subset of the Operation roles. Empty
local roles inherit the Operation roles. Role names are stored as strings; renaming a
role requires updating operation configs.

Role names are edited through the **Access Roles** multi-select on the Operation
config edit page (`/companies/:company_id/operation_configs/:id/edit`). The picker
reads the company's roles from the client cache. The location edit page gets an
**Access Roles** picker restricted to the Operation roles (or all company roles
when the Operation allows all), plus a status selector. Only `metadata["roles"]`
is editable there; every other key already present in the appointment metadata is
preserved when the form is saved. Raw metadata is never exposed in the UI.

---

## 7. Frontend

| Surface | Stimulus controller | Backend |
|---|---|---|
| Operations (one row per location) | `Companies_Operations_IndexController` (`companies--operations--index`) | `Companies::OperationsController#index/launch` |
| Operation details / edit (branch and warehouse) | `Companies_BranchOperationAppointments_ShowController` / `Companies_BranchOperationAppointments_EditController` (and the warehouse pair) | `BranchOperationAppointmentsController` / `OperationWarehouseAppointmentsController` |
| Operation Configs | `Companies_OperationConfigs_IndexController` (`companies--operation-configs--index`) | `Companies::OperationConfigsController#index` |
| Operation config details / edit | `Companies_OperationConfigs_ShowController` / `Companies_OperationConfigs_EditController` | `Companies::OperationConfigsController#show/edit/update` |
| POS | `Companies_Operations_Pos_ShowController` (`companies--operations--pos--show`) | `Companies::Operations::PosController#show` |
| Reception | `Companies_Operations_Reception_ShowController` (`companies--operations--reception--show`) | `Companies::Operations::ReceptionController#show/check_in/pre_register/advance/create_parcel/notify_parcel/pick_up_parcel/notify_host` |
| Booking | `Companies_Operations_Booking_ShowController` (`companies--operations--booking--show`) | `Companies::Operations::BookingController#show/customers/create_reservation/extend_reservation/finish_reservation/cancel_reservation` |
| Inventory | `Companies_Operations_Inventory_ShowController` (`companies--operations--inventory--show`) | `Companies::Operations::InventoryController#show/ledger/export/create_receipt/post_receipt/create_transfer/receive_transfer/create_export/create_adjustment/create_reorder/start_count/show_count/update_count/submit_count` |
| Store Manager | `Companies_Operations_StoreManager_ShowController` (`companies--operations--store-manager--show`) | `Companies::Operations::StoreManagerController#show` |
| Placeholders | `Companies_Operations_<Type>_ShowController` | `Companies::Operations::<Type>Controller#show` |

### 7.1 Time contract

Every operation console belongs to one physical location, so its clock is the
appointment Branch/Warehouse timezone — never the browser and never UTC on
screen. `OperationSerializer.location` ships `timezone` and `utc_offset`
(seconds). Console services return ISO UTC timestamps only; the Stimulus
controller formats with `Helpers.locationTime(value, format, appointment.location)`.
"Today" is the location's calendar day. The full rule is `docs/TIME_DISPLAY.md`.

Reception reuses the existing domain instead of adding visitor/parcel tables:

- **Visit** = `Event` (branch-scoped) with
  `metadata["reception_kind"] = "visit"` **and** a linked Customer. A booking
  with no guest is never a visit. `pending/draft` → expected, `confirmed` →
  lobby, `in_progress` → inside, `completed` → departed, `cancelled` hidden.
- **Visitor** = `Customer` linked through `CustomerEventAppointment`.
- **Host** = `Employee` linked through `EmployeeEventAppointment`.
- **Room** = `Facility` linked through `EventFacilityAppointment`. Rooms are the
  branch/global facilities whose category looks room-like (fallback: all
  facilities). Readiness is derived from the current/next facility Event.
- **Pre-registration** = `Reception::PreRegisterService` creates a `pending`
  visit from branch-local date/time input. Room overlap is allowed; this page
  does not run the Booking conflict checker.
- **Parcel** = `Event` with `metadata["reception_kind"] = "parcel"`,
  `workflow_status: received`, and the recipient employee linked through
  `EmployeeEventAppointment`. Completed parcels disappear from the console.
- **Appointment** = today's Event with a facility link, excluding visit/parcel
  kinds. It appears in the side panel and never moves a visitor count.
- **Shift** = this employee's `ScheduledShift` for the branch whose
  `expected_start_at <= now <= expected_end_at`; nil hides the pill.
- **Timers** = lobby wait from `lobby_entered_at` (legacy fallback
  `checked_in_at`, then start); inside time from `inside_at` (legacy fallback
  `checked_in_at`). Average wait is the mean of lobby waits.
- **Notifications** = `Reception::NotifyHostService` and
  `ParcelService#notify` create one direct notification
  (`notifications.recipient_employee_id`) per click and stamp
  `host_notified_at` / `notified_at`. No tag broadcast is sent.
- **Print** = browser print of one visit. The screen is `print:hidden`; the
  hidden print root contains only company, Visitor, name, visitor company, host,
  room, branch, time and code.
- **Caps** = visits/parcels/appointments first 200. Counts stay full-data
  counts; lists label the cap. Rooms load all room-like facilities and preview 8.

The console payload is `{ visits, parcels, rooms, appointments, counts, shift,
generated_at }`; the controller also ships `company` and `reference`
(`hosts`, `facilities`). The Stimulus controller polls every 20 seconds and
updates only live regions, preserving open forms, typed values, the queue
filter and header search.

`Reception::ConsoleService` builds the read payload;
`Reception::GuestResolver`, `Reception::CheckInService`,
`Reception::PreRegisterService`, `Reception::AdvanceService`,
`Reception::NotifyHostService`, `Reception::ParcelService` and
`Reception::ShiftService` own the writes/derived state. The Stimulus controller
only renders the payload and posts the write actions.

The mobile/tablet route mounts the same Stimulus controller from a Shell-First
`<div>` built by `shell_html` (`Mobile::Companies::Operations::ReceptionController`;
see `docs/MOBILE.md` §2 for why the mobile layout needs it); the responsive
Tailwind layout handles phone portrait, tablet portrait and tablet landscape.
The mobile Operations list adds an **Open Reception** action next to **Open POS**.

Booking reuses the same domain for resource reservations:

- **Timeline row** = `Facility` (room, storage, floor, office) scoped to the
  branch, grouped by its real `category`. Names are never classified as
  equipment/desks.
- **Booking block** = `Event` for the selected day, positioned by `start_at` /
  `end_at` and linked to its spaces through `EventFacilityAppointment`. The
  day query is an overlap query (`start_at < day_end AND end_at > day_start`),
  so a booking that starts the previous day is still visible.
- **Day window** is fixed at 08:00–18:00 and labelled as such. Bookings that
  overlap the window are clipped into blocks; bookings entirely outside it are
  shown as clickable time tags on their facility row.
- **Status** = `upcoming`, `in_progress`, `done`; cancelled Events are excluded
  from the payload. `Booking::Status` derives the state from workflow status
  and the server-supplied `now`, so the KPI strip and the needle agree.
- **Spaces in use** = facilities whose linked non-completed booking is in
  progress at `now`. Category cards and "Spaces by type" are built from those
  facility categories; a category with no facilities never appears.
- **Conflict safety** = `Booking::ConflictChecker` refuses any overlapping
  active booking of the same facility inside a reservation transaction that
  locks the facility row first. Back-to-back windows are allowed. Cancelled
  and completed bookings have released the space.
- **Host / customer** = optional `Employee` / `Customer` records linked
  through `EmployeeEventAppointment` / `CustomerEventAppointment`; the form
  never accepts free-text names.
- **Extend / end / cancel** update the same selected Event. End & release sets
  the Event to `completed`, ends an in-progress Event at `now`, and releases
  stock holds through `Events::AfterSaveService`.
- **Caps** = bookings 200, facilities 100, hosts 100. The payload carries
  `{ capped, limit }`; lists are labelled, KPI counts stay full-data counts.
- **Run sheet** = browser print of the selected day only (branch, date, one line
  per non-cancelled booking in time order).

`Booking::ConsoleService` builds the read payload; `Booking::ReservationService`,
`Booking::ExtendService`, `Booking::FinishService`, `Booking::CancelService`, and
`Booking::CustomerSearchService` own the writes/lookup. The Stimulus controller
only renders the payload, keeps a typed form draft in state, and posts actions.

### 7.1 Booking — deliberately not in this pass

- Weekly recurrence.
- Deposits or payments at booking time.
- Real branch opening hours (08:00–18:00 is an explicit stand-in).
- A health signal behind a "live engine" pill.
- Drag-to-reschedule.
- Automatic no-show release.
- Room List / Desk Zones as separate screens.

### 7.2 Inventory — one warehouse, four loops

The Inventory console is warehouse-scoped. `Inventory::ConsoleService` builds the
read payload (four KPI cards, first ledger page, inbound/outbound stacks, open and
last cycle count, supplier/warehouse reference data); `Inventory::LedgerQueryService`
owns server search, the reorder-point threshold expression, full filter counts and
50-row pages. Exact stock codes are resolved in the DB; other text search uses
Meilisearch with a `company + warehouse` filter.

Every write finishes in the console:

- **Receive** = `Inventory::ReceiveService` creates a `StockImport` + one line and
  executes it through `StockMovementService::Imports::CreateService` (one `add`
  ledger row). An open import can be resumed and posted.
- **Transfer** = `Inventory::TransferService` creates the document and calls
  `StockMovementService::Transfers::InitiateService` (source available drops via a
  hold). The destination console shows the incoming transfer and calls
  `StockMovementService::Transfers::ReceiveService`, which moves the units and
  resolves/creates the destination stock row.
- **Export** = `Inventory::ExportService` creates a one-shot `StockExport`; source
  on hand drops and nothing arrives elsewhere.
- **Adjust** = `Inventory::AdjustmentService` converts a target new on hand into a
  delta `StockAdjustment` (increase/decrease) with the chosen reason. It blocks a
  target below `stock.pending`.
- **Reorder** = `Inventory::ReorderService` creates/reuses a real `Purchase` +
  `PurchaseItem` line with `business_type: stock_reorder`. One open purchase per
  product per warehouse; the row action then links to that purchase.
- **Count** = `Inventory::CountService` starts a `StockCount` for the warehouse
  (snapshotting every stock row's expected quantity under a warehouse row lock),
  saves counted progress, and submits one adjustment per line whose counted value
  differs from the **current** on hand. Rows below reserved are skipped with a
  named error and the rest post. Zero-variance submit still completes a count.

Reorder points come from `ReorderRule` (`min_quantity + safety_stock`) per product
per warehouse, falling back to `LOW_STOCK_THRESHOLD`. The ledger footnote says so.

*Deliberately not in this pass:* BOM/work orders, RFID, dock doors/gates/bays,
pallets/cartons/weight, zone capacity, cloud-sync health, fulfillment-node role,
and the six sibling tabs. The Store Manager tab cleanup remains separate.

Store Manager reuses Orders, Stocks and Employees for the branch command screen:

- **Sales KPIs** = today's paid/completed `Order` rows for the branch, compared
  with the previous day.
- **Fulfillment queue** = today's branch orders in `draft`, `pending`,
  `confirmed` or `in_progress`; the channel chip comes from `business_type`
  (`in_store` → Click & Collect, `online` → Local Delivery, `phone` → Phone Hold).
- **Shelf alerts** = branch `Stock` rows where `quantity - pending` is at or
  below `LOW_STOCK_THRESHOLD`; warehouse availability is the sum of other stock
  rows for the same product.
- **Registers** = today's orders grouped by the credited `Employee`, with shift
  sales and order count.
- **Roster** = active branch employees, with "Active POS" for employees who
  processed orders today.
- **Footfall** is not modelled yet; the payload reports `connected: false` and
  the panel shows hourly order volume instead of inventing visitor counts.

`StoreManager::ConsoleService` builds the read payload; the Stimulus controller
only renders it. The web route is built first; mobile parity is out of scope for
this pass.

The Operations pages use **full-page show + edit** pages, never modals. The two list
pages link the row name to the show page and the edit icon to the edit page. Both
list pages have GET filter bars:

- Operations: keyword, operation type, status, location
- Operation Configs: keyword, operation type, status

The Operation config edit page edits company access roles with a multi-select role
picker (the company's roles come from the client cache); it never exposes raw JSON.
The location edit page has an **Access Roles** picker restricted to the Operation
roles (or all company roles when the Operation allows all) plus a status selector.
It never exposes raw JSON; other metadata keys are preserved but not editable.
The Operations index has no Add button. It lists one row per branch/warehouse
location; Launch is disabled when the location is inactive or the employee lacks
the effective roles. Operation Configs has no Add button and warns that saving a
config here resets every branch and warehouse config.

---

## 8. Adding a new operation type

A new operation type touches every layer. The full procedure — design intake,
real-data rules, page inventory, backend contract, web/mobile parity,
exact-value feature tests, and definition of done — is in
[`docs/OPERATION_PAGES.md`](OPERATION_PAGES.md). Read it before starting.

At a glance:

1. Add the enum value to `Operation.operation_type`.
2. Add the `OPERATION_TYPES` entry (label, code prefix, appointment scope).
3. Backfill existing companies (Operation + appointments).
4. Add the web route, policy, controller, and `OperationLaunchService` entry.
5. Add the console service and real-data payload.
6. Add the shared Stimulus controller.
7. Add the mobile route, policy, shell, and Operations-list link.
8. Add translations and exact-value feature tests.
9. Update `docs/MOBILE.md`, `docs/MOBILE_FEATURE_MATRIX.md`, and BE↔FE headers.

See `docs/TODO.md` "Operations — new operation_type backfill" for the existing
backfill gap.

---

## 9. Database

- `operations`: unique `(company_id, operation_type)`; unique `code`.
- `branch_operation_appointments`: unique `(company_id, branch_id, operation_id)`.
- `operation_warehouse_appointments`: unique `(company_id, operation_id, warehouse_id)`.
- Both appointment tables carry the standard System Fields block; the column default
  is `metadata = {}`, while `Seed::OperationService` copies the Operation metadata
  onto every new appointment.

---

*End of documentation*
