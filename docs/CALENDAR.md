# Skycom Calendar / Schedule Module

> **Status**: Live (2026-09-30). Skycom owns its own scheduling data. No external
> provider (Cal.com, Google, Outlook) is connected — see §7 for the seam that
> will host one later.
>
> Replaces the old, never-finished `events` domain (`events`, `event_groups`,
> `event_tag_appointments`, `event_group_tag_appointments`,
> `employee_event_appointments`, `employee_event_group_appointments`), removed
> 2026-09-30. The old tables had no time columns at all, so nothing was migrated
> across.

---

## 1. What it is

A booking system for companies that schedule things: a dental clinic booking a
patient into a surgery room with a dentist, an assistant and the X-ray; a salon
booking a client with a stylist and a chair. Fourteen `calendar_*` tables, ten
pages, a month/week/day board, and a hard block on double-booking.

The worked example throughout this doc is the dental clinic from the original
design conversation.

---

## 2. Design principles

| Principle | How it shows up |
|---|---|
| **Isolated island** | No calendar model includes `CategoryConcern`, `PropertyMappingConcern`, `DynamicSearchConcern` or `TagConcern`. No `SearchQueryService`, no Meilisearch, no dynamic columns. |
| **No direct ERP references** | The calendar module never names `Employee`, `Customer`, `Facility`, `Stock` or `Service` in a foreign key. It reaches them only through a polymorphic `source_type` / `source_id` pair. |
| **Multi-tenant** | Every table has `company_id` + a foreign key. Tenancy is enforced in the controller layer (this app has no `acts_as_tenant` and no `default_scope`). |
| **Raw data, no scheduling logic in Skycom** | `calendar_availability_rules` stores hours; it does not compute free slots. That is the adapter's job (§7). |
| **Sync-ready** | Every syncable table carries `external_provider` / `external_id` / `external_etag` / `sync_status` / `last_synced_at` / `last_sync_error`. Unused today. |

### The source bridge

`Calendar::SourceLinkConcern` is the only door into the core ERP:

```ruby
class CalendarPractitioner
  source_links_to "Employee", "User"
  requires_source_link true          # must resolve to a live record
end
```

| Table | May point at |
|---|---|
| `calendar_practitioners` | `Employee`, `User` — **required** |
| `calendar_procedures` | `Service` — optional |
| `calendar_locations` | `Facility`, `Branch` — optional |
| `calendar_equipments` | `Stock`, `Product` — optional |
| `calendar_participants` | `Customer` — optional |
| `calendar_events` | `Order`, `Reservation` (what created the booking) — optional |

Because the link is polymorphic there is **no database foreign key**, so the
model validates it instead: `source_type` must be on the declared list, and
`source_id` must resolve to an existing row. See §5 for the guard that stops a
typo'd `source_type` raising `NameError` instead of failing validation.

`Employee` reaches back through the same pair:

```ruby
has_many :calendar_practitioners, -> { where(source_type: "Employee") },
  foreign_key: :source_id, inverse_of: :source, dependent: :destroy
```

---

## 3. Table map

```
Company
  │
  ├── calendar_positions ──┬── calendar_practitioners ──┐  (source_type/source_id → Employee|User)
  │                        │                             │
  │                        └── calendar_procedures ──────┼── calendar_events ──┐
  │                                      (source → Service)  │                   │
  │                                                          │                   │
  ├── calendar_locations ── (source → Facility|Branch) ───────┤                   │
  ├── calendar_equipments ── (source → Stock|Product) ────────┤                   │
  ├── calendar_participants ─ (source → Customer) ────────────┤                   │
  │                                                          │                   │
  └── calendar_availability_rules (practitioner XOR location) │                   │
                                                             │                   │
   calendar_event_practitioners ─────────────────────────────┘                   │
   calendar_event_locations ─────────────────────────────────────────────────────┤
   calendar_event_equipment ─────────────────────────────────────────────────────┤
   calendar_event_participants ───────────────────────────────────────────────────┘

   calendar_sync_connections ──< calendar_sync_logs        (provider config + audit)
```

| Table | Purpose |
|---|---|
| `calendar_positions` | A bookable job position — "Dentist", "Dental Assistant". |
| `calendar_practitioners` | A person who can be booked, filling a position. |
| `calendar_locations` | A bookable room or place. |
| `calendar_equipments` | A bookable device. |
| `calendar_participants` | The person an appointment is for. |
| `calendar_procedures` | A bookable appointment type — "Removal teeth". |
| `calendar_events` | The booking: time window + status. |
| `calendar_event_practitioners` | Which practitioners, and in what capacity (lead / assistant / observer). |
| `calendar_event_locations` | Which rooms (primary / secondary). |
| `calendar_event_equipment` | Which machines. |
| `calendar_event_participants` | Who the booking is for. |
| `calendar_availability_rules` | Raw weekly working hours per practitioner or room, plus blackouts. |
| `calendar_sync_connections` | Per-company provider config. Credentials are **Active Record encrypted**. |
| `calendar_sync_logs` | Append-only audit of every push / pull. |

### Naming

Table names are plural everywhere, matching the other 191 tables in the schema —
including `calendar_equipments`, whose singular `Equipment` is a mass noun Rails
would otherwise pluralise awkwardly. Every table uses `id: :uuid, default: -> { "uuidv7()" }` and carries the mandated System Fields block.

### Useful indexes

- `calendar_events (company_id, starts_at, ends_at)` — drives both the board's range query and the overlap probe.
- `calendar_event_<resource> (company_id, <resource>_id)` — drives the conflict probe per resource.
- `calendar_availability_rules` has two CHECK constraints: exactly one owner, and `end_time > start_time`.

---

## 4. The dental case, end to end

| Concept | Row |
|---|---|
| Position | `calendar_positions` → *Dentist* |
| Practitioners | `calendar_practitioners` × 2, each `source_type: "Employee"` |
| Room | `calendar_locations` → *Surgery Room 1* (`source_type: "Facility"`) |
| Machine | `calendar_equipments` → *X-Ray* (`source_type: "Stock"`) |
| Patient | `calendar_participants` → *Patient A* (`source_type: "Customer"`) |
| Procedure | `calendar_procedures` → *Tooth Extraction*, 60 min, `requires_location: true`, `requires_equipment: true`, `requires_practitioners: 2` |
| Availability | `calendar_availability_rules` → Mon–Fri 09:00–17:00 per practitioner |
| Booking | `calendar_events` + 4 join rows (2 practitioners, 1 room, 1 machine, 1 patient) |

---

## 5. Conflict detection

**A double-booking is a hard block on save**, and the check lives on the model —
not in a service — so it applies on every write path: controller, console, rake
task and seeder alike.

```ruby
# CalendarEvent
validate :no_resource_conflicts, on: %i[create update]
```

### The rule

```
existing.starts_at < candidate.starts_at_window.ends_at  AND  existing.ends_at > candidate.starts_at
```

Concretely, two events conflict when

```
existing.starts_at < candidate.ends_at  AND  existing.ends_at > candidate.starts_at
```

The window is **half-open**: shared endpoints are *not* an overlap, so
10:00–11:00 followed by 11:00–12:00 for the same practitioner is perfectly
normal. Only a partial overlap (10:00–11:30 against 10:30–11:30) collides.

### What is checked

Every assigned practitioner, location, machine and participant. A resource
booked across three overlapping events yields **one** error, not three.

### What is ignored

- `cancelled` and `no_show` events — they release the resource.
- Another company's rows.

### Statuses

`CalendarEvent::BLOCKING_STATUSES = pending, confirmed, in_progress` occupy a
resource. `CalendarEvent::HIDDEN_ON_BOARD_STATUSES = cancelled` is the only
status the board hides — a completed or no-show appointment still happened and
belongs on the grid.

### Where the errors surface

`Calendar::BookingService` wraps the save and raises
`Calendar::BookingService::Conflict` (a double-booking) or
`Calendar::BookingService::Error` (an ordinary validation failure). The
controller renders `errors: [...]` with HTTP 422 in both cases, per
`docs/API_ERROR_FORMAT.md`.

The booking form also offers **Check availability**, which calls the read-only
`POST /calendar_events/conflicts` pre-flight so the clash is visible *before*
submitting. The same server rules run again on save, so the pre-flight is a
convenience and never the source of truth. When editing, the pre-flight passes
`except_id` so the booking does not report itself as its own conflict.

---

## 6. Availability

`calendar_availability_rules` stores raw weekly windows:

| Field | Meaning |
|---|---|
| `calendar_practitioner_id` / `calendar_location_id` | Exactly one — enforced by a CHECK constraint. |
| `days_of_week` | ISO weekdays `1..7` (Mon..Sun). **Empty means every day.** |
| `start_time` / `end_time` | `"HH:MM"`, 24h, in `timezone`. No overnight spans in v1. |
| `is_unavailable` | A blackout / leave block that subtracts from availability. |
| `effective_from` / `effective_to` | Optional validity window. |

Two rules for the same owner, overlapping days and overlapping times are
rejected by the controller with an `errors` entry — a provider must never
receive a contradictory schedule.

**Skycom does not compute free slots from these.** A provider that owns
scheduling logic is authoritative, and that is exactly why the hours are stored
raw. Free-slot search is `Calendar::Adapter#available_slots` (§7).

---

## 7. The provider seam

Nothing is connected. `Calendar::AdapterFactory::REGISTRY` is empty, so
`available?("calcom")` is `false` and calling `.for(company, provider: "calcom")`
raises `UnknownProvider`. The Sync page reports this honestly rather than
pretending an integration is live.

| Piece | Role |
|---|---|
| `Calendar::Adapter` | Abstract base. `provider`, `sync_resource`, `create_event`, `update_event`, `cancel_event`, `fetch_events(from:, to:)`, `available_slots(...)` — each raises `Calendar::Adapter::NotImplementedError` (rescuable, unlike Ruby's built-in `NotImplementedError`, which descends from `ScriptError`). Implementations must call `mark_synced!` / `mark_sync_failed!` and write a `CalendarSyncLog` per attempt. |
| `Calendar::AdapterFactory` | `Calendar::AdapterFactory.for(company, provider:)` — the only entry point. Registering Cal.com later is one line here plus one new adapter file. |
| `Calendar::SyncableConcern` | Declares the sync columns and the `pending_sync` / `synced` / `sync_failed` / `externally_linked` scopes. |
| `calendar_sync_connections` | Per-company config. `credentials` is `encrypts`-ed at rest and is **never** serialised — `public_attributes` whitelists the safe keys. |
| `calendar_sync_logs` | Append-only audit, with `direction` and `status` enums. |

`CALENDAR_SYNC_PROVIDERS` declares the supported set (`calcom`, `google`,
`outlook`) so the Sync page can list what *would* be connectable.

---

## 8. Pages

Sidebar group **Calendar/Schedule** (`calendar_schedule`), inserted after
`attendance`:

| Item | Route | Controller |
|---|---|---|
| Calendar Board | `/calendars` | `Companies::CalendarsController` |
| Appointments | `/calendar_events` | `Companies::CalendarEventsController` |
| Procedures | `/calendar_procedures` | `…::CalendarProceduresController` |
| Positions | `/calendar_positions` | `…::CalendarPositionsController` |
| Practitioners | `/calendar_practitioners` | `…::CalendarPractitionersController` |
| Locations | `/calendar_locations` | `…::CalendarLocationsController` |
| Equipment | `/calendar_equipments` | `…::CalendarEquipmentsController` |
| Participants | `/calendar_participants` | `…::CalendarParticipantsController` |
| Availability | `/calendar_availability_rules` | `…::CalendarAvailabilityRulesController` |
| Calendar Sync | `/calendar_syncs` | `…::CalendarSyncsController` |

The five resource pages (positions / practitioners / locations / equipment /
participants) exist because the booking form needs a picker for each — without
CRUD pages a user could only book against seed data.

### The board

`Companies::CalendarsController#index` renders a shell;
`#events?start=&end=` is the grid's range query. It returns the
FullCalendar-compatible field names the shared `calendar` Stimulus controller
already understands (`id` / `title` / `start` / `end` / `allDay` /
`backgroundColor` / `extendedProps`).

That controller's `apiUrl` value has **no default** — a consumer must always
supply one. Two consumers today:

- the board → `data-calendar-api-url-value="/companies/:id/calendars/events"`
- `/demo` → `data-calendar-api-url-value="/demo/calendar_events"`

It accepts both payload shapes (bare array and `{ events: [...] }`). Both range
ends are widened to cover their whole day, because the grid asks with plain
`YYYY-MM-DD` and a midnight end would drop the entire final day.

### Forms

`Helpers.form()` emits a plain `<form>`, and most of the app relies on the
server issuing a redirect. This module is JSON-only (AGENTS.md: "Data Flow: JSON
API, avoid server-side HTML partials"), so every calendar form carries
`data-action="submit->…#submit"` and uses
`controllers/companies/form_submit.js`:

- `submitViaJson` intercepts the submit, calls `fetchJson`, and dispatches
  `form:success` / `form:error`.
- `formBodyFromDom` converts FormData's **flat** bracket keys
  (`"calendar_event[starts_at]"`) into real nested objects. Rails only
  un-flattens those from a form-encoded body — a JSON body is taken literally,
  so without this `params.require(:calendar_event)` raises.

---

## 9. Seeding

`Seed::CalendarEnrichService` builds the dental scenario: 2 positions, 4
practitioners, 2 rooms, 2 machines, 8 participants, 3 procedures, 5 availability
windows and ~220 bookings across −2 months / +6 weeks. Wired into
`Seed::HospitalEnrichService` (company_3, the dental clinic).

**Bookings are deliberately non-overlapping per resource.** The hard-block
validation has no seed bypass — `Seed::CalendarEventService` goes through
`Calendar::BookingService` — so a seeder that picked times at random would
raise `InvalidRecord` partway through and leave a half-built dataset. Slot
handout guarantees no practitioner, room or machine is ever in two places at
once.

---

## 10. Permissions

The eight user-facing calendar models were added to
`Company::DEFAULT_RESOURCE_NAMES`, without which ABAC cannot grant access and
the Permissions page will not list them. Policies are the standard six-method
template; the board resolves against `CalendarEvent` read rather than owning a
resource of its own.

`DEFAULT_RESOURCE_NAMES` is only a **fallback**: `Company#resource_names` reads
`metadata["resource_names"]` first. Companies seeded before this change keep
their existing list and will not see the calendar resources in the Permissions
UI until the list is extended.

---

## 11. Gotchas

- **`permit(days_of_week: [])`** — a bare `:days_of_week` symbol is *silently
  dropped* by strong params for an array value. The form would save an empty
  day list and every rule would then match every day.
- **A bogus `source_type` raises `NameError`, not a validation error** — reading
  a polymorphic association `constantize`s the type. `Calendar::SourceLinkConcern`
  therefore validates the type *first* and only reads `source` once the type is
  known good (`source_resolvable?`).
- **`company_id` is nil until the association is read** — the same-company
  guards fall back to `company&.id`, otherwise a lazily-built record silently
  skips the check.
- **`calendar_equipments`** — plural table, singular `CalendarEquipment` model
  and a `has_many :calendar_equipments` from `Company`. Matches Rails
  inflection; every table in this schema is plural.
- **Multi-selects on the booking form** — the first selection becomes the
  `lead` (or `primary`) and the rest take the fallback role. A single
  `has_many` join table rather than a `has_and_belongs_to_many`, because the
  role has to be stored.

---

*See also: `docs/RESOURCES.md` (table catalogue), `docs/ABAC.md` (policies),
`docs/SIDEBAR.md` (adding a group), `docs/API_ERROR_FORMAT.md` (error shape),
`docs/MEILISEARCH.md` (which this module deliberately does not use).*
