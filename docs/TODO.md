# Skycom TODO / Backlog

> **Status**: Backlog — not scheduled work. A performance item leaves this doc
> only when its trigger is hit and the switch is implemented. A feature item
> leaves when its checklist is complete.

## Convention

Every performance item has the same four lines:

| Line | Meaning |
|------|---------|
| **Trigger** | The observable condition that promotes this from backlog to work |
| **Current cost** | What we pay today by not doing it |
| **Switch to** | The target design |
| **Cost of switching** | What the migration itself costs (code, data, ops) |

This doc holds two kinds of list:

- **Performance items** (numbered §1–§7) — the four-line format above.
- **Feature items** — checkbox rows. The largest is the
  [ERP feature roadmap](#erp-feature-roadmap--100-item-gap-audit) at the bottom:
  100 features audited against the codebase, with item numbers kept stable so
  work can be picked by number. Update the badge as work lands; tick the box
  only when it is end-to-end (BE + FE + feature spec).

---

## Payroll — client-calculated results (feature backlog)

**Idea**: Skycom exposes raw payroll input (`AttendanceMonth` / `AttendanceDay`,
employee salary/allowance, `PayrollConfig`). The client calculates payroll
outside Skycom with its own formula, then posts the finished figures back.
Skycom only stores and displays the result; it never applies rates or formulas.

- [ ] **Raw-data export** — expose attendance months/days + employee
  compensation for download (today the payroll CSV exports only
  employee/status/month).
- [ ] **Skeleton-only generation** — `Payrolls::GenerateService` creates or
  finds the employee+month row and snapshots raw attendance facts; remove its
  `PAYROLL_TAX_RATE` / `PAYROLL_SOCIAL_INSURANCE_RATE` /
  `PAYROLL_OVERTIME_MULTIPLIER` calculations.
- [ ] **Result intake path** — accept client-submitted money fields (currently
  `payroll_params` permits only `status` and `notes`), either via `update` or a
  dedicated results endpoint/service.
- [ ] **Fixed columns vs line items** — decide whether every client shares the
  same breakdown, or arbitrary earning/deduction categories need
  `payroll_lines` / jsonb.
- [ ] **Draft-only edits** — money fields editable only while `draft`;
  `approved` / `paid` rows frozen; explicit adjustment path after approval.
- [ ] **Provenance + audit** — record source (`external`), formula/version,
  `uploaded_by`, `calculated_at`, import batch; before/after history for money
  changes.
- [ ] **Validation policy** — revisit non-negative-only validation (negative
  adjustments); decide whether `net = gross - tax - deduction` should be
  enforced when client formulas may differ.
- [ ] **Total deductions** — decide whether `total_deductions_cents` stays
  derived (`tax + deduction`) or becomes a stored/client-submitted value once
  arbitrary lines exist.
- [ ] **Remove hardcoded rate label** —
  `mobile_helper.rb#mobile_payroll_tax_label` prints "Statutory (18.4%)" from
  `PAYROLL_*` constants.
- [ ] **Intake shape** — single-employee update vs bulk month upload/CSV, with
  idempotent upsert on `(company, employee, month)`.
- [ ] **Specs** — feature first, then model, then request: intake, draft-only
  immutability, bulk upsert idempotency, mobile display.

---

## Operations — new operation_type backfill (out of scope for the operations refactor)

Adding a value to `Operation.operation_type` / `OPERATION_TYPES` is not enough for existing
companies:

- Operation Configs has no create action, so existing companies won't get the new
  Operation record.
- Existing branches/warehouses won't get the new appointment rows.
- Launch/route/controller/FE wiring must also be added.

> Full new-type procedure: `docs/OPERATION_PAGES.md`.

Future task:

- Add `Seed::OperationService.sync_catalog!(company:)` — idempotent upsert of every
  `OPERATION_TYPES` key for one company.
- Run it for all companies in a data migration or rake task.
- It must create the Operation record (catalog label, desktop resolution) and
  active appointments for every existing branch/warehouse whose
  `appointment_scope` matches.
- Add the enum value, `Companies::Operations::<Type>Controller`, route,
  `OperationLaunchService` mapping, FE Stimulus controller, and `OPERATION_TYPES` entry.

## FAQ — deferred answers (feature backlog)

The System → FAQ page (`docs/FAQ.md`) states current limits honestly. Every
`planned` or `manual` answer maps to an item here. Existing roadmap entries are
cross-referenced instead of duplicated.

New items:

- [ ] **Company ownership transfer** — move the Owner role and owner employee to
      another employee with an explicit confirmation and audit row. FAQ: owner role.
- [ ] **POS price override** — manager-approved line-price override with a reason
      and audit trail. FAQ: "Who sets the price?"
- [ ] **POS thermal receipt printer** — direct ESC/POS or driver integration; the
      current receipt is an 80 mm browser print. FAQ: "What can't I do in POS?"
- [ ] **POS cash drawer, float, and split payments** — cash-drawer integration,
      opening float, split tender, and open-item sales; Store Manager stores the
      shift close, but POS does not control the drawer. FAQ: "What can't I do in
      POS today?"
- [ ] **Non-POS payment screen** — take payment for an order created outside POS
      without editing transaction rows by hand. FAQ: "Can I take payment outside POS?"
- [ ] **Booking recurrence** — repeat rules for weekly/monthly reservations. FAQ:
      "Can I create recurring bookings?"
- [ ] **Booking deposit/payment** — collect a deposit at reservation and link it to
      the booking. FAQ: "Can I create recurring bookings or take a deposit?"
- [ ] **Footfall sensor** — door-counter integration; today the page shows only the
      real buyer count. FAQ: "Why is there no footfall sensor?"
- [ ] **Attendance month scheduled refresh** — nightly job that resolves days and
      rebuilds months without manual re-runs. FAQ: "Why is my attendance month out of date?"
- [ ] **Mobile check-out** — expose check-out (and break) on mobile Home; the service
      exists but the screen does not. FAQ: "Can employees check out on mobile?"
- [ ] **Leave request workflow** — file, approve, and list leave requests; balances
      and records exist but there is no form or approval inbox. FAQ: leave questions.
- [ ] **Mobile exam pages** — question bank/exam/My Exams/timed attempt on the
      Android shell. FAQ: "Are exams available on mobile?"
- [ ] **Storage quota and billing** — per-company quota, versioning, and credit
      deduction for stored bytes. FAQ: "Is storage billed or quota-limited?"
- [ ] **BOM, zones, pallets, RFID** — inventory expansion only if a customer needs
      it; intentionally not modelled today. FAQ: "Why are BOM, zones, pallets, and
      RFID not available?"
- [ ] **Automatic refund reversal** — gateway refund + restock + invoice adjustment
      in one audited flow; today approval and reversal are separate. FAQ: "Why
      doesn't a refund reverse money or stock automatically?"

Existing roadmap references:

- POS refund/exchange from the till → **POS follow-ups** + roadmap item **53**.
- Offline POS and mobile → roadmap items **50** and **94**.
- Mobile push and Vietnamese UI → roadmap items **89** and **93**
  (`docs/MOBILE_FEATURE_MATRIX.md`).
- Reception SMS/email/push → roadmap item **89** (delivery channels).
- Payroll amount intake and draft-only editing → **Payroll — client-calculated
  results** section above.
- Adding an operation type → **Operations — new operation_type backfill** section.
- KPI → commission/bonus → roadmap item **48**.

## Company#business_type is seed-only

`Company#business_type` does not change runtime business logic. Skycom is a
dynamic, atomic system; use categories, properties, appointments, and ABAC
policies for per-company differences.

At this time `business_type` only matters for seed defaults for modules that still
use it. Do not add runtime `business_type_*?` branches.

## 1. Comment image variants → async preprocessing

- **Trigger**: first view of a comment image stalls (variant is processed
  **synchronously on first request** today), or concurrent first-views
  saturate web workers with MiniMagick.
- **Current cost**: `image_attachment`'s `:display` variant
  (`app/models/company_ticket_comment.rb`) is built lazily — whoever first
  opens the thread (or receives the socket payload URL) pays the resize.
  Eager upload-time processing was deliberately rejected (see git history:
  variants were chosen over `prepared_upload` so no custom image code ships).
- **Switch to**: a Solid Queue job calling
  `comment.image_attachment.variant(:display).preprocessed` on create, so
  the variant exists before anyone views it.
- **Cost of switching**: adds a job + queue to monitor; socket payload URLs
  stay valid (same representation URL, just pre-generated).

## 2. Comment thread pagination

- **Trigger**: tickets with hundreds of comments/logs.
- **Current cost**: `format_ticket_detail` loads **all** comments + logs +
  attachments on every detail open (both company and admin show endpoints).
- **Switch to**: `?comment_page=`-style pagination on `ticket_comments` in
  both show endpoints; FE thread renders pages instead of the full list.
- **Cost of switching**: FE thread template gains paging state; socket-inject
  must insert into the visible page or bump an "N new" indicator.

## 3. Socket fan-out narrowing

- **Trigger**: high comment volume wakes every open detail page company-wide.
- **Current cost**: `company_ticket_commented` publishes on `company_<id>` —
  all subscribers in the company receive every comment event and filter
  client-side by ticket id.
- **Switch to**: per-ticket channel
  (`WEBSOCKET.channel_name(:company_ticket, id)`): BE publish ×2, FE
  subscribe ×2, JWT channel claims (`WebsocketConcern`, admin layout)
  extended to include the ticket channel.
- **Cost of switching**: channel-claim wiring on both layouts; admin pool
  detail must resolve the ticket's channel the same way the company side does.

## 4. Attachment delivery via CDN

- **Trigger**: attachment downloads become a bandwidth hotspot.
- **Current cost**: local/MinIO blob paths served through the app host with
  `disposition: attachment` (forced download).
- **Switch to**: CDN-signed representation URLs; revisit the forced-download
  policy per content type when the URL host changes.
- **Cost of switching**: storage/CDN config, signed-URL expiry handling in
  `format_attachment` on both controllers, socket payload compatibility.

## 5. Notification bell unread count

- **Trigger**: `GET .../notifications/unread_count` shows up slow in traces,
  or a 10-minute TTL expiry triggers a miss storm (every active employee
  recomputes at once).
- **Current cost**: `refreshBell()` (`companies/layout_controller.js`) fires
  on **every page navigation**, each hitting `Notifications::UnreadQuery`
  (`app/services/notifications/unread_query.rb`) — a subscribed-tag join +
  `created_at > last_read_all_at` + `NOT IN (reads)` + `DISTINCT` that grows
  with notification volume and the reads table. A 1-hour per-employee
  `sync_cache` (`CacheKeyService.employee_unread_notifications(id)`) absorbs
  the steady state, but every expiry recomputes the full query and socket
  `notification_created` only triggers yet another `GET`.
- **Switch to**: push-based badge — the `notification_created` payload
  carries the increment (or the new count) so the bell updates with **zero
  GETs**, falling back to the endpoint only on reconnect; and/or a
  materialized per-employee unread counter (increment on publish, decrement
  on read/mark-all) replacing the join-minus-reads query, with the 10-minute
  TTL replaced by write-through invalidation.
- **Cost of switching**: payload shape + per-employee fan-out in
  `Notifications::CreateService` (one count per subscriber vs one broadcast);
  counter table + backfill; read paths (`mark_all_read`, single reads) must
  keep the counter exact or the badge lies.

## 6. Record cache — current state and trade-offs

**Implemented**: `Session`, `User`, `Company`, `Employee` are cached in
`Rails.sync_cache` (unversioned keys, `refresh_cache`/`remove_cache`
invalidation, TTL backstop). `User`/`Company`/`Employee` are re-instantiated
from cached attributes via `Model.instantiate`, eliminating per-request DB
reads on cache hit; `Session` stays a compact hash.

**Trade-off**: `instantiate` allocates an ActiveRecord object and re-casts
attributes on every request. This is far cheaper than a DB round-trip and keeps
all existing callers (`current_company.shift_templates`, `current_user.companies`,
etc.) working without a refactor, but it is not zero-cost and still holds a full
AR instance in memory per request.

**Future improvement (hash-based, zero-DB, zero-instantiate)**: migrate callers
to raw, indexed FK queries (`ShiftTemplate.where(company_id: ...)`,
`current_user["system_role"] == "admin"`) and return compact hashes from
`current_user`/`current_company`/`current_employee` instead of AR objects.
See `/home/skyler/.opencode/plan/hash-based-records.md` for the field inventory
and migration recipe. Until that refactor lands, `instantiate` remains the
compatibility bridge.

## 7. Notification bell unread count → fold into page JSON

- **Trigger**: `GET .../notifications/unread_count` shows up in every
  page-load trace, or the bell becomes a latency hotspot on navigation.
- **Current cost**: each page load issues a separate request for the unread
  count (shell + data + bell = 3 requests). The count is already cached
  per employee (10-min TTL via `Notifications::UnreadQuery`), but a request
  still fires on every navigation and the cache miss recomputes the
  subscribed-tag join.
- **Switch to**: include the unread count in the page's JSON response at the
  same level as `pagination` (e.g. `unread_count` field on index/show
  payloads), so the bell updates from data already fetched. Drop the
  standalone `unread_count` request; fall back to the endpoint only on
  reconnect or when the field is absent.
- **Cost of switching**: add the field to the relevant controllers'
  JSON payloads and update the FE bell to read from the page data (or the
  client cache) instead of calling the endpoint. Keep the endpoint for
  backwards compatibility / reconnect recovery.

## ERP feature roadmap — 100-item gap audit

> **Source**: 2026-11-17 audit of the "Super ERP" 100-feature checklist against
> the live codebase (221 tables, 219 models, controllers, routes, services).
>
> **How to use**: pick the next item from this list. Update the badge as work
> lands; delete the row only when the feature is end-to-end (BE + FE + feature
> spec). Item numbers are preserved from the source checklist so a session can
> say "do 6 and 47" without ambiguity.
>
> Legend: ✅ built · 🟡 partial / foundation only · ❌ missing

### Scorecard

| Verdict | Count | Items |
|---|---|---|
| ✅ built | 9 | 23, 29, 39, 69, 76, 80, 85, 95, 98 |
| 🟡 partial | 27 | 6, 10, 12, 13, 16–22, 24, 34, 36, 46, 49, 50, 53, 68, 74, 77–79, 88, 89, 93, 100 |
| ❌ missing | 64 | every item not listed above |

**Highest-leverage clusters**

1. **Finance depth** (pillars 1 + 3) — there is no accounting core at all: no
   GL, AP/AR automation, budgets, assets, or FX. Blocked on a double-entry
   ledger underneath the existing money paths (`docs/MONEY_FLOW.md` is the
   current contract).
2. **Projects & field service** (pillar 8) — `Project` / `Task` / `ProjectGroup`
   / `TaskGroup` tables and seed services already exist; missing controllers,
   routes, and UI, not schema.
3. **Enterprise trust** (pillar 10) — public REST/GraphQL API, outbound
   webhooks, SSO/MFA, white-label, feature flags, sandbox, tenant export. Each
   is bounded work; none needs research.
4. **Automation & polish** — AI copilot/forecasting, report builder, scheduled
   digests, Cmd+K search, per-record comments, DMS versioning/OCR, offline
   mobile, e-signatures.

### Pillar 1 — Financial Management & Accounting

- [ ] **1 · Multi-entity & intercompany accounting** ❌ — `Company` → `Branch`
      only; no legal entities, consolidation, or intercompany eliminations.
- [ ] **2 · Real-time General Ledger** ❌ — no chart of accounts, journal
      entries, or posting. `Transaction` / `Invoice` are payment records.
- [ ] **3 · Multi-currency & auto-FX revaluation** ❌ — `currency` is an enum
      column on ~40 models (`CURRENCIE_CODES`); no rates or conversion.
- [ ] **4 · AI-assisted bank reconciliation** ❌ — nothing.
- [ ] **5 · AP automation (OCR invoice scanning)** ❌ — purchases are manual
      line items.
- [ ] **6 · AR & dunning** 🟡 — `Invoice#due_date`, `payment_status: overdue`,
      dashboard "overdue invoices" block. No reminders, aging buckets, late fees.
- [ ] **7 · Three-way invoice matching** ❌ — the purchase→stock bridge exists
      (`StockMovementService::Purchases::CompleteService`); no PO/GRN/invoice match.
- [ ] **8 · Dynamic budgeting & variance alerts** ❌ — only discount-campaign
      budgets (`discount_groups.total_budget_cents`).
- [ ] **9 · Cash flow forecasting** ❌ — nothing.
- [ ] **10 · Localized tax & e-invoicing** 🟡 — `TaxConfig` + the Taxes page
      review raw tax-prep data; `TaxesController` is explicitly "no tax
      calculation", and there is no e-invoice portal.
- [ ] **11 · Fixed asset lifecycle & depreciation** ❌ — nothing.
- [ ] **12 · Cost center & profit center P&L** 🟡 — analytics has branch/category
      revenue mix, margin, CLV, cohorts; no cost-center P&L.

### Pillar 2 — Human Resources & Talent (HCM)

- [ ] **13 · Centralized directory & org chart** 🟡 — employee CRUD, departments,
      employee groups with `manager_id`, `Employee::ManagerConcern`; no
      org-chart visualization.
- [ ] **14 · Applicant Tracking System (ATS)** ❌ — nothing.
- [ ] **15 · Onboarding & offboarding checklists** ❌ — `Task` / `TaskGroup`
      tables exist but have no controller or UI.
- [ ] **16 · Biometric, GPS & geofenced attendance** 🟡 — `AttendanceConfig`
      (radius, `require_photo`) and `AttendanceLog` (lat/long, device
      fingerprint, photo). Mobile checks in only; no check-out, biometric
      terminal, or IP restriction.
- [ ] **17 · Complex shift & roster scheduling** 🟡 — `ShiftTemplate`
      (fixed / pure-flexible / core-hours, grace, break) + `ScheduledShift`.
      No rotation rules, split shifts, or swap approvals.
- [ ] **18 · Leave & accrual engine** 🟡 — requests with workflow approval,
      `AttendanceLeave` (paid/sick/unpaid), `AttendanceBalance.entitled_days`
      per year. No accrual rules, carryover limits, or comp time.
- [ ] **19 · OKR & 360 performance reviews** 🟡 — `KpiConfig` registry
      (metric, target, weight, period) + performance leaderboard. No 360
      feedback, appraisals, or compensation link.
- [ ] **20 · Learning Management System (LMS)** 🟡 — exams: question bank,
      assignments, attempts, grading, summaries. No courses, certifications, or
      expiry reminders.
- [ ] **21 · Employee document vault & e-signatures** 🟡 — `Document` (markdown
      + attachments) assigned to employees, folder/stored-file storage, ABAC.
      No e-signature.
- [ ] **22 · Employee Self-Service portal & mobile app** 🟡 — Android shell has
      profile, attendance, password-gated payroll, requests, notifications, 5
      operation consoles. No expense claims, payslip PDF, or profile editing.

### Pillar 3 — Payroll & Compensation

- [x] **23 · One-click automated payroll runs** ✅ —
      `Payrolls::GenerateService` builds gross-to-net from attendance months
      with config filters and draft/approved/paid states.
- [ ] **24 · Statutory tax & social insurance engine** 🟡 — flat constants
      (`PAYROLL_TAX_RATE` 10%, `PAYROLL_SOCIAL_INSURANCE_RATE` 8.4%,
      `PAYROLL_OVERTIME_MULTIPLIER` 1.5). Not jurisdictional or bracket-based.
- [ ] **25 · Multi-cycle & multi-currency payroll** ❌ — monthly only; currency
      is copied from the employee.
- [ ] **26 · Earned wage access & salary advances** ❌ — nothing.
- [ ] **27 · Expense reimbursement (receipt OCR)** ❌ — nothing.
- [ ] **28 · Bank disbursement files + payroll GL** ❌ — CSV export only; no
      ACH/SEPA/local formats and no journal posting.

### Pillar 4 — Inventory & Warehouse Management (WMS)

- [x] **29 · Real-time multi-warehouse stock ledger** ✅ — `Stock`,
      immutable `StockTransaction` ledger, `StockPending` holds, transfers,
      imports/exports (`docs/STOCK.md`).
- [ ] **30 · Bin, rack & zone mapping** ❌ — warehouse-level only.
- [ ] **31 · Serial number & lot/batch tracking** ❌ — no serial/lot/batch
      columns anywhere.
- [ ] **32 · FEFO / FIFO / expiry management** ❌ — generic `expiration_date`
      column only; no expiry-aware picking rules.
- [ ] **33 · Dynamic reorder points & safety stock** ❌ — `StockPending` is a
      reservation hold, not replenishment.
- [ ] **34 · Barcode, QR & RFID mobile scanning** 🟡 — `renderQrCode` helper
      renders QR (`docs/QR_CODE.md`); no scanner in the Android shell.
- [ ] **35 · Wave, batch & zone picking** ❌ — nothing.
- [ ] **36 · Cycle counting & blind stocktakes** 🟡 — manual `StockAdjustment`
      corrections; no scheduled counts or shrinkage reporting.
- [ ] **37 · Landed cost allocation** ❌ — nothing.
- [ ] **38 · Kitting, bundling & disassembly** ❌ — nothing.

### Pillar 5 — Procurement & Supply Chain

- [x] **39 · Purchase requisition & multi-tier approvals** ✅ — `Purchase` +
      `Workflow` / `WorkflowStep` + `Workflows::AdvanceService` + ABAC + audit
      log (`docs/PURCHASE_WORKFLOW.md`).
- [ ] **40 · RFQ portal** ❌ — nothing.
- [ ] **41 · Vendor scorecard & performance analytics** ❌ — `Supplier` CRUD
      only; no on-time delivery or defect metrics.
- [ ] **42 · Blanket POs & vendor contracts** ❌ — nothing.
- [ ] **43 · Drop-shipping & cross-docking** ❌ — nothing.
- [ ] **44 · RMA & supplier returns** ❌ — `Refund` is customer-facing only.

### Pillar 6 — Sales, CRM & Omnichannel Commerce

- [ ] **45 · Unified lead-to-cash pipeline** ❌ — orders/invoices/customers
      only; no leads, opportunities, stages, or win/loss reasons.
- [ ] **46 · CPQ engine** 🟡 — the discount engine is real (discount groups,
      promo campaigns, codes, budgets, reservations); no quote document or
      pricing approval guardrails.
- [ ] **47 · Customer credit limit & risk controls** ❌ — no credit-limit field
      and no order hold.
- [ ] **48 · Sales commission automation** ❌ — employee attribution exists for
      KPI only.
- [ ] **49 · Subscription & recurring billing** 🟡 — `SubscriptionPlan` /
      `SubscriptionGroup` plus order/branch appointments; no scheduler,
      proration, or churn tracking.
- [ ] **50 · Omnichannel POS** 🟡 — POS console + `OrderProcessingV1`
      (availability → reserve → discount → QR/cash → receipt). No split
      payments, loyalty, cash-drawer reconciliation, or offline.
- [ ] **51 · B2B self-service wholesale portal** ❌ — no customer-facing portal.
- [ ] **52 · E-commerce & marketplace connectors** ❌ — no Shopify, WooCommerce,
      Amazon, or Shopee integration.
- [ ] **53 · Returns, refunds & store credit** 🟡 — `Refund` follows a
      refund-process workflow, but the model states money/stock reversal is
      manual; no restock/quarantine.

### Pillar 7 — Manufacturing & Production (MRP)

No manufacturing concepts or tables exist in the codebase (the only "BOM" hits
are UTF-8 byte-order marks in CSV parsing). Whole-pillar build, or decline.

- [ ] **54 · Multi-level Bill of Materials (BOM)** ❌
- [ ] **55 · Material Requirements Planning (MRP)** ❌
- [ ] **56 · Work center & capacity scheduling** ❌
- [ ] **57 · Shop floor control & work orders** ❌
- [ ] **58 · Subcontracting & outsourced processing** ❌
- [ ] **59 · Quality control & non-conformance** ❌
- [ ] **60 · Actual vs. standard production costing** ❌

### Pillar 8 — Project Management & Field Service

- [ ] **61 · WBS & Gantt charts** ❌ — `Project` / `Task` / groups have tables
      and seed services only; no controller, route, or UI.
- [ ] **62 · Resource capacity & utilization** ❌ — nothing.
- [ ] **63 · Billable timesheets & expense linking** ❌ — nothing.
- [ ] **64 · Flexible project billing models** ❌ — nothing.
- [ ] **65 · Real-time project margin & burn rate** ❌ — nothing.
- [ ] **66 · Field service dispatch & route optimization** ❌ — nothing.
- [ ] **67 · Preventive equipment maintenance** ❌ — nothing.
- [ ] **68 · Customer support helpdesk & SLA** 🟡 — internal `Ticket`
      helpdesk (workflow, comments, logs) and `CompanyTicket` (tenant → Skycom
      support with admin reply/resolve/rating). No external-customer helpdesk
      and no SLA timers.

### Pillar 9 — Executive Business Intelligence & AI Copilot

- [x] **69 · Role-based executive command center** ✅ — dashboard (10 blocks)
      plus analytics (9 blocks: pillars, margin, revenue mix, top items,
      cohorts, inventory, workforce, CLV), permission-gated per block.
- [ ] **70 · Natural language AI data copilot** ❌ — the sidebar group exists
      but is `comingSoon: true`.
- [ ] **71 · AI demand & inventory forecasting** ❌ — nothing.
- [ ] **72 · Fraud & anomaly detection** ❌ — nothing.
- [ ] **73 · What-if scenario simulator** ❌ — nothing.
- [ ] **74 · Custom report builder** 🟡 — `TableConfig` dynamic tables plus
      dashboard/analytic block toggles; `resources :reports` and
      `company_reports_path()` exist with **no controller**.
- [ ] **75 · Automated scheduled digests** ❌ — Solid Queue exists, but no
      digest job or mailer.

### Pillar 10 — Multi-Tenant Platform, Security & Extensibility

- [x] **76 · Strict tenant data isolation** ✅ — system companies, company
      scoping, membership assertions (`docs/SYSTEM_COMPANY.md`).
- [ ] **77 · Granular RBAC & field-level access** 🟡 — ABAC is strong at
      record/action level with `PermissionLog`; no field-level masking
      (e.g. hiding salary per user).
- [ ] **78 · Immutable audit trail** 🟡 — `paper_trail` gem + `versions` table
      are installed but `has_paper_trail` is commented out. Only domain logs
      exist (`PermissionLog`, `TableConfigLog`, `EventConfigLog`,
      `AttendanceConfigLog`, `WorkflowStepLog`, `StockTransaction`).
- [ ] **79 · No-code workflow & approval builder** 🟡 — workflow + nested steps,
      category-bound, rework/reject. Approval chains only; no conditions,
      actions, or notifications.
- [x] **80 · Custom fields, entities & form builder** ✅ — categories + typed
      property slots + `TableConfig` + profile/subprofile buckets
      (`docs/CATEGORY_DYNAMIC_SCHEMA.md`, `docs/PROFILE_SUBPROFILE.md`).
- [ ] **81 · Document & print template designer** ❌ — order `receipt` action
      only.
- [ ] **82 · Enterprise SSO & MFA** ❌ — Google OAuth2 only; no SAML, OIDC,
      Microsoft Entra, passkeys, or MFA.
- [ ] **83 · IP whitelisting & session policies** ❌ — single-session enforcement
      only; no IP allowlist or idle-timeout policy.
- [ ] **84 · GDPR/PDPA retention & anonymization** ❌ — soft delete only; no
      retention policy or anonymization.
- [x] **85 · Multi-language & localization** ✅ — EN/VI `translate()` +
      `dictionary.js`, plus the timezone display contract
      (`docs/LANGUAGE.md`, `docs/TIME_DISPLAY.md`).
- [ ] **86 · Tenant white-labeling** ❌ — no custom domains, themes, or branded
      email.
- [ ] **87 · Modular feature flags & tiered subscriptions** ❌ — capabilities are
      global constants (`EXPORT_ENABLED_RESOURCES`); no per-tenant entitlements.
- [ ] **88 · Collaborative comments & @mentions** 🟡 — comment threads with
      images and WebSocket exist on `Ticket` and `CompanyTicket` only; not
      attachable to invoices/POs/records.
- [ ] **89 · Unified notification center** 🟡 — in-app notifications, tag
      subscriptions, unread badge, realtime socket, throttling. No email, push,
      Slack, Teams, or Zalo delivery.
- [ ] **90 · Global instant search (Cmd+K)** ❌ — Meilisearch powers per-page
      table search only; no cross-entity palette.
- [ ] **91 · Public REST & GraphQL APIs** ❌ — no `api` namespace, no API keys,
      no GraphQL.
- [ ] **92 · Event-driven outbound webhooks** ❌ — only inbound mock payment
      webhooks exist (`docs/MOCK_API.md`).
- [ ] **93 · Native iOS & Android apps** 🟡 — Android Hotwire Native shell with
      13 screens (`docs/MOBILE.md`); no iOS.
- [ ] **94 · Offline-first sync engine** ❌ — no service worker or native cache.
- [x] **95 · Bulk data import/export wizards** ✅ — `Imports` (allowlist, dry
      run, approve, run, log-based rollback) + `CompanyMigrations` (chunked,
      config-driven, resume/retry/rollback) + per-page CSV export
      (`docs/IMPORT.md`, `docs/DATA_MIGRATION.md`, `docs/EXPORT.md`).
- [ ] **96 · Per-tenant sandbox / staging** ❌ — nothing.
- [ ] **97 · PITR backups & tenant export** ❌ — nothing.
- [x] **98 · Usage metering & tenant billing portal** ✅ — wallet, usage logs,
      daily/monthly usage, credit deduction, top-ups (QR/redirect gateways),
      billing page, admin credits, promo campaigns (`docs/CREDIT_DEDUCTION.md`).
- [ ] **99 · In-app interactive walkthroughs** ❌ — nothing.
- [ ] **100 · Document Management System (DMS)** 🟡 — nested `Folder` +
      `StoredFile` (Active Storage, MIME/size limits, polymorphic attachable) +
      storage statistics; no file versioning or OCR indexing.

### Dangling surfaces — finish or delete

Planned features whose routes/helpers/tables exist without an implementation.
Each one is a broken link in the product today.

- [ ] `reports`, `tasks`, `payslips`, `announcements`, `transactions` — routes
      in `config/routes.rb` and path helpers in `url_helpers.js`, **no
      controllers**.
- [ ] `Project` / `ProjectGroup` / `Task` / `TaskGroup` — models + seed services
      only; no controller, no projects route.
- [ ] `has_paper_trail` commented out in `app/models/employee.rb` while the gem
      and `versions` table are live (directly unlocks item 78).
- [ ] Dashboard/analytic blocks and `EXPORT_ENABLED_RESOURCES` are global
      constants; confirm this is intended before item 87 is attempted.

### POS follow-ups (after the 2026-11-19 till completion)

- [ ] **Stale pending discount cleanup** — if a browser dies after Apply, the
      code stays `pending` on the order. Add a lazy release (or a small
      recurring job) for pending POS discounts older than a documented TTL.
- [ ] **Category-correct pagination** — the category pills filter the loaded
      50; a category with no items in the first page can look empty. Pass
      `category_id` to the catalog service when the catalog grows beyond 50
      per category.
- [ ] **POS refund / exchange** — void is before payment only; paid sales still
      go to Orders/Refunds. Build the reason-coded flow from the paid receipt.

---

*See also: `docs/WEBSOCKET.md` (channels/events), `docs/CACHE.md` (tiers),
`docs/EXPORT.md`, `docs/TEST_PRIORITY.md`.*
