# Skycom Discount Engine

> **Status**: Live (2026-09-22) — backend only. Single-use discount codes generated in
> bulk under campaign groups, reserved at POS pay, consumed only when the Invoice
> becomes paid, released on cancel, reverted (with budget refund) on the refund path.
> FE dashboards and a standalone apply endpoint are future work.

---

## 1. Overview

Two models, both **config/ledger-style** (no dynamic `property_*` slots, no
CategoryConcern/DynamicSearchConcern — the `Workflow` precedent):

| Model | Purpose |
|-------|---------|
| `DiscountGroup` | Campaign config: calculation type/value, budget cap + spend, validity window, campaign status |
| `Discount` | Single-use code ledger: unique code, consumption state, SoT bindings (order/invoice/customer/employee) |

Key business rules:

1. **Strictly single-use codes** — each `Discount.code` is unique per company (DB
   unique index on `[:company_id, :code]`) and can be consumed at most once.
2. **Batch generation** — codes are generated in bulk under a parent group using
   prefix-based high-entropy strings (`PREFIX-XXXXXXXX`).
3. **Deferred settlement (Invoice as SoT)** — applying a code at POS pay only
   *reserves* it (`pending`). A code is consumed **only when the associated
   Invoice transitions to paid**. Cancel releases it; refund reverts it.
4. **Auditability** — the Discount row directly captures `order_id`, `invoice_id`,
   `customer_id` (walk-in customers included), and `employee_id` (applied by)
   for complete traceability.

## 2. The Money-Flow Decision (why invoice price is reduced at creation)

Skycom's commerce chain derives `Invoice.payment_status` from
`SUM(completed transactions.price_cents) >= invoice.price_cents`
(`Transaction#sync_invoice_payment_status`, `docs/MONEY_FLOW.md` §4). That tenet is
**never modified**. Instead, the discount reduces the invoice **at creation**:

```
gross = order.order_appointments.sum(:total_price) * 100
invoice.price_cents = [ gross - discount.amount_cents, 0 ].max
```

Consequences:
- The customer pays the discounted amount — the `Transaction` is created with the
  discounted `price_cents` (amount the gateway/QR carries), so the derivation is
  automatically consistent.
- The `amount_cents` snapshot on the Discount (computed against the ORDER subtotal
  at reservation time) is the single source for the price reduction AND the budget
  accounting — never recomputed.
- Receipt shows the net subtotal (`invoice.price_cents`) plus a `discount_amount`
  display line (`Companies::OrdersController#receipt`).

## 3. Schema

### discount_groups

| Column | Purpose |
|--------|---------|
| `company_id` | Tenant scope |
| `name` / `description` / `code` / `prefix` | Identity; `prefix` is upcased via `normalizes` |
| `discount_type` | inline enum `{ fixed_amount: 0, percentage: 1 }` |
| `amount_cents` | fixed-amount value in cents (required for fixed_amount) |
| `percentage` (15,4) | percentage value 0–100 (required for percentage) |
| `max_amount_cents` | cap for percentage discounts (optional) |
| `total_budget_cents` / `current_spent_cents` | optional campaign budget + spent (default 0, NOT permittable — service-owned) |
| `campaign_status` | inline enum `{ draft: 0, active: 1, paused: 2, exhausted: 3 }` |
| `start_at` / `end_at` | validity window (`end_at > start_at` validated) |
| `currency` | `CURRENCIE_CODES` enum, validated to match the order at apply time |
| System Fields | standard block (`lifecycle_status`, `workflow_status`, `business_type`, `expiration_date`, `metadata`, `discarded_at`, `permission_resource_name`) |

Indexes: `code` unique, `[company_id, campaign_status]` composite.

### discounts

| Column | Purpose |
|--------|---------|
| `code` | unique per company (`[:company_id, :code]` index); upcased via `normalizes` |
| `status` | inline enum `{ unused: 0, pending: 1, used: 2, expired: 3 }` |
| `amount_cents` | snapshot of the computed discount at reservation |
| `used_at` | consumption timestamp |
| `order_id` / `invoice_id` | reservation binding (order) → consumption binding (invoice) |
| `customer_id` | derived from `order.customer` at reservation |
| `employee_id` | the employee who applied the code (FK → `employees`) |
| System Fields | standard block |

Indexes: `[:company_id, :code]` unique, `[discount_group_id, :status]`, `status`.

## 4. State Machine

### Transition Matrix

| Current | Trigger | Target | Side effects |
|---------|---------|--------|--------------|
| `unused` | Clerk pays with the code (`InitiatePaymentService` → `Discounts::ApplyService`) | `pending` | Binds `order_id`, `customer_id`, `employee_id`, snapshots `amount_cents` |
| `pending` | Invoice becomes **paid** (`Invoice#sync_discount_state`) | `used` | Sets `used_at`, binds `invoice_id`, `discount_group.adjust_spent!(+amount)` (may flip group to `exhausted`) |
| `pending` | Pay cancelled (`CancelPaymentService`) / initiation failure | `unused` | Clears all bindings + amount (`Discount#release!`) |
| `used` | Invoice **leaves** paid — transaction destroyed → re-derived `unpaid` (refund/void) | `unused` | `discount_group.adjust_spent!(-amount)` (reactivates an exhausted group), clears all bindings (`Discount#revert!`) |

### Consumption/Reversal hook (single point)

`Invoice#sync_discount_state` (`app/models/invoice.rb`) — fires on
`after_update, if: :saved_change_to_payment_status?`:

```ruby
def sync_discount_state
  if paid?
    order.discounts.status_pending.find_each { |discount| discount.consume!(invoice: self) }
  else
    discounts.status_used.find_each(&:revert!)
  end
end
```

Consume goes through the **order** (the pending code is bound to the order until
the invoice that consumes it exists). This is the commerce-chain mirror of
`CompanyInvoice#complete_order_if_paid!` — a rare money event using a callback,
per `docs/ATOMIC_PURPOSE.md`.

### Budget accounting

`DiscountGroup#adjust_spent!(delta_cents)` runs inside `with_lock` (row lock):
- `current_spent_cents += delta`
- spend reaches `total_budget_cents` → `campaign_status = exhausted`
- an exhausted group dropping under the cap (refund) → back to `active`

## 5. Services (result-hash contract, `docs/PURCHASE_WORKFLOW.md` style)

| Service | Contract | Notes |
|---------|----------|-------|
| `Discounts::BatchGenerator.call(discount_group:, quantity:, code_length: 8)` | `{ success:, generated: } \| { success: false, errors: [...] }` | One `insert_all!`; `PREFIX-XXXXXXXX`; in-memory `Set` collision guard vs all company codes; DB unique index is the race guard. Quantity 1..1000, code length 4..64, prefix-length overflow guard |
| `Discounts::ApplyService.call(company:, order:, code:, employee: nil)` | `{ success:, discount: } \| { success: false, errors: [...] }` | Row-locked (`lock.find_by`) lookup of an `unused` code → group active + in window → currency match → amount > 0 → budget check → `reserve!` |
| `Discounts::ReleaseService.call(discount: \| order:)` | `{ success:, released: n }` | Releases `pending` codes only (never `used`) |

## 6. POS Integration Sequence

```
Retail Cashier → POST /companies/:id/order_processing/v1/pay
                   { order_id, payment_method_appointment_id, discount_code? }
      │
      ▼
InitiatePaymentService.call(order:, appointment:, discount_code:, employee:)
  ├── validate_appointment!
  ├── apply_discount!                     Discounts::ApplyService → code unused → pending
  ├── ReserveStockService                 (any failure here → discount&.release!)
  ├── transaction:
  │     ├── create_invoice                price_cents = gross - discount.amount_cents
  │     ├── create_transaction            price_cents = invoice.price_cents (net)
  │     ├── CASH → CompletePaymentService → txn completed
  │     │     └─ Transaction callback derives Invoice.payment_status = paid
  │     │         └─ Invoice#sync_discount_state → discount.consume! → group budget +
  │     └── QR  → gateway (merchant identity) → txn pending; code stays pending
  │           └─ webhook → CompletePaymentService → same consumption chain
  │
  └── pay_cancel → CancelPaymentService → ReleaseReservedStockService
                    + Discounts::ReleaseService (code → unused) + txn failed
```

- Pay accepts `discount_code` (optional). Invalid code → `InvalidDiscountError` →
  422 `{ errors: [...] }` — nothing created, code untouched, stock untouched
  (discount is applied **before** stock reservation).
- Response gains `discount_amount_cents` when a discount was applied.
- Receipt payload gains `discount_amount`.

## 7. Permission Model

- `DiscountGroup` + `Discount` are in `Company::DEFAULT_RESOURCE_NAMES` → every new
  company gets auto CRUD policies ("Can create/read/update/delete …") via
  `Seed::RetailInitService#create_all_crud_policies`. Existing companies need a
  re-seed (or manual policy creation) to get them.
- `Companies::DiscountGroupsPolicy` + `Companies::DiscountsPolicy` map actions to
  ABAC (`record.can?`); `generate_codes` maps to `update`. Auto-derived by
  `Companies::Authorizable` — no explicit authorize calls.
- Role grants (retail init): Admin + Manager full CRUD on both resources. Owner
  bypass covers owners.

## 8. Testing

| Spec | Coverage |
|------|----------|
| `spec/models/discount_group_spec.rb` | validations (scoped uniqueness, type-conditional money fields, window), `currently_active?`, `adjust_spent!` exhaust/reactivate |
| `spec/models/discount_spec.rb` | code uniqueness scope, cross-company guard, `compute_amount_cents`, all four transitions |
| `spec/models/invoice_discount_sync_spec.rb` | consume on paid / revert on leave-paid / exhausted reactivation / no-op on other updates |
| `spec/services/discounts/batch_generator_spec.rb` | bulk insert, prefix format, cross-group collisions, quantity + code-length guards (incl. nil code_length) |
| `spec/services/discounts/apply_service_spec.rb` | reserve success + snapshot, case-insensitive lookup, unknown/pending/used, paused/window, currency, budget, zero subtotal |
| `spec/services/discounts/release_service_spec.rb` | by order / by object, used untouched |
| `spec/services/order_processing_v1/initiate_payment_service_spec.rb` | discounted cash invoice + consumption, QR pending, `InvalidDiscountError` cleanliness, gateway-failure release |
| `spec/services/order_processing_v1/cancel_payment_service_spec.rb` | releases the reserved code |
| `spec/requests/companies/discount_groups_controller_spec.rb` | CRUD, `current_spent_cents` not permittable, generate_codes + 422 + 403, scoping |
| `spec/requests/companies/discounts_controller_spec.rb` | index + filters (status/group), show, scoping, foreign 404 |

Run: `bundle exec rspec spec/models/discount_group_spec.rb spec/models/discount_spec.rb \
spec/models/invoice_discount_sync_spec.rb spec/services/discounts \
spec/services/order_processing_v1 spec/requests/companies/discount_groups_controller_spec.rb \
spec/requests/companies/discounts_controller_spec.rb spec/requests/companies/order_processing`

## 9. Not Built Yet (future phases)

| Item | Notes |
|------|-------|
| FE dashboards | Stimulus controllers for discount groups (CRUD + code grid) — `Serves Stimulus:` headers already reference the future pairs |
| Standalone apply endpoint | Dashboard/invoice apply (currently POS pay only) |
| Auto-expiry sweeper | `expired` enum exists; enforcement today is apply-time window check only |
| Approval flow | `requires_approval`/threshold was cut from v1 (YAGNI) |
| Hospital init grants | Retail-only grants; mirror in `HospitalInitService` when the hospital track needs discounts |
| Real gateways | Mock QR/Redirect stand-ins (see `docs/MONEY_FLOW.md` §13) |

## 10. File Reference

| File | Purpose |
|------|---------|
| `app/models/discount_group.rb` | Campaign config + budget mutation (`adjust_spent!`) |
| `app/models/discount.rb` | Code ledger + state transitions (`reserve!/consume!/release!/revert!`) |
| `app/models/invoice.rb` | `sync_discount_state` callback + `has_many :discounts` |
| `app/services/discounts/batch_generator.rb` | Bulk code generation |
| `app/services/discounts/apply_service.rb` | Reservation phase |
| `app/services/discounts/release_service.rb` | Pending → unused |
| `app/services/order_processing_v1/initiate_payment_service.rb` | Pay-time apply + discounted invoice + failure cleanup |
| `app/services/order_processing_v1/cancel_payment_service.rb` | Cancel path release |
| `app/services/order_processing_v1/invalid_discount_error.rb` | POS error class |
| `app/controllers/companies/discount_groups_controller.rb` | Group CRUD + `generate_codes` |
| `app/controllers/companies/discounts_controller.rb` | Code ledger (read-only) |
| `app/policies/companies/{discount_groups,discounts}_policy.rb` | ABAC policies |
| `app/services/seed/discount_group_service.rb` / `discount_service.rb` | Seed services |
| `app/services/seed/retail_init_service.rb` | Role grants |
| `app/services/seed/retail_enrich_service.rb` | Dev sample groups + codes |
| `db/migrate/20260922000001_create_discount_groups.rb` / `20260922000002_create_discounts.rb` | Schema |

---

*See also: `docs/MONEY_FLOW.md` (payment derivation tenets), `docs/ORDER_PROCESSING_V1.md`
(POS pipeline), `docs/ABAC.md` (permissions), `docs/CONSTANTS.md` (single-file constants
in `Discounts::BatchGenerator`).*
