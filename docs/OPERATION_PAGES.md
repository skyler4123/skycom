# Adding an Operation Page

> **Audience:** AI coding agents and engineers adding a new full-screen Operation page to Skycom.
>
> **This guide is the executable version of `docs/OPERATIONS.md` §8.** It covers design intake, real-data rules, backend, web, mobile, translations, tests, documentation, and verification.
>
> **Companion docs:** `docs/OPERATIONS.md` (domain), `docs/MOBILE.md` (Hotwire Native shell), `docs/AGENT_PLAYBOOK.md` (working method), `docs/STYLING_GUIDELINES.md`, `docs/LANGUAGE.md`, `docs/TEST_PRIORITY.md`, `docs/FLAKY_TESTS.md`, `docs/CACHE.md`, `docs/MEILISEARCH.md`, `docs/API_ERROR_FORMAT.md`.

---

## Contents

1. [Quick path](#1-quick-path)
2. [What counts as a new Operation page](#2-what-counts-as-a-new-operation-page)
3. [Non-negotiables](#3-non-negotiables)
4. [Phase 0 — Understand the design before coding](#4-phase-0--understand-the-design-before-coding)
5. [Phase 1 — Register the operation type](#5-phase-1--register-the-operation-type)
6. [Phase 2 — Backend](#6-phase-2--backend)
7. [Phase 3 — Web frontend](#7-phase-3--web-frontend)
8. [Phase 4 — Mobile (Hotwire Native)](#8-phase-4--mobile-hotwire-native)
9. [Phase 5 — Tests](#9-phase-5--tests)
10. [Phase 6 — Documentation and cross-links](#10-phase-6--documentation-and-cross-links)
11. [Definition of done](#11-definition-of-done)
12. [Worked example: Housekeeping](#12-worked-example-housekeeping)
13. [Scaling to a new location owner](#13-scaling-to-a-new-location-owner)
14. [Anti-patterns](#14-anti-patterns)
15. [Final review checklist](#15-final-review-checklist)

---

## 1. Quick path

A new Operation page is not done until **all** of these are true:

- [ ] Enum value + `OPERATION_TYPES` entry + backfill plan.
- [ ] Web route, web policy, web controller, launch mapping.
- [ ] Console service with a real-data payload.
- [ ] Web Stimulus controller.
- [ ] Mobile route, mobile policy, mobile shell, mobile Operations list link.
- [ ] Translations for every new string.
- [ ] Exhaustive feature tests for web and mobile, including four viewport sizes.
- [ ] Docs and BE↔FE headers updated.
- [ ] `bin/rubocop`, `bin/check_colors --strict`, and `bin/brakeman` pass.
- [ ] Manual web + mobile smoke test with real data.

If any layer is missing, the page is a placeholder, not an Operation page.

---

## 2. What counts as a new Operation page

A new Operation page means:

- a new value in `Operation.operation_type`;
- a new entry in `OPERATION_TYPES`;
- a full-screen console at `/companies/:company_id/operations/<type>/:operation_id`;
- a matching mobile route at `/mobile/companies/:company_id/operations/<type>/:operation_id`;
- one shared Stimulus controller used by both web and mobile;
- real data from the database, related records, or a documented cache;
- feature tests that prove every visible block and number.

It does **not** mean:

- a new Operations index page or Operation config page;
- a modal;
- a placeholder page with “Coming soon”;
- a page that only looks right with demo data.

`Operation` records are seeded, not created from the UI. The UI edits config through `operation_configs`; the operation page itself is a console.

---

## 3. Non-negotiables

| Rule | Meaning |
|---|---|
| **Real data only** | Every number, name, date, status, chart, and signal comes from persisted records, a derived aggregate, or a documented cache. No sample arrays, random values, lorem ipsum, fake names, or hardcoded KPI numbers. |
| **Honest gaps** | If a metric is not modelled, return `available: false` and render “Not connected” or an empty state. Never render `0` unless `0` is the true value. Distinguish `0` from `null`. |
| **No dead controls** | Every visible button, link, tab, filter, and field either works or is disabled with a visible reason. Remove decorative controls that do nothing. |
| **One Stimulus controller** | Web and mobile mount the same `Companies_Operations_<Type>_ShowController`. Do not create a mobile-only operation controller. |
| **Two orientations** | Phone portrait, phone landscape, tablet portrait, and tablet landscape must all be usable. Tables scroll inside their card instead of widening the page. |
| **Semantic colors only** | Use `bg-card`, `text-foreground`, `text-muted-foreground`, `border-line`, `bg-primary`, `text-danger`, etc. No raw palette classes, no `dark:` on themed colors. |
| **Translate everything** | Every user-facing string goes through `translate()` and gets a Vietnamese entry in `app/javascript/controllers/helpers/dictionary.js`. |
| **Feature test is the proof** | A request spec passing is not proof. The feature test must assert the real rendered values for the real flow. |
| **Company and location scoped** | All reads start from `current_company` and the resolved appointment. Never trust a company/location id from the browser for authorization. |
| **No raw JSON or metadata in the UI** | Metadata is configuration. Give editable keys typed controls; never expose a JSON textarea or raw `<pre>` on a user-facing page. |
| **Errors use `{ errors: [...] }`** | Never `{ error: "..." }`. Use `:unprocessable_content`, `:forbidden`, `:not_found`, or `:internal_server_error`. |
| **Caching is deliberate** | A cache is allowed only with a documented key, TTL, and invalidation path. Never cache an authorization decision without keying it by employee/roles. |

---

## 4. Phase 0 — Understand the design before coding

### 4.1 Build the page inventory

The design team gives HTML + Tailwind. Do not start with the HTML. Start with a table that explains what every block means.

| # | Visible element | User question it answers | Mockup value | Real source (table / column / aggregate) | Decision | Test |
|---|---|---|---|---|---|---|
| 1 | KPI “Rooms Ready” | How many rooms can be used now? | `24` | `Facility` rows for this branch with no active `Event` link | use | exact count inside `[data-operation-block="kpis"]` |
| 2 | “Guest satisfaction 4.8” | How happy are guests? | `4.8` | no survey table | omit | assert the block is absent |
| 3 | “Footfall today” | How many people entered? | `1,248` | no sensor; real proxy is today’s orders | adapt | label “Order volume” + exact order count |
| 4 | “Live map” | Where is the work? | map | no geodata; real zones exist | adapt | zone list with exact occupancy |
| 5 | “Assign cleaner” | Who owns this room? | button | `Employee` + appointment/Event link | build write | click, assert DB change + toast + reload |

Every row must have a real source or an explicit “omit/adapt/build” decision. If a row cannot be tested deterministically, the block is not ready.

### 4.2 Questions to answer for every block

- What decision does this block help the operator make?
- Which real record changes when this number changes?
- What is the time window — today, this shift, this month, all time?
- Is it company-wide, branch-wide, warehouse-wide, or per-employee?
- What is the empty state?
- What is the loading state?
- What is the error state?
- Does it need a write action? If yes, what exactly persists, and what is the failure message?
- Can a known fixture produce an exact expected value?
- Is the design block decorative, redundant, or essential?

### 4.3 Adaptation decision tree

Use this order:

1. **Exact source exists** → use it.
2. **Derivable from real records** → compute it and document the formula (e.g. `quantity - pending`, paid orders today, rooms without an active Event).
3. **Replaceable by adjacent real data** → answer the same user question with a different real metric, and change the label honestly (e.g. footfall sensor unavailable → hourly order volume).
4. **Omit** → decorative, redundant, or impossible. Remove it. Do not leave a fake number or a dead card.
5. **Build the domain** → the block is central to the operator’s job and no source exists. Add the smallest real table/model/service, with migration, validations, seed/factory support, and tests. Do not fake it in the meantime.
6. **Honest placeholder** → only for a signal that is genuinely planned. Return `available: false`, show “Not connected” and the reason. This is a last resort, not a default.

Never: random values, hardcoded counts, placeholder names, fake chart series, invented dates, or a demo array left in the Stimulus controller.

### 4.4 Worked mapping example

Mockup block: “Live occupancy heatmap 87%”.

- Real source: `Facility` rows and active `Event` links.
- Decision: replace the heatmap with a real zone/room table and an exact ready/busy count.
- Why: no sensor/geodata, but the operator’s real question is “which rooms are free?”
- Test: create 3 rooms, link 1 to an active Event; assert “2 ready / 1 busy” and the exact room names.

Mockup block: “Average guest rating 4.8”.

- Real source: none.
- Decision: omit.
- Why: it is not central to the front-desk job and inventing it would be lying.
- Test: assert the rating block is absent.

### 4.5 Approval gate

Before writing code, present the completed page inventory and the out-of-scope list to the human partner. If the design requires a new domain table, stop and confirm. Do not silently invent a data model.

---

## 5. Phase 1 — Register the operation type

### 5.1 Enum

`app/models/operation.rb`:

```ruby
enum :operation_type, {
  pos: 100,
  booking: 200,
  inventory: 300,
  reception: 400,
  housekeeping: 500,
  store_manager: 700
}, prefix: true
```

Rules:

- Pick a new, unused integer. Never renumber existing values.
- The value is persisted; changing it later requires a data migration.

### 5.2 Catalog constant

`config/initializers/constants.rb`:

```ruby
OPERATION_TYPES = {
  pos: { label: "POS", code_prefix: "POS", appointment_scope: :branch }.freeze,
  booking: { label: "Booking", code_prefix: "BKG", appointment_scope: :branch }.freeze,
  inventory: { label: "Inventory", code_prefix: "INV", appointment_scope: :warehouse }.freeze,
  reception: { label: "Reception", code_prefix: "RCP", appointment_scope: :branch }.freeze,
  housekeeping: { label: "Housekeeping", code_prefix: "HSK", appointment_scope: :branch }.freeze,
  store_manager: { label: "Store Manager", code_prefix: "MGR", appointment_scope: :branch }.freeze
}.freeze
```

- `label` is the seeded display name.
- `code_prefix` is used for Operation and appointment codes.
- `appointment_scope` is a **seed-time hint only**: `:branch` creates `BranchOperationAppointment` rows; `:warehouse` creates `OperationWarehouseAppointment` rows.

### 5.3 Backfill existing companies

Adding the enum and constant does **not** create records for existing companies. Every company must receive:

- one `Operation` row for the new type;
- one active appointment for every matching branch or warehouse.

Use the existing idempotent service:

```ruby
Seed::OperationService.seed_defaults!(company: company)
```

Run it for every company in a data migration or rake task. If the team implements the planned `Seed::OperationService.sync_catalog!(company:)`, use that instead and add its spec. See `docs/TODO.md` “Operations — new operation_type backfill”.

Verification:

```ruby
company.operations.find_by!(operation_type: :housekeeping)
company.branches.find_each { |branch| branch.branch_operation_appointments.find_by!(operation: housekeeping_operation) }
```

Do not ship a new type without a backfill plan.

### 5.4 Location scope

Today the supported scopes are `:branch` and `:warehouse`. The page must not care which one it is:

- `Operations::AppointmentResolver` resolves the appointment.
- The controller receives `@appointment`.
- The serializer exposes `appointment.location`.

A future location owner is covered in §13. Do not special-case branch/warehouse inside the page controller or Stimulus controller.

### 5.5 Access roles

- Operation-level `metadata["roles"]` defines who can access the operation.
- Appointment-level roles may only narrow the Operation roles, never widen them.
- Empty Operation roles means every employee with `Operation` read can access it.
- The page relies on `Companies::Operations::BaseController#authorize_operation_roles!`.
- Do not add a new authorization model for a new page unless the page is a new resource.

---

## 6. Phase 2 — Backend

### 6.1 File map

| Layer | File |
|---|---|
| Enum | `app/models/operation.rb` |
| Catalog | `config/initializers/constants.rb` |
| Seed/backfill | `app/services/seed/operation_service.rb` |
| Web route | `config/routes.rb` |
| Web policy | `app/policies/companies/operations/<type>_policy.rb` |
| Web controller | `app/controllers/companies/operations/<type>_controller.rb` |
| Console service | `app/services/<domain>/console_service.rb` |
| Serializer | `app/services/operation_serializer.rb` (only if a new location shape) |
| Launch mapping | `app/services/operation_launch_service.rb` |
| Web Stimulus | `app/javascript/controllers/companies/operations/<type>/show_controller.js` |
| Mobile route | `config/routes.rb` |
| Mobile policy | `app/policies/mobile/companies/operations/<type>_policy.rb` |
| Mobile controller | `app/controllers/mobile/companies/operations/<type>_controller.rb` |
| Mobile list link | `app/views/mobile/companies/operations/index.html.erb` |
| Web feature spec | `spec/features/companies/operations/<type>_spec.rb` |
| Mobile feature spec | `spec/features/mobile/<type>_spec.rb` |
| Web request spec | `spec/requests/companies/operations/<type>_spec.rb` |
| Mobile request spec | `spec/requests/mobile/<type>_controller_spec.rb` |
| Model/seed specs | `spec/models/operation_spec.rb`, `spec/services/seed/operation_service_spec.rb` |
| Docs | `docs/OPERATIONS.md`, `docs/MOBILE.md`, `docs/MOBILE_FEATURE_MATRIX.md` |

### 6.2 Routes

`config/routes.rb` inside `resources :operations, only: [:index]`:

```ruby
collection do
  get "housekeeping/:operation_id", to: "operations/housekeeping#show", as: :housekeeping
  # write actions, if any:
  post "housekeeping/:operation_id/assign", to: "operations/housekeeping#assign", as: :housekeeping_assign
end
```

Mobile, inside `namespace :mobile`:

```ruby
get "operations/housekeeping/:operation_id", to: "operations/housekeeping#show", as: :housekeeping
```

Use the same `<type>` name everywhere: route helper, controller, policy, Stimulus identifier, mobile shell.

### 6.3 Web policy

`app/policies/companies/operations/housekeeping_policy.rb`:

```ruby
# frozen_string_literal: true

class Companies::Operations::HousekeepingPolicy < Companies::Operations::BasePolicy
end
```

`BasePolicy#show?` already checks `record.can?(:read, Operation)`. Add action methods only if you add write actions:

```ruby
def assign?
  show?
end
```

Do not widen access. The appointment role gate still runs in `BaseController`.

### 6.4 Controller

`app/controllers/companies/operations/housekeeping_controller.rb`:

```ruby
# frozen_string_literal: true

# Companies::Operations::HousekeepingController — the Housekeeping operation.
# Hydrates the resolved BranchOperationAppointment and exposes the live
# room/cleanliness payload built from Facilities, Events and Employees.
#
# Serves Stimulus: Companies_Operations_Housekeeping_ShowController
# Endpoints: GET /companies/:company_id/operations/housekeeping/:operation_id
# Docs: docs/OPERATIONS.md, docs/OPERATION_PAGES.md
class Companies::Operations::HousekeepingController < Companies::Operations::BaseController
  private

  def expected_operation_type
    :housekeeping
  end

  def operation_payload
    {
      coming_soon: false,
      housekeeping: Housekeeping::ConsoleService.call(
        company: current_company,
        appointment: @appointment
      )
    }
  end
end
```

Rules:

- Inherit `Companies::Operations::BaseController`.
- Define `expected_operation_type`.
- Override `operation_payload`; set `coming_soon: false`.
- Keep the controller thin. No aggregation, no loops over records, no business rules.
- For writes, add a service and a strong-params method; return `{ message: ... }` or `{ errors: [...] }`.

### 6.5 Console service

`app/services/housekeeping/console_service.rb`:

```ruby
# frozen_string_literal: true

# Housekeeping::ConsoleService — builds the live payload for the Housekeeping
# operation. Every value comes from persisted Facilities, Events and Employees.
# Docs: docs/OPERATIONS.md, docs/OPERATION_PAGES.md
class Housekeeping::ConsoleService
  def self.call(company:, appointment:, now: Time.current)
    new(company: company, appointment: appointment, now: now).call
  end

  def initialize(company:, appointment:, now:)
    @company = company
    @appointment = appointment
    @branch = appointment.branch
    @now = now
  end

  def call
    {
      location: location_payload,
      generated_at: now.iso8601,
      kpis: kpis_payload,
      rooms: rooms_payload,
      staff: staff_payload,
      alerts: alerts_payload
    }
  end

  private

  attr_reader :company, :appointment, :branch, :now

  def location_payload
    { id: branch.id, name: branch.name, code: branch.code, kind: "branch" }
  end

  def kpis_payload
    {
      rooms_ready: rooms_ready_count,
      rooms_busy: rooms_busy_count,
      rooms_dirty: rooms_dirty_count,
      staff_on_duty: staff_on_duty_count
    }
  end

  # ... real queries only, scoped to company + branch ...
end
```

Payload rules:

- `call(company:, appointment:, now:)` is the standard signature.
- Return a hash with stable keys. The Stimulus controller reads these keys directly.
- Include `generated_at` as ISO 8601.
- Include `location` with `id`, `name`, `code`, `kind`.
- Use `*_cents` for money; never floats for currency.
- Use fixed constants for query limits (e.g. `ROOM_LIMIT = 200`), never unbounded lists.
- Scope every query by `company` and the appointment’s location.
- Use `includes`/`preload` for associations serialized in the payload.
- Use SQL aggregates for counts where possible.
- Never use SQL `LIKE`/`ILIKE` for text search. Use Meilisearch (`ms_raw_search`) or exact ids.
- Empty collections return `[]`; missing signals return `nil` plus `available: false`.
- Do not read the current user from the service; authorization is the controller’s job.
- Do not hide a missing metric behind `0`.

### 6.6 Serializer

Reuse `OperationSerializer.operation` and `OperationSerializer.appointment`. Do not duplicate the operation/appointment shape in the new controller. If the page needs a new location kind, extend `OperationSerializer#location` once; do not fork it per page.

### 6.7 Launch mapping

`app/services/operation_launch_service.rb`:

```ruby
ROUTES = {
  "pos" => :pos_company_operations_path,
  "booking" => :booking_company_operations_path,
  "inventory" => :inventory_company_operations_path,
  "reception" => :reception_company_operations_path,
  "housekeeping" => :housekeeping_company_operations_path,
  "store_manager" => :store_manager_company_operations_path
}.freeze
```

Without this, the Operations index cannot launch the new page.

### 6.8 Write actions

If the design has a write action:

- Add a route and controller action.
- Add a service under the domain namespace (e.g. `Housekeeping::AssignService`).
- Use strong params: `params.require(:housekeeping).permit(...)`.
- Return `{ success: true, message: "..." }` or `{ success: false, errors: [...] }`.
- Render success with the server message; render failure with `status: :unprocessable_content`.
- Test success, validation failure, persistence after reload, and role denial.
- Do not put the write in the Stimulus controller or in a GET action.

### 6.9 Error contract

```ruby
render json: { errors: [ "Room is already assigned." ] }, status: :unprocessable_content
```

- Use `errors` plural array.
- Use `:unprocessable_content` for validation/business failures.
- Use `:forbidden` for authorization.
- Use `:not_found` for missing records.
- Use `:internal_server_error` for unexpected failures.
- The frontend catch block reads `error.errors?.join(", ")`.

### 6.10 Caching

- Operation index/config payloads use `Rails.sync_cache` and `OperationPageCacheConcern`.
- Console payloads are operational and should normally be live.
- If a heavy aggregate is cached, document the key, TTL, and invalidation. Include company/location/date in the key.
- Never cache an authorization decision without employee/roles in the key.
- Use the owning model/domain method for Kredis; never call `Kredis.redis` from a service/controller/job.
- See `docs/CACHE.md`.

---

## 7. Phase 3 — Web frontend

### 7.1 Naming and header

File: `app/javascript/controllers/companies/operations/housekeeping/show_controller.js`

Class: `Companies_Operations_Housekeeping_ShowController`

Header comments:

```javascript
// Housekeeping — the branch-level room/cleanliness console.
//
// Serves Stimulus: Companies_Operations_Housekeeping_ShowController
// Depends on BE: Companies::Operations::HousekeepingController#show
//               (operation + appointment + config + housekeeping payload)
// Endpoints: Helpers.housekeeping_company_operation_path
// Docs: docs/OPERATIONS.md, docs/OPERATION_PAGES.md
```

### 7.2 Lifecycle

```javascript
async connect() {
  this.companyId = this.element.dataset.companyId || pathParts[2]
  this.operationId = this.element.dataset.operationId || pathParts[5]
  this.branchId = new URLSearchParams(window.location.search).get("branch_id")

  try {
    await this.loadConsole()
    this.renderContent()
  } catch (error) {
    this.element.innerHTML = this.renderLoadError(error)
  }
}
```

Rules:

- Read ids from `dataset` first, then the URL.
- Read `branch_id` or `warehouse_id` from the query string.
- `loadConsole()` calls `Helpers.<type>_company_operation_path(...)` and stores the payload.
- `reloadConsole()` re-fetches and re-renders after writes; preserve scroll where useful.
- `renderContent()` composes small named methods (`renderHeader`, `renderKpis`, `renderRooms`, …). A 600-line `contentHTML()` is a warning sign.
- On error, render a readable error state. Never leave a blank page.

### 7.3 Rendering rules

- Escape every dynamic value with `this.escape(...)` or `Helpers.escapeHtml(...)`.
- Wrap every user-facing string in `translate(...)`.
- Add every new key to `app/javascript/controllers/helpers/dictionary.js` with a Vietnamese value.
- Use `tooltip(...)` for icon-only buttons.
- Use semantic tokens only.
- Every card, panel, table, dropdown, and group needs `border border-line` and/or `bg-card`/`bg-muted`.
- No `dark:` variants on themed colors.
- No raw palette classes.
- Prefer icons + text over icon-only actions.
- Empty states tell the user what to do next.
- Disabled controls say why they are disabled.
- No dead tabs or filters. If a tab has no data, show its empty state.
- No raw metadata/JSON blocks.

### 7.4 Responsive layout

Use the house pattern:

```html
<div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
  <div data-housekeeping-main-column class="lg:col-span-8 flex flex-col gap-4 min-w-0">
    ...
  </div>
  <div data-housekeeping-side-column class="lg:col-span-4 flex flex-col gap-4 min-w-0">
    ...
  </div>
</div>
```

- Phone portrait and landscape: single column, side below main.
- Tablet portrait: single column.
- Tablet landscape (`lg`, ≥1024px): side beside main.
- Tables use `overflow-x-auto` inside their card; never widen the page.
- Test at 390×844, 844×390, 768×1024, 1280×800.

### 7.5 Semantic class conversion

| Design HTML | Skycom class |
|---|---|
| `bg-white` | `bg-card` |
| `bg-slate-50` | `bg-background` or `bg-muted` |
| `text-slate-900` | `text-foreground` |
| `text-slate-500` | `text-muted-foreground` |
| `border-slate-200` | `border-line` |
| `bg-blue-600` | `bg-primary` |
| `text-white` on primary | `text-primary-foreground` |
| `bg-emerald-100 text-emerald-700` | `bg-success/10 text-success` |
| `bg-amber-100 text-amber-700` | `bg-warning/10 text-warning` |
| `bg-red-100 text-red-700` | `bg-danger/10 text-danger` |
| `dark:bg-slate-900` | remove; the token already switches |

Run `bin/check_colors --strict` before claiming the page is done.

### 7.6 Stimulus skeleton

```javascript
import { Controller } from "@hotwired/stimulus"

export default class Companies_Operations_Housekeeping_ShowController extends Controller {
  /** @type {any | null} */ operation = null
  /** @type {any | null} */ appointment = null
  /** @type {any} */ housekeeping = {}
  /** @type {string | null} */ companyId = null
  /** @type {string | null} */ operationId = null
  /** @type {string | null} */ branchId = null

  async connect() {
    const pathParts = window.location.pathname.split("/")
    this.companyId = this.element.dataset.companyId || pathParts[2]
    this.operationId = this.element.dataset.operationId || pathParts[5]
    this.branchId = new URLSearchParams(window.location.search).get("branch_id")

    try {
      await this.loadConsole()
      this.renderContent()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      this.element.innerHTML = `<div class="flex h-screen items-center justify-center text-lg font-semibold text-danger">${translate("Failed to load the housekeeping console.")}${detail ? ": " + this.escape(detail) : ""}</div>`
    }
  }

  async loadConsole() {
    const params = this.branchId ? { branch_id: this.branchId } : {}
    const response = await fetchJson(
      Helpers.housekeeping_company_operation_path(this.companyId, this.operationId, params)
    )
    this.operation = response.operation
    this.appointment = response.appointment
    this.housekeeping = response.housekeeping || {}
    return response
  }

  async reloadConsole() {
    const scrollY = window.scrollY
    await this.loadConsole()
    this.renderContent()
    window.scrollTo(0, scrollY)
  }

  renderContent() {
    this.element.innerHTML = `
      <div class="min-h-screen bg-background text-foreground">
        ${this.renderHeader()}
        <main class="mx-auto flex w-full max-w-[1440px] flex-col gap-4 px-4 py-4 lg:px-6">
          <div data-operation-block="kpis">${this.renderKpis()}</div>
          <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
            <div data-housekeeping-main-column class="lg:col-span-8 flex flex-col gap-4 min-w-0">
              <div data-operation-block="rooms">${this.renderRooms()}</div>
            </div>
            <div data-housekeeping-side-column class="lg:col-span-4 flex flex-col gap-4 min-w-0">
              <div data-operation-block="staff">${this.renderStaff()}</div>
              <div data-operation-block="alerts">${this.renderAlerts()}</div>
            </div>
          </div>
        </main>
      </div>
    `
  }

  // ... small render methods ...
}
```

Add `data-operation-block="<key>"` to every major block. Tests use these selectors to assert exact values without relying on layout or order.

---

## 8. Phase 4 — Mobile (Hotwire Native)

### 8.1 Route

`config/routes.rb`:

```ruby
get "operations/housekeeping/:operation_id", to: "operations/housekeeping#show", as: :housekeeping
```

### 8.2 Mobile policy

`app/policies/mobile/companies/operations/housekeeping_policy.rb`:

```ruby
# frozen_string_literal: true

# Housekeeping runs inside an Operation, so operators only need Operation read.
class Mobile::Companies::Operations::HousekeepingPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Operation)
  end
end
```

### 8.3 Mobile controller and shell

`app/controllers/mobile/companies/operations/housekeeping_controller.rb`:

```ruby
# frozen_string_literal: true

# Mobile::Companies::Operations::HousekeepingController — Shell-First
# housekeeping console for the mobile/tablet app. The response is only a mount
# point; Companies_Operations_Housekeeping_ShowController hydrates the payload
# from the web JSON endpoint.
# Serves Stimulus: Companies_Operations_Housekeeping_ShowController (hydrate)
# Endpoints: GET /mobile/companies/:company_id/operations/housekeeping/:operation_id
# Docs: docs/MOBILE.md, docs/OPERATION_PAGES.md
class Mobile::Companies::Operations::HousekeepingController < Mobile::Companies::BaseController
  before_action :set_operation
  before_action :set_appointment
  before_action :authorize_operation!

  def show
    render html: shell_html.html_safe, layout: true
  end

  private

  def set_operation
    @operation = current_company.operations.find_by!(
      id: params[:operation_id],
      operation_type: :housekeeping
    )
  end

  def set_appointment
    @appointment = Operations::AppointmentResolver.call(
      company: current_company,
      operation: @operation,
      employee: @employee,
      branch_id: params[:branch_id]
    )

    return if @appointment&.workflow_status_active?

    redirect_to mobile_company_operations_path(current_company),
      alert: "No active operation found for this location."
  end

  def authorize_operation!
    return if @operation.accessible_by?(@employee, appointment: @appointment)

    redirect_to mobile_company_operations_path(current_company),
      alert: "You do not have access to this operation."
  end

  def shell_html
    <<~HTML
      <div class="min-h-dvh bg-background"
        data-controller="companies--operations--housekeeping--show darkmode"
        data-company-id="#{@company.id}"
        data-operation-id="#{@operation.id}"
        data-user-name="#{ERB::Util.html_escape(@employee.name)}"
        data-user-role="#{ERB::Util.html_escape(@employee.roles.first&.name || "Employee")}"></div>
    HTML
  end
end
```

Rules:

- The mobile controller is a mount point only. It does not build the page payload.
- The `data-controller` must be the shared web controller.
- The mobile shell must include `darkmode`.
- Warehouse-scoped operations pass `warehouse_id` instead of `branch_id` to the resolver; follow the existing Inventory controller.
- Do not add a mobile-specific Stimulus controller.

### 8.4 Mobile Operations list link

`app/views/mobile/companies/operations/index.html.erb` currently has a hardcoded branch/warehouse `if/elsif`. Add the new type in the correct branch:

```erb
<% if operation.operation_type == "housekeeping" %>
  <%= link_to mobile_company_housekeeping_path(@company, operation, branch_id: appointment.branch_id),
    class: "..." do %>
    <span class="material-symbols-outlined text-xl">cleaning_services</span>
    Open Housekeeping
  <% end %>
<% end %>
```

Rules:

- Branch-scoped types go in the `BranchOperationAppointment` block.
- Warehouse-scoped types go in the `OperationWarehouseAppointment` block.
- The link must carry the location id from the appointment.
- The label is “Open <Operation label>”.
- If the list is not updated, the page is unreachable from mobile.

The current if/elsif is a known scaling weak point. A future refactor should move launch-path mapping into a shared service, but do not leave the current type unwired.

### 8.5 Same controller, different shell

Web and mobile must both end up mounting:

```html
data-controller="companies--operations--housekeeping--show"
```

- Web does it through `app/views/layouts/application.html.erb` and `stimulus_controller`.
- Mobile does it through `shell_html`.
- If the controller name changes, both break. Keep the name stable.

---

## 9. Phase 5 — Tests

### 9.1 Feature tests are the proof

- Feature tests are the primary proof.
- Model tests protect invariants.
- Request specs cover JSON contracts and edge cases.
- A passing request spec never excuses a failing feature test.
- Run in priority order: feature → model → request. Stop on the first failure.

### 9.2 Page inventory becomes the test matrix

Every row in the Phase 0 inventory becomes a test. Use `data-operation-block="<key>"` wrappers and exact values:

```ruby
scenario "renders every KPI from real records" do
  visit housekeeping_path
  kpis = find('[data-operation-block="kpis"]', wait: 10)

  within(kpis) do
    expect(page).to have_content("Rooms Ready")
    expect(page).to have_content("2")
    expect(page).to have_content("Rooms Busy")
    expect(page).to have_content("1")
    expect(page).to have_content("Staff On Duty")
    expect(page).to have_content("3")
  end
end
```

Do not stop at labels. Assert the exact value that the fixture must produce.

### 9.3 Required scenarios

| Area | Required test |
|---|---|
| Page load | Page renders the console title and every block from real fixtures |
| Every KPI | Exact value inside the block, plus label |
| Every list/table | Exact row names, codes, statuses, and numeric columns |
| Every chart/bar | Exact counts or accessible summary; no pixel assertions |
| Every signal | Connected/available state, or honest “Not connected” with no fake number |
| Empty state | A block with no records shows its empty message |
| Search/filter | Filter narrows rows; clearing restores; no matches state |
| Write action | Success toast from server, DB change, reload shows new state |
| Write failure | Validation error toast from server, no DB change |
| Inactive appointment | Redirect/error, page not rendered |
| Unauthorized role | Forbidden/redirect, page not rendered |
| Cross-company | 404, no data leak |
| Mobile list | “Open <Type>” appears only for the right type and location, and navigates |
| Mobile orientations | 390×844, 844×390, 768×1024, 1280×800 layout assertions |
| Time window | `travel_to` proves today/yesterday/shift boundaries |
| Currency | Exact formatted money; no float drift |
| Cache | If cached, invalidation test proves fresh data after a change |

### 9.4 Test data rules

- Create only the records the page reads, using `Seed::*Service` or factories.
- Use `let!` when the page needs the record before `visit`.
- Use `travel_to` for today/yesterday/shift tests.
- Never use `sleep`. Use `have_content(..., wait: 10)` or `have_selector(..., wait: 10)`.
- Scope selectors to the block or row.
- Reset the browser window in `ensure`.
- Sign in as an owner for content tests; use a separate employee/role setup for permission tests.
- Assert the DB change, not just the toast.
- Assert the server message, not a generic frontend fallback.

### 9.5 Model and request specs

Model:

- enum value exists and is unique per company;
- `OPERATION_TYPES` entry exists;
- `seed_defaults!` creates the Operation and appointments for existing locations;
- backfill is idempotent;
- appointment uniqueness/company scoping;
- role narrowing rules.

Request:

- JSON 200 with exact payload values;
- `coming_soon: false`;
- inactive appointment → 422 with `errors`;
- non-matching operation type → 404;
- cross-company → 404;
- write success/failure contracts;
- no N+1-sensitive payload omissions (assert associations are present).

### 9.6 Feature spec skeleton

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Companies::Operations::Housekeeping", type: :feature, js: true do
  let(:company) { create(:company) }
  let(:owner) { company.user }
  let(:branch) { create(:branch, company: company, name: "Harbor Hotel") }
  let(:operation) { create(:operation, company: company, branch: branch, operation_type: :housekeeping) }
  let(:housekeeping_path) do
    "/companies/#{company.id}/operations/housekeeping/#{operation.id}?branch_id=#{branch.id}"
  end

  before { sign_in(owner) }

  scenario "renders every KPI from real records" do
    # create exactly the records the KPI block reads
    visit housekeeping_path

    within(find('[data-operation-block="kpis"]', wait: 10)) do
      expect(page).to have_content("Rooms Ready")
      expect(page).to have_content("2")
    end
  end

  scenario "shows the empty state when there are no rooms" do
    visit housekeeping_path

    within(find('[data-operation-block="rooms"]', wait: 10)) do
      expect(page).to have_content("No rooms match this view.")
    end
  end

  scenario "assigns a room and persists the change" do
    # create room + staff, visit, click Assign, assert toast + DB + reload
  end
end
```

Mobile skeleton:

```ruby
RSpec.feature "Mobile Housekeeping", type: :feature, js: true do
  # ...
  scenario "opens from the mobile operations list" do
    visit mobile_company_operations_path(company)
    click_link "Open Housekeeping"

    expect(page).to have_current_path(
      mobile_company_housekeeping_path(company, operation, branch_id: branch.id),
      wait: 10
    )
    expect(page).to have_content("Housekeeping Operations Console", wait: 10)
  end

  { "phone portrait" => [ 390, 844 ],
    "phone landscape" => [ 844, 390 ],
    "tablet portrait" => [ 768, 1024 ],
    "tablet landscape" => [ 1280, 800 ] }.each do |label, (width, height)|
    scenario "keeps the layout usable on #{label}" do
      page.driver.browser.manage.window.resize_to(width, height)
      visit housekeeping_path
      expect(page).to have_content("Housekeeping Operations Console", wait: 10)
      # assert main/side position for the breakpoint
    ensure
      page.driver.browser.manage.window.resize_to(1400, 900)
    end
  end
end
```

### 9.7 Verification commands

```bash
bundle exec parallel_rspec -n 14 spec/features/companies/operations/housekeeping_spec.rb
bundle exec parallel_rspec -n 14 spec/features/mobile/housekeeping_spec.rb
bundle exec parallel_rspec -n 14 spec/models/operation_spec.rb spec/services/seed/operation_service_spec.rb
bundle exec parallel_rspec -n 14 spec/requests/companies/operations/housekeeping_spec.rb
bundle exec parallel_rspec -n 14 spec/requests/mobile/housekeeping_controller_spec.rb
```

Then:

```bash
bin/rubocop
bin/check_colors --strict
bin/brakeman
```

Never declare done from request/model specs alone.

---

## 10. Phase 6 — Documentation and cross-links

Update:

- `docs/OPERATIONS.md` — catalog table, routes table, frontend table, and link this guide from §8.
- `docs/MOBILE.md` — route table, data contract, flow.
- `docs/MOBILE_FEATURE_MATRIX.md` — if mobile parity/status changes.
- `AGENTS.md` doc map — add this guide.
- BE↔FE headers — both the Rails controller (`Serves Stimulus:`) and the Stimulus controller (`Depends on BE:` / `Endpoints:`).
- `docs/MODEL_CALLBACKS.md` — if callbacks were added or changed.
- `config/initializers/constants.rb` — no inline constants.
- `app/javascript/controllers/helpers/dictionary.js` — every new string.
- `docs/TODO.md` — if backfill remains outstanding.

Remove stale comments such as “this first pass ships demo data” when the page is real. A comment that says demo data exists is a red flag in review.

---

## 11. Definition of done

- [ ] Enum value added; existing values unchanged.
- [ ] `OPERATION_TYPES` entry added with label, prefix, and scope.
- [ ] Existing companies backfilled with Operation + appointments.
- [ ] Web route, policy, controller, launch mapping added.
- [ ] Mobile route, policy, controller, shell added; mobile list link works.
- [ ] Console service returns real data only; no sample/demo/hardcoded values.
- [ ] Every visible block, number, row, chart, signal, and action is in the page inventory.
- [ ] Every inventory row has a feature test with an exact expected value.
- [ ] Empty, error, disabled, inactive, unauthorized, and cross-company states are tested.
- [ ] Write actions persist and reload; failure contract tested.
- [ ] Web and mobile share one Stimulus controller.
- [ ] Four viewport sizes tested; tables scroll inside cards.
- [ ] Semantic tokens only; `bin/check_colors --strict` passes.
- [ ] Every user-facing string has `translate()` + Vietnamese dictionary entry.
- [ ] No raw JSON/metadata UI.
- [ ] Docs and BE↔FE headers updated.
- [ ] `bin/rubocop`, `bin/brakeman`, and the feature/model/request specs pass.
- [ ] Manual smoke test on web + mobile with real data.
- [ ] No dead controls, dead tabs, or “Coming soon” placeholders left behind.

---

## 12. Worked example: Housekeeping

> Illustrative only. This is not a request to build Housekeeping.

Assume a branch-scoped operation that answers: “Which rooms are ready, dirty, or occupied, and who is cleaning them?”

| Mockup block | Real source | Decision | Test |
|---|---|---|---|
| Rooms ready / busy / dirty | `Facility` + active `Event` links | use | exact counts |
| Room list with status | `Facility` + `Event` | use | exact room names and statuses |
| Cleaner roster | `Employee` active at branch | use | exact names/roles |
| “Assign cleaner” | new `HousekeepingAssignment` or Event metadata | build write | click, DB change, toast |
| Guest rating 4.8 | none | omit | block absent |
| Live heatmap | no geodata | adapt to zone table | exact zone counts |

Files:

- `app/models/operation.rb`
- `config/initializers/constants.rb`
- `app/services/seed/operation_service.rb` (backfill invocation)
- `config/routes.rb`
- `app/policies/companies/operations/housekeeping_policy.rb`
- `app/controllers/companies/operations/housekeeping_controller.rb`
- `app/services/housekeeping/console_service.rb`
- `app/services/operation_launch_service.rb`
- `app/javascript/controllers/companies/operations/housekeeping/show_controller.js`
- `app/policies/mobile/companies/operations/housekeeping_policy.rb`
- `app/controllers/mobile/companies/operations/housekeeping_controller.rb`
- `app/views/mobile/companies/operations/index.html.erb`
- specs as listed in §6.1
- docs as listed in §10

The page is not done until the files above exist and the test matrix passes.

---

## 13. Scaling to a new location owner

Today an Operation is appointed to a Branch or a Warehouse. To add a future location type:

1. Create an atomic appointment table/model, e.g. `<Location>OperationAppointment`, with:
   - `company_id`, `<location>_id`, `operation_id`;
   - unique index on the triplet;
   - `metadata` default `{}`;
   - `lifecycle_status` and `workflow_status`;
   - company/location/operation validations;
   - `OperationPageCacheConcern` and `SetDefaultCompanyConcern` where applicable.
2. Include `OperationAppointmentConcern` in the location model and declare:
   ```ruby
   operation_appointments_for <Location>OperationAppointment, scope: :<scope>, foreign_key: :<location>
   ```
3. Add `:<scope>` to the relevant `OPERATION_TYPES` entries (or a new scope).
4. Extend `Seed::OperationService.ensure_appointments_for!` usage for the new location.
5. Extend `Operations::AppointmentResolver` with a new `when :<scope>` branch.
6. Extend `OperationLaunchService` to pass the new location param.
7. Extend `OperationSerializer#location` to serialize the new location shape.
8. Add the mobile operations list link for the new appointment class.
9. Add feature tests for launch, resolution, authorization, and mobile list.
10. Backfill existing companies.

Keep the page controller and Stimulus controller location-agnostic. The resolver and serializer own location differences.

Do not introduce a polymorphic `OperationAppointment` unless the team explicitly decides to replace the atomic pairwise pattern. The current house pattern is one appointment table per location type.

---

## 14. Anti-patterns

| Bad | Good |
|---|---|
| Add the enum + a “Coming soon” placeholder | Wire all layers, or do not ship the type |
| Hardcode KPI numbers to match the mockup | Compute from real records and test exact values |
| Render `0` for an unmodelled signal | `available: false` + “Not connected” |
| Create a mobile-only Stimulus controller | Mount the shared web controller |
| Duplicate branch/warehouse logic in the page | Use the appointment resolver/serializer |
| Put business logic in the controller | Use a `ConsoleService` / write service |
| Use SQL `LIKE` for text search | Meilisearch (`ms_raw_search`) or exact ids |
| Show raw metadata/JSON | Typed inputs or omit |
| Use `bg-white` / `text-slate-500` | Semantic tokens |
| Add `dark:` on themed colors | The token already switches |
| Write tests that only assert labels | Assert exact values from fixtures |
| Use `sleep` in feature tests | `have_content(..., wait: 10)` |
| Claim done from request specs | Run the feature tests first |
| Leave a dead tab/button | Implement, disable with a reason, or remove |
| Cache authorization without employee key | Key by employee/roles or do not cache |
| Add only a policy + placeholder JS (the current `kitchen`/`housekeeping` orphan state) | Treat all layers as one deliverable |

---

## 15. Final review checklist

- [ ] The page inventory is complete and approved.
- [ ] Every inventory row has a real source or an explicit omit/adapt/build decision.
- [ ] No sample/demo/random data remains.
- [ ] Enum, constant, backfill, route, policy, controller, service, serializer, launch mapping are all present.
- [ ] Web and mobile mount the same Stimulus controller.
- [ ] Mobile list links to the page with the correct location id.
- [ ] Four viewports pass.
- [ ] Every visible number/block/action has an exact feature assertion.
- [ ] Empty/error/disabled/inactive/unauthorized/cross-company states pass.
- [ ] Write actions persist and reload.
- [ ] `bin/check_colors --strict`, `bin/rubocop`, `bin/brakeman` pass.
- [ ] Feature → model → request specs pass.
- [ ] Docs and BE↔FE headers are current.
- [ ] Manual web + mobile smoke test passes.
