# Billing Engine — Backend Design

> Date: 2026-06-24
> Status: Approved design
> Implements: ROADMAP.md Phases 1, 3, 4 (backend only)

---

## 1. Architecture Overview

Three-phase backend pipeline built on existing billing models (last commit). Relational approach using `ContractFeature`/`ContractMetric` join tables (not JSONB).

```
┌─────────────────────────────────────────────────────────┐
│ Phase 1: Real-Time Runtime (every request)               │
│                                                         │
│  Feature Check ──► Company#feature_enabled?(:key)       │
│                    └── active_billing_contract           │
│                        └── contract_features.exists?     │
│                                                         │
│  Usage Meter ──► after_commit on: :create               │
│                    └── Redis INCR (daily key)           │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 2: Nightly Sync (23:55 daily)                      │
│                                                         │
│  SyncDailyUsageJob                                       │
│    └── Scan Redis keys → DailyUsageLog upsert           │
│    └── Delete processed Redis keys                      │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 3: End-of-Month Billing (1st of month)             │
│                                                         │
│  MonthlyBillingJob                                       │
│    ├── CalculatorService  (compute charges)             │
│    ├── InvoiceService     (create BillingInvoice)       │
│    └── SettlementService  (deduct wallets + trip CB)    │
└─────────────────────────────────────────────────────────┘
```

---

## 2. New Migrations

### Migration A — Wallet fields on `companies`

Add these columns to the `companies` table:

| Column | Type | Default | Description |
|--------|------|---------|-------------|
| `promo_balance_cents` | integer | 0 | Promotional credit balance (deducted first) |
| `main_balance_cents` | integer | 0 | Company-deposited balance (deducted second) |
| `soft_debt_threshold_cents` | integer | -10000 | Max negative combined balance before read_only |

### Migration B — `wallet_transactions` table

| Column | Type | Description |
|--------|------|-------------|
| `company_id` | uuid, FK | Scoped to company |
| `billing_invoice_id` | uuid, FK, nullable | Links to invoice if deduction |
| `transaction_type` | integer (enum) | top_up, deduction, refund, promo_credit |
| `amount_cents` | integer | Transaction amount |
| `currency` | string | Default "USD" |
| `balance_before_cents` | integer | Snapshot of main_balance before |
| `balance_after_cents` | integer | Snapshot of main_balance after |
| `promo_balance_before_cents` | integer | Snapshot of promo_balance before |
| `promo_balance_after_cents` | integer | Snapshot of promo_balance after |
| `description` | text | Human-readable explanation |
| `timestamps` | — | created_at, updated_at |

Index: `[company_id, created_at]` for chronological lookup.

---

## 3. Data Flow

### 3.1 Feature Entitlement Gate

```
Employee clicks "Multi-Warehouse"
  │
  ▼
Company#feature_enabled?("inventory_advanced")
  │
  ├── active_billing_contract = billing_contracts.currently_active.first
  │     └── scope: lifecycle_status: :active, start_date <= now, (end_time IS NULL OR end_time >= now)
  │
  ├── resource = BillingResource.find_by(name: "inventory_advanced", resource_type: :addon_feature)
  │
  └── active_billing_contract.contract_features.exists?(billing_resource: resource)
        ├── true  → render feature
        └── false → return "feature not available"
```

### 3.2 Usage Metering (Redis INCR)

```
Order created (after_commit)
  │
  ▼
MeteringConcern#increment_usage_counter
  │
  └── key = "skycom:company:#{company_id}:orders:#{Date.current.strftime('%Y%m%d')}"
      Redis.incr(key)
```

Key pattern: `skycom:company:<uuid>:<resource_name>:<YYYYMMDD>`

### 3.3 Nightly Sync (Phase 2)

```
SyncDailyUsageJob (23:55 daily)
  │
  ├── SCAN Redis for keys matching "skycom:company:*:*:#{yesterday_yyyymmdd}"
  │
  ├── For each key:
  │     ├── Parse: company_id, resource_name, date
  │     ├── resource = BillingResource.find_by(name: resource_name)
  │     ├── DailyUsageLog.find_or_initialize_by(...)
  │     │     .update!(usage_count: redis_value)
  │     └── Redis.del(key)
```

### 3.4 Monthly Billing (Phase 3)

```
MonthlyBillingJob.perform_later (1st of month 00:00)
  │
  ├── Company.active.find_each do |company|
  │     │
  │     ├── CalculatorService.call(company)
  │     │     ├── base = contract.fixed_monthly_price_cents
  │     │     ├── features = contract.contract_features.active.sum(:monthly_flat_price_cents)
  │     │     ├── For each contract_metric:
  │     │     │     actual = DailyUsageLog.for_period(start, end).sum(:usage_count)
  │     │     │     overage = [actual - free_allowance, 0].max * unit_price_cents
  │     │     └── return { total_cents, breakdown }
  │     │
  │     ├── InvoiceService.call(company, calculator_result)
  │     │     └── BillingInvoice.create!(lifecycle_status: :final, payment_status: :unpaid)
  │     │
  │     └── SettlementService.call(invoice)
  │           ├── Deduct from promo_balance_cents first
  │           ├── Deduct from main_balance_cents second
  │           ├── Record WalletTransaction per deduction
  │           ├── If remaining > 0: invoice.update(payment_status: :overdue)
  │           │     └── company.circuit_breaker_trip!
  │           └── If fully covered: invoice.update(payment_status: :paid)
  │
  └── Log summary (companies processed, errors, total collected)
```

---

## 4. Wallet Deduction Algorithm

```
total_cents = breakdown.total

# Step 1: Deduct from promo balance
if company.promo_balance_cents >= total_cents
  company.promo_balance_cents -= total_cents
  remaining = 0
else
  remaining = total_cents - company.promo_balance_cents
  company.promo_balance_cents = 0
end

# Step 2: Deduct from main balance
if company.main_balance_cents >= remaining
  company.main_balance_cents -= remaining
  remaining = 0
else
  remaining -= company.main_balance_cents
  company.main_balance_cents = 0
end

# Step 3: Record transactions
WalletTransaction.create!(company:, billing_invoice: invoice, ...)
WalletTransaction.create!(company:, billing_invoice: invoice, ...) if both changed

# Step 4: Handle shortfall
if remaining > 0
  invoice.update!(payment_status: :overdue)
  company.circuit_breaker_trip!
end
```

---

## 5. Circuit Breaker

`Company::CircuitBreakerConcern` provides:
- `circuit_breaker_trip!` → sets `workflow_status: :read_only`
- `circuit_breaker_reset!` → sets `workflow_status: :active` (called when balance recovers)
- `after_update` callback on `main_balance_cents` change — auto-reset if balance recovers above threshold

When a company is `read_only`:
- No create/update/delete operations succeed (checked at application layer)
- Only reads and navigation work
- UI hides all forms/buttons, shows persistent banner

---

## 6. File Manifest

### New Files

| # | File | Type | Purpose |
|---|------|------|---------|
| 1 | `db/migrate/YYYYMMDDHHMMSS_add_wallet_fields_to_companies.rb` | Migration | Add promo_balance_cents, main_balance_cents, soft_debt_threshold_cents |
| 2 | `db/migrate/YYYYMMDDHHMMSS_create_wallet_transactions.rb` | Migration | Create wallet_transactions table |
| 3 | `app/models/wallet_transaction.rb` | Model | WalletTransaction with enum, validations, belongs_to |
| 4 | `app/models/concerns/company/billing_concern.rb` | Concern | feature_enabled?, active_billing_contract, wallet methods |
| 5 | `app/models/concerns/company/circuit_breaker_concern.rb` | Concern | circuit_breaker_trip!, circuit_breaker_reset! |
| 6 | `app/models/concerns/metering_concern.rb` | Concern | after_commit Redis INCR for countable models |
| 7 | `app/services/billing/calculator_service.rb` | Service | Compute total_cents + breakdown |
| 8 | `app/services/billing/invoice_service.rb` | Service | Create BillingInvoice from calculator result |
| 9 | `app/services/billing/settlement_service.rb` | Service | Deduct wallets, record transactions, trip breaker |
| 10 | `app/services/billing/seed_resources_service.rb` | Service | Populate billing_resources table |
| 11 | `app/jobs/billing/sync_daily_usage_job.rb` | Job | Nightly Redis → DailyUsageLog sync |
| 12 | `app/jobs/billing/monthly_billing_job.rb` | Job | Monthly billing orchestration |

### Modified Files

| # | File | Change |
|---|------|--------|
| 1 | `app/models/company.rb` | Add `include Company::BillingConcern`, `include Company::CircuitBreakerConcern`, `has_many :wallet_transactions` |
| 2 | `config/recurring.yml` | Add SyncDailyUsageJob schedule (23:55 daily) and MonthlyBillingJob (1st 00:00) |

### Files That Include `MeteringConcern`

Countable models that trigger Redis counters on create:

| Model | Resource Key | Trigger Event |
|-------|-------------|---------------|
| `Order` | `orders` | Order created (workflow_status: :paid) |
| `Employee` | `employees` | Employee created (lifecycle_status: :active) |
| `Branch` | `branches` | Branch created |
| `Customer` | `customers` | Customer created |

---

## 7. Existing Models (already committed)

| Model | File | Notes |
|-------|------|-------|
| `BillingResource` | `app/models/billing_resource.rb` | Catalog of metered resources + addon features |
| `BillingContract` | `app/models/billing_contract.rb` | Per-company contract with `currently_active` scope |
| `ContractFeature` | `app/models/contract_feature.rb` | Addon feature assignments (validates `addon_feature` type) |
| `ContractMetric` | `app/models/contract_metric.rb` | Volumetric metric config (validates `volumetric` type) |
| `BillingInvoice` | `app/models/billing_invoice.rb` | Monthly billing invoice (auto-generates INV-YYYYMM-XXXXXX) |
| `DailyUsageLog` | `app/models/daily_usage_log.rb` | Daily usage snapshots with `for_period` scope |

---

## 8. Error Handling

| Layer | Failure Mode | Behavior |
|-------|-------------|----------|
| MeteringConcern | Redis unavailable | Rescues `Redis::BaseConnectionError`, logs warning, does NOT block the create operation |
| SyncDailyUsageJob | Redis SCAN timeout | Logs error, retries on next run (idempotent) |
| SyncDailyUsageJob | Single key parse failure | Skips that key, logs warning, continues with rest |
| MonthlyBillingJob | Single company failure | Logs error, continues with next company |
| SettlementService | Balance insufficient | Creates overdue invoice, trips circuit breaker |
| CalculatorService | No active contract | Returns zero charges (free tier without contract) |

---

## 9. Testing Strategy

| Component | Test Type | Key Assertions |
|-----------|-----------|----------------|
| `Company::BillingConcern` | Unit | `feature_enabled?` returns true/false based on ContractFeature existence |
| `MeteringConcern` | Unit | Redis INCR called on create with correct key pattern |
| `SyncDailyUsageJob` | System | Redis keys → DailyUsageLog records, keys deleted |
| `Billing::CalculatorService` | Unit | Correct total with overages, features, base price |
| `Billing::InvoiceService` | Unit | Creates BillingInvoice with correct amounts |
| `Billing::SettlementService` | Unit | Wallet deduction order, WalletTransaction creation, circuit breaker trip |
| `Billing::MonthlyBillingJob` | System | End-to-end: companies processed, invoices created |
| `Company::CircuitBreakerConcern` | Unit | `trip!` sets read_only, `reset!` sets active |
| `WalletTransaction` | Unit | Validates transaction_type, tracks before/after balances |

---

## 10. Non-Goals (Frontend / Future)

- No `GET /companies/:id/usage` API endpoint (Phase 3 roadmap — frontend usage charts)
- No `GET /companies/:id/billing` API endpoint
- No feature management UI (enable/disable addons from settings)
- No credit card auto-charge or QR code generation
- No proration logic for mid-cycle feature changes
- These are explicitly scoped out of this BE-only plan.
