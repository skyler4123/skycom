# Skycom Credit Deduction System

> **Status**: Live. Credit deduction is controlled at the **controller action level** via an `after_action` filter, and the deduction logic lives in a dedicated service class hierarchy (`CompanyCreditDeduction::*`).

---

## 1. Overview

Every credit-consuming action (dashboard access, order creation, customer creation, ...) must leave a trail: the wallet balance moves and usage is metered. This document defines **how** those deductions are wired and executed.

### The Two Rules

1. **Never deduct inline in a controller action.** The demo pattern (`credit_warning = deduct_dashboard_credits` — a private controller method that mutates the wallet inside the action body) is deprecated: it couples business logic to the controller, duplicates the deduct/meter/rescue code in every action, and is not scalable.
2. **Deduction is a filter concern; the logic belongs to a service class.** Each controller *declares* which `CompanyCreditDeduction::*` service runs for which action. The `after_action` filter executes the service after a successful JSON response.

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
| **Successful responses only** | `response.successful?` — 4xx/5xx never deduct |
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
  │
  ├── deduct promo balance first     (drain as much as possible)
  ├── deduct main balance second     (drain the remainder)
  ├── absorb remainder into debt     (only when promo + main are exhausted)
  │
  └── company.record_credit_usage!(cost)   ← Kredis counter, always
```

**Never raises for an insufficient balance.** When promo and main are both empty, the uncovered cost is absorbed by `debt_credit_balance` (normally 0). Deduction "always succeeds" — the request is never blocked by a low balance.

---

## 4. The Multi-Balance Wallet

**File**: `app/models/company_wallet.rb`

The wallet stores credit balance **numbers only** (atomic-purpose pattern — no business logic). The `CompanyCreditDeduction::*` services own the priority rules.

### Balances

| Column | Purpose | Top-up target? | Deduct order |
|--------|---------|----------------|--------------|
| `main_credit_balance` | Purchased credits (top-ups land here) | ✅ Yes (`add_credits!`) | 2nd |
| `promo_credit_balance` | Promotional credits (signup bonus, campaigns) | ❌ No | **1st** |
| `debt_credit_balance` | Absorbed shortfall when promo + main are 0. Normally 0. | ❌ No | 3rd (accumulates) |

> **Note**: `credit_balance` was renamed to `main_credit_balance` in the multi-balance migration (`20260821000001_add_multi_balance_to_company_wallets.rb`). Top-up behavior is unchanged — `add_credits!` still lands on the main balance.

> **Debt behavior is TBD**: what happens when `debt_credit_balance > 0` (blocking, debt ceiling, repayment) is handled in a future iteration.

### Low-Level API (the only wallet mutation entry points)

```ruby
wallet.add_credits!(amount:, source:, description:)                    # top-up → main only
wallet.add_to!(balance: :promo, amount:, source:, description:)        # grant promo credits
wallet.deduct_from!(balance: :main, amount:, source:, description:)   # atomic per-balance deduct
```

- Every mutation is a **conditional UPDATE** (single balance ≥ amount) — no concurrent overdraw; `lock_version` provides optimistic locking.
- `deduct_from!` raises `CompanyWallet::InsufficientCreditsError` only when that **single** balance lacks funds — the `CompanyCreditDeduction::BaseService` orchestrates across balances so this never surfaces in the deduction path.
- Every mutation writes a `CompanyWalletLog` audit row with `balance_type` (`main` / `promo` / `debt`) + before/after snapshots.
- Balance keys are validated against `CompanyWallet::BALANCES` (single-file constant) — unknown keys raise `ArgumentError`.

---

## 5. Warning & Balance Display (Separate Concern)

The deduction service **only cares about deducting**. It returns no warning message. Insufficient-balance feedback is a separate concern, handled by whichever logic owns the display — e.g. the dashboard JSON already exposes the full wallet state:

```json
{
  "wallet": {
    "main_credit_balance": 98,
    "promo_credit_balance": 0,
    "debt_credit_balance": 0,
    "currency": "USD"
  }
}
```

The frontend (or future alerting logic) decides what to surface from those numbers. The old `credit_warning` JSON key was removed with the demo pattern.

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

**4. Specs** (TDD — write first):

```ruby
# spec/services/company_credit_deduction/companies/dashboards/export_service_spec.rb
# + request-level coverage in spec/requests/companies/credit_deduction_spec.rb
```

---

## 7. File Reference

| File | Purpose |
|------|---------|
| `app/controllers/concerns/companies/credit_deduction_concern.rb` | `after_action :run_credit_deduction` + `deduct_company_credits_for` DSL |
| `app/controllers/companies/application_controller.rb` | Includes the concern for all company controllers |
| `app/services/company_credit_deduction/base_service.rb` | Epic service: priority deduction + metering, subclass contract |
| `app/services/company_credit_deduction/companies/dashboards/index_service.rb` | Dashboard-access deduction (reference implementation) |
| `app/models/company_wallet.rb` | Multi-balance wallet: `add_to!` / `deduct_from!` / `add_credits!` |
| `app/models/company_wallet_log.rb` | Audit log with `balance_type` enum |
| `config/initializers/constants.rb` | `CREDIT_USAGE_RATES` (per-action costs) |
| `db/migrate/20260821000001_add_multi_balance_to_company_wallets.rb` | `main_credit_balance` rename + `promo_credit_balance` + `debt_credit_balance` + `balance_type` |
| `spec/services/company_credit_deduction/base_service_spec.rb` | Priority/deduction/metering coverage |
| `spec/services/company_credit_deduction/companies/dashboards/index_service_spec.rb` | Dashboard service contract |
| `spec/requests/companies/credit_deduction_spec.rb` | after_action filter behavior (JSON-only, rescue, payload) |
| `spec/features/companies/dashboards/index_spec.rb` | End-to-end dashboard deduction scenarios |

---

## 8. See Also

- `docs/ATOMIC_PURPOSE.md` — the credit chain (`CompanyTransaction → CompanyInvoice → CompanyOrder → CompanyWallet`) and the atomic-purpose pattern; the wallet's per-balance entry points are called by `CompanyCreditDeduction::*` services
- `docs/CONSTANTS.md` — constant conventions (`CREDIT_USAGE_RATES` is the single source of action costs)

---

*End of document*
