# Skycom Money Flow Architecture — The Absolute Rules

> **Status**: Live. This document defines how money moves in the **credit era**. The B2B paid-feature billing system (BillingContract/BillingResource/feature gating/settlement/circuit-breaker) was removed in `404053ca` (2026-08-12). Company → Skycom money now flows through the **credit chain** (`CompanyOrder → CompanyInvoice → CompanyTransaction → CompanyWallet`, see `docs/ATOMIC_PURPOSE.md`), and company → customer money flows through the **commerce chain** (`Order → Invoice → Transaction → PaymentMethod`). Both follow the same canonical rule: **every cent that moves must leave a trail** — no orphan money, no direct status flips.

---

## 1. Purpose

Skycom has two distinct domains where money moves:

| Domain | Direction | What Happens |
|--------|-----------|--------------|
| **Credit (B2B)** | Company → Skycom | The company pays Skycom **in credits** for platform consumption (dashboard access, order creation, customer creation, ...) and tops up its wallet with money |
| **Commerce (B2C)** | Customer → Company | The company charges its customers for goods and services via POS |

Both domains follow **the same canonical chain** of models and the same derivation rule. The rule is simple: **every cent that moves must leave a trail** — from order to invoice to transaction to payment method to balance. No orphan money, no direct status flips.

---

## 2. Naming Convention — The Two Money Vocabularies

Skycom uses distinct prefixes to separate system-controlled money models (company pays Skycom) from company-scoped business models (customer pays company).

### Credit Chain (Company → Skycom) — `Company*` Prefix

Models prefixed with `Company*` form the **pay-as-you-go credit chain**. They are company-scoped but platform-governed — the company tops them up, Skycom's deduction services draw them down.

| Model | Purpose |
|-------|---------|
| `CompanyOrder` | The deal — money tier → credits (`CREDIT_RATES[country]`), rate snapshot; `complete!` idempotently credits the wallet |
| `CompanyInvoice` | The bill — `payment_status` **derived** from transaction sum, never set directly |
| `CompanyTransaction` | The ledger entry + **sole gateway interface** — created pending, completed by webhook |
| `CompanyWallet` | Stores balance **numbers only** (main/promo/debt) — no business logic |
| `CompanyPaymentMethod` | B2B payment method used by `CompanyTransaction` (Mock QR / Mock Redirect / cash) |
| `CompanyWalletLog` | Audit trail — every balance mutation with before/after snapshots + `balance_type` |
| `CompanyUsageLog` | Opt-in per-action detail rows (why a balance moved) |
| `CompanyDailyUsage` / `CompanyMonthlyUsage` | Metered usage snapshots (hourly / daily slots) |

### Commerce Chain (Customer → Company) — no prefix

Company-facing business models have **no prefix**. They are per-company and controlled by the company.

| Model | Purpose |
|-------|---------|
| `Order` | Customer purchase (pending → paid), `workflow_status` tracks state |
| `OrderAppointment` | Line items — polymorphic link to chargeable resources, price snapshot |
| `Invoice` | Bill to customer — `payment_status` **derived** from transaction sum |
| `Transaction` | Payment audit row + **sole gateway interface** — `price_cents`, `payment_method_id`, `status` pending/completed/failed |
| `PaymentMethod` | Global catalog — how money moves (qr / redirect / cash) |
| `PaymentMethodAppointment` | Per-tenant link (company-level / branch-level) with merchant identity |

### Why the Distinction Matters

```
CompanyOrder.first
# => #<CompanyOrder:0x... company_id: "abc-123", money_amount_cents: 50000, credit_amount: 500000>
# ↑ Skycom's rate tier: company pays for credits

Order.first
# => #<Order:0x... company_id: "abc-123", workflow_status: "pending">
# ↑ The company's own customer sale
```

The two chains never cross. A `CompanyOrder` is not a thing the company sells — it is a thing the **company buys from Skycom**. An `Order` is not metered — it is the company's own business record.

---

## 3. The Canonical Chains

### 3.1 The Credit Chain (B2B — company pays Skycom)

```
  Top-up (money in)                     Deduction (credits out)
  ─────────────────                     ─────────────────────
CompanyOrder (money tier → credits)     CompanyCreditDeduction::* after_action
      │                                        │  deduct promo → main → debt
      ▼                                        │  company.record_credit_usage!(cost)
CompanyInvoice (the bill)                      ▼
      │  payment_status DERIVED           CompanyWallet (main/promo/debt)
      ▼                                        │  company_wallet_logs (audit)
CompanyTransaction (gateway entry)             │  company_usage_logs (opt-in detail)
      │  status: pending → completed           │
      ▼                                        ▼
CompanyWallet (add_credits!)            CompanyUsageSyncJob → CompanyDailyUsage / MonthlyUsage
```

Rules (see `docs/ATOMIC_PURPOSE.md`):
- Each record is mutated **only** by the record above it.
- `CompanyInvoice.payment_status` is **derived** from `SUM(company_transactions.money_amount_cents)` of `completed` payment transactions — never set directly.
- When the invoice becomes paid, `CompanyInvoice#complete_order_if_paid!` calls `CompanyOrder#complete!` (idempotent), which credits the wallet via `wallet.add_credits!`.
- The hot usage path (`record_credit_usage!`) is a Kredis counter drained by `CompanyUsageSyncJob` — no DB writes per action.

### 3.2 The Commerce Chain (B2C — customer pays company)

```
Chargeable item (Product / Service / ...)
      │
      ▼
OrderAppointment (line item: quantity, unit_price, total_price)
      │
      ▼
Order (transaction context: customer, branch, business_type)
      │
      ▼
Invoice (bill to customer; price_cents)
      │  payment_status DERIVED from Transaction sum
      ▼
Transaction (payment record: price_cents, payment_method_id, status)
      │  created by InitiatePaymentService, completed by webhook / cash path
      ▼
PaymentMethod (global catalog — how money moves) / PaymentMethodAppointment (merchant identity)
```

Rules:
- `Invoice.payment_status` is **derived** from `SUM(transactions.price_cents)` of **completed** transactions — pending Mock QR payments never pay the invoice early.
- `Transaction` is the **sole gateway interface** — invoices and orders never talk to gateways.
- `FinalizeJob` (async) writes stock ledger, decrements balances, creates the export doc after the order is paid.

---

## 4. The Absolute Rule

> **`Invoice.payment_status` (both domains) MUST be derived from the sum of its transaction records — completed transactions only.**

### Credit chain (`CompanyTransaction`)

```ruby
# app/models/company_transaction.rb
after_create  :sync_invoice_payment_status, if: :completed?
after_update  :sync_invoice_payment_status, if: :completed?
after_destroy :sync_invoice_payment_status

def sync_invoice_payment_status
  total = company_invoice.company_transactions
    .where(transaction_type: :payment, status: :completed)
    .sum(:money_amount_cents)
  new_status = total >= company_invoice.money_amount_cents ? :paid : :unpaid
  return if company_invoice.payment_status == new_status.to_s
  company_invoice.update!(payment_status: new_status)
end
```

### Commerce chain (`Transaction`)

```ruby
# app/models/transaction.rb
after_create  :sync_invoice_payment_status, if: -> { completed? && !price_cents.zero? }
after_update  :sync_invoice_payment_status, if: :completed?
after_destroy :sync_invoice_payment_status

def sync_invoice_payment_status
  total = invoice.transactions.sum(:price_cents)
  new_status = total >= invoice.price_cents ? :paid : :unpaid
  return if invoice.payment_status == new_status.to_s
  invoice.update!(payment_status: new_status)
end
```

### What This Means

| Scenario | Behavior | Enforced By |
|----------|----------|-------------|
| Create an invoice without any completed transaction | ❌ Stays `unpaid` (pending txns are silent) | `if: :completed?` gate on the callback |
| Create a transaction as `completed` (instant cash path) | ✅ Invoice auto-transitions to `paid` | `after_create` on the transaction model |
| Webhook completes a pending transaction (top-up / POS QR) | ✅ Invoice auto-transitions to `paid` | `after_update` on the transaction model |
| Destroy a transaction (refund/void) | ✅ Invoice auto-reverts to `unpaid` | `after_destroy` on the transaction model |
| Sum of completed transactions >= invoice price | ✅ Invoice is `paid` | Callback computes `total >= price_cents` |
| Set `invoice.payment_status = :paid` directly | ❌ **FORBIDDEN** — no code may bypass the derivation | Code review + convention |

### Exception: `price_cents == 0`

The commerce `Transaction` skips the derivation when `price_cents` is zero (nothing moved, nothing to record). In the credit chain, a `CompanyTransaction` with a positive `money_amount_cents` always derives.

---

## 5. Domain 1: The Credit Chain (B2B) — Company Pays Skycom

### 5.1 Top-Up (money in)

**Files**: `app/services/top_ups/create_service.rb`, `app/controllers/companies/top_ups_controller.rb`, `app/controllers/webhooks/payments/*`

Flow:

```
Company selects a CREDIT_RATES[country] tier + a b2b CompanyPaymentMethod
      │
      ▼
TopUps::CreateService.call
      │  (one transaction)
      ├── CompanyOrder.create!  (money_amount_cents, credit_amount, rate snapshot)
      ├── CompanyInvoice.create!(payment_status: :unpaid)
      ├── CompanyTransaction.create!(status: :pending, gateway_reference: "TOPUP_<hex>", gateway_payload: {})
      │
      └── Payments::InitiateService.new(transaction: txn).call
            │  reads CompanyPaymentMethod.strategy → GATEWAY_STRATEGY_CLASSES
            ├── mock_qr_gateway      → returns { qr_string }      (scan to pay)
            └── mock_redirect_gateway→ returns { redirect_url }   (hosted checkout)
      │
      ▼  webhook (mock bank fires async POST)
Webhooks::Payments::MockQrGatewayController / MockRedirectGatewayController
      │  validates signature + amount, finds CompanyTransaction by gateway_reference
      ▼
txn.update!(status: :completed)
      │  after_update :sync_invoice_payment_status → CompanyInvoice.payment_status = paid
      │  after_update :complete_order_if_paid!     → CompanyOrder#complete!
      │        └─ wallet.add_credits!(credit_amount)   → main balance
      ▼
WEBSOCKET.publish_event(:top_up_completed)   → frontend redirects to Usage/Billing
```

### 5.2 Deduction (credits out)

**Files**: `app/controllers/concerns/companies/credit_deduction_concern.rb`, `app/services/company_credit_deduction/*`

Every consuming action (dashboard access, order creation, customer creation, ...) declares its deduction via an `after_action` filter — **never inline in the action**:

```ruby
class Companies::DashboardsController < Companies::ApplicationController
  deduct_company_credits_for :index, with: CompanyCreditDeduction::Companies::Dashboards::IndexService
end
```

The service drains the wallet in priority order:

```
CompanyCreditDeduction::BaseService#call
  ├── should_run? ── no ──► return
  ├── cost = CREDIT_USAGE_RATES[action_type] ── zero ──► return
  ├── wallet = company.company_wallet ── missing ──► return
  ├── deduct promo balance first     (drain as much as possible)
  ├── deduct main balance second     (drain the remainder)
  ├── absorb remainder into debt     (only when promo + main are exhausted)
  └── company.record_credit_usage!(cost)   ← Kredis counter, always
```

See `docs/CREDIT_DEDUCTION.md` for the full service hierarchy contract.

### 5.3 The Multi-Balance Wallet

**File**: `app/models/company_wallet.rb`

| Column | Purpose | Deduct order |
|--------|---------|--------------|
| `main_credit_balance` | Purchased credits (top-ups land here) | 2nd |
| `promo_credit_balance` | Promotional credits | **1st** |
| `debt_credit_balance` | Absorbed shortfall when promo + main are 0 | 3rd (accumulates) |

Low-level mutation entry points (the only wallet mutation paths — called by the deduction services and the chain):

```ruby
wallet.add_credits!(amount:, source:, description:)                   # top-up → main only
wallet.add_to!(balance: :promo, amount:, source:, description:)       # grant promo credits
wallet.deduct_from!(balance: :main, amount:, source:, description:)   # atomic per-balance deduct
```

- Every mutation runs inside `with_lock` (transaction + row-level `FOR UPDATE`) — concurrent deductions serialize on the wallet row, no overdraw.
- Every mutation writes a `CompanyWalletLog` audit row (`balance_type` main/promo/debt + before/after snapshots).
- `CompanyWallet#total_credit_balance` = `main + promo` (debt is not spendable).

### 5.4 Usage Metering (the hot path)

**Files**: `app/models/company.rb` (`kredis_counter :credit_usage`), `app/jobs/company_usage_sync_job.rb`, `app/models/company_daily_usage.rb`, `app/models/company_monthly_usage.rb`

```
Service → company.record_credit_usage!(10)      Kredis INCR (unsynced delta)
CompanyUsageSyncJob (periodic)                  drain counter → DB → reset to 0
Reads: today = DB total + Redis delta; past = DB only
```

- The counter is a plain accumulator — it only counts and resets; agnostic to the sync period.
- `CompanyDailyUsage` stores hourly slots (`h0`..`h23`), `CompanyMonthlyUsage` stores daily slots (`d1`..`d31`), both with a denormalized `total_credits` column.
- Callers go through the model wrappers only (`record_credit_usage!` / `credit_usage_delta`) — never the Kredis proxy directly (`docs/KREDIS.md`).
- Opt-in detail logging (`CompanyUsageLog`) records *why* a balance moved for a 5-minute window — toggle on the Usage page.

---

## 6. Domain 2: Commerce (B2C) — Company Charges the Customer

### 6.1 How Company Resources Connect to Orders (via OrderAppointment)

Any chargeable resource — `Product`, `Service`, `SubscriptionPlan` — becomes a line item through the `OrderConcern` and the polymorphic `OrderAppointment` join table:

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

`OrderAppointment` captures the **price snapshot at time of order** (`quantity`, `unit_price`, `total_price`), so later price changes don't affect existing orders.

### 6.2 The POS Payment Chain

**File**: `docs/ORDER_PROCESSING_V1.md` — full pipeline. Summary:

```
Frontend (Retail Cashier)
  │  cart (local state) → checkout (create Order) → pay (reserve stock + invoice) → finalize (async)
  ▼
Companies::OrderProcessing::V1Controller#checkout
  ├── CheckAvailabilityService   (Kredis available counter)
  ├── CreateOrderService         (Order pending + OrderAppointment line items + Walk-in customer)
  ▼
V1Controller#pay
  ├── PaymentMethodAppointment.branch_level.find_by!(id:, company_id:)
  └── InitiatePaymentService.call(order:, appointment:)
        ├── validates appointment (branch scope + active)
        ├── ReserveStockService   (atomic DECRBY + DB pending += qty)
        ├── Invoice.create!       (unpaid)
        ├── Transaction.create!(status: :pending, payment_method_id, gateway_reference: "POS_<hex16>")
        │
        ├── CASH mode → CompletePaymentService.call (synchronous) → txn completed → invoice paid → order paid
        └── QR mode  → gateway call (merchant identity from appointment) → txn.gateway_payload = { qr_string }
              │
              ▼  mock bank webhook
        Webhooks::Payments::MockQrGatewayController
              ├── resolves CompanyTransaction (top-ups) first, else Transaction (POS)
              └── OrderProcessingV1::CompletePaymentService.call(transaction:)
                    ├── txn.update!(status: :completed) → derives Invoice.payment_status
                    ├── order.workflow_status = :paid
                    └── FinalizeJob.perform_later (ledger + balances + export)

pay_cancel → CancelPaymentService (release reserved stock + mark txn failed)
```

### 6.3 Multiple Payments Per Invoice

A single invoice may be paid in installments (split tender / partial payments). The derivation rule handles it:

```
Invoice # price_cents: 50_00
  ├── Transaction #1: 20_00 (completed)  → SUM = 20_00 < 50_00 → unpaid
  └── Transaction #2: 30_00 (completed)  → SUM = 50_00 >= 50_00 → paid
If #2 is refunded (destroyed) → SUM = 20_00 → reverts to unpaid
```

---

## 7. PaymentMethod: The Global Bridge

`PaymentMethod` is a **global catalog** — it does not belong to any company. It defines **how money moves** in both domains via `payment_mode` (`qr` / `redirect` / `cash`) and `strategy` (maps to a gateway service class in `GATEWAY_STRATEGY_CLASSES`).

### 7.1 Two Flavors

| Model | Used by | Notes |
|-------|---------|-------|
| `CompanyPaymentMethod` | `CompanyTransaction` (credit chain / top-ups) | b2b-focused; seeded (Mock QR, Mock Redirect, Cash) |
| `PaymentMethod` | `Transaction` (POS sales) | linked to companies/branches via `PaymentMethodAppointment` |

Both share the `payment_mode` (`qr`/`redirect`/`cash`) and `strategy` enums.

### 7.2 Appointments (merchant identity)

`PaymentMethodAppointment` links a global `PaymentMethod` to a tenant scope — **Company** (default) or **Branch** — and holds the merchant bank identity (`merchant_number`, `merchant_name`, `merchant_id`) that gets embedded in QR strings (`ACC:`/`NAME:`/`MCC:` segments). This enables per-branch treasury (multi-account) or centralized treasury (single-account) routing without code changes. See `docs/PAYMENT_METHODS.md`.

### 7.3 Interaction Pattern

| `payment_mode` | Pattern | What Happens |
|----------------|---------|--------------|
| `:cash` | No gateway | Transaction completed synchronously (POS cash / wallet auto-debit) |
| `:qr` | Offline async | Gateway returns QR string; customer scans; bank webhook completes the transaction |
| `:redirect` | Online async | Gateway returns a hosted checkout URL; completion webhook completes the transaction |

`CompanyTransaction` / `Transaction` is created **first** with the payment method; the system uses the method to determine the gateway interaction. The gateway response always updates the transaction, never the invoice or order directly.

---

## 8. The Money Flow Tenets

These are immutable. Every developer and AI agent **must** follow them.

### Tenet 1: Transaction Is the Source of Truth

Invoice payment statuses, wallet balances, and usage are all **derived** from `CompanyTransaction` / `Transaction` records — never the other way around.

```
CompanyTransaction → CompanyInvoice.payment_status
Transaction       → Invoice.payment_status
CompanyTransaction → CompanyOrder.complete! → CompanyWallet balance
```

### Tenet 2: No Orphan Money

Every transaction **must** belong to an invoice (`company_invoice_id` / `invoice_id` is NOT NULL). Every `CompanyOrder` must link to exactly one `CompanyInvoice`. No orphan records, no dangling money.

### Tenet 3: No Direct Status Assignment

No code path may set `invoice.payment_status = :paid` directly. The only way an invoice becomes `paid` is the `sync_invoice_payment_status` callback triggered by a **completed** transaction lifecycle event.

```ruby
# ✅ CORRECT
txn.update!(status: :completed)   # → callback derives → paid

# ❌ FORBIDDEN
invoice.update!(payment_status: :paid)
```

### Tenet 4: Full Audit Trail

Every wallet mutation writes a `CompanyWalletLog` (`balance_type`, before/after snapshots, source, description). Every completed transaction records `money_amount_cents`/`price_cents`, `currency`, `gateway_reference`, and `gateway_payload` — enough to reconstruct financial state without external systems.

### Tenet 5: PaymentMethod Is the Final Link

Every money flow terminates at a `PaymentMethod` (or `CompanyPaymentMethod`) that defines the transfer mechanism: `:qr` (scan & pay), `:redirect` (hosted page), `:cash` (manual receipt).

### Tenet 6: Money Flows Through the Chain, Never Direct Writes

No service, controller, or job may write a wallet balance directly (`wallet.update!(main_credit_balance:)`). Credits move only through `CompanyOrder#complete!` → `wallet.add_credits!` (money in) and `CompanyCreditDeduction::*` → `wallet.deduct_from!`/`add_to!` (money out).

### Tenet 7: Transaction Is the Sole Gateway Interface

Only `CompanyTransaction` (top-ups) and `Transaction` (POS) communicate with external payment gateways. Invoices and orders never talk to gateways.

---

## 9. Enforcement Mechanisms

### 9.1 Callback Pattern (both transaction models)

```ruby
after_create  :sync_invoice_payment_status, if: :completed?            # (credit) / if completed && !price_cents.zero? (commerce)
after_update  :sync_invoice_payment_status, if: :completed?
after_destroy :sync_invoice_payment_status
```

Plus, in the credit chain:

```ruby
# CompanyInvoice
after_update :complete_order_if_paid!, if: :saved_change_to_payment_status? && paid?
```

### 9.2 Invoice-Level Guard

The invoice models never expose a public path to set `payment_status` — enforcement is architectural convention + code review. No service, controller, or job calls `invoice.update!(payment_status:)`.

### 9.3 Spec Requirements

Every money-moving feature test must assert derivation, not assignment:

```ruby
# Credit chain
expect(invoice.reload.payment_status).to eq("paid")
expect(invoice.company_transactions.sum(:money_amount_cents)).to be >= invoice.money_amount_cents
expect(company.company_wallet.reload.main_credit_balance).to eq(expected_main)

# Commerce
expect(invoice.reload.payment_status).to eq("paid")
expect(invoice.transactions.sum(:price_cents)).to be >= invoice.price_cents
```

### 9.4 What to Check in Code Review

| Smell | Problem |
|-------|---------|
| `invoice.update!(payment_status: :paid)` | ❌ Direct status assignment |
| `wallet.update!(main_credit_balance: ...)` outside the chain/deduction services | ❌ Direct balance write |
| `Transaction.create!` without `price_cents` / `CompanyTransaction` without `money_amount_cents` | ❌ No monetary value |
| Transaction without a payment method | ❌ Can't tell HOW money moved |
| `Invoice.gateway_call()` or `Order.gateway_call()` | ❌ Only transactions talk to gateways |
| Creating an invoice with no transaction in the same flow | ❌ Orphan invoice — never becomes paid |

---

## 10. Current Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| **Credit chain** (`CompanyOrder → CompanyInvoice → CompanyTransaction → CompanyWallet`) | ✅ Complete | `docs/ATOMIC_PURPOSE.md` |
| **Multi-balance wallet** (`main`/`promo`/`debt`, `with_lock` atomicity, wallet logs) | ✅ Complete | `app/models/company_wallet.rb` |
| **Top-up** (Mock QR + Mock Redirect gateways, webhooks, WS `top_up_completed`) | ✅ Complete | `app/services/top_ups/create_service.rb` |
| **Deduction** (`CompanyCreditDeduction::*` after_action, promo→main→debt) | ⚠️ Partial | Only `access_dashboard` wired (`Dashboards#index`); `create_order`/`create_customer` rates defined but no service classes yet |
| **Usage metering** (Kredis delta → `CompanyUsageSyncJob` → Daily/Monthly) | ✅ Complete | `docs/ATOMIC_PURPOSE.md` Hot Path Rule |
| **Opt-in usage logging** (`CompanyUsageLog`, 5-min window) | ✅ Complete | Usage page toggle |
| **POS Order Processing V1** (checkout → pay → finalize, cash + Mock QR) | ✅ Complete | `docs/ORDER_PROCESSING_V1.md` |
| **PaymentMethod / PaymentMethodAppointment** (global catalog + merchant identity) | ✅ Complete | `docs/PAYMENT_METHODS.md` |
| **Commerce Invoice/Transaction derivation** | ✅ Complete | `Transaction` `status` enum + completion-gated `sync_invoice_payment_status` |
| **Debt enforcement** (what happens when `debt_credit_balance > 0`) | ⬜ TBD | Tracked in `docs/ROADMAP.md` Phase 1.3 |
| **Real gateways** (MoMo / ZaloPay / VNPay / Stripe) | ⬜ Future | Mock strategies (`mock_qr_gateway`, `mock_redirect_gateway`) stand in |

---

## 11. Complete Lifecycle Scenario

This example traces a company through a full credit cycle — from consuming actions through top-up.

```
Day 1:  Company active, wallet promo_balance $500, main_balance $0
        (signup bonus promo credits)

09:00   Dashboard visit
        → Dashboards#index JSON
        → after_action CompanyCreditDeduction::Dashboards::IndexService (access_dashboard, 2)
        → promo -2, main unchanged, record_credit_usage!(2)

09:05   Customer creation
        → (future) Customers#create → CreateService (create_customer, 7)
        → promo -7, main unchanged, record_credit_usage!(7)

09:10   POS order paid (cash)
        → OrderProcessingV1: Transaction completed → Invoice paid → order paid → FinalizeJob
        → (future) create_order deduction (10)
        → promo -10, main unchanged, record_credit_usage!(10)

Wallet now: promo 481, main 0, debt 0

Usage sync runs → CompanyDailyUsage[09:00] += 2, [09:05] += 7, [09:10] += 10 (total 19)

Week 2:  Company consumes aggressively; promo drains to 0; main 0
         → next deduction: promo 0, main 0 → debt absorbs the shortfall
         → debt_credit_balance > 0 (behavior TBD — Phase 1.3)

Owner sees low balance warning on Usage page
  → navigates to Top Up
  → selects CREDIT_RATES tier (e.g. $5.00 → 500,000 credits)
  → selects Mock QR method
  → scans QR with banking app → mock bank webhook
  → CompanyTransaction completed → invoice paid → order complete! → wallet.add_credits!(500,000)
  → main balance +500,000; debt still 0 (TBD)
  → top_up_completed WS event → redirected to Usage
```

---

## 12. File Reference

| File | Purpose |
|------|---------|
| `app/models/company_order.rb` | Credit deal — `complete!` idempotent wallet credit |
| `app/models/company_invoice.rb` | Credit bill — `payment_status` derived + `complete_order_if_paid!` |
| `app/models/company_transaction.rb` | Credit ledger + gateway entry — `sync_invoice_payment_status` |
| `app/models/company_wallet.rb` | Multi-balance wallet — `add_credits!` / `add_to!` / `deduct_from!` |
| `app/models/company_payment_method.rb` | B2B payment method for the credit chain |
| `app/models/transaction.rb` | POS payment audit row — `sync_invoice_payment_status` (completed-gated) |
| `app/models/invoice.rb` | Customer bill — `payment_status` derived |
| `app/models/payment_method.rb` | Global payment gateway registry (`payment_mode`, `strategy`) |
| `app/models/payment_method_appointment.rb` | Company/branch link + merchant identity + lifecycle cascade |
| `app/services/top_ups/create_service.rb` | Creates the top-up chain + initiates gateway |
| `app/services/company_credit_deduction/base_service.rb` | Deduction core (promo → main → debt + metering) |
| `app/services/order_processing_v1/*` | POS pipeline services (checkout → pay → finalize) |
| `app/services/payments/*` | `InitiateService` + gateway strategies |
| `app/controllers/concerns/companies/credit_deduction_concern.rb` | `after_action` deduction DSL |
| `app/controllers/webhooks/payments/*` | Mock gateway webhooks (dual lookup: CompanyTransaction then Transaction) |
| `app/controllers/companies/top_ups_controller.rb` | Top-up page + gateway initiation |
| `app/jobs/company_usage_sync_job.rb` | Drains Kredis usage delta → Daily/Monthly usage tables |
| `config/initializers/constants.rb` | `CREDIT_RATES`, `CREDIT_USAGE_RATES`, `GATEWAY_STRATEGIES`, `GATEWAY_STRATEGY_CLASSES` |

---

## 13. Payment Gateway Architecture

### Core Principle

The payment process does one thing: **move a transaction from `pending` to `completed` (or `failed`).**

There is no payment logic in controllers, models, or jobs. Every gateway strategy is a self-contained service class that follows the same contract.

### Architecture

```
CompanyTransaction / Transaction
       │
       ▼
Payments::InitiateService
       │
       ├── Reads payment_method.strategy
       ├── Resolves class via GATEWAY_STRATEGY_CLASSES
       └── Instantiates and calls the gateway class
               │
               ▼
         Gateway Service (e.g., Payments::MockQrGateway)
               │
               ├── Builds API request
               ├── Calls external gateway (or returns immediately for system payments)
               └── Returns { success:, gateway_reference:, gateway_payload: }
```

### The Contract

Every gateway service class must:

1. Accept keyword arguments via `**kwargs` (splat) — each gateway receives all common params but only uses what it needs
2. Implement `#call` returning:
   - `{ success: true, gateway_reference: "...", gateway_payload: { ... } }` on success
   - `{ success: false, error: "..." }` on failure

### Adding a New Gateway

Three steps — no changes to InitiateService or controllers.

**1. Create the service class:**

```ruby
# app/services/payments/my_gateway.rb
module Payments
  class MyGateway
    def initialize(amount_cents:, invoice_id:, memo:, gateway_url:, secret_key:, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @memo = memo
      @gateway_url = gateway_url
      @secret_key = secret_key
    end

    def call
      response = call_external_api(...)

      if response.success?
        { success: true, gateway_reference: response.txn_id, gateway_payload: response.body }
      else
        { success: false, error: response.error }
      end
    end
  end
end
```

**2. Register the strategy:**

```ruby
# config/initializers/constants.rb

GATEWAY_STRATEGIES = {
  # ...
  my_gateway: 14   # next available number >= 10
}.freeze

GATEWAY_STRATEGY_CLASSES = {
  # ...
  my_gateway: "Payments::MyGateway"
}.freeze
```

**3. Create a `PaymentMethod` / `CompanyPaymentMethod` record** with the new strategy.

### Strategy Types

| Type | Value Range | Behavior | Examples |
|------|-------------|----------|---------|
| **System payments** | < 10 | Return success immediately — no external call | `Payments::Cash`, `Payments::WalletAutoDebit` |
| **External gateways** | >= 10 | Call external API, return result | `Payments::MockQrGateway`, `Payments::MockRedirectGateway` |

---

*End of document*
