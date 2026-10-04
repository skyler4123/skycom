# Skycom Event Domain

> **Status**: Live. Events prove the Atomic Appointment thesis: `Event` stays a
> single-purpose table (who/what/when), and every cross-concept link —
> dentist procedure, hotel stay, restaurant banquet — is a pairwise
> `*_appointment` row. There is no `CalendarEquipment` table; there is
> `Event + EventStockAppointment`.

---

## 1. Overview

| Concept | Role |
|---------|------|
| **Event** | The occasion — name, time window (`start_at/end_at`), category, branch. Tracks, never charges. |
| **EventConfig** | Per-category rule row — hold stock? block-or-warn on hold failure? build an order on completion? warn on double-booking? |
| **Appointment rows** | The links — who (customer/employee), what (service), where (facility/branch), needs (stock), bills (order) |
| **Order** | The money — auto-created on completion when asked, then paid through the normal POS pipeline |

```
Event (confirmed, needs 2 × Wagyu + banquet service)
  │  create_stock_pending? ──yes──▶ StockPending holds (:event) — pending += qty
  │  overlapping facility/host? ──▶ warnings[] (warn-but-allow, never blocks)
  ▼  workflow_status → completed
  ├── release :event holds (pending -= qty)
  └── create_order_on_complete? ──yes──▶ Order (pending) + EventOrderAppointment
        │  cashier pays via POS (re-holds as :pos → invoice paid → finalize consumes)
        ▼
      Invoice paid → StockExport + ledger remove
```

The golden split: **Event tracks, Order gets paid.** No double-hold by
construction — event holds release *before* the order is born, and the order
re-holds through its own standard path.

## 2. Schema

### events (folded — `20251130133544_create_events.rb`)

Dynamic resource (60 `property_*` slots) + `start_at`/`end_at` datetimes.
`event_group_id` nullable (standalone events need no group).
`business_type: { appointment: 0, procedure: 1, reservation: 2, banquet: 3 }`
(default `appointment`); `workflow_status` reuses `WORKFLOW_STATUS`
(`pending` ≈ scheduled → `confirmed` → `in_progress` → `completed`/`cancelled`).
Validation: `end_at > start_at` when both present.

### event_configs (one per company + category)

| Flag | Default | Meaning |
|------|---------|---------|
| `create_stock_pending` | `false` | Hold requirement lines as `:event` `StockPending` rows |
| `strict_stock_hold` | `false` | `true` → hold failure rolls everything back (422, nothing saved); `false` → save anyway with a warning |
| `create_order_on_complete` | `false` | Build a pending `Order` from the lines when the event completes |
| `warn_on_facility_overlap` | `true` | Warn when a linked facility is booked by another event in the window |
| `warn_on_host_overlap` | `true` | Warn when a linked employee hosts another event in the window |

### Appointment rows (all `SetDefaultCompanyConcern`, unique `[company_id, a_id, b_id]`)

| Table | Pair | Extras |
|-------|------|--------|
| `branch_event_appointments` | Branch ↔ Event | `role` |
| `customer_event_appointments` | Customer ↔ Event | `role` (patient/guest/vip_client) |
| `employee_event_appointments` (pre-existing) | Employee ↔ Event | — (no role column in v1) |
| `event_service_appointments` | Event ↔ Service | `role` |
| `event_facility_appointments` | Event ↔ Facility | `role` (room_asset/dining_table/…) |
| `event_stock_appointments` | Event ↔ Stock | `quantity` only — **no role**; never writes `Stock` columns |
| `event_order_appointments` | Event ↔ Order | — (bridge trace, service-created only) |

Names are alphabetical (`Customer < Event`, `Event < Facility/Order/Service/Stock`, `Branch < Event`).

## 3. Runtime Contract

### Warn-but-allow

Conflicts and shortages never block a save (unless `strict_stock_hold`).
Every write response carries `warnings[]`:

```json
{ "event": { "...": "..." }, "warnings": ["Facility VIP Table #05 is already booked by ..."] }
```

HTML flows append the count to the flash notice. Real validation failures
stay `422 { errors: [...] }` (`docs/API_ERROR_FORMAT.md`).

### Holds lifecycle (`Events::AfterSaveService`)

One transaction-safe entry point; the controller passes the pre-save
`previous_workflow_status` + `previous_stock_map`:

- **Create/update** — hold added stock lines (flag on); release removed lines.
- **Done (`completed`/`cancelled`)** — release all still-holding `:event`
  pendings for the event's lines (scope release prefers same-`business_type`
  rows first — fungibility accepted per `docs/STOCK.md` §4.5).
- Holds move `pending` only through `hold`/`release` ledger rows
  (`StockPendings::HoldService` / `ReleaseService`); `quantity` is never touched.

### Order bridge (`Events::CreateOrderService`) — DECOUPLED (dormant)

> Events stay independent until reconnected. `Events::AfterSaveService#bridge_order`
> early-returns, so completing an event releases holds but never builds an order.
> The service, table, and associations are kept intact for a one-line reconnect.

Fires on `completed` when the flag is on and lines exist (idempotent — one
order per event): customer = first linked customer else Walk-in; product
lines from stock needs (`product.price` snapshot, need quantity); service
lines (`service.price`, qty 1); `business_type: :in_store`,
`workflow_status: :pending`. The order then pays normally
(`docs/ORDER_PROCESSING_V1.md`).

## 4. Endpoints & Pages

| Surface | Route | Notes |
|---------|-------|-------|
| Events CRUD | `/companies/:id/events` (+ `.json`) | Dynamic search/filter index; JSON create/update return `{ event, warnings }` + accept link arrays (`customer_ids…`, `event_stock_lines`) |
| Event Configs CRUD | `/companies/:id/event_configs` | Plain index (category filter), no Meilisearch (config-style) |
| Calendar board | `/companies/:id/calendar` (+ `.json?start=&end=`) | Day/week/month board over real events (range query, ≤500, no pagy); click-a-slot opens the full-detail create modal prefilled with that slot |

FE: `companies/events/{index,new,show,edit}`, `companies/event_configs/*`,
`companies/calendars/index` (board) + `companies/events/new_modal`
(board create, JSON submit → toast + `calendar:refresh` event, no reload).
Sidebar group `calendar` ("Calendar/Schedule"): Calendar, Events, Event Configs.

## 5. Seeding

**Init** (`RetailInitService` / `HospitalInitService`): `events` categories
(Procedure Booking / Room Stay / Table Reservation — hospital: Ward Stay /
Consultation) with `create_default_event_configs` (bookings hold + bill;
Consultation bills without holds). Admin + Manager get full Event/EventConfig
grants; CRUD policies auto-created via `Company::DEFAULT_RESOURCE_NAMES`.

**Enrich** (retail): 2 events per branch across categories (round-robin),
each linking customer + host + service + facility + 1 stock unit —
planning rows only, no holds, no orders.

## 6. Testing

| Spec | Coverage |
|------|----------|
| `spec/models/event*_spec.rb`, `event_config_spec.rb`, `*_appointment_spec.rb` | associations, company derivation, time window, quantity validation, no-inventory-mutation |
| `spec/services/events/conflict_warning_service_spec.rb` | facility/host overlap, flag-off silence, cancelled ignored, stock shortage |
| `spec/services/events/after_save_service_spec.rb` | hold opt-in/out, strict raise vs warn, update reconciliation, release on completed/cancelled, order bridge trigger |
| `spec/services/events/create_order_service_spec.rb` | snapshots, walk-in fallback, idempotency, flag-off, zero-lines |
| `spec/services/events/search_query_service_spec.rb` | shared dynamic-search contract |
| `spec/services/seed/retail_init_event_spec.rb` | categories + configs + grants on fresh retail company |
| `spec/requests/companies/{events,calendars}_controller_spec.rb` | search contract, JSON create/update + warnings, board range + scoping |
| `spec/features/companies/{events,event_configs,calendars}/*_spec.rb` | index/new/show/edit E2E, config CRUD, board views + click-to-create modal |

Run: `bundle exec parallel_rspec -n 10 spec/models/event* spec/services/events \
spec/services/seed/retail_init_event_spec.rb spec/requests/companies/events_controller_spec.rb \
spec/requests/companies/calendars_controller_spec.rb spec/features/companies/events \
spec/features/companies/event_configs spec/features/companies/calendars`

## 7. Not Built Yet

| Item | Notes |
|------|-------|
| `role` on employee links | `employee_event_appointments` predates the pattern; add via normal additive migration when needed |
| Stock deduction on completion | Holds release; consumption happens through the bridged Order's finalize (the sanctioned path) |
| `event_groups` categories | Groups work standalone; init seeds `events` categories only |
| Recurring events | No recurrence rule; one row per occurrence |
| Hospital enrich events | Retail only for now; mirror `create_events` when the hospital track needs it |

## 8. File Reference

| File | Purpose |
|------|---------|
| `app/models/event.rb` / `event_config.rb` | Occasion + per-category rules |
| `app/models/{branch,customer}_event_appointment.rb`, `event_{service,facility,stock,order}_appointment.rb` | Atomic links |
| `app/services/events/conflict_warning_service.rb` | Overlap + shortage warnings |
| `app/services/events/after_save_service.rb` (+ `strict_hold_error.rb`) | Hold reconcile + release + bridge trigger |
| `app/services/events/create_order_service.rb` | Completed → pending Order + link |
| `app/services/events/search_query_service.rb` | TableConfig → Meilisearch |
| `app/controllers/companies/{events,event_configs,calendars}_controller.rb` | CRUD + board feed |
| `app/policies/companies/{events,event_configs,calendars}_policy.rb` | ABAC (`calendars#index?` = read Event) |
| `app/javascript/controllers/companies/{events,event_configs,calendars}/` | Dashboards + board + create modal |
| `app/services/seed/{retail,hospital}_init_service.rb` | Categories + configs + grants |
| `app/services/seed/{event,event_group}_service.rb` | Seed builders (group auto-create dropped — groups stay manual in v1) |
| `db/migrate/20251130133544_create_events.rb` (folded) / `20261003000001..07` | Schema |

---

*See also: `docs/STOCK.md` (holds + fungibility), `docs/ORDER_PROCESSING_V1.md`
(the pipeline the bridged order flows through), `docs/DYNAMIC_TABLE.md` §8
(search rollout), `docs/SIDEBAR.md` (calendar group).*
