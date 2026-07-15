# Skycom Money Flow Architecture — The Absolute Rules

> **Status**: Target architecture. Some parts are implemented, some are aspirational. This document defines what every money-related code path **must** conform to.

---

## 1. Purpose

Skycom has two distinct domains where money moves:

| Domain | Direction | What Happens |
|--------|-----------|--------------|
| **Billing (B2B)** | Skycom → Company | Skycom charges the company for platform usage (metrics, features, plan) |
| **Commerce (B2C)** | Company → Customer | The company charges its customers for goods and services |

Both domains follow **the same canonical chain** of models. The rule is simple: **every cent that moves must leave a trail** — from catalog to contract to invoice to transaction to payment method. No orphan money, no direct status flips.

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
   Transaction          ◄── Source of truth for money movement
       │
       ▼
  PaymentMethod         ◄── Defines HOW money moves (qr / redirect / cash)
```

Each domain maps real models to this chain:

| Layer | Billing (B2B) | Commerce (B2C) |
|-------|---------------|----------------|
| **Catalog** | `BillingResource` — **System-level global catalog**. Seeded by Skycom. Country-scoped pricing (US/VN). Two types: `volumetric` (metered usage counters: orders, storage_mb, employees, branches, customers, api_calls, stock_mutations) and `addon_feature` (flat monthly add-on fees: analytics_dashboard, hrm_attendance, custom_roles, etc.). No `company_id`. Companies **never** create `BillingResource` records. | `Product` / `Service` / `SubscriptionPlan` / etc. — **Company-scoped business catalog**. Belongs to a `company_id`. Company creates them, sets prices, defines categories/properties. Companies own their catalog entirely — Skycom only provides the schema. |
| **Contract** | `BillingContract` — per-company pricing plan, allowances, feature toggles, base price | `Order` — captures items (via `OrderAppointment`), quantities, unit prices, customer, branch |
| **Invoice** | `BillingInvoice` — monthly charge; `movement_type: :charge`, `target_balance: :main_balance`, `payment_status: unpaid/paid/overdue` | `Invoice` — bill to customer; `total_price`, `workflow_status` tracks lifecycle, `payment_status` derived from transactions |
| **Transaction** | `BillingTransaction` — ledger entry; records `amount_cents`, before/after snapshots of both wallet balances | Transaction record — records `amount_cents`, `payment_method_id`, gateway transaction ID, etc. |
| **Balance** | `BillingWallet` (future separate model; currently `company.main_balance_cents` + `company.promo_balance_cents`) | N/A — the customer pays directly, the company does not hold a balance for them |
| **PaymentMethod** | `PaymentMethod` where `business_type: :b2b` — system-level: wallet auto-debit, card-on-file, QR fallback for bank transfer | `PaymentMethod` where `business_type: :b2c` — customer-facing: Cash, MoMo, ZaloPay, VNPay, Credit Card, etc. |

---

## 4. The Absolute Rule

> **`Invoice.payment_status` MUST be derived from the sum of its `Transactions`.**

```
Invoice.payment_status  =  SUM(Transaction.amount_cents) >= Invoice.price_cents
                              ? :paid
                              : :unpaid
```

This rule is enforced by callback on the Transaction model:

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
| Create a paid invoice without any transaction | ❌ **FORBIDDEN** — callback never fires, invoice stays `unpaid` | Transaction `after_create` callback |
| Delete a transaction (refund/void) | ✅ Invoice auto-reverts to `unpaid` | Transaction `after_destroy` callback |
| Sum of transactions exactly equals invoice price | ✅ Invoice transitions to `paid` | Callback computes `total >= price_cents` |
| Sum exceeds invoice price | ✅ Invoice is `paid` (overpayment credits go to wallet) | Callback computes `total >= price_cents` |
| Set `invoice.payment_status = :paid` directly in any code path | ❌ **FORBIDDEN** — no code may bypass the derivation | Review + lint |

### Exception: `price_cents == 0`

When an invoice has zero price (within-allowance usage), it may be auto-marked `paid` without a transaction. This is the only exception — nothing moved, nothing to record.

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

### 5.3 Wallet Concept

The company's ability to pay is backed by `BillingWallet` (currently stored as columns on `Company`, to be extracted):

| Balance | Priority | Source |
|---------|----------|--------|
| `promo_balance_cents` | Deducted FIRST | Free credits from Skycom (signup bonus, promotions) |
| `main_balance_cents` | Deducted SECOND | Real money deposited by the company |

When both balances are insufficient, the invoice goes `overdue` and a `PaymentMethod` (with `payment_mode: :qr`) generates a QR code for the company to pay via bank transfer.

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
       ├── payment_status ← DERIVED FROM Transaction sum
       │
       └── has_many :transactions
             │
             ▼
Transaction (record)
       │
       ├── amount_cents ← HOW MUCH was paid
       ├── payment_method_id ← WHICH method was used (FK → PaymentMethod)
       ├── gateway_transaction_id (for online payments: MoMo txn ID, etc.)
       ├── currency_code
       ├── after_create → sync_invoice_payment_status
       │
       └── belongs_to :payment_method
             │
             ▼
PaymentMethod (business_type: :b2c)
       │
       ├── payment_mode: :qr | :redirect | :cash
       ├── gateway_url (for online payments)
       └── defines HOW the customer pays the company
```

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
       ├── Transaction.create!(
       │       invoice: invoice,
       │       amount_cents: amount,
       │       payment_method_id: payment_method_id,
       │       gateway_transaction_id: "...",   # from mock or real gateway
       │       currency_code: order.currency_code
       │     )
       │     │
       │     └── after_create → sync_invoice_payment_status
       │           ├── SUM(transactions.amount_cents) >= invoice.total_price?
       │           └── invoice.update!(payment_status: :paid)
       │
       └── Order.update!(workflow_status: :paid)
             │
             └── FinalizeJob.perform_later(order.id)
                   ├── WriteStockLedgerService
                   ├── UpdateStockBalancesService
                   └── FinalizeOrderService
```

### 6.4 Multiple Transactions Per Invoice

A single invoice may be paid in multiple installments (split tender: cash + card, or partial payments):

```ruby
Invoice # total_price: 50_00 ($50.00)
  ├── Transaction #1: amount_cents: 20_00 (cash)
  │     └── after_create → SUM = 20_00 < 50_00 → payment_status: :unpaid
  │
  └── Transaction #2: amount_cents: 30_00 (credit card)
        └── after_create → SUM = 50_00 >= 50_00 → payment_status: :paid
```

If Transaction #2 is later refunded (destroyed):
`after_destroy → SUM = 20_00 < 50_00 → payment_status: :unpaid` (invoice reverts)

---

## 7. PaymentMethod: The Global Bridge

`PaymentMethod` is a **global catalog** — it does not belong to any company. It defines **how money moves** in both domains.

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

### 7.3 B2B Payment Methods

B2B payment methods are used by the platform to collect from companies:

| Method | payment_mode | How It Works | Status |
|--------|-------------|--------------|--------|
| Wallet auto-debit | `:cash` (manual/internal) | SettlementService deducts from promo_balance + main_balance automatically | ✅ Live |
| QR bank transfer | `:qr` | Generate QR for outstanding amount, company pays via banking app | ✅ Mock API |
| Card auto-charge | `:redirect` | Auto-charge registered card on month-end | 🔜 Future (P1 #11) |

### 7.4 B2C Payment Methods

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

### Tenet 1: Transaction Is the Source of Truth

Company balances, invoice payment statuses, and financial reports are all **derived** from Transaction records. Never the other way around.

```
Transactions → Invoice.payment_status
Transactions → Company.main_balance_cents  (recomputed from BillingTransaction sum)
```

If balances ever drift, they must be reconstructed from Transactions — not the reverse.

### Tenet 2: No Orphan Money

Every Transaction **must** belong to an Invoice (`billing_invoice_id` / `invoice_id` is `NOT NULL`). Every Invoice **must** have a `movement_type` (`:charge` or `:deposit`) that explains the direction of flow.

### Tenet 3: No Direct Status Assignment

No code path may set `invoice.payment_status = :paid` directly. The only way an invoice becomes `paid` is through the `sync_invoice_payment_status` callback triggered by a Transaction lifecycle event.

```ruby
# ✅ CORRECT
Transaction.create!(invoice: invoice, amount_cents: 1000)
  # → after_create fires → sync_invoice_payment_status → paid

# ❌ FORBIDDEN
invoice.update!(payment_status: :paid)
```

### Tenet 4: Full Audit Trail

Every Transaction must record enough context to reconstruct the financial state without consulting external systems:

| Field | Purpose |
|-------|---------|
| `amount_cents` | How much moved |
| `currency_code` | In what denomination |
| `balance_before_cents` / `balance_after_cents` | Wallet snapshots (B2B only) |
| `promo_balance_before_cents` / `promo_balance_after_cents` | Promo wallet snapshots (B2B only) |
| `payment_method_id` | Which method was used |
| `gateway_transaction_id` | External gateway reference (for online payments) |
| `billing_invoice_id` / `invoice_id` | Which invoice this settles |

### Tenet 5: PaymentMethod Is the Final Link

Every money flow terminates at a `PaymentMethod` that defines the actual transfer mechanism:

```
Flow: Catalog → Contract → Invoice → Transaction → PaymentMethod
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

---

## 9. Enforcement Mechanisms

### 9.1 Callback Pattern

Every Transaction model **must** implement:

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

### 9.2 Invoice-Level Guard

Every Invoice model **should** guard against direct payment_status manipulation:

```ruby
validate :payment_status_not_manually_set

def payment_status_not_manually_set
  return unless payment_status_changed?
  return unless persisted? # allow initial :unpaid on create

  # Check if this change was triggered by a transaction callback
  # (Transaction callback fires inside the same request, so we can't
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
expect(invoice.transactions.sum(:amount_cents)).to be >= invoice.price_cents

# Verify balance was updated (B2B only)
expect(company.reload.main_balance_cents).to eq(expected_main)
expect(company.reload.promo_balance_cents).to eq(expected_promo)
```

### 9.4 What to Check In Code Review

| Smell | Problem |
|-------|---------|
| `invoice.update!(payment_status: :paid)` | ❌ Direct status assignment — should come from Transaction |
| `Transaction.create!` without `amount_cents` | ❌ No monetary value — impossible to derive status |
| `Transaction.create!` without `payment_method_id` | ❌ No link to PaymentMethod — can't tell HOW money moved |
| `BillingTransaction.create!` without balance snapshots | ❌ No audit trail — can't reconstruct wallet state |
| Creating an Invoice without a Transaction in the same flow | ❌ Orphan invoice — will never become `paid` |

---

## 10. Current Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| **BillingResource** | ✅ Complete | Global catalog with country-scoped pricing |
| **BillingContract** | ✅ Complete | Per-company active contract with features + metrics |
| **BillingInvoice** | ✅ Complete | `payment_status` derived from BillingTransaction sum |
| **BillingTransaction** | ✅ Complete | Full audit trail with balance snapshots |
| **SettlementService** | ✅ Complete | Wallet deduction with re-entry guards |
| **PaymentMethod** | ✅ Complete | Global catalog with `business_type` (b2b/b2c) and `payment_mode` (qr/redirect/cash) |
| **PaymentMethodAppointment** | ✅ Complete | Links PaymentMethod to companies/branches |
| **BillingWallet** | ⬜ Separate model | Currently columns on `Company` — extract to `BillingWallet` model |
| **POS Transaction model** | ⬜ Needs rework | Missing `amount_cents` and `payment_method_id`; no `sync_invoice_payment_status` callback |
| **Commerce Invoice** | ⬜ Needs rework | Missing `payment_status` column derived from Transaction sum |
| **Gateway integration (MoMo/VNPay/Stripe)** | ⬜ Future | P1 #11 on roadmap — will create real gateway transactions with `payment_mode: :qr` and `:redirect` |

---

## 11. Reference

| File | Purpose |
|------|---------|
| `app/models/billing_invoice.rb` | B2B invoice with derived payment_status |
| `app/models/billing_transaction.rb` | B2B ledger entry with sync callback |
| `app/models/billing_contract.rb` | Per-company pricing contract |
| `app/models/billing_resource.rb` | Global catalog of metered + addon resources |
| `app/models/contract_feature.rb` | BillingContract ↔ addon_feature bridge |
| `app/models/contract_metric.rb` | BillingContract ↔ volumetric bridge |
| `app/models/payment_method.rb` | Global payment gateway registry (b2b + b2c) |
| `app/models/payment_method_appointment.rb` | Company-to-payment-method link |
| `app/models/daily_metric_log.rb` | Volumetric usage snapshots |
| `app/models/daily_feature_log.rb` | Feature-active-day snapshots for proration |
| `app/services/billing/calculator_service.rb` | Monthly charge computation |
| `app/services/billing/invoice_service.rb` | BillingInvoice creation |
| `app/services/billing/settlement_service.rb` | Wallet deduction + BillingTransaction creation |
| `app/models/concerns/company/circuit_breaker_concern.rb` | Lifecycle transitions, flag_unpaid!, try_reactivate! |
| `app/models/concerns/company/billing_concern.rb` | feature_enabled?, record_usage!, wallet helpers |
| `app/jobs/billing/monthly_billing_job.rb` | Monthly invoice creation cron |
| `app/jobs/billing/sync_suspension_job.rb` | Daily suspension cron |
| `app/jobs/billing/sync_daily_metric_job.rb` | Hourly Redis → DailyMetricLog sync |
| `app/jobs/billing/sync_daily_feature_job.rb` | 6-hourly DailyFeatureLog snapshot |
| `app/models/invoice.rb` | B2C invoice (needs payment_status column) |
| `app/controllers/companies/order_processing/v1_controller.rb` | POS checkout + pay API |
| `docs/BILLING.md` | Full billing system documentation |
| `docs/BILLING_TRANSACTIONS.md` | BillingTransaction source-of-truth pattern |
| `docs/ORDER_PROCESSING_V1.md` | POS order pipeline documentation |
| `app/models/concerns/order_concern.rb` | Gives order line-item capability to any company resource |
| `config/initializers/constants.rb` (billing section) | `BILLING_VOLUMETRIC_RESOURCES`, `BILLING_ADDON_FEATURES`, `BILLING_PRICES_BY_COUNTRY`, `DEFAULT_FREE_TIER_ALLOWANCES` |
