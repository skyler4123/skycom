# Skycom Billing System

## 1. Overview

Skycom implements a **usage-based billing engine** with a **dual-wallet system** and a **circuit breaker** for access control. The system meters every business action, generates monthly invoices, and automatically settles them from the company's wallet — falling back to voluntary payment via QR/bank transfer when balances are insufficient.

### Architecture

```
[MeteringConcern] ──► record_usage! ──► Redis daily counter (Kredis)
                                          │
                   ┌─ SyncDailyMetricJob (1h)  ─► DailyMetricLog (PostgreSQL) ──► overages
                   │
[SyncDailyFeatureJob (6h)] ──► DailyFeatureLog (PostgreSQL) ──► per-feature proration
                   │
[MonthlyBillingJob] ──► CalculatorService ──► InvoiceService ──► BillingInvoice (unpaid)
                                                                 │
                                          after_create_commit ──┘
                                                 │
                                                 ▼
                          auto_settle_unpaid_invoices (CircuitBreakerConcern)
                                                 │
                                                 ▼
                          SettlementService.settle_all
                          ├── Wallet sufficient  ─► invoice.paid, try_reactivate!
                           └── Wallet insufficient ─► invoice.overdue, flag_unpaid!
                                                    │
                                                    ▼
                           suspension_at set ─► is_accessible? false ─► check_accessable (Authorizable)
                                                    │
                          [Voluntary payment via BillingController#pay_all]
                                                    │
                                                    ▼
                          settle_all ─► try_reactivate! ─► active
```

---

## 2. Company Circuit Breaker

The circuit breaker controls company operational state via `lifecycle_status`, `has_unpaid_invoices_at`, and `suspension_at`.

**File**: `app/models/concerns/company/circuit_breaker_concern.rb`

### 2.1 Lifecycle Status

| Status | Value | Behavior | Trigger |
|--------|-------|----------|---------|
| `active` | 0 | Full operations — all features work normally | Default; reached via `try_reactivate!` when all invoices paid |
| `suspended` | 3 | Blocked — redirected to billing page; `is_accessible?` returns false | `SyncSuspensionJob` runs daily at midnight when `suspension_at` has passed |
| `disabled` | 30 | Terminal — no transitions out | Company deletion request |

### 2.2 has_unpaid_invoices_at (Billing Timestamp)

A datetime column on `companies` that records when the company first had unpaid invoices. This is a **billing indicator only** — it does not affect operational access. The billing dashboard uses it to show a warning banner.

- **Set** by `flag_unpaid!` to `Time.current` when unpaid invoices exist
- **Cleared** by `try_reactivate!` when all invoices are paid
- Checked by `set_billing_warning` in `ApplicationController`: shows flash message when invoices have been unpaid for more than 5 days

### 2.3 suspension_at (The Deadline)

`suspension_at` is the timestamp deadline before automatic suspension. It is set as a grace period (end of month) and cleared on reactivation.

- **Set** by `flag_unpaid!` to `Time.current.end_of_month` (gives runway until month end)
- **Extendable** by admin — push the date forward to keep the company accessible
- **Cleared** by `try_reactivate!` when all invoices are paid
- **Checked** by `SyncSuspensionJob` daily at midnight:
  - If `suspension_at <= Time.current` and company is not already `suspended` or `disabled` → `mark_suspended!`

### 2.4 is_accessible? (Access Gate)

**`is_accessible?`** returns `false` when `lifecycle_status_suspended?`:
- `suspended` → not accessible → `check_accessable` redirects to billing page
- `active` / `disabled` → accessible (disabled is terminal but still returnable)

**`check_accessable`** is a `before_action` in the `Companies::Authorizable` concern that redirects to `company_billing_path` when `!current_company.is_accessible?`.

### 2.5 State Transitions

```
                  flag_unpaid! (unpaid invoices exist)
    active  ────────────────────────────────────────►  active (*)
       ▲      (has_unpaid_invoices = true,                  │
       │       suspension_at = end_of_month)                │
       │                                                    │  suspension_at passes
       │                                                    ▼
       │                                              suspended
       │                                                    │
       │              try_reactivate!                       │
       └────────────────────────────────────────────────────┘
              (all invoices paid)

(*) Company stays active until suspension_at passes and SyncSuspensionJob marks it suspended.
```

### 2.6 Key Methods

| Method | Description |
|--------|-------------|
| `flag_unpaid!` | Sets `has_unpaid_invoices_at: Time.current` + `suspension_at: end_of_month`. Does NOT change `lifecycle_status`. Idempotent. Raises if `disabled`. |
| `mark_suspended!` | Sets `lifecycle_status: :suspended`. Called by `SyncSuspensionJob` when deadline passes. Idempotent. |
| `try_reactivate!` | If no unpaid/overdue invoices remain → `lifecycle_status: :active`, `suspension_at: nil`, `has_unpaid_invoices_at: nil`. No-op if `disabled`. |
| `is_accessible?` | `true` when not `lifecycle_status_suspended?` |
| `auto_settle_unpaid_invoices` | Triggered on balance change + after unpaid invoice creation. Calls `SettlementService.settle_all`. Re-entry guarded. |

---

## 3. BillingContract (Feature Gating)

The BillingContract is the source of truth for what features a company can access and how usage is priced.

**File**: `app/models/billing_contract.rb`

### 3.1 Feature Gating

```ruby
company.feature_enabled?("analytics_dashboard")  # => true/false
```

The check traverses:
```
Company
  └── active_billing_contract (currently_active)
        └── contract_features (active)
              └── matches BillingResource by name + resource_type: :addon_feature
```

| Layer | Check |
|-------|-------|
| **Backend (Ruby)** | `Company#feature_enabled?(:key)` via `BillingConcern` |
| **Frontend (JS)** | `currentContract().feature_enabled?("key")` from client cache |

### 3.2 Billing Resources

`BillingResource` is the global catalog of all metered and add-on features:

| Resource Type | Examples | Purpose |
|---------------|----------|---------|
| `volumetric` | orders, storage_mb, employees, branches, customers, api_calls, stock_mutations | Metered usage with allowance + overage pricing |
| `addon_feature` | hrm_attendance, analytics_dashboard, custom_roles, open_api, sso_saml | Per-feature monthly add-on toggle |

### 3.3 Pricing Storage

| Join Table | Stores | Links |
|------------|--------|-------|
| `ContractFeature` | `monthly_flat_price_cents` | BillingContract ↔ addon_feature BillingResource |
| `ContractMetric` | `free_allowance` + `unit_price_cents` | BillingContract ↔ volumetric BillingResource |

---

## 4. Wallet System

Each company has two balance accounts (stored as `*_balance_cents` integer columns on Company):

| Balance | Source | Deduction Order |
|---------|--------|-----------------|
| **`promo_balance_cents`** | Promotional credits from Skycom (e.g., +$10 new company bonus) | FIRST |
| **`main_balance_cents`** | Company deposits from past payments or overpayments | SECOND |

### 4.1 WalletTransaction (Audit Trail)

Every balance change is recorded in `WalletTransaction`:

| Field | Description |
|-------|-------------|
| `transaction_type` | `top_up`, `deduction`, `refund`, `promo_credit` |
| `amount_cents` | Amount of this transaction |
| `balance_before_cents` / `balance_after_cents` | Main balance snapshots |
| `promo_balance_before_cents` / `promo_balance_after_cents` | Promo balance snapshots |
| `billing_invoice` | Reference to the triggering invoice |

**File**: `app/models/wallet_transaction.rb`

---

## 5. Monthly Invoice Cycle

### 5.1 MonthlyBillingJob

**File**: `app/jobs/billing/monthly_billing_job.rb`
**Schedule**: 1st of each month at 00:00 (`config/recurring.yml`)
**Scope**: `Company.where.not(lifecycle_status: %i[disabled suspended])`

```ruby
def process_company(company)
  result = CalculatorService.call(company)        # 1. Compute charge
  return if result.total_cents.zero?

  invoice = InvoiceService.call(company, result)   # 2. Create unpaid BillingInvoice
  return unless invoice

  company.flag_unpaid! if company.billing_invoices.unpaid_or_overdue.exists?  # 3. Set deadline
end
```

> **Note**: The job does NOT call SettlementService directly. Auto-settlement happens reactively via the `after_create_commit` callback on BillingInvoice (see Section 6).

### 5.2 CalculatorService

**File**: `app/services/billing/calculator_service.rb`

Computes monthly charge from:
1. Base contract price (if any)
2. Add-on feature flat prices (`ContractFeature.monthly_flat_price_cents`), **daily-prorated per feature** by the number of calendar days that specific feature was active (see Section 10.5)
3. Volumetric overage: `(usage − free_allowance) × unit_price` per `ContractMetric` (NOT prorated — pure usage-based)

**Per-feature proration rules:**
- `feature_active_days == 0` → $0 (feature was never enabled, or company was suspended the entire period)
- `feature_active_days >= days_in_period` → full monthly total (exact advertised price, no rounding drift)
- otherwise → `(monthly_flat_price × feature_active_days) / days_in_period` (integer division → cents)

Returns a `Result` struct with `total_cents` and a `Breakdown` struct exposing:
- `base_cents` — contract fixed monthly price
- `features_cents` — sum of per-feature prorated add-on feature prices
- `overages` — hash of `resource_name => overage_cents`
- `days_in_period` — calendar days in the month (e.g., 28–31)

### 5.3 InvoiceService

**File**: `app/services/billing/invoice_service.rb`

Creates a `BillingInvoice` from the CalculatorService result:
- Links to the company's active `BillingContract`
- Sets `price_cents`, `period_start`, `period_end`
- Sets `payment_status: :unpaid`
- Auto-generates `invoice_number` like `INV-202606-A1B2C3`

The `after_create_commit :attempt_auto_settlement` callback fires immediately after the invoice is committed to the database.

---

## 6. Auto-Settlement

### 6.1 The Dual Trigger

`auto_settle_unpaid_invoices` fires on two events:

| Trigger | Callback | When |
|---------|----------|------|
| Balance change | `after_update` on Company (CircuitBreakerConcern) | `main_balance_cents` or `promo_balance_cents` changed (e.g., top-up) |
| New unpaid invoice | `after_create_commit` on BillingInvoice | Invoice created with `payment_status: :unpaid` |

Both call `company.auto_settle_unpaid_invoices` → `Billing::SettlementService.settle_all(company)`.

### 6.2 Re-Entry Guards

Three levels of guards prevent infinite loops:

1. **Company-level** (CircuitBreakerConcern): `Thread.current[:__settling_company_id]` — prevents the same company from being settled concurrently
2. **Company set** (SettlementService.settle_all): `Thread.current[:__settling_companies]` Set — prevents nested `settle_all` calls
3. **Invoice-level** (SettlementService.call): `Thread.current[:__settling_invoice_ids]` Set — prevents the same invoice from being settled twice

Balance mutations inside SettlementService use `update_columns` (bypasses callbacks) to prevent the CircuitBreakerConcern `after_update` from re-entering settlement.

### 6.3 Guard Conditions in auto_settle_unpaid_invoices

```ruby
def auto_settle_unpaid_invoices
  return if Thread.current[:__settling_company_id] == id  # already settling
   return if lifecycle_status_disabled?                     # terminal state (suspended jobs skip via scope)
  return unless main_balance_cents.positive? || promo_balance_cents.positive?  # no money
  return unless billing_invoices.unpaid_or_overdue.exists? # nothing to pay
  # ... proceed to settle
end
```

---

## 7. SettlementService

**File**: `app/services/billing/settlement_service.rb`

### 7.1 SettlementService.call (Single Invoice)

Deduction algorithm:

```
1. total = invoice.price_cents
2. If total == 0 → mark_paid, done
3. company.with_lock do:
   a. remaining = deduct_from_promo(total)
      - If promo >= total: promo -= total, remaining = 0
      - Else: promo = 0, remaining = total - promo_before
   b. remaining = deduct_from_main(remaining)
      - If main >= remaining: main -= remaining, remaining = 0
      - Else: main = 0, remaining -= main_before
   c. If remaining > 0:
      - flag_unpaid! (sets has_unpaid_invoices + suspension_at)
      - invoice.payment_status = :overdue
   d. Else:
      - invoice.payment_status = :paid
4. Record WalletTransaction (before/after snapshots)
```

### 7.2 SettlementService.settle_all (Batch)

```ruby
result = Billing::SettlementService.settle_all(company)
# => { paid_count: Integer, remaining_cents: Integer }
```

Processes all unpaid/overdue invoices **oldest first** (ordered by `created_at`), stopping when the wallet is exhausted. Returns:
- `paid_count` — number of invoices fully paid
- `remaining_cents` — total unpaid amount still outstanding (for QR/bank transfer display)

### 7.3 Reactivation Side Effect

When an invoice is marked `paid`:
- `BillingInvoice#after_update :try_reactivate_company` fires
- This calls `company.try_reactivate!`
- If no unpaid/overdue invoices remain → `lifecycle_status: :active`, `suspension_at: nil`, `has_unpaid_invoices_at: nil`

---

## 8. Voluntary Payment

When the wallet is insufficient, the company owner must pay the remaining amount via QR/bank transfer.

### 8.1 BillingController

**File**: `app/controllers/companies/billing_controller.rb`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/companies/:id/billing` | GET | View outstanding invoices + wallet balances |
| `/companies/:id/billing/pay` | POST | Settle all outstanding invoices |

The controller is **exempt from `check_accessable`** so blocked companies can still pay their bills.

### 8.2 pay_all Response

```json
{
  "message": "All invoices paid. Account reactivated!",
  "paid_count": 3,
  "reactivated": true,
  "remaining_cents": 0
}
```

When `remaining_cents > 0`, the frontend displays QR/bank transfer instructions for the remaining amount. Once the owner tops up their wallet externally, the `after_update` callback on Company (balance change) triggers `auto_settle_unpaid_invoices` again — automatically paying any remaining invoices.

---

## 9. hide_billing_alerts

**Column**: `companies.hide_billing_alerts` (boolean, default `false`, null `false`)

When `true`, suppresses the past_due warning flash message displayed by `ApplicationController#set_billing_warning`.

| Effect | Behavior |
|--------|----------|
| Past due flash warning | **Suppressed** |
| `check_accessable` (access blocking) | **Unaffected** — still blocks when `suspended` |
| `flag_unpaid!` / `try_reactivate!` | **Unaffected** — lifecycle transitions still fire |

This is a **passive UI toggle** — it does not affect billing logic, access control, or settlement. It only hides the visual warning banner for companies with `has_unpaid_invoices_at` set.

---

## 10. Usage Metering

### 10.1 MeteringConcern

**File**: `app/models/concerns/metering_concern.rb`

Auto-increments Redis usage counters when business records are created. Included by models that should count toward billing volumetric metrics:

```ruby
class Order < ApplicationRecord
  include MeteringConcern
  metered_as :orders  # key must match a BillingResource name
end
```

On `Order.create` → `after_commit` fires → `company.record_usage!("orders")` → Kredis `INCR` on a daily-keyed Redis key.

### 10.2 Redis Counter Key Pattern

```
c:<uuid>:<resource_key>:<YYYYMMDD>
```

Example: `c:abc-123:orders:20260623`

Counters use `Kredis.integer` with a 36h TTL — Redis is the source of truth for the current day.

### 10.3 DailyMetricLog (PostgreSQL Persistence)

**File**: `app/models/daily_metric_log.rb`

Every 4 hours, `SyncDailyMetricJob`:
1. SCANs Redis for metering keys
2. Reads counters via `company.meter_usage` (Kredis with DB fallback on Redis restart)
3. Upserts one `DailyMetricLog` row per company + resource + day

This creates a permanent, queryable history. The `DailyMetricLog` table stores `company_id`, `billing_resource_id`, `log_date`, and `usage_count`.

### 10.4 Billing Concern Helpers

**File**: `app/models/concerns/company/billing_concern.rb`

| Method | Description |
|--------|-------------|
| `record_usage!(key, quantity: 1)` | Increments today's Redis counter |
| `meter_usage(key, log_date:)` | Reads counter (Redis today, or DailyMetricLog for past dates) |
| `wallet_balance_cents` | `promo_balance_cents + main_balance_cents` |
| `debt_ceiling_reached?` | `wallet_balance_cents < soft_debt_threshold_cents` |

### 10.5 Per-Feature Day Tracking (Daily Proration Source of Truth)

Add-on feature prices are daily-prorated per feature. The source of truth for "was this feature active on this date?" is `DailyFeatureLog`.

**File**: `app/models/daily_feature_log.rb`

- One row per company + contract_feature + calendar date (uniqueness enforced by `[company_id, contract_feature_id, log_date]` index)
- A row existing means "the feature was active AND the company was accessible on that date"; absence means the feature was disabled or the company was suspended
- Read by `CalculatorService#compute_prorated_features` at invoice time — each feature is prorated independently

**File**: `app/jobs/billing/sync_daily_feature_job.rb`

Idempotent 6-hour snapshot job:
1. Iterates all non-disabled, non-suspended companies via `find_each(batch_size: 50)`
2. Calls `company.is_accessible?` — if true, iterates all active `ContractFeature` records
3. `DailyFeatureLog.find_or_create_by!(company:, contract_feature:, log_date:)` per feature
4. The unique index collapses duplicate inserts across the 4 daily runs into a single row
5. Per-company rescue so one bad record doesn't abort the batch

**Why 6-hour frequency?** If a feature is enabled at 10:00 AM, the 06:00 or 12:00 run already recorded it. The company got 10+ hours of value → fair to bill for that 1 calendar date. The unique index guarantees no double-counting regardless of how many runs fire.

**Schedule** (`config/recurring.yml`): `every 6 hours`

---

## 11. File Reference

| File | Lines | Purpose |
|------|-------|---------|
| `app/models/billing_contract.rb` | 38 | Source-of-truth contract: enabled features, pricing, allowances |
| `app/models/billing_invoice.rb` | 42 | Monthly invoice; auto-settlement + reactivation callbacks |
| `app/models/billing_resource.rb` | 21 | Global catalog of volumetric + addon_feature resources |
| `app/models/contract_feature.rb` | 29 | Join: BillingContract ↔ addon_feature (flat monthly price) |
| `app/models/contract_metric.rb` | 31 | Join: BillingContract ↔ volumetric (allowance + overage price) |
| `app/models/daily_metric_log.rb` | 26 | Persisted daily metric snapshot from Redis (volumetric) |
| `app/models/daily_feature_log.rb` | 30 | Persisted daily feature-active-day snapshot (source of truth for per-feature proration) |
| `app/models/wallet_transaction.rb` | 34 | Audit trail for every wallet balance change |
| `app/models/concerns/company/billing_concern.rb` | 66 | Feature gating, wallet helpers, Redis metering |
| `app/models/concerns/company/circuit_breaker_concern.rb` | 75 | Lifecycle transitions, suspension_at, is_accessible?, auto_settle_unpaid_invoices |
| `app/jobs/billing/sync_suspension_job.rb` | 28 | Daily midnight cron: marks companies suspended when suspension_at passes |
| `app/models/concerns/metering_concern.rb` | 39 | Auto-increments Redis counters on record creation |
| `app/services/billing/calculator_service.rb` | 96 | Computes monthly charge (base + prorated features + overages) |
| `app/services/billing/invoice_service.rb` | 45 | Creates BillingInvoice from CalculatorService result |
| `app/services/billing/settlement_service.rb` | 162 | Deducts invoice from wallet; re-entry guarded; returns paid_count + remaining_cents |
| `app/services/billing/seed_resources_service.rb` | 58 | Seeds BillingResource catalog (7 volumetric + 12 addon) |
| `app/jobs/billing/monthly_billing_job.rb` | 42 | Monthly invoice creation for non-disabled companies |
| `app/jobs/billing/sync_daily_metric_job.rb` | 64 | Hourly sync of Redis counters → DailyMetricLog |
| `app/jobs/billing/sync_daily_feature_job.rb` | 34 | 6-hourly snapshot of active features → DailyFeatureLog |
| `app/controllers/companies/billing_controller.rb` | 56 | Billing portal: view + pay outstanding invoices; exempt from check_accessable |

---

## 12. Complete Lifecycle Example

```
Day 1:  Company active, promo_balance $10, main_balance $0
        Orders: 250 (allowance 200, overage 50 × $0.10 = $5)
        Add-on features: analytics_dashboard ($5/mo)

Day 1 (00:00): MonthlyBillingJob runs
  → CalculatorService: total_cents = $5 (overage) + $5 (feature) = $10
  → InvoiceService: creates BillingInvoice(price_cents: 1000, unpaid)
  → after_create_commit fires
  → auto_settle_unpaid_invoices
  → SettlementService.settle_all
    → Invoice #1 ($10): deduct from promo_balance ($10 → $0), remaining = 0
    → invoice.payment_status = :paid
    → try_reactivate! → already active, no-op
  → flag_unpaid! NOT called (already paid, no unpaid invoices remain)

Day 15: Company used another 100 orders overage = $10 more owed
        (but this only bills at next month — no mid-month invoices)

Next month (Day 1): MonthlyBillingJob runs again
  → CalculatorService: total_cents = $10 (new overage) + $5 (feature) = $15
  → InvoiceService: creates BillingInvoice(price_cents: 1500, unpaid)
  → after_create_commit fires
  → auto_settle_unpaid_invoices
  → SettlementService.settle_all
    → promo_balance $0, main_balance $0 → nothing to deduct
    → remaining $15 > 0 → flag_unpaid!, invoice.overdue
  → suspension_at set to end of month

Day 1 (afternoon): Owner sees warning, navigates to /billing
  → BillingController#pay_all
  → settle_all → still no wallet → remaining_cents: 1500
  → Frontend shows QR for $15 bank transfer

Day 3: Owner transfers $15, support credits main_balance
  → Company.update! (main_balance_cents: 1500)
  → after_update fires (saved_change_to_main_balance_cents?)
  → auto_settle_unpaid_invoices
  → SettlementService.settle_all
    → Invoice: deduct from main_balance ($15 → $0), remaining = 0
    → invoice.payment_status = :paid
    → try_reactivate! → lifecycle_status: active, suspension_at: nil, has_unpaid_invoices_at: nil
    → Company fully restored
```

---

*End of documentation*/se