# Skycom Money Flow Architecture — The Absolute Rules

> **Status**: Target architecture. Some parts are implemented, some are aspirational. This document defines what every money-related code path **must** conform to.

---

## 1. Purpose

Skycom has two distinct domains where money moves:

| Domain | Direction | What Happens |
|--------|-----------|--------------|
| **Billing (B2B)** | Skycom → Company | Skycom charges the company for platform usage (metrics, features, plan) |
| **Commerce (B2C)** | Company → Customer | The company charges its customers for goods and services |

Both domains follow **the same canonical chain** of models. The rule is simple: **every cent that moves must leave a trail** — from catalog to contract to invoice to payment to payment method. No orphan money, no direct status flips.

---

## 2. The `Billing*` Naming Convention — System vs Company Resources

Skycom uses the `Billing*` prefix as a **namespace signal** to distinguish system-controlled money models from company-scoped business models.

### System-Level (Billing*) — Controlled by Skycom

Models prefixed with `Billing*` (e.g., `BillingResource`, `BillingContract`, `BillingInvoice`, `BillingTransaction`) are **platform-internal**. They have:

| Attribute | Detail |
|-----------|--------|
| **Scope** | Global (no `company_id`) or system-scoped — they are not company resources |
| **Who creates** | Skycom seeds them (rake task, onboarding). Companies **never** create `Billing*` records |
| **Who controls pricing** | Skycom sets prices centrally (per country via `country_code`). Companies do not set or negotiate individual `BillingResource` prices |
| **Purpose** | Define the platform's billing catalog and track internal money movement (what Skycom charges companies) |
| **Examples** | `BillingResource` (global catalog of metered resources + add-on features), `BillingContract` (per-company pricing plan), `BillingTransaction` (ledger entry) |

The central system model is **`BillingResource`**. It is Skycom's "menu" — a global catalog that lists **everything the platform can charge a company for**, with two resource types:

- **`volumetric`** — Usage-based metered counters (e.g., orders, storage in MB, employees, branches). These are tracked by the `MeteringConcern` and priced by overage unit.
- **`addon_feature`** — Flat monthly fees for premium features (e.g., `analytics_dashboard`, `hrm_attendance`, `custom_roles`).

Each `BillingResource` is seeded **per country** (`country_code: :us` or `:vn`) with market-specific pricing. For example, `analytics_dashboard` costs 500¢/mo in the US market but 125,000₫/mo in VN. Companies do not create, edit, or delete `BillingResource` records.

### Feature Gating via BillingContract

The `BillingContract` is the source of truth for what features a company can access:

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

Pricing is stored in join tables:

| Join Table | Stores | Links |
|------------|--------|-------|
| `ContractFeature` | `monthly_flat_price_cents` | BillingContract ↔ addon_feature BillingResource |
| `ContractMetric` | `free_allowance` + `unit_price_cents` | BillingContract ↔ volumetric BillingResource |

### Company-Scoped (No `Billing*` Prefix) — Controlled by the Company

Company-facing business models (`Product`, `Service`, `SubscriptionPlan`, `Order`, `Invoice`, etc.) have **no `Billing*` prefix**. They have:

| Attribute | Detail |
|-----------|--------|
| **Scope** | Per-company (`company_id` on every record) |
| **Who creates** | The company's employees (via dashboards, APIs, POS) |
| **Who controls pricing** | The company sets its own prices for its products/services |
| **Purpose** | Run the company's business — sell goods and services to its customers |
| **Examples** | `Product` (what the company sells), `Order` (a customer's purchase), `Invoice` (bill to customer) |

### Why the Distinction Matters

```
BillingResource.volumetric.first
# => #<BillingResource:0x... name: "orders", country_code: "us", resource_type: "volumetric">
# ↑ Skycom decides: "we charge $0.10 per overage order"
# ↑ NO company_id — this is a global catalog entry

Product.first
# => #<Product:0x... name: "Face Cream", company_id: "abc-123", price_cents: 2999>
# ↑ The company decides: "we sell Face Cream for $29.99"
# ↑ HAS company_id — this is the company's own catalog
```

The two catalogs never cross. A `BillingResource` is not a thing a company sells — it is a thing **Skycom sells to the company**. A `Product` is not something Skycom meters — it is something **the company sells to its customers**.

---

## 3. The Canonical Chain

```
Catalog / Resource
       │
       ▼
  Contract / Order
       │
       ▼
     Invoice
       │
       ▼
BillingTransaction /   ◄── Source of truth for money movement
     Payment                AND the sole gateway interface
       │
       ▼
  PaymentMethod         ◄── Defines HOW money moves (qr / redirect / cash)
```

Each domain maps real models to this chain:

| Layer | Billing (B2B) | Commerce (B2C) |
|-------|---------------|----------------|
| **Catalog** | `BillingResource` — **System-level global catalog**. Seeded by Skycom. Country-scoped pricing (US/VN). Two types: `volumetric` (metered usage counters: orders, storage_mb, employees, branches, customers, api_calls, stock_mutations) and `addon_feature` (flat monthly add-on fees: analytics_dashboard, hrm_attendance, custom_roles, etc.). No `company_id`. Companies **never** create `BillingResource` records. | `Product` / `Service` / `SubscriptionPlan` / etc. — **Company-scoped business catalog**. Belongs to a `company_id`. Company creates them, sets prices, defines categories/properties. Companies own their catalog entirely — Skycom only provides the schema. |
| **Contract** | `BillingContract` — per-company pricing plan, allowances, feature toggles, base price | `Order` — captures items (via `OrderAppointment`), quantities, unit prices, customer, branch |
| **Invoice** | `BillingInvoice` — monthly charge; `movement_type: :charge`, `target_balance: :main_balance`, `payment_status: unpaid/paid/overdue` | `Invoice` — bill to customer; `total_price`, `workflow_status` tracks lifecycle, `payment_status` derived from Payment sum (target) |
| **BillingTransaction** (B2B) / **Payment** (B2C) | `BillingTransaction` — ledger entry; records `amount_cents`, before/after snapshots of both wallet balances | `Payment` — payment record; needs `amount_cents`, `payment_method_id`, gateway fields + sync callback (target) |
| **Balance** | `BillingWallet` (future separate model; currently `company.main_balance_cents` + `company.promo_balance_cents`) | N/A — the customer pays directly, the company does not hold a balance for them |
| **PaymentMethod** | `PaymentMethod` where `business_type: :b2b` — system-level: wallet auto-debit, card-on-file, QR fallback for bank transfer | `PaymentMethod` where `business_type: :b2c` — customer-facing: Cash, MoMo, ZaloPay, VNPay, Credit Card, etc. |

---

## 4. The Absolute Rule

> **`Invoice.payment_status` MUST be derived from the sum of its `Payment`/`BillingTransaction` records.**

```
Invoice.payment_status  =  SUM(Payment/BillingTransaction.amount_cents) >= Invoice.price_cents
                              ? :paid
                              : :unpaid
```

This rule is enforced by callback on the model that records money movement:

```ruby
# BillingTransaction (already enforces this):
after_create  :sync_invoice_payment_status, unless: -> { amount_cents.zero? }
after_destroy :sync_invoice_payment_status

def sync_invoice_payment_status
  total = billing_invoice.billing_transactions.sum(:amount_cents)
  new_status = total >= billing_invoice.price_cents ? :paid : :unpaid
  return if billing_invoice.payment_status == new_status.to_s
  billing_invoice.update!(payment_status: new_status)
end
```

### What This Means

| Scenario | Behavior | Enforced By |
|----------|----------|-------------|
| Create a paid invoice without any payment record | ❌ **FORBIDDEN** — callback never fires, invoice stays `unpaid` | `after_create` callback on the payment model |
| Delete a payment (refund/void) | ✅ Invoice auto-reverts to `unpaid` | `after_destroy` callback on the payment model |
| Sum of payments exactly equals invoice price | ✅ Invoice transitions to `paid` | Callback computes `total >= price_cents` |
| Sum exceeds invoice price | ✅ Invoice is `paid` (overpayment credits go to wallet) | Callback computes `total >= price_cents` |
| Set `invoice.payment_status = :paid` directly in any code path | ❌ **FORBIDDEN** — no code may bypass the derivation | Review + lint |

### Exception: `price_cents == 0`

When an invoice has zero price (within-allowance usage), it may be auto-marked `paid` without a payment record. This is the only exception — nothing moved, nothing to record.

### 4.1 Payment/BillingTransaction as the Sole Gateway Interface

`BillingTransaction` (B2B) and `Payment` (B2C) are the **only** objects that communicate with external payment gateways. Neither invoices nor orders interact with gateways directly.

```
 BillingTransaction / Payment            Payment Gateway
    │                                       │
    ├── payment_method_id ────► determines how to call
    │     ├── mode: :qr       → generate QR code (offline)
    │     ├── mode: :redirect → redirect to hosted payment page
    │     ├── mode: :cash     → no gateway (manual receipt)
    │     └── mode: :api      → direct API call (Stripe, PayPal, etc.)
    │
    ├── gateway sends response
    │     ├── gateway_transaction_id (external reference)
    │     ├── status (success / failure / pending)
    │     └── settlement details (timestamp, fees, etc.)
    │
    ├── BillingTransaction/Payment updates itself from gateway response
    │     └── after_update :sync_invoice_payment_status
    │           └── Invoice.payment_status derived from SUM(payments)
    │
    └── Invoice / Order never talk to gateway
```

**How it works:**

1. A `BillingTransaction` or `Payment` is created with a `payment_method_id` FK pointing to a `PaymentMethod`
2. The `PaymentMethod.payment_mode` (qr/redirect/cash) determines HOW the gateway interaction works
3. For online payments, the record initiates the gateway call (API request or redirect)
4. The gateway responds — either synchronously (API callback) or asynchronously (webhook)
5. The gateway response updates the record (gateway_transaction_id, status, etc.)
6. The record's `after_create`/`after_update`/`after_destroy` callback calls `sync_invoice_payment_status`
7. The parent Invoice's `payment_status` is updated based on the sum of all its `BillingTransaction`/`Payment` records

**B2B example (QR bank transfer):**
```
BillingInvoice (unpaid)
  → BillingTransaction.create!(payment_method: b2b_qr)
    → PaymentMethod.payment_mode == :qr
      → render QR code for company to scan & pay
      → bank sends webhook → Rails receives it
        → BillingTransaction.update!(gateway_transaction_id: "ref-123", status: "completed")
          → after_update :sync_invoice_payment_status
            → BillingInvoice.payment_status → :paid
```

**B2C example (redirect to MoMo):**
```
Payment.create!(payment_method: momo, invoice: invoice)
  → PaymentMethod.payment_mode == :redirect
    → redirect customer to MoMo hosted page
    → customer authorizes and completes payment
    → MoMo redirects back with result params
    → Payment.update!(gateway_txn_id: "MOMO-456", ...)
      → after_update :sync_invoice_payment_status
        → Invoice.payment_status → :paid
```

**Key rule:** `BillingTransaction`/`Payment` is the bridge between Skycom's internal money flow and external financial systems. No other record type may initiate or receive gateway communication.

---

## 5. Domain 1: Billing (B2B) — Skycom Charges the Company

### 5.1 The Models

```
BillingResource (global catalog)
       │
       ├── resource_type: :volumetric  →  ContractMetric  →  BillingContract
       └── resource_type: :addon_feature →  ContractFeature →  BillingContract
                                                               │
                                                               ▼
                                                    BillingContract (per-company)
                                                         │
                                                         ├── fixed_monthly_price_cents
                                                         ├── contract_features (addon toggles)
                                                         ├── contract_metrics (allowances + unit prices)
                                                         └── lifecycle_status: :active | :expired | ...
                                                               │
                                                               ▼
                                                    BillingInvoice (created monthly)
                                                         │
                                                         ├── movement_type: :charge
                                                         ├── target_balance: :main_balance
                                                         ├── price_cents (computed from CalculatorService)
                                                         ├── payment_status: :unpaid (initially)
                                                         │     └── derived from BillingTransaction sum
                                                         │
                                                         └── has_many :billing_transactions
                                                               │
                                                               ▼
                                                    BillingTransaction (ledger entry)
                                                         │
                                                         ├── transaction_type: :deduction
                                                         ├── amount_cents
                                                         ├── balance_before_cents / balance_after_cents
                                                         ├── promo_balance_before_cents / promo_balance_after_cents
                                                         └── after_create → sync_invoice_payment_status
                                                               │
                                                               ▼
                                                    PaymentMethod (business_type: :b2b)
                                                         │
                                                         ├── payment_mode: :qr | :redirect | :cash
                                                         └── defines HOW the company pays Skycom
```

### 5.2 The Settlement Chain

```
MonthlyBillingJob (1st of month @ 00:00)
  │
  ├── 1. CalculatorService.call(company)
  │       ├── base = contract.fixed_monthly_price_cents
  │       ├── features = Σ prorated addon prices (via DailyFeatureLog)
  │       └── overages = Σ (usage - allowance) × unit_price (via DailyMetricLog)
  │
  ├── 2. InvoiceService.call(company, result)
  │       └── BillingInvoice.create!(payment_status: :unpaid)
  │             │
  │             └── after_create_commit :attempt_auto_settlement
  │                   │
  │                   └── Company#auto_settle_unpaid_invoices
  │                         │
  │                         └── SettlementService.settle_all(company)
  │                               │
  │                               ├── Process invoices oldest-first
  │                               ├── For each invoice:
  │                               │     ├── deduct_from_promo(price)     # promo balance first
  │                               │     ├── deduct_from_main(remaining)  # main balance second
  │                               │     │
  │                               │     ├── BillingTransaction.create!     ← Source of Truth
  │                               │     │     ├── balance_before/after snapshots
  │                               │     │     ├── promo_balance_before/after snapshots
  │                               │     │     └── after_create → sync_invoice_payment_status
  │                               │     │           ├── SUM(transactions) >= price? → :paid
  │                               │     │           └── invoice.update!(payment_status:)
  │                               │     │
  │                               │     └── if shortfall:
  │                               │           ├── company.flag_unpaid! (sets suspension_at)
  │                               │           └── invoice.update!(payment_status: :overdue)
  │                               │
  │                               └── company.try_reactivate! if all invoices now paid
  │
  └── 3. (If flag_unpaid! was called: company is now on a deadline)
          └── SyncSuspensionJob (daily @ 00:00)
                └── suspension_at passed? → mark_suspended!
```

#### 5.2.1 MonthlyBillingJob

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

The job does NOT call SettlementService directly. Auto-settlement happens reactively via the `after_create_commit` callback on BillingInvoice.

#### 5.2.2 CalculatorService

**File**: `app/services/billing/calculator_service.rb`

Computes monthly charge from:
1. Base contract price (if any)
2. Add-on feature flat prices (`ContractFeature.monthly_flat_price_cents`), **daily-prorated per feature** by the number of calendar days that specific feature was active
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

#### 5.2.3 InvoiceService

**File**: `app/services/billing/invoice_service.rb`

Creates a `BillingInvoice` from the CalculatorService result:
- Links to the company's active `BillingContract`
- Sets `price_cents`, `period_start`, `period_end`
- Sets `payment_status: :unpaid`
- Auto-generates `invoice_number` like `INV-202606-A1B2C3`

The `after_create_commit :attempt_auto_settlement` callback fires immediately after the invoice is committed to the database.

### 5.3 Auto-Settlement

Auto-settlement attempts to pay unpaid invoices from the company's wallet immediately after they are created or when the wallet balance changes.

#### 5.3.1 The Dual Trigger

`auto_settle_unpaid_invoices` fires on two events:

| Trigger | Callback | When |
|---------|----------|------|
| Balance change | `after_update` on Company (CircuitBreakerConcern) | `main_balance_cents` or `promo_balance_cents` changed (e.g., top-up) |
| New unpaid invoice | `after_create_commit` on BillingInvoice | Invoice created with `payment_status: :unpaid` |

Both call `company.auto_settle_unpaid_invoices` → `Billing::SettlementService.settle_all(company)`.

#### 5.3.2 SettlementService.call (Single Invoice)

**File**: `app/services/billing/settlement_service.rb`

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
4. Record BillingTransaction (before/after snapshots) — callback auto-syncs invoice.payment_status
```

#### 5.3.3 Batch Settlement

```ruby
result = Billing::SettlementService.settle_all(company)
# => { paid_count: Integer, remaining_cents: Integer }
```

Processes all unpaid/overdue invoices **oldest first** (ordered by `created_at`), stopping when the wallet is exhausted. Returns:
- `paid_count` — number of invoices fully paid
- `remaining_cents` — total unpaid amount still outstanding (for QR/bank transfer display)

#### 5.3.4 Re-Entry Guards

Three levels of guards prevent infinite loops:

1. **Company-level** (CircuitBreakerConcern): `Thread.current[:__settling_company_id]` — prevents the same company from being settled concurrently
2. **Company set** (SettlementService.settle_all): `Thread.current[:__settling_companies]` Set — prevents nested `settle_all` calls
3. **Invoice-level** (SettlementService.call): `Thread.current[:__settling_invoice_ids]` Set — prevents the same invoice from being settled twice

Balance mutations inside SettlementService use `update_columns` (bypasses callbacks) to prevent the CircuitBreakerConcern `after_update` from re-entering settlement.

```ruby
def auto_settle_unpaid_invoices
  return if Thread.current[:__settling_company_id] == id  # already settling
  return if lifecycle_status_disabled?                     # terminal state (suspended jobs skip via scope)
  return unless main_balance_cents.positive? || promo_balance_cents.positive?  # no money
  return unless billing_invoices.unpaid_or_overdue.exists? # nothing to pay
  # ... proceed to settle
end
```

#### 5.3.5 Balance Update Patterns

Company balances (`main_balance_cents`, `promo_balance_cents`) are updated **by the same service that creates the BillingTransaction**. The balance update and the transaction creation happen together as a unit:

**Deduction (SettlementService):**
```ruby
company.update_columns(main_balance_cents: main_after)  # bypasses callbacks
BillingTransaction.create!(
  company: company,
  billing_invoice: invoice,
  transaction_type: :deduction,
  amount_cents: amount,
  balance_before_cents: main_before,
  balance_after_cents: main_after,
)
```

**Top-Up:**
```ruby
invoice = BillingInvoice.create!(
  company: company, movement_type: :deposit,
  target_balance: :main_balance, price_cents: amount,
)

# After payment confirmation:
company.update_columns(main_balance_cents: company.main_balance_cents + amount)
BillingTransaction.create!(
  company: company, billing_invoice: invoice,
  transaction_type: :top_up, amount_cents: amount,
)
```

#### 5.3.6 Balance Recovery

If balances ever drift (e.g., manual DB changes), they can be reconstructed from transactions:

```ruby
def recompute_balances!
  update_columns(main_balance_cents: 0, promo_balance_cents: 0)
  billing_transactions.includes(:billing_invoice).find_each do |txn|
    invoice = txn.billing_invoice
    next unless invoice
    case [invoice.movement_type, invoice.target_balance]
    when ["deposit", "main_balance"]
      self.class.increment_counter(:main_balance_cents, id, by: txn.amount_cents)
    when ["charge", "main_balance"]
      self.class.decrement_counter(:main_balance_cents, id, by: txn.amount_cents)
    when ["deposit", "promo_balance"]
      self.class.increment_counter(:promo_balance_cents, id, by: txn.amount_cents)
    when ["charge", "promo_balance"]
      self.class.decrement_counter(:promo_balance_cents, id, by: txn.amount_cents)
    end
  end
end
```

### 5.4 Wallet System

Each BillingInvoice uses two classifying enums to describe the money movement:

| Enum | Values | Description |
|------|--------|-------------|
| `movement_type` | `deposit` (money in), `charge` (money out) | Direction of flow |
| `target_balance` | `main_balance`, `promo_balance` | Which wallet is affected |
| `created_by` | `system`, `customer` | Who initiated the invoice |

#### Example Invoice Combinations

| Invoice Type | movement_type | target_balance | created_by | Effect |
|-------------|---------------|----------------|------------|--------|
| Monthly billing charge | `charge` | `main_balance` | `system` | Decreases `main_balance_cents` |
| Company top-up | `deposit` | `main_balance` | `customer` | Increases `main_balance_cents` |
| Promotional credit | `deposit` | `promo_balance` | `system` | Increases `promo_balance_cents` |

The company's ability to pay is backed by `BillingWallet` (currently stored as columns on `Company`, to be extracted as a separate model):

| Balance | Priority | Source |
|---------|----------|--------|
| `promo_balance_cents` | Deducted FIRST | Free credits from Skycom (signup bonus, promotions) |
| `main_balance_cents` | Deducted SECOND | Real money deposited by the company |

When both balances are insufficient, the invoice goes `overdue` and a `PaymentMethod` (with `payment_mode: :qr`) generates a QR code for the company to pay via bank transfer.

### 5.5 Company Circuit Breaker

The circuit breaker controls company operational state via `lifecycle_status`, `has_unpaid_invoices_at`, and `suspension_at`.

**File**: `app/models/concerns/company/circuit_breaker_concern.rb`

#### Lifecycle Status

| Status | Value | Behavior | Trigger |
|--------|-------|----------|---------|
| `active` | 0 | Full operations — all features work normally | Default; reached via `try_reactivate!` when all invoices paid |
| `suspended` | 3 | Blocked — redirected to billing page; `is_accessible?` returns false | `SyncSuspensionJob` runs daily at midnight when `suspension_at` has passed |
| `disabled` | 30 | Terminal — no transitions out | Company deletion request |

#### has_unpaid_invoices_at (Billing Timestamp)

A datetime column on `companies` that records when the company first had unpaid invoices. This is a **billing indicator only** — it does not affect operational access.

- **Set** by `flag_unpaid!` to `Time.current` when unpaid invoices exist
- **Cleared** by `try_reactivate!` when all invoices are paid
- Checked by `set_billing_warning` in `ApplicationController`: shows flash message when invoices have been unpaid for more than 5 days

#### suspension_at (The Deadline)

`suspension_at` is the timestamp deadline before automatic suspension. It is set as a grace period (end of month) and cleared on reactivation.

- **Set** by `flag_unpaid!` to `Time.current.end_of_month` (gives runway until month end)
- **Extendable** by admin — push the date forward to keep the company accessible
- **Cleared** by `try_reactivate!` when all invoices are paid
- **Checked** by `SyncSuspensionJob` daily at midnight:
  - If `suspension_at <= Time.current` and company is not already `suspended` or `disabled` → `mark_suspended!`

#### is_accessible? (Access Gate)

**`is_accessible?`** returns `false` when `lifecycle_status_suspended?`:
- `suspended` → not accessible → `check_accessable` redirects to billing page
- `active` / `disabled` → accessible (disabled is terminal but still returnable)

**`check_accessable`** is a `before_action` in `Companies::Authorizable` that redirects to `company_billing_path` when `!current_company.is_accessible?`.

#### State Transitions

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

#### Key Methods

| Method | Description |
|--------|-------------|
| `flag_unpaid!` | Sets `has_unpaid_invoices_at: Time.current` + `suspension_at: end_of_month`. Does NOT change `lifecycle_status`. Idempotent. Raises if `disabled`. |
| `mark_suspended!` | Sets `lifecycle_status: :suspended`. Called by `SyncSuspensionJob` when deadline passes. Idempotent. |
| `try_reactivate!` | If no unpaid/overdue invoices remain → `lifecycle_status: :active`, `suspension_at: nil`, `has_unpaid_invoices_at: nil`. No-op if `disabled`. |
| `is_accessible?` | `true` when not `lifecycle_status_suspended?` |
| `auto_settle_unpaid_invoices` | Triggered on balance change + after unpaid invoice creation. Calls `SettlementService.settle_all`. Re-entry guarded. |

### 5.6 Voluntary Payment & QR Fallback

When the wallet is insufficient, the company owner must pay the remaining amount via QR/bank transfer.

#### BillingController

**File**: `app/controllers/companies/billing_controller.rb`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/companies/:id/billing` | GET | View outstanding invoices + wallet balances |
| `/companies/:id/billing/pay` | POST | Settle all outstanding invoices |

The controller is **exempt from `check_accessable`** so blocked companies can still pay their bills.

#### pay_all Response

```json
{
  "message": "All invoices paid. Account reactivated!",
  "paid_count": 3,
  "reactivated": true,
  "remaining_cents": 0
}
```

When `remaining_cents > 0`, the frontend displays QR/bank transfer instructions for the remaining amount. Once the owner tops up their wallet externally, the `after_update` callback on Company (balance change) triggers `auto_settle_unpaid_invoices` again — automatically paying any remaining invoices.

### 5.7 hide_billing_alerts

**Column**: `companies.hide_billing_alerts` (boolean, default `false`, null `false`)

When `true`, suppresses the unpaid-invoice warning flash message displayed by `ApplicationController#set_billing_warning`.

| Effect | Behavior |
|--------|----------|
| Unpaid invoice flash warning | **Suppressed** |
| `check_accessable` (access blocking) | **Unaffected** — still blocks when `suspended` |
| `flag_unpaid!` / `try_reactivate!` | **Unaffected** — lifecycle transitions still fire |

This is a **passive UI toggle** — it does not affect billing logic, access control, or settlement. It only hides the visual warning banner for companies with `has_unpaid_invoices_at` set.

---

## 6. Domain 2: Commerce (B2C) — Company Charges the Customer

### 6.1 The Models

```
Chargeable Item (Product / Service / Subscription / etc.)
       │
       ▼
OrderAppointment (line item: unit_price, quantity, total_price)
       │
       ▼
Order (transaction context: customer, branch, business_type)
       │
       ▼
Invoice (bill to customer)
       │
       ├── total_price (sum of line items)
       ├── workflow_status (general lifecycle — not the payment status)
       ├── payment_status ← DERIVED FROM Payment sum (target)
       │
       └── has_many :payments
             │
             ▼
Payment (record)
       │
       ├── amount_cents ← HOW MUCH was paid (target)
       ├── payment_method_id ← WHICH method was used (target: FK → PaymentMethod)
       ├── gateway_transaction_id (for online payments: MoMo txn ID, etc.)
       ├── currency_code
       ├── after_create → sync_invoice_payment_status (target)
       │
       └── belongs_to :payment_method (target)
             │
             ▼
PaymentMethod (business_type: :b2c)
       │
       ├── payment_mode: :qr | :redirect | :cash
       ├── gateway_url (for online payments)
       └── defines HOW the customer pays the company
```

> **Note:** Items marked "(target)" are aspiration — the current `Payment` model is stripped of `amount_cents`, `payment_method_id`, and payments callback. See [Section 11](#11-current-implementation-status) for status.

### 6.2 How Company Resources Connect to Orders (via OrderAppointment)

Any chargeable resource — `Product`, `Service`, `SubscriptionPlan`, or any other company-scoped model — can become a line item in an `Order` through the **`OrderConcern`** and the polymorphic `OrderAppointment` join table.

```ruby
# app/models/concerns/order_concern.rb
module OrderConcern
  extend ActiveSupport::Concern
  included do
    has_many :order_appointments, as: :appoint_to, dependent: :destroy
    has_many :orders, through: :order_appointments
  end
end
```

Models that include `OrderConcern` (Product, Service, etc.) automatically get:

| Association | Type | Purpose |
|-------------|------|---------|
| `order_appointments` | `has_many :as => :appoint_to` | Polymorphic link: this resource acts as a line item in orders |
| `orders` | `has_many :through` | All orders containing this resource |

The `OrderAppointment` table stores the line-item context:

```ruby
OrderAppointment
  ├── appoint_to_type / appoint_to_id   → polymorphic FK to the chargeable resource (Product, Service, etc.)
  ├── order_id                          → FK to the Order
  ├── company_id                        → always matches the Order's company
  ├── quantity                          → how many units
  ├── unit_price                        → price per unit at time of order
  └── total_price                       → quantity × unit_price (denormalized)
```

This polymorphic pattern means the `Order` can contain **any mix of different resource types** — a single order can include a Product, a Service, and a SubscriptionPlan — without needing separate join tables or schema changes. The `OrderAppointment` captures the **price snapshot at time of order**, so changes to the Product's current price don't affect existing orders.

**The chain is always:** `Resource → OrderAppointment (line item) → Order (aggregate) → Invoice (bill)`. The `OrderAppointment` is how the company's own catalog items enter the money flow.

### 6.3 The Payment Chain

```
Frontend (POS / Web / Mobile)
  │
  ├── 1. User selects items → Order created (workflow_status: :pending)
  │
  ├── 2. User selects payment method (Cash / MoMo / Credit Card / etc.)
  │
  ├── 3. User confirms payment
  │       │
  │       ▼
  ProcessPaymentService.call(order:, payment_method_id:, amount:)
       │
       ├── ReserveStockService (atomic Redis DECRBY)
       │
       ├── Invoice.create!(total_price: ..., payment_status: :unpaid)
       │
       ├── Payment.create!(                          ← Sole gateway interface
       │       invoice: invoice,
       │       amount_cents: amount,
       │       payment_method_id: payment_method_id,  ← determines gateway behavior
       │       gateway_transaction_id: "...",          ← from gateway response
       │       currency_code: order.currency_code
       │     )
       │     │
       │     ├── PaymentMethod.payment_mode:
       │     │     ├── :cash   → no gateway interaction
       │     │     ├── :qr     → render QR code, wait for scan
       │     │     └── :redirect → redirect to gateway page
       │     │
       │     ├── gateway sends response (sync callback or webhook)
       │     │     └── Payment.update!(gateway_status, gateway_txn_id)
       │     │
       │     └── after_create / after_update → sync_invoice_payment_status
       │           ├── SUM(payments.amount_cents) >= invoice.total_price?
       │           └── invoice.update!(payment_status: :paid)
       │
       └── Order.update!(workflow_status: :paid)
             │
             └── FinalizeJob.perform_later(order.id)
                   ├── WriteStockLedgerService
                   ├── UpdateStockBalancesService
                   └── FinalizeOrderService
```

### 6.4 Multiple Payments Per Invoice

A single invoice may be paid in multiple installments (split tender: cash + card, or partial payments):

```ruby
Invoice # total_price: 50_00 ($50.00)
  ├── Payment #1: amount_cents: 20_00 (cash)
  │     └── after_create → SUM = 20_00 < 50_00 → payment_status: :unpaid
  │
  └── Payment #2: amount_cents: 30_00 (credit card)
        └── after_create → SUM = 50_00 >= 50_00 → payment_status: :paid
```

If Payment #2 is later refunded (destroyed):
`after_destroy → SUM = 20_00 < 50_00 → payment_status: :unpaid` (invoice reverts)

---

## 7. PaymentMethod: The Global Bridge

`PaymentMethod` is a **global catalog** — it does not belong to any company. It defines **how money moves** in both domains. The `BillingTransaction`/`Payment` uses its `payment_method_id` to determine the gateway interaction pattern.

### 7.1 The Enum

```ruby
enum :business_type, {
  b2c: 0,  # Company → Customer (Cash, MoMo, VNPay, Credit Card, etc.)
  b2b: 1   # Skycom → Company (wallet auto-debit, card-on-file, QR bank transfer)
}

enum :payment_mode, {
  qr: 0,       # Render QR code → customer scans & pays via banking app
  redirect: 1, # Redirect to provider hosted page (MoMo, VNPay, PayPal)
  cash: 2      # Manual cash/onsite payment — no gateway
}
```

### 7.2 How Companies Access Payment Methods

Companies link to global `PaymentMethod` records via `PaymentMethodAppointment`:

```ruby
PaymentMethodAppointment
  ├── company_id      → scopes to the company
  ├── payment_method_id → FK to global PaymentMethod
  ├── branch_id       → optional: scope to a specific branch
  └── business_type   → :online | :in_store | :recurring
```

This allows each company to enable only the payment methods relevant to their market (e.g., MoMo + Cash for VN companies, Stripe + Cash for US companies).

### 7.3 BillingTransaction/Payment <-> PaymentMethod Interaction

The `PaymentMethod.payment_mode` defines how the `BillingTransaction`/`Payment` interacts with the gateway:

| `payment_mode` | Interaction Pattern | What Happens |
|----------------|-------------------|--------------|
| `:cash` | No gateway | Record is created directly. No external API call. Payment is manual/onsite. |
| `:qr` | Offline async | Record triggers QR code generation encoding payment details. Customer scans with banking app. Bank sends webhook on completion → record updated. |
| `:redirect` | Online sync+async | Record initiates redirect to gateway (MoMo, VNPay, Stripe). Customer authorizes on gateway page. Gateway calls back via redirect or webhook → record updated. |

The `BillingTransaction`/`Payment` is created FIRST with a `payment_method_id`. The system uses the PaymentMethod to determine the gateway service/endpoint to call. The gateway response always updates the record, never the Invoice or Order directly.

### 7.4 B2B Payment Methods

B2B payment methods are used by the platform to collect from companies:

| Method | payment_mode | How It Works | Status |
|--------|-------------|--------------|--------|
| Wallet auto-debit | `:cash` (manual/internal) | SettlementService deducts from promo_balance + main_balance automatically | ✅ Live |
| QR bank transfer | `:qr` | Generate QR for outstanding amount, company pays via banking app | ✅ Mock API |
| Card auto-charge | `:redirect` | Auto-charge registered card on month-end | 🔜 Future (P1 #11) |

### 7.5 B2C Payment Methods

B2C payment methods are used by the company's customers:

| Method | payment_mode | How It Works | Status |
|--------|-------------|--------------|--------|
| Cash | `:cash` | Manual receipt at POS | ✅ Live (cosmetic) |
| MoMo (VN) | `:qr` or `:redirect` | QR scan or redirect to MoMo app | 🔜 Future |
| ZaloPay (VN) | `:qr` | QR scan via Zalo app | 🔜 Future |
| VNPay (VN) | `:redirect` | Redirect to VNPay hosted page | 🔜 Future |
| Credit Card (US) | `:redirect` | Stripe/PaymentElement hosted page | 🔜 Future |

---

## 8. The Money Flow Tenets

These are immutable. Every developer and AI agent **must** follow them.

### Tenet 1: Payment/BillingTransaction Is the Source of Truth

Company balances, invoice payment statuses, and financial reports are all **derived** from `BillingTransaction`/`Payment` records. Never the other way around.

```
BillingTransaction/Payment → Invoice.payment_status
BillingTransaction         → Company.main_balance_cents  (recomputed from sum)
```

If balances ever drift, they must be reconstructed from `BillingTransaction` records — not the reverse.

### Tenet 2: No Orphan Money

Every `BillingTransaction`/`Payment` **must** belong to an Invoice (`billing_invoice_id` / `invoice_id` is `NOT NULL`). Every Invoice **must** have a `movement_type` (`:charge` or `:deposit`) that explains the direction of flow.

### Tenet 3: No Direct Status Assignment

No code path may set `invoice.payment_status = :paid` directly. The only way an invoice becomes `paid` is through the `sync_invoice_payment_status` callback triggered by a `BillingTransaction`/`Payment` lifecycle event.

```ruby
# ✅ CORRECT
BillingTransaction.create!(invoice: invoice, amount_cents: 1000)
  # → after_create fires → sync_invoice_payment_status → paid

# ❌ FORBIDDEN
invoice.update!(payment_status: :paid)
```

### Tenet 4: Full Audit Trail

Every `BillingTransaction`/`Payment` must record enough context to reconstruct the financial state without consulting external systems:

| Field | Purpose |
|-------|---------|
| `amount_cents` | How much moved |
| `currency_code` | In what denomination |
| `balance_before_cents` / `balance_after_cents` | Wallet snapshots (B2B only) |
| `promo_balance_before_cents` / `promo_balance_after_cents` | Promo wallet snapshots (B2B only) |
| `payment_method_id` | Which method was used (determines gateway interaction) |
| `gateway_transaction_id` | External gateway reference (for online payments) |
| `billing_invoice_id` / `invoice_id` | Which invoice this settles |

### Tenet 5: PaymentMethod Is the Final Link

Every money flow terminates at a `PaymentMethod` that defines the actual transfer mechanism:

```
Flow: Catalog → Contract → Invoice → BillingTransaction/Payment → PaymentMethod
                                                                     │
                                                                     ├── :qr       → QR code generated, customer scans & pays
                                                                     ├── :redirect → Customer redirected to gateway page
                                                                     └── :cash     → Manual receipt, no gateway
```

### Tenet 6: Balance Changes Trigger Re-Settlement

When a company's wallet balance changes (top-up, promo credit), the system must automatically re-attempt settlement of all unpaid invoices:

```ruby
# Company::CircuitBreakerConcern
after_update :auto_settle_unpaid_invoices,
  if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }
```

This ensures that a company that tops up enough to cover outstanding invoices is reactivated immediately — no manual intervention needed.

### Tenet 7: BillingTransaction/Payment Is the Sole Gateway Interface

Only `BillingTransaction` (B2B) and `Payment` (B2C) may communicate with external payment gateways. Invoices and orders never interact with gateways.

```
Gateway API call / webhook → BillingTransaction/Payment.update!(gateway_status, gateway_txn_id)
                                │
                                └── after_update :sync_invoice_payment_status
                                      └── Invoice.payment_status derived

Invoice / Order → NEVER talks to gateway
```

The `BillingTransaction`/`Payment`'s `payment_method_id` FK determines which gateway to use and which interaction pattern (qr/redirect/cash) to follow.

---

## 9. Enforcement Mechanisms

### 9.1 Callback Pattern

Every `BillingTransaction` and `Payment` model **must** implement:

```ruby
after_create_commit :sync_invoice_payment_status, unless: -> { amount_cents.zero? }
after_destroy_commit :sync_invoice_payment_status

private

def sync_invoice_payment_status
  total = invoice.transactions.sum(:amount_cents)
  new_status = total >= invoice.price_cents ? :paid : :unpaid
  return if invoice.payment_status == new_status.to_s
  invoice.update!(payment_status: new_status)
end
```

Where `invoice.transactions` is `billing_invoice.billing_transactions` (B2B) or `invoice.payments` (B2C).

### 9.2 Invoice-Level Guard

Every Invoice model **should** guard against direct payment_status manipulation:

```ruby
validate :payment_status_not_manually_set

def payment_status_not_manually_set
  return unless payment_status_changed?
  return unless persisted? # allow initial :unpaid on create

  # Check if this change was triggered by a Payment/BillingTransaction callback
  # (the callback fires inside the same request, so we can't
  # easily distinguish. The real enforcement is: no code outside of
  # the callback should change payment_status.)
end
```

Real enforcement is through **code review** and **architectural convention** — no service object, controller, or job should ever call `invoice.update!(payment_status:)`.

### 9.3 Spec Requirements

Every feature test that exercises payment **must** assert:

```ruby
# Verify payment_status was derived, not set directly
expect(invoice.reload.payment_status).to eq("paid")
expect(invoice.payments.sum(:amount_cents)).to be >= invoice.price_cents

# Verify balance was updated (B2B only)
expect(company.reload.main_balance_cents).to eq(expected_main)
expect(company.reload.promo_balance_cents).to eq(expected_promo)
```

### 9.4 What to Check In Code Review

| Smell | Problem |
|-------|---------|
| `invoice.update!(payment_status: :paid)` | ❌ Direct status assignment — should come from Payment/BillingTransaction |
| `Payment.create!` without `amount_cents` | ❌ No monetary value — impossible to derive status |
| `Payment.create!` without `payment_method_id` | ❌ No link to PaymentMethod — can't tell HOW money moved |
| `BillingTransaction.create!` without balance snapshots | ❌ No audit trail — can't reconstruct wallet state |
| `Invoice.gateway_call()` or `Order.gateway_call()` | ❌ Only BillingTransaction/Payment talks to gateways |
| Creating an Invoice without a Payment/BillingTransaction in the same flow | ❌ Orphan invoice — will never become `paid` |

---

## 10. Usage Metering Subsystem

The metering subsystem counts every business action so Skycom knows how much each company is using. It is the upstream data source for the [CalculatorService](#522-calculatorservice) that generates monthly charges.

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

## 11. Current Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| **BillingResource** | ✅ Complete | Global catalog with country-scoped pricing |
| **BillingContract** | ✅ Complete | Per-company active contract with features + metrics |
| **BillingInvoice** | ✅ Complete | `payment_status` derived from BillingTransaction sum |
| **BillingTransaction** | ✅ Complete | Full audit trail with balance snapshots, `sync_invoice_payment_status` callback |
| **SettlementService** | ✅ Complete | Wallet deduction with re-entry guards |
| **PaymentMethod** | ✅ Complete | Global catalog with `business_type` (b2b/b2c) and `payment_mode` (qr/redirect/cash) |
| **PaymentMethodAppointment** | ✅ Complete | Links PaymentMethod to companies/branches |
| **MeteringConcern** | ✅ Complete | Auto-increments Redis counters on record creation |
| **DailyMetricLog** | ✅ Complete | Persisted hourly metric snapshots |
| **DailyFeatureLog** | ✅ Complete | Persisted 6-hourly feature-active-day snapshots |
| **MonthlyBillingJob** | ✅ Complete | Monthly invoice creation for non-disabled companies |
| **CalculatorService** | ✅ Complete | Monthly charge computation with per-feature proration |
| **InvoiceService** | ✅ Complete | BillingInvoice creation from CalculatorService result |
| **SyncDailyMetricJob** | ✅ Complete | Hourly sync of Redis counters → DailyMetricLog |
| **SyncDailyFeatureJob** | ✅ Complete | 6-hourly snapshot of active features → DailyFeatureLog |
| **SyncSuspensionJob** | ✅ Complete | Daily midnight suspension cron |
| **BillingWallet** | ⬜ Separate model | Currently columns on `Company` — extract to `BillingWallet` model |
| **Billing Dashboard** | ✅ Complete | Self-service portal with usage charts, wallet, pay-all |
| **BillingController** | ✅ Complete | View + pay outstanding invoices; exempt from `check_accessable` |
| **POS Payment model (`Payment`)** | ⬜ Needs rework | Missing `amount_cents`, `payment_method_id`, and `sync_invoice_payment_status` callback |
| **Commerce Invoice** | ⬜ Needs rework | Missing `payment_status` column derived from Payment sum |
| **Gateway integration (MoMo/VNPay/Stripe)** | ⬜ Future | P1 #11 on roadmap — will create real gateway transactions with `payment_mode: :qr` and `:redirect` |

---

## 12. Complete Lifecycle Scenario

This example traces a company through a full billing cycle — from active operations through overage, auto-settlement, suspension, and recovery.

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

## 13. Reference

| File | Purpose |
|------|---------|
| `app/models/billing_invoice.rb` | B2B invoice with derived payment_status |
| `app/models/billing_transaction.rb` | B2B ledger entry with sync callback |
| `app/models/billing_contract.rb` | Per-company pricing contract (feature gating, allowances, pricing) |
| `app/models/billing_resource.rb` | Global catalog of metered + addon resources |
| `app/models/contract_feature.rb` | BillingContract ↔ addon_feature bridge (flat monthly price) |
| `app/models/contract_metric.rb` | BillingContract ↔ volumetric bridge (allowance + overage price) |
| `app/models/payment_method.rb` | Global payment gateway registry (b2b + b2c) |
| `app/models/payment_method_appointment.rb` | Company-to-payment-method link |
| `app/models/daily_metric_log.rb` | Volumetric usage snapshots |
| `app/models/daily_feature_log.rb` | Feature-active-day snapshots for proration |
| `app/models/payment.rb` | B2C payment record (needs amount_cents, payment_method_id, callback) |
| `app/models/invoice.rb` | B2C invoice (needs payment_status column) |
| `app/models/concerns/metering_concern.rb` | Auto-increments Redis counters on record creation |
| `app/models/concerns/company/billing_concern.rb` | feature_enabled?, record_usage!, wallet helpers |
| `app/models/concerns/company/circuit_breaker_concern.rb` | Lifecycle transitions, flag_unpaid!, try_reactivate! |
| `app/models/concerns/order_concern.rb` | Gives order line-item capability to any company resource |
| `app/services/billing/calculator_service.rb` | Monthly charge computation |
| `app/services/billing/invoice_service.rb` | BillingInvoice creation |
| `app/services/billing/settlement_service.rb` | Wallet deduction + BillingTransaction creation |
| `app/services/billing/seed_resources_service.rb` | Seeds BillingResource catalog |
| `app/jobs/billing/monthly_billing_job.rb` | Monthly invoice creation cron |
| `app/jobs/billing/sync_suspension_job.rb` | Daily suspension cron |
| `app/jobs/billing/sync_daily_metric_job.rb` | Hourly Redis → DailyMetricLog sync |
| `app/jobs/billing/sync_daily_feature_job.rb` | 6-hourly DailyFeatureLog snapshot |
| `app/controllers/companies/billing_controller.rb` | Billing portal: view + pay; exempt from check_accessable |
| `app/controllers/companies/order_processing/v1_controller.rb` | POS checkout + pay API |
| `docs/ORDER_PROCESSING_V1.md` | POS order pipeline documentation |
| `docs/BILLING_DASHBOARD.md` | Billing dashboard frontend documentation |
| `config/initializers/constants.rb` (billing section) | `BILLING_VOLUMETRIC_RESOURCES`, `BILLING_ADDON_FEATURES`, `BILLING_PRICES_BY_COUNTRY`, `DEFAULT_FREE_TIER_ALLOWANCES` |
