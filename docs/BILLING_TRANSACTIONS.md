# Skycom Billing Transactions — Source of Truth for Money Movement

## 1. Core Principle

**Every money movement in Skycom must be recorded as a BillingTransaction, and every BillingTransaction must belong to a BillingInvoice.** The company's wallet balances (`main_balance_cents`, `promo_balance_cents`) and each invoice's `payment_status` are derived from the transaction records — the `billing_transactions` table is the accounting ledger.

```
BillingInvoice (the "why" — what happened)
├── movement_type: deposit | charge
├── target_balance: main_balance | promo_balance
├── created_by: system | customer
├── price_cents: the expected amount
│
├── has_many BillingTransactions (the "what" — how it was settled)
│   ├── amount_cents: how much moved
│   ├── billing_invoice_id: FK (required)
│   └── balance before/after snapshots
│
└── payment_status (derived from transactions)
    └── paid if SUM(transactions.amount_cents) >= price_cents
```

## 2. How Invoices Classify Money Movement

Each `BillingInvoice` has two classifying enums:

### movement_type

| Value | Direction | Example |
|-------|-----------|---------|
| `deposit` (0) | Money flows INTO the company wallet | Top-up, promo credit |
| `charge` (1) | Money flows OUT of the company wallet | Monthly billing deduction |

### target_balance

| Value | Affects | Example |
|-------|---------|---------|
| `main_balance` (0) | Company `main_balance_cents` | Top-ups, monthly billing |
| `promo_balance` (1) | Company `promo_balance_cents` | Promotional credits |

### created_by

| Value | Who created it | Example |
|-------|----------------|---------|
| `system` (0) | Skycom platform (auto-generated) | Monthly billing, promo credits |
| `customer` (1) | Company-initiated | Manual top-up |

### Example Invoice Combinations

| Invoice Type | movement_type | target_balance | created_by | Effect |
|-------------|---------------|----------------|------------|--------|
| Monthly billing charge | `charge` | `main_balance` | `system` | Decreases `main_balance_cents` |
| Company top-up | `deposit` | `main_balance` | `customer` | Increases `main_balance_cents` |
| Promotional credit | `deposit` | `promo_balance` | `system` | Increases `promo_balance_cents` |

## 3. How Payment Status Works

The `payment_status` column on `BillingInvoice` is **not set directly** by business logic. Instead, it is **derived from the sum of BillingTransactions** linked to that invoice:

```
total = SUM(billing_transactions.amount_cents)

if total >= invoice.price_cents  →  :paid
if total == 0                     →  :unpaid
```

This is enforced by a `BillingTransaction` callback:

```ruby
# app/models/billing_transaction.rb
after_create_commit :sync_invoice_payment_status
after_destroy_commit :sync_invoice_payment_status

def sync_invoice_payment_status
  total = billing_invoice.billing_transactions.sum(:amount_cents)
  new_status = total >= billing_invoice.price_cents ? :paid : :unpaid
  billing_invoice.update!(payment_status: new_status)
end
```

Whenever a transaction is created or destroyed, it triggers a recomputation of the parent invoice's status. This means:

- **Transactions are the source of truth** — the `payment_status` column is a cached computation
- **No bypassing** — you cannot mark an invoice as `paid` directly without creating a transaction
- **Auto-recovery** — if a transaction is deleted (e.g., void/refund), the invoice automatically reverts to `unpaid`

## 4. How Company Balances Are Updated

Company balances (`main_balance_cents`, `promo_balance_cents`) are updated **by the same service that creates the BillingTransaction**. The balance update and the transaction creation happen together as a unit:

### Deduction (SettlementService)

```ruby
# Billing::SettlementService
company.update_columns(main_balance_cents: main_after)  # bypasses callbacks
BillingTransaction.create!(
  company: company,
  billing_invoice: invoice,
  transaction_type: :deduction,
  amount_cents: amount,
  balance_before_cents: main_before,
  balance_after_cents: main_after,
  # ...
)
```

### Top-Up (future implementation)

```ruby
# Companies::TopUpsController or TopUpService
invoice = BillingInvoice.create!(
  company: company,
  movement_type: :deposit,
  target_balance: :main_balance,
  price_cents: amount,
  # ...
)

# After payment confirmation:
company.update_columns(main_balance_cents: company.main_balance_cents + amount)
BillingTransaction.create!(
  company: company,
  billing_invoice: invoice,
  transaction_type: :top_up,
  amount_cents: amount,
  # ...
)
```

## 5. Balance Recovery

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

## 6. Rules (Enforced by Design)

1. **Every BillingTransaction MUST belong to a BillingInvoice** — `billing_invoice_id` is `NOT NULL` at the database level
2. **Every BillingInvoice's payment_status IS derived from its transactions** — no code should set `payment_status` directly (the callback handles it)
3. **Company balances are updated alongside transactions** — the creator service updates both together
4. **No orphan money movements** — every cent that enters or leaves a company balance has a trail back to an invoice

## 7. See Also

- `docs/BILLING.md` — Full billing system documentation
- `app/models/billing_transaction.rb` — Model with callback logic
- `app/models/billing_invoice.rb` — Invoice model with enums and scopes
- `app/services/billing/settlement_service.rb` — Deduction logic
