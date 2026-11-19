# Business Analysis documentation — Implementation Plan

> **For agentic workers:** Execute inline in this session (AGENTS.md: no
> subagents unless the user asks). Steps use `- [ ]` checkboxes for tracking.
> Do not modify application code — this plan produces documentation only.

**Goal:** Give a business analyst — a person, a team, or an AI reading cold — a
complete, honest picture of what each Operation page and dashboard actually does
today, so they can decide what to finish, what to cut, and what to build next.

**Architecture:** Ten markdown documents under `docs/business_analysis/`. One
shared `README.md` (legend, glossary, index), one app-wide overview, and one
document per shippable surface. Every page doc follows the same nine-section
contract, marks every control with a status badge, and traces every number to a
real source or labels it fabricated.

**Tech stack:** Markdown only. Audit sources are the existing Stimulus
controllers (`app/javascript/controllers/companies/...`), the console services
(`app/services/...`) and the Rails controllers (`app/controllers/companies/...`).

**Spec:** §2–§4 of this file (design approved 2026-11-19). No separate spec file.

---

## Global constraints

- **Docs only.** No changes to application code, tests, seeds, or config.
- **Business language.** File paths, method names, and table names appear only
  in §9 (Engineering appendix). Sections 1–8 must be readable by someone who has
  never opened the codebase.
- **English.** Glossary terms stay in English; no Vietnamese in these docs.
- **No screenshots.** §3 is a text screen map.
- **Stable IDs.** Controls: `<PREFIX>-<nn>` (e.g. `SM-03`). Decisions:
  `<PREFIX>-D<n>` (e.g. `POS-D2`). Never renumber an existing ID; retire it with
  a strikethrough if the control disappears.
- **Badges are fixed** (§3.2). Do not invent a new badge without adding it to the
  legend in `README.md` first.
- **Every claim has evidence.** Either a code reference in §9 or a named test.
  "Verified" without evidence is not allowed.
- **No TBD.** A gap with no options is not a gap; it is unfinished work.
- **Link, never duplicate.** `docs/TODO.md` owns the app-wide missing-feature
  list; `docs/MOBILE_FEATURE_MATRIX.md` owns mobile parity. Reference them.
- **Dates.** Every page doc carries `Last audited: YYYY-MM-DD` and a one-line
  audit scope ("frontend + service + controller, seed data not exercised").
- **Length.** Target 300–600 lines per page doc. Longer means the doc is
  transcribing code rather than explaining business behavior.

## Review focus

The five failure modes most likely to make these docs hurt instead of help, and
where each is pinned down:

| # | Failure mode | What a reader would wrongly conclude | Pinned by |
|---|---|---|---|
| 1 | A control looks wired but its handler only toasts | "This works" — then the user clicks it in a demo | §4 procedure B + every console Task Step 3 (read the handler body) |
| 2 | A number with no record behind it reads as real | "Our utilisation is 84%" — a fabricated metric ships | §4 procedure C + every console Task Step 4 (trace to records) |
| 3 | The empty state is blank or broken for a new company | "It works" — the first paying customer sees a dead page | §3 template "empty state" + Task 9 Step 5 (new-company blocks) |
| 4 | A control exists in code but is never rendered (hidden behind a tab that cannot open) | "Users can do this" — they cannot | §4 procedure B + inventory row marked ⛔ or ✕unreachable |
| 5 | A write looks successful but does not persist, or bypasses a role gate | "Safe to give to staff" — data is lost or access is too wide | §4 procedure D (writes + gates) + Tasks 3–5 §7 |

Doc drift after a code change is covered by the living-doc hooks in Task 11.

---

## 1. Current state

### 1.1 Surfaces in scope

| Doc | Route | Frontend | Backend | Writes |
|---|---|---|---|---|
| POS | `/companies/:company_id/operations/pos/:operation_id` | `companies/operations/pos/show_controller.js` (1,034) | `Companies::Operations::PosController` (payload inline, no console service) | checkout, pay, pay-cancel via OrderProcessing V1 |
| Booking | `.../operations/booking/:operation_id` | `.../booking/show_controller.js` (1,015) | `Booking::ConsoleService`, `Companies::Operations::BookingController` | create reservation |
| Reception | `.../operations/reception/:operation_id` | `.../reception/show_controller.js` (1,211) | `Reception::ConsoleService`, `ReceptionController` | check-in, advance, notify host, parcel notify/pickup |
| Inventory | `.../operations/inventory/:operation_id` | `.../inventory/show_controller.js` (875) | `Inventory::ConsoleService`, `InventoryController` | none (read-only) |
| Store Manager | `.../operations/store_manager/:operation_id` | `.../store_manager/show_controller.js` (955) | `StoreManager::ConsoleService`, `StoreManagerController` | none (read-only) |
| Operations landing | `/companies/:company_id/operations` + `operation_configs` + appointment show/edit | `companies/operations/index_controller.js` (162), `operation_configs/*`, `operation_appointments/*` | `OperationsController`, `OperationConfigsController`, `Branch/OperationWarehouseAppointmentsController` | activate/deactivate, edit metadata/roles |
| Dashboard | `/companies/:company_id/dashboards` | `companies/dashboards/index_controller.js` (677), `show_controller.js` (136, config) | `DashboardsController`, `Dashboards::OverviewService` | dashboard block config |
| Analytics | `/companies/:company_id/analytics` | `companies/analytics/index_controller.js` (627) | `AnalyticsController`, `Analytics::DashboardService` | none |

`housekeeping/show_controller.js` and `kitchen/show_controller.js` are three-line
stubs for operation types absent from `OPERATION_TYPES`. They are unreachable.
Decide in `01-operations-landing.md` whether to delete them.

### 1.2 Seed findings (verify, then include)

These were found during design recon. Each must be re-checked against the code
before it lands in a doc; line numbers drift.

| Page | Finding | Evidence |
|---|---|---|
| Store Manager | 6 of 7 header tabs are dead — clicking toasts "*X* is coming soon." | `show_controller.js:850-853` (`selectNav`) |
| Store Manager | "Daily Shift Report" quick action toasts "not connected yet" | `show_controller.js:919` |
| Store Manager | "Diagnostics" toasts "not connected yet" | `show_controller.js:932` |
| Store Manager | Register names are invented from row index ("Main Counter", "Express Kiosk", "Pickup Desk") | `store_manager/console_service.rb:368-376` |
| Store Manager | Shift label derives from the browser's local hour, not the branch clock | `show_controller.js:123-127` |
| Store Manager | "Store Open • Fully Operational" is static text | `show_controller.js:274` |
| Inventory | `global_utilization` returns a hardcoded `84` when there are no zones | `inventory/console_service.rb:254-257` |
| Inventory | Zone names are synthesized as `"Zone #A: <name>"` from list index | `inventory/console_service.rb:246` |
| Inventory | Audit card returns `available: false` (honest gap) | `inventory/console_service.rb:264` |
| POS | Every Service is listed at price `0` | `operations/pos_controller.rb:82` |
| POS | Catalog silently capped at 50 products and 50 services | `operations/pos_controller.rb:58,75` |
| POS | Stock is read from one warehouse only (`find_by`) | `operations/pos_controller.rb:60` |

### 1.3 Why this matters

A control that toasts "coming soon" and a number that returns `84` on empty data
are both visible to a paying user. The docs must separate *honest gaps* (the UI
says "Not connected") from *lies* (the UI shows a plausible number). That
distinction drives the ship-readiness verdict on every page.

---

## 2. Target doc set

```
docs/business_analysis/
  README.md                  index · legend · glossary · audit log
  00-app-overview.md         APP
  01-operations-landing.md   OPS
  02-pos.md                  POS
  03-booking.md              BKG
  04-reception.md            RCP
  05-inventory.md            INV
  06-store-manager.md        SM
  07-dashboard.md            DSH
  08-analytics.md            ANL
```

Build order: README → **Store Manager sample** → human review gate → four
remaining consoles → landing → app overview → dashboard → analytics →
integration.

---

## 3. Page doc contract

### 3.1 Template

```markdown
# <Page name>

> **Last audited:** YYYY-MM-DD · **Audit scope:** frontend + service + controller
> **Ship readiness:** 🟢 shippable · 🟠 shippable with gaps · 🔴 not shippable
> **Who this is for:** <operator role> · **Mobile:** <same console / not mounted>
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md)

## 1. What this page is for
<One paragraph: the job, when in the day it is used, what "done" looks like.>

## 2. Who uses it
<The person and their goal. What they can do here. What they must do elsewhere.>

## 3. The screen, in words
<Layout map: header, KPIs, main table, cards, tabs. Then states: empty, loading,
error. Include what the user sees when the page has no data.>

## 4. Control inventory
| ID | Area | Control | What it does today | Status | If shipped as-is |
|---|---|---|---|---|---|
| SM-01 | ... | ... | ... | ✅ | ... |

## 5. Numbers on screen
| Metric as labelled | What it claims | Real source | Verdict |
|---|---|---|---|
| ... | ... | ... | ✅ real / 🟡 approximate / 🔢 fabricated / 💤 not connected |

## 6. Gaps by user job
<For each gap: the user question it blocks, then options —
"smallest real version" / "cut it" / "build the domain" —
with effort S/M/L and dependencies.>

## 7. Decisions for the BA
**SM-D1 — <decision>**
- Option A: ... (consequence)
- Option B: ... (consequence)
- Recommendation (optional): ...

## 8. Safe demo path
<Numbered click path that shows only real behaviour. Then "Do not demo".>

## 9. Engineering appendix
<Endpoints, tables, service methods, tests, file paths. Engineers only.>
```

### 3.2 Status legend

| Badge | Meaning | Test for it |
|---|---|---|
| ✅ | Works end to end | A click persists or computes from real records |
| 🟡 | Partial | Works but limited (read-only, capped, missing a filter) |
| 🗑️ | Placeholder toast | Clicking says "coming soon" / "not connected yet" |
| 💤 | Honest gap | Block renders "Not connected" and explains no source exists |
| ⛔ | Dead | Visible, clickable, and does nothing at all |
| 🚧 | Missing | The job needs it; nothing is on screen |
| 🔢 | Fabricated number | Displays a plausible value not derived from records |

Ship readiness: 🔴 if any 🔢 or ⛔ is visible; 🟠 if only 🗑️/💤/🚧 remain;
🟢 if neither.

### 3.3 README contents

1. What this folder is for and the three readers (person / team / AI).
2. How to use it: read README → pick a page → read §1–§8 → decide on §7.
3. Status legend (§3.2) plus a mapping line to the mobile matrix badges
   (✅=✅, 🟡=🟡, 🚧=🚧, 💤=💤, ❓=⛔).
4. Page index table: doc · surface · ship readiness · control count · gaps ·
   last audited.
5. Glossary of domain terms (see §4, step A).
6. Audit log: date, scope, what changed.
7. Rules for keeping docs current.

---

## 4. Shared audit procedure (run for every page doc)

**A. Read the page end to end.** Frontend controller, backend controller,
service (if any), and the route. Read the header comment first — it names the
endpoints and the Stimulus consumer.

**B. Enumerate controls mechanically, then correct by hand.**

```bash
P=app/javascript/controllers/companies/operations/store_manager/show_controller.js
grep -n '<button\|<a href\|<input\|<select\|<textarea' "$P"
grep -n 'data-action=' "$P"
grep -o 'translate("[^"]*")' "$P" | sort -u
```

Every `<button>` must end up in the inventory as wired, submit, or dead. Expect
false positives: header comments containing `#show`, and buttons wired through a
helper attribute such as `${Helpers.darkmodeTrigger()}`.

**C. Trace every number.** List each rendered figure. For each, find the payload
key, then the method that produces it, then the records it reads. If it reads
nothing — a literal, an index, a `Time.current` fallback — it is 🔢 and must be
labelled.

```bash
S=app/services/store_manager/console_service.rb
grep -n '^  def ' "$S"
```

**D. Note writes and their gates.** For every write: which endpoint, what it
persists, what the success message is, what happens on failure.

**E. Cross-check the mobile surface.** If `docs/MOBILE_FEATURE_MATRIX.md` lists
the page, make sure the two docs do not contradict each other. Note differences
in §9 only.

**F. Write §1–§3, then §4–§5, then §6–§7, then §8–§9.** Gaps come from user
jobs, not from missing code.

**G. Verify before committing.** Re-read the doc against the code: every badge
defensible, every number traced, every button present.

---

## 5. Tasks

### Task 1: README, legend, glossary, index

**Files:**
- Create: `docs/business_analysis/README.md`

**Produces:** the legend, the glossary, and the index table that every later
task appends to.

- [x] **Step 1: Create the folder and README** with the seven sections in §3.3.
- [x] **Step 2: Write the glossary.** Cover at minimum: Company, Branch,
  Warehouse, Employee, Customer, Operation, Operation type, Branch/Warehouse
  appointment, Operation config, Workflow status, Lifecycle status, Category,
  Dynamic property, Dynamic table, Policy/Role/Permission, Event, Facility,
  Order, Stock, Stock pending, Invoice, Purchase, Discount, Company credit,
  Ticket, KPI, Exam, Attendance month/day, Payroll, Shift template, Scheduled
  shift, Import, Company migration, Notification, Document/Folder.
  One sentence each, business meaning first.
- [x] **Step 3: Seed the index table** with all ten rows, verdict column empty
  except for pages already audited.
- [x] **Step 4: Add the audit log** with today's date and "initial set".
- [x] **Step 5: Verify** every glossary term is used somewhere in the app (grep
  the sidebar or routes) and that no term has two names.
- [x] **Step 6: Commit** `docs(ba): add business analysis index, legend and glossary`.

---

### Task 2: Store Manager sample (review gate)

**Files:**
- Create: `docs/business_analysis/06-store-manager.md`
- Modify: `docs/business_analysis/README.md` (index row)

**Reads:** `app/javascript/controllers/companies/operations/store_manager/show_controller.js`,
`app/services/store_manager/console_service.rb`,
`app/controllers/companies/operations/store_manager_controller.rb`,
`app/controllers/companies/operations/base_controller.rb`, routes for
`store_manager`.

**Produces:** the reference document every other console doc is modelled on.

- [x] **Step 1: Run the shared procedure (§4) steps A–E.**
- [x] **Step 2: Write §1–§3.** Name the operator (store manager on a shift), the
  job, and what the seven header tabs promise versus what exists.
- [x] **Step 3: Write §4.** Include the six dead tabs, both placeholder quick
  actions, and the dark-mode toggle (wired). Record the control count.
- [x] **Step 4: Write §5.** Trace gross sales, active POS counters, orders to
  fulfill, shelf alerts, staff on duty, footfall, hourly volume, registers.
  Label invented register names and the static "Fully Operational" badge.
- [x] **Step 5: Write §6–§7.** At minimum decide: keep or remove the six tabs;
  build or cut the shift report; replace index-based register names; branch
  clock vs browser clock.
- [x] **Step 6: Write §8–§9.** Safe demo path = overview only, no header tabs,
  no shift report.
- [x] **Step 7: Verify** with §4 step G and the counts in §1.1.
- [x] **Step 8: Update the README index row** with verdict and counts.
- [x] **Step 9: Commit** `docs(ba): add store manager console analysis`.

> **Checkpoint:** show the user the sample and ask whether the format is right
> before writing the other four consoles. Adjust the template here, not later.

---

### Task 3: POS

**Files:** Create `docs/business_analysis/02-pos.md`; update README index.

**Reads:** `operations/pos/show_controller.js`,
`app/controllers/companies/operations/pos_controller.rb`,
OrderProcessing V1 controller/routes, `docs/ORDER_PROCESSING_V1.md`,
`docs/PAYMENT_METHODS.md`.

- [x] **Step 1:** Run procedure A–E.
- [x] **Step 2:** §1–§3 — cashier flow, tabs (open orders), cart, payment.
- [x] **Step 3:** §4 — every button including checkout, pay, cancel, receipt,
  customer lookup, tab management, category filters.
- [x] **Step 4:** §5 — product price, stock, service price (0!), totals, tax,
  payment methods. Explain the 50-product cap.
- [x] **Step 5:** §6–§7 — decisions on service pricing, catalog cap, stock source
  (branch vs warehouse), refunds/voids.
- [x] **Step 6:** §8–§9.
- [x] **Step 7:** Verify, update README, commit `docs(ba): add POS console analysis`.

---

### Task 4: Booking

**Files:** Create `docs/business_analysis/03-booking.md`; update README index.

**Reads:** `operations/booking/show_controller.js`,
`app/services/booking/console_service.rb`,
`app/controllers/companies/operations/booking_controller.rb`, `docs/EVENTS.md`.

- [x] **Step 1:** Run procedure A–E.
- [x] **Step 2:** §1–§3 — reservations desk, calendar/day view, resources.
- [x] **Step 3:** §4 — reservation form, date navigation, filters, resource cards.
- [x] **Step 4:** §5 — occupancy, busy/available counts, booking status.
- [x] **Step 5:** §6–§7 — decisions on conflicts/overbooking, cancellation,
  deposits/payment, recurring bookings.
- [x] **Step 6:** §8–§9.
- [x] **Step 7:** Verify, update README, commit `docs(ba): add booking console analysis`.

---

### Task 5: Reception

**Files:** Create `docs/business_analysis/04-reception.md`; update README index.

**Reads:** `operations/reception/show_controller.js`,
`app/services/reception/console_service.rb`,
`app/controllers/companies/operations/reception_controller.rb`.

- [ ] **Step 1:** Run procedure A–E.
- [ ] **Step 2:** §1–§3 — front desk: lobby, expected, checked-in, parcels, rooms.
- [ ] **Step 3:** §4 — walk-in check-in, check-out/re-open, notify host, parcel
  log/notify/pickup, tab filters, search.
- [ ] **Step 4:** §5 — waiting time, visit counts, room availability, parcel counts.
- [ ] **Step 5:** §6–§7 — decisions on notifications delivery (toast only vs real),
  badge printing, walk-in customer creation, host lookup.
- [ ] **Step 6:** §8–§9.
- [ ] **Step 7:** Verify, update README, commit `docs(ba): add reception console analysis`.

---

### Task 6: Inventory

**Files:** Create `docs/business_analysis/05-inventory.md`; update README index.

**Reads:** `operations/inventory/show_controller.js`,
`app/services/inventory/console_service.rb`,
`app/controllers/companies/operations/inventory_controller.rb`, `docs/STOCK.md`.

- [ ] **Step 1:** Run procedure A–E.
- [ ] **Step 2:** §1–§3 — warehouse view: stock ledger, zones, inbound/outbound.
- [ ] **Step 3:** §4 — filters, search, row actions, links (all read-only).
- [ ] **Step 4:** §5 — total SKUs, low stock, utilization (hardcoded 84), zone
  occupancy, audit card (available:false).
- [ ] **Step 5:** §6–§7 — decisions on writes (transfers/adjustments from here?),
  the fabricated utilization, synthesized zone names, audit domain.
- [ ] **Step 6:** §8–§9.
- [ ] **Step 7:** Verify, update README, commit `docs(ba): add inventory console analysis`.

---

### Task 7: Operations landing and configuration

**Files:** Create `docs/business_analysis/01-operations-landing.md`; update README index.

**Reads:** `companies/operations/index_controller.js`,
`companies/operation_configs/{index,show,edit}_controller.js`,
`companies/operation_appointments/{show,edit}_controller.js`,
the four backend controllers, `OperationLaunchService`,
`docs/OPERATIONS.md`, `docs/OPERATION_PAGES.md` §1–§3.

- [ ] **Step 1:** Run procedure A–E.
- [ ] **Step 2:** §1–§3 — what a company admin sees: operation list, statuses,
  launch, config, roles.
- [ ] **Step 3:** §4 — launch button, filters, config edit fields, active/inactive
  toggle, role selection.
- [ ] **Step 4:** §5 — status counts, location assignment.
- [ ] **Step 5:** §6–§7 — decide: delete housekeeping/kitchen stubs; whether a
  company can add an operation type later; what an inactive operation looks like
  to an operator; role narrowing.
- [ ] **Step 6:** §8–§9.
- [ ] **Step 7:** Verify, update README, commit `docs(ba): add operations landing analysis`.

---

### Task 8: App overview

**Files:** Create `docs/business_analysis/00-app-overview.md`; update README index.

**Reads:** `app/javascript/controllers/companies/sidebar_items.js` (every sidebar
group, including the three coming-soon groups),
`config/initializers/constants.rb` (`OPERATION_TYPES`), `docs/TODO.md`,
`docs/MOBILE_FEATURE_MATRIX.md`, and the module docs: `MONEY_FLOW`, `STOCK`,
`PURCHASE_WORKFLOW`, `HR`, `KPI`, `EXAMS`, `EVENTS`, `DISCOUNTS`,
`PAYMENT_METHODS`, `CREDIT_DEDUCTION`, `IMPORT`, `DATA_MIGRATION`, `SIDEBAR`.

- [ ] **Step 1:** Build a module table: group · business purpose · key pages ·
  status (real / partial / coming soon) · doc that owns the detail.
- [ ] **Step 2:** Add the five operation consoles with verdicts from Tasks 2–7.
- [ ] **Step 3:** Describe who buys Skycom and which industries fit, noting that
  `business_type` does not change runtime behavior.
- [ ] **Step 4:** Describe the commercial shape (plans, company credits, top-up,
  billing) in business terms.
- [ ] **Step 5:** Write "what is genuinely not ready" — a short, honest list
  linking to `docs/TODO.md` rather than repeating it.
- [ ] **Step 6:** Verify every sidebar group appears exactly once.
- [ ] **Step 7:** Commit `docs(ba): add app overview`.

---

### Task 9: Dashboard

**Files:** Create `docs/business_analysis/07-dashboard.md`; update README index.

**Reads:** `companies/dashboards/index_controller.js` + `blocks.js` +
`show_controller.js`, `DashboardsController`, `Dashboards::OverviewService`.

- [ ] **Step 1:** Run procedure A–E for all ten blocks.
- [ ] **Step 2:** §1–§3 — the daily "how is the company doing" page.
- [ ] **Step 3:** §4 — block config toggles, links, period selectors.
- [ ] **Step 4:** §5 — each KPI, chart, and list: source and verdict. Note the
  5-minute cache and financial-visibility gate in business terms.
- [ ] **Step 5:** §6–§7 — decisions on empty company, what a new company sees,
  which blocks a cashier may see.
- [ ] **Step 6:** §8–§9.
- [ ] **Step 7:** Verify, update README, commit `docs(ba): add dashboard analysis`.

---

### Task 10: Analytics

**Files:** Create `docs/business_analysis/08-analytics.md`; update README index.

**Reads:** `companies/analytics/index_controller.js` + `blocks.js`,
`AnalyticsController`, `Analytics::DashboardService`,
`Analytics::PeriodRange`, `Analytics::RevenueCalculator`.

- [ ] **Step 1:** Run procedure A–E for all nine blocks.
- [ ] **Step 2:** §1–§3 — the periodic review page.
- [ ] **Step 3:** §4 — period selector, block toggles, exports.
- [ ] **Step 4:** §5 — pillars, secondary metrics, margin, revenue mix, top items,
  cohorts, inventory, workforce, CLV. Mark anything estimated.
- [ ] **Step 5:** §6–§7 — decisions on missing data, period comparisons, what
  counts as revenue.
- [ ] **Step 6:** §8–§9.
- [ ] **Step 7:** Verify, update README, commit `docs(ba): add analytics analysis`.

---

### Task 11: Integration and consistency pass

**Files:**
- Modify: `AGENTS.md` (one row in the Doc Map)
- Modify: `docs/OPERATION_PAGES.md` (Phase 6 — update the BA doc)
- Modify: `docs/business_analysis/README.md` (final index + audit log)

- [ ] **Step 1:** Add to `AGENTS.md` Doc Map, under "Working method":
  `| Deciding what an Operation page still needs | docs/business_analysis/README.md — per-page control inventory, gaps and BA decisions |`
- [ ] **Step 2:** Add one line to `OPERATION_PAGES.md` Phase 6: "Update the
  page's record in `docs/business_analysis/` (inventory, numbers, verdict)."
- [ ] **Step 3:** Consistency sweep: badge vocabulary identical everywhere, every
  ID unique across all docs, every internal link resolves, every page doc has
  `Last audited`.
- [ ] **Step 4:** Cross-doc contradiction check: any claim in `00-app-overview.md`
  about a console must match that console's page doc.
- [ ] **Step 5:** Commit `docs(ba): link business analysis from agent guides`.

---

## 6. Verification

Documentation has no test suite. These checks replace one:

```bash
ls docs/business_analysis/                     # 10 files, no strays
grep -L "Last audited:" docs/business_analysis/*.md   # must print nothing
grep -rhoE '\b(APP|OPS|POS|BKG|RCP|INV|SM|DSH|ANL)-[0-9]+' docs/business_analysis | sort | uniq -d  # must print nothing
grep -c '^| SM-' docs/business_analysis/06-store-manager.md  # matches stated count
```

Per page:

- [ ] Every `<button>`, `<a href>`, `<input>`, `<select>` in the controller is in
  the inventory, or is listed under "intentionally not a control" (layout only).
- [ ] Every payload figure rendered in the frontend appears in §5.
- [ ] Every 🔢/⛔ has a matching decision in §7.
- [ ] The ship-readiness verdict follows §3.2 mechanically.
- [ ] No file path or method name outside §9.

Accuracy spot-check (run once at the end, per console):

```bash
P=app/javascript/controllers/companies/operations/store_manager/show_controller.js
grep -o '#[a-zA-Z][a-zA-Z0-9]*' "$P" | sed 's/^#//' | sort -u | while read -r m; do
  grep -qE "(^|[^a-zA-Z0-9_])$m *\(" "$P" || echo "check: $m"
done
```

Expected output: only names that appear in the header comment (`show`).

---

## 7. Risks

- **False confidence.** A doc that says ✅ when the click silently fails is worse
  than no doc. Every ✅ needs a read of the handler body, not just the label.
- **Line drift.** Seed findings carry line numbers; they will move. Re-grep
  before citing.
- **Template pressure.** Nine sections invite padding. If a section has nothing
  to say, write "Nothing on this page does X" — do not invent content.
- **Scope creep into fixes.** Finding a fabricated number is the job; fixing it
  is not. Record it and move on.
- **Duplication with existing docs.** `OPERATION_PAGES.md` explains how to build;
  these docs explain what exists and what it means. Do not restate the build
  procedure.

---

## 8. Out of scope

- Fixing any finding. No code, seed, or test changes.
- Mobile-specific analysis (owned by `docs/MOBILE_FEATURE_MATRIX.md`).
- The 69 non-operation sidebar pages (module-level coverage only, in
  `00-app-overview.md`).
- Admin console, marketing homepage, billing internals.
- Screenshots, videos, or design mockups.
- The ERP 100-item roadmap (owned by `docs/TODO.md`).

---

## 9. Definition of done

- [ ] `docs/business_analysis/` holds the ten documents listed in §2.
- [ ] `README.md` explains the folder to a person, a team, and an AI, with a
  legend, a glossary, and a complete index.
- [ ] Every page doc follows the nine-section contract and carries a
  ship-readiness verdict.
- [ ] Every control and every number on every page is accounted for with evidence.
- [ ] Every fabricated number (🔢) and dead control (⛔) has a decision entry.
- [ ] Every page has a safe demo path and a "do not demo" list.
- [ ] IDs are unique and stable; links resolve; no TBD.
- [ ] `AGENTS.md` and `docs/OPERATION_PAGES.md` point at the folder.
- [ ] No application code changed.
