# Skycom Credit Deduction System

> **Status**: Live. Credit deduction is controlled at the **controller action level** via an `after_action` filter, and the deduction logic lives in a dedicated service class hierarchy (`CompanyCreditDeduction::*`).
>
> **Hard boundary**: deduction is **controller-only**. Background jobs, imports,
> seeds, and migrations are **free-credit** — they may grant credits and drain
> usage counters, but they must never call `CompanyCreditDeduction::*`,
> `CompanyWallet#deduct_from!`, or `Company#record_credit_usage!`.

---

## 1. Overview

Every credit-consuming action (dashboard access, order creation, customer creation, ...) must leave a trail: the wallet balance moves and usage is metered. This document defines **how** those deductions are wired and executed.

### The Two Rules

1. **Never deduct inline in a controller action.** The demo pattern (`credit_warning = deduct_dashboard_credits` — a private controller method that mutates the wallet inside the action body) is deprecated: it couples business logic to the controller, duplicates the deduct/meter/rescue code in every action, and is not scalable.
2. **Deduction is a filter concern; the logic belongs to a service class.** Each controller *declares* which `CompanyCreditDeduction::*` service runs for which action. The `after_action` filter executes the service after a successful JSON response.

### Deduction Boundary — Controllers Only

Background jobs are **free-credit**. A suspended company is still processed by
company-wide jobs (usage sync, promo campaigns), and those runs must never move
credits out of the wallet.

| Path | May deduct? | May grant credits? | May meter usage? |
|------|-------------|--------------------|------------------|
| Controller action via `deduct_company_credits_for` | ✅ | ✅ | ✅ |
| `CompanyUsageSyncJob` | ❌ | ❌ | ❌ — it only drains the counter |
| Promo campaign job / top-up completion | ❌ | ✅ | ❌ |
| Data import / migration job | ❌ | ❌ | ❌ |
| Order finalization job | ❌ | ❌ | ❌ |
| Seed data | ❌ | ✅ (demo top-ups) | ✅ (demo usage only) |

When a feature exists in both a controller and a background job (data import,
order finalization, bulk updates), **the deduction belongs to the controller
entry point only**. Do not move it into a shared domain service that the job
also calls. The mechanical guard is
`spec/services/credit_deduction_boundary_spec.rb`, which scans `app/jobs`,
`app/services/company_migrations`, and `app/services/seed` for deduction calls.

### Why a Service Subclass per Place/Action?

The same **action type** can have different deduction rules in different places:

| Place | Action type | Cost | Guard |
|-------|-------------|------|-------|
| `DashboardsController#index` | `access_dashboard` | 2 | JSON only |
| Future: `DashboardController#export` | `access_dashboard` | 5 (heavier operation) | JSON only |
| Future: `OrdersController#create` | `create_order` | 10 | Feature enabled |

Because rules differ per place even for the same action type, each (controller, action) pair gets its **own subclass** of the epic `CompanyCreditDeduction::BaseService`. The subclass controls cost, description, and guards; the base class owns the deduction core (priority order + metering).

---

## 2. The after_action Filter (Controller Layer)

**File**: `app/controllers/concerns/companies/credit_deduction_concern.rb`

Included in `Companies::ApplicationController`, so every company-scoped controller inherits a single `after_action :run_credit_deduction`.

### Declarative DSL

```ruby
class Companies::DashboardsController < Companies::ApplicationController
  # Map one or more actions to their dedicated service.
  deduct_company_credits_for :index, with: CompanyCreditDeduction::Companies::Dashboards::IndexService
end
```

### Filter Behavior

| Rule | Detail |
|------|--------|
| **Runs after the action** | `after_action` — the response is already rendered |
| **JSON only** | HTML shell requests never deduct |
| **Successful responses only** | `response.successful?` — 4xx/5xx never deduct. A suspended company's JSON request is 403, so it never deducts. |
| **Delegates entirely** | Calls `ServiceClass.call(company: current_company)` — the controller holds no deduct logic |
| **Never breaks the request** | Any error inside the deduction is rescued and logged as `[CompanyCreditDeduction]` — the page always renders |

### Deprecated Demo Pattern (Do NOT Use)

```ruby
# ❌ FORBIDDEN — inline deduction in the action body
def index
  credit_warning = deduct_dashboard_credits   # private controller method mutating the wallet
  render json: { ..., credit_warning: credit_warning }
end
```

Removed in the after_action refactor. The warning-surfacing responsibility moved out of the deduction path entirely — balance display is a separate concern (see §5).

---

## 3. The CompanyCreditDeduction Service Hierarchy (Service Layer)

```
app/services/company_credit_deduction/
├── base_service.rb                                 # The epic — deduction core
└── companies/
    └── dashboards/
        └── index_service.rb                        # CompanyCreditDeduction::Companies::Dashboards::IndexService
```

**Naming convention**: the constant matches the route path exactly.

| URL | Service class |
|-----|---------------|
| `/companies/:company_id/dashboards` + `index` | `CompanyCreditDeduction::Companies::Dashboards::IndexService` |
| `/companies/:company_id/orders` + `create` | `CompanyCreditDeduction::Companies::Orders::CreateService` (future) |

> The dashboard JSON payload is cached for 5 minutes (`DASHBOARD_CACHE_EXPIRY`,
> `docs/CACHE.md` §7), but deduction still runs **per request** through the
> `after_action` filter. A cache hit is still a dashboard access and is billed.

### 3.1 `CompanyCreditDeduction::BaseService` — The Epic

One purpose: **move credits out of the wallet for one action and meter the usage.**

```ruby
class CompanyCreditDeduction::Companies::Dashboards::IndexService < CompanyCreditDeduction::BaseService
  def action_type = "access_dashboard"   # key in CREDIT_USAGE_RATES + CompanyUsageLog
  def description = "Dashboard access"   # human-readable audit log description
end
```

| Method | Default | Override? | Purpose |
|--------|---------|-----------|---------|
| `action_type` | **required** (raises if missing) | Always | Key into `CREDIT_USAGE_RATES`; mirrored in `CompanyUsageLog.action_type` |
| `cost` | `CREDIT_USAGE_RATES[action_type]` | Optional | Place-specific pricing (same action type, different cost) |
| `description` | `action_type` humanized | Optional | Audit trail text |
| `should_run?` | `company.present?` | Optional | Place-specific guards (feature gating, request format, ...) |

### 3.2 The Deduction Core (inherited — never reimplement)

```
call(company:)
  ├── should_run?  ── no ──► return
  ├── cost = cost() ── zero ──► return
  ├── wallet = company.company_wallet ── missing ──► return
  ├── balance_before = wallet.total_credit_balance
  │
  ├── deduct promo balance first   (while it is positive)
  ├── deduct main balance second   (absorbs the whole remainder, even below zero)
  │
  ├── if balance_before < 0:
  │     Rails.logger.warn("[CompanyCreditDeduction] deduction while negative ...")
  │     company.sync_credit_status!(total_credit_balance: balance_after)
  │
  └── company.record_credit_usage!(cost)   ← Kredis counter, always
```

**Never raises for an insufficient balance.** Negative balances are allowed:
`0 - 2 = -2` is silent. If a later deduction starts while the balance is already
negative, the service logs a warning and rechecks `workflow_status` (which derives
`suspend` for any total ≤ 0). There is no debt column and no debt absorption.

---

## 4. The Two-Balance Wallet

**File**: `app/models/company_wallet.rb`

The wallet stores credit balance **numbers only** (atomic-purpose pattern — no business logic). The `CompanyCreditDeduction::*` services own the priority rules.

### Balances

| Column | Purpose | Top-up target? | Deduct order |
|--------|---------|----------------|--------------|
| `main_credit_balance` | Purchased credits (top-ups land here) | ✅ Yes (`add_credits!`) | 2nd |
| `promo_credit_balance` | Promotional credits (signup bonus, campaigns) | ❌ No | **1st** |

- New companies get `SIGNUP_PROMO_CREDITS` (1,000) in the **promo** balance at
  creation, so they start active. System-owned companies receive the same grant;
  only their suspension exemption is special.
- Both columns are BIGINT and may be **negative**. A negative total is allowed
  and derives `workflow_status: suspend`.

### Low-Level API (the only wallet mutation entry points)

```ruby
wallet.add_credits!(amount:, source:, description:)                    # top-up → main only
wallet.add_to!(balance: :promo, amount:, source:, description:)        # grant promo credits
wallet.deduct_from!(balance: :main, amount:, source:, description:)   # deduct (controller-only)
```

- Every mutation runs inside **`with_lock`** (transaction + row-level `FOR UPDATE`) — concurrent deductions serialize on the wallet row.
- `deduct_from!` does **not** raise on a low balance; it subtracts the full amount and may make the balance negative. `add_to!` / `add_credits!` are allowed from jobs (money IN); `deduct_from!` is controller-only (money OUT).
- Every mutation writes a `CompanyWalletLog` audit row with `balance_type` (`main` / `promo`) + before/after snapshots, then calls `company.sync_credit_status!` so the company status follows the new total.
- Balance keys are validated against `CompanyWallet::BALANCES` (single-file constant) — unknown keys raise `ArgumentError`.

### Company Credit Status (derived)

`companies.workflow_status` is derived from the usable balance:

| Value | Meaning | Web/API/mobile | Background jobs | Set when |
|-------|---------|----------------|-----------------|----------|
| `active` | Normal company with usable credit | Allowed | Processed | `total > 0` |
| `disabled` | Owner no longer uses Skycom | Not suspension-blocked (manual state) | Skipped | Manual/back-office |
| `suspend` | No usable credit (`total <= 0`) | Web redirects to top-up; JSON/mobile return 403 | Processed (free-credit) | `total <= 0` |

- `companies.lifecycle_status` is legacy and is not used for access control.
- `Company#suspended?` is backed by a `ram_cache` boolean; status changes write the
  new value locally and broadcast a `sync_cache` invalidation so every worker
  rebuilds it (see `docs/CACHE.md` §7).
- System companies are exempt from credit suspension.
- Any credit movement can move a `disabled` company back to `active` (the user
  must be able to recover by topping up).

---

## 5. Warning & Balance Display (Separate Concern)

The deduction service **only cares about deducting**. It returns no warning message. Insufficient-balance feedback is a separate concern, handled by whichever logic owns the display — e.g. the dashboard JSON already exposes the full wallet state:

```json
{
  "wallet": {
    "main_credit_balance": 98,
    "promo_credit_balance": 0,
    "currency": "USD"
  }
}
```

The frontend decides what to surface from those numbers. Suspension itself is
enforced by the request block (§5.2), not by a warning key. The old
`credit_warning` JSON key was removed with the demo pattern.

### 5.1 Opt-in Detail Logging (Usage Page)

Per-action detail rows (`CompanyUsageLog` — *why* a balance moved) are **opt-in** and hot-table safe. The Usage page (`GET /companies/:id/usage`) exposes the toggle:

| Control | Endpoint | Effect |
|---------|----------|--------|
| **Enable Logging** button | `POST .../usage/enable_logging` | `wallet.enable_usage_logging!` — opens a 5-minute recording window |
| **Stop Logging** button | `POST .../usage/disable_logging` | `wallet.disable_usage_logging!` — closes the window immediately |

While active, the page shows a table of that window's log rows; when off (the default), the table renders as an empty layout.

---

## 5.2 Suspended Company — Request Blocking

A suspended company cannot use the business surface:

| Request | Result |
|---------|--------|
| Web HTML (company pages) | `302` → `new_company_top_up_path` |
| Web JSON (company pages) | `403` + `{ errors: ["Your company is suspended. Please top up to continue."] }` |
| Mobile company pages | `403` with a mobile-layout notice (top-up is web-only) |
| Top-Up / Billing / Usage | Allowed — recovery and inspection pages |
| Sign-in / root / client cache / webhooks | Allowed |

Implementation:
- `Companies::SuspendedCompanyConcern` is included **after**
  `Companies::Authorizable` in `Companies::ApplicationController`.
- `Mobile::Companies::SuspendedCompanyConcern` does the same for mobile company
  pages.
- `Companies::TopUpsController`, `Companies::BillingController`, and
  `Companies::UsageController` skip the filter.
- `Companies::TopUpsPolicy#new?` is `true` for any employee so a redirected
  employee never loops on authorization; payment initiation stays
  permission-gated.

### Shortfall guard (safety net)

The controller block is the primary prevention. The deduction service also has a
last-line guard: if a deduction reaches it while the pre-deduction balance is
negative, it logs `[CompanyCreditDeduction] deduction while negative ...` and
rechecks `workflow_status`. The first overdraw (`0 → -2`) is silent; a later
deduction while already negative logs.

---

## 6. Adding a New Deduction Point (Step by Step)

**1. Add the action cost** (if the action type is new):

```ruby
# config/initializers/constants.rb
CREDIT_USAGE_RATES = {
  create_order: 10,
  access_dashboard: 2,
  create_customer: 7,
  create_export: 5          # new action type
}.freeze
```

**2. Create the dedicated service subclass** (path matches the route):

```ruby
# app/services/company_credit_deduction/companies/dashboards/export_service.rb
module CompanyCreditDeduction
  module Companies
    module Dashboards
      class ExportService < CompanyCreditDeduction::BaseService
        def action_type = "create_export"
        def description = "Dashboard export"

        # Optional place-specific guard:
        # def should_run? = @company.feature_enabled?("analytics_dashboard")
      end
    end
  end
end
```

**3. Declare it in the controller** — one line, no other controller changes:

```ruby
class Companies::DashboardsController < Companies::ApplicationController
  deduct_company_credits_for :export, with: CompanyCreditDeduction::Companies::Dashboards::ExportService
end
```

Do **not** call the service from a background job, import, seed, or migration.
If the same action also runs in a job, deduct only at the controller entry point
(see “Deduction Boundary — Controllers Only” above).

**4. Specs** (TDD — write first):

```ruby
# spec/services/company_credit_deduction/companies/dashboards/export_service_spec.rb
# + request-level coverage in spec/requests/companies/credit_deduction_spec.rb
```

---

## 7. Testing — Wallet Seeding Requirement

New companies start with `SIGNUP_PROMO_CREDITS` (1,000) in the promo balance.
Credit-focused tests should use the `:without_signup_promo` company factory trait
or the `seed_random_wallet!` helper so exact balance assertions stay
deterministic. The trait is not a shortcut for the state machine: it gives a
known zero baseline, and the wallet/service specs must still exercise every
transition.

### Required state transitions

| State transition | Expected status | Covered by |
|---|---|---|
| Signup init (promo 1,000) | `active` | `company_credit_status_spec` |
| `0` | `suspend` | `company_credit_status_spec`, `company_wallet_spec` |
| `0` → positive (`SIGNUP_PROMO_CREDITS`) | `active` | `company_credit_status_spec` |
| positive → `0` (deduction reaches zero) | `suspend` | `company_credit_status_spec`, `company_wallet_spec` |
| positive → negative (overdraw) | `suspend` | `company_credit_status_spec`, `company_wallet_spec`, `base_service_spec` |
| negative → positive (top-up/grant) | `active` | `company_credit_status_spec`, `company_wallet_spec` |
| `disabled` → positive | `active` | `company_credit_status_spec` |
| System company at `0` or negative | stays `active` | `company_credit_status_spec` |

### Reusable Helper

**File**: `spec/support/credit_wallet_helper.rb:1`

```ruby
# Clears the signup promo, then seeds promo-first priority.
snapshot = seed_random_wallet!(company) # => { promo_start: 200..500, main_start: 200..500 }
# or custom ranges:
snapshot = seed_random_wallet!(company, promo_range: 300..600, main_range: 300..600)

visit company_dashboards_path(company)
expect(company.company_wallet.reload.promo_credit_balance).to eq(snapshot[:promo_start] - 2)
expect(company.company_wallet.reload.main_credit_balance).to eq(snapshot[:main_start])
expect(company.credit_usage_delta).to eq(CREDIT_USAGE_RATES[:access_dashboard])
```

For specs that need a zero wallet without the signup bonus:
`create(:company, :without_signup_promo)`. The trait clears both balances and
sets the company to `suspend`; any subsequent `add_to!`/`add_credits!` returns it
to `active`.

Auto-loaded via `spec/rails_helper.rb:26` (`Rails.root.glob('spec/support/**/*.rb')`), so no per-file `require` needed — works for `type: :feature` (js), `:request`, and `:job`.

### The Full E2E Chain (Redis → DB)

This is the canonical pattern proven in `spec/features/companies/credit_deduction_e2e_spec.rb:1`:

```
visit (trigger after_action deduct → Kredis INCR) → assert credit_usage_delta
  → CompanyUsageSyncJob.perform_now (drain counter → DB)
  → assert CompanyDailyUsage h<HH> / CompanyMonthlyUsage d<DD> / total_credits
```

See `docs/ATOMIC_PURPOSE.md` § Hot Path Rule for the `kredis_counter :credit_usage` + `CompanyUsageSyncJob` drain details.

---

## 8. File Reference

| File | Purpose |
|------|---------|
| `app/controllers/concerns/companies/credit_deduction_concern.rb` | `after_action :run_credit_deduction` + `deduct_company_credits_for` DSL |
| `app/controllers/companies/application_controller.rb` | Includes the concern for all company controllers |
| `app/services/company_credit_deduction/base_service.rb` | Epic service: priority deduction + metering, subclass contract |
| `app/services/company_credit_deduction/companies/dashboards/index_service.rb` | Dashboard-access deduction (reference implementation) |
| `app/models/company_wallet.rb` | Two-balance wallet: `add_to!` / `deduct_from!` / `add_credits!`; status sync |
| `app/models/company_wallet_log.rb` | Audit log with `balance_type` enum (`main` / `promo`) |
| `app/models/company.rb` | `COMPANY_WORKFLOW_STATUS`, `suspended?`, `sync_credit_status!`, signup promo, suspension cache |
| `app/controllers/concerns/companies/suspended_company_concern.rb` | Web HTML redirect / JSON 403 |
| `app/controllers/concerns/mobile/companies/suspended_company_concern.rb` | Mobile 403 page |
| `config/initializers/constants.rb` | `CREDIT_USAGE_RATES`, `COMPANY_WORKFLOW_STATUS`, `SIGNUP_PROMO_CREDITS` |
| `db/migrate/20261031000001_remove_debt_from_company_wallets.rb` | Drops the debt column and discards old debt log rows |
| `spec/support/credit_wallet_helper.rb` | **Reusable `seed_random_wallet!` helper (clears signup promo + randomized seeding)** |
| `spec/services/credit_deduction_boundary_spec.rb` | Mechanical guard: jobs/imports never call deduction |
| `spec/services/company_credit_deduction/base_service_spec.rb` | Priority/deduction/metering coverage |
| `spec/services/company_credit_deduction/companies/dashboards/index_service_spec.rb` | Dashboard service contract |
| `spec/requests/companies/credit_deduction_spec.rb` | after_action filter behavior (JSON-only, rescue, payload) |
| `app/controllers/companies/usage_controller.rb` | Usage page: wallet/daily/monthly JSON + opt-in `enable_logging` / `disable_logging` endpoints + window log feed |
| `spec/features/companies/usages/show_spec.rb` | Usage-page toggle E2E (empty default layout → record → stop clears) |
| `spec/features/companies/dashboards/index_spec.rb` | End-to-end dashboard deduction scenarios |
| `spec/features/companies/credit_deduction_e2e_spec.rb` | **E2E js:true — Kredis delta → SyncJob → Daily/Monthly DB** |

---

## 9. See Also

- `docs/ATOMIC_PURPOSE.md` — the credit chain (`CompanyTransaction → CompanyInvoice → CompanyOrder → CompanyWallet`) and the atomic-purpose pattern; the wallet's per-balance entry points are called by `CompanyCreditDeduction::*` services
- `docs/CONSTANTS.md` — constant conventions (`CREDIT_USAGE_RATES` is the single source of action costs)

---

*End of document*
