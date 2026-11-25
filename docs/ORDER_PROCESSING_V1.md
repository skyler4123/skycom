# Skycom Order Processing V1

> **2026-11-25 per-resource tax update.** The till uses server-owned prices,
> sells services through `OrderServiceAppointment`, snapshots each line's tax
> code/rate/treatment on the order and invoice, supports mixed tax-added and
> tax-included lines, groups tax by code on receipts and Tax Data, supports
> discount apply/remove on the pending order, voids a pending order, prints an
> 80 mm slip, locks the terminal server-side, and resolves one selling-stock
> pile per product. The current contract is summarized in §1.1. Older sections
> below that still describe a client `unit_price`, one company-wide tax rate, or
> a local-only cancel are superseded by §1.1.

## 1. Overview

The **Order Processing V1** pipeline is a multi-step POS order lifecycle that connects the POS frontend to backend services, a controller API, a background job, and KRedis-based stock tracking.

### 1.1 Current POS contract (2026-11-19)

- **Cart → ORDER.** `POST checkout` accepts `{ branch_id, customer_id?, items: [{ product_id|service_id, quantity }] }`.
  The server resolves the catalog record and its selling stock row, writes the
  `Order` plus `OrderProductAppointment` / `OrderServiceAppointment` lines, and
  snapshots each line's tax code, name, rate, inclusive flag, taxable cents, and
  tax cents. A missing code falls back to the company default. The response is
  in cents: `subtotal_cents`, `tax_cents`, `added_tax_cents`, `total_cents`,
  `currency`, `tax_lines`, `items`. A client-supplied `unit_price` is ignored; a
  stale display is refreshed from the response.
- **Discount.** `POST apply_discount` reserves a single-use code on the pending
  order and returns the new totals. `POST remove_discount` releases it. Pay
  uses the pending reservation; a code passed to pay replaces it only after the
  new reservation succeeds.
- **Pay.** `POST pay` with `{ order_id, payment_method_appointment_id, cash_received_cents? }`.
  The `Invoice` is created with `price_cents = total` (subtotal − discount +
  added tax), `tax_cents`, `total_cents`, and the grouped `tax_breakdown`
  snapshot. Cash validates
  received ≥ total and stores `cash_received_cents` / `change_cents` on the
  transaction. QR returns a token + `qr_string` and waits for the webhook.
- **Void.** `POST cancel` marks the order `cancelled`, fails pending
  transactions (releasing stock holds and the discount), and voids unpaid
  invoices. Paid orders are refused; refunds stay in Orders.
- **Receipt.** `GET receipt` returns cents, branch, cashier, line items,
  subtotal, discount/code, grouped `tax_lines`, total, tender, cash received,
  change.
- **Lock.** `POST lock` / `POST unlock` set/clear a company-scoped session flag.
  Money endpoints return `423 { errors: ["Terminal is locked"] }` while locked.
- **Tax.** Each product/service owns a tax code; blank falls back to the Tax
  Config default. `OrderTotalsService` allocates the discount proportionally,
  then computes tax per line. A code either adds tax on top or extracts it from
  the gross price. Zero tax hides the row. The order line and invoice keep the
  snapshot, so later code edits never rewrite a sale.
- **Stock.** `Pos::SellingStockResolver` picks the branch's main warehouse
  first, then the oldest, and the first warehouse in that order with available
  stock. The label names it; the order line persists that `stock_id`; pay
  reserves the same row.



### Core Flow

```
Cart (local state) → checkout (create Order) → pay (reserve stock + invoice) → finalize (async: ledger + balances + export)
```

### Architecture Layers

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Frontend** | `controllers/companies/operations/pos/show_controller.js` | Cart state machine, two-phase ORDER/COMPLETE PAYMENT buttons |
| **Controller** | `controllers/companies/order_processing/v1_controller.rb` | HTTP API for checkout + pay |
| **Services** | `services/order_processing_v1/` | 7 services forming the pipeline |
| **Job** | `jobs/order_processing_v1/finalize_job.rb` | Async finalization after payment |
| **Routes** | `config/routes.rb` | 2 custom POST routes |
| **URL Helpers** | `controllers/helpers/url_helpers.js` | 2 JavaScript path helpers |

---

## 2. Pipeline Flow Diagram

```
Frontend (JS)                    Controller                    Services                    Job / Async
─────────────                    ──────────                    ────────                    ──────────

addToCart() ── local state only

initiateOrder()                  CHECKOUT
  │
  └── POST /order_processing/v1/checkout
        body: { branch_id, items: [{product_id|service_id, quantity}] }
        │
        ▼
    V1Controller#checkout
      │
      ├── CheckAvailabilityService.call(items:)
      │     └── reads stock.available_counter (KRedis)
      │         └── failure → 422 { errors: ["Insufficient stock for item ..."] }
      │
      ├── CreateOrderService.call(company:, branch:, items:, customer:)
      │     ├── Order.create!(workflow_status: :pending)
      │     ├── OrderProductAppointment.insert_all!(items)
      │     └── creates "Walk-in Customer" if none provided
      │
      └── 201 { order_id, subtotal_cents, tax_cents, total_cents, currency, items }

pay()                              PAY
  │
  └── POST /order_processing/v1/pay
        body: { order_id, payment_method_appointment_id }
        │
        ▼
    V1Controller#pay
      │
      ├── BranchPaymentMethodAppointment.find_by!(id:, company_id:)   ← branch-scoped
      │
      └── InitiatePaymentService.call(order:, appointment:)
            │
            ├── validates: appointment.branch == order.branch + lifecycle active
            ├── ReserveStockService.call(items:)  → { reserved: [...] }
            │     └── KRedis DECRBY stock:<id>:available
            ├── Invoice.create! (payment_status: unpaid)
            ├── Transaction.create!(status: :pending, payment_method_id:,
            │     gateway_reference: "POS_<hex16>")
            │
            ├── CASH mode → CompletePaymentService.call(transaction:)   (synchronous)
            │     └── txn completed → invoice paid → order paid
            │
            └── QR mode → GATEWAY_STRATEGY_CLASSES[strategy] gateway call
                  │     (merchant_number/name/id from the appointment)
                  └── txn.gateway_payload = { qr_string }
                        │
                        ▼
              Mock API webhook → Webhooks::Payments::MockQrGatewayController
                    ├── resolves CompanyTransaction (top-ups) first, else Transaction (POS)
                    └── CompletePaymentService.call(transaction:)
                          │
                          ├── Transaction.update!(status: :completed)
                          │     └── after_update callback derives Invoice.payment_status
                          ├── invoice/order workflow_status = :paid
                          └── WEBSOCKET pos_payment_completed { transaction_token, order_id }

pay_cancel()                       PAY CANCEL (abandoned QR)
  │
  └── POST /order_processing/v1/pay_cancel
        body: { transaction_token }
        │
        ▼
    V1Controller#pay_cancel
      └── CancelPaymentService.call(transaction_token:, company:)
            ├── ReleaseReservedStockService.call(order:)   ← restores availability + pending
            └── Transaction.update!(status: :failed)

                                                    ┌─ FinalizeJob#perform(order_id)
                                                    │   (idempotent guards)
                                                    │   ├── order.workflow_status == "paid"?
                                                    │   └── StockExport.exists? for this order?
                                                    │
                                                    ├── WriteStockLedgerService.call(order:)
                                                    │     └── per line: StockMovementService::BaseService
                                                    │         (consume_hold: true) → StockTransaction created
                                                    │           └─ hardened callback: quantity -= qty,
                                                    │              pending hold released, Redis synced
                                                    │
                                                    └── FinalizeOrderService.call(order:)
                                                          └── StockExport.create!(business_type: :sale)
                                                              └── links to Order via appoint_for
```

---

## 3. Frontend — POS Controller

**File**: `app/javascript/controllers/companies/operations/pos/show_controller.js`
**Class**: `Companies_Operations_Pos_ShowController`
**Extends**: `Controller` (standalone, not layout)

The same controller also powers the mobile POS page. `Mobile::Companies::Operations::PosController#show`
returns a Shell-First mount point with `data-company-id` / `data-operation-id`;
the controller reads those attributes (falling back to the web URL path) and
hydrates from the same `/companies/:company_id/operations/pos/:operation_id.json`
endpoint. See `docs/MOBILE.md` §4.

### 3.1 Cart → Order Link (click item to DB)

Clicking a product/service card does **not** hit the backend — it mutates local `tabs[].items[]` only. The DB link is created later by `ORDER`.

```
Card (renderProductCard) ── data-action="click->...#addToCart" + params {kind, id, name, priceCents, stockQuantity}
        │
        ▼ addToCart(event)
        ├── if (this.orderId || this.locked) return
        ├── priceSet === false → warn; product stock 0 → warn
        ├── existing ? qty++ (capped at stockQuantity) : push({ kind, id, name, priceCents, qty:1 })
        └── renderContent() → cart + Subtotal/Discount/Tax/Total (cents)
        │
        ▼ initiateOrder() — only here does the cart flush to DB
        items = activeTab.items.map(i =>
          i.kind === "service" ? { service_id: i.id, quantity: i.qty }
                               : { product_id: i.id, quantity: i.qty })
        POST /order_processing/v1/checkout { branch_id, customer_id?, items } → CreateOrderService
                └── server price + selling stock + tax snapshot; Order + lines
        pay later reads the persisted line snapshots — never trusts the click params.
```

The cart is per tab: `orderId`, `orderTotalCents`, `appliedDiscount`,
`cashReceivedCents`, `awaitingToken`, and `receipt` live on the tab. Paid
receipts are not persisted; open carts are saved in localStorage.

### State Machine

The controller implements a two-phase POS flow:

```
State ──► ORDER phase ──► COMPLETE PAYMENT phase ──► back to ORDER
              │                    │
         Cart editable         Cart locked
         ORDER button          COMPLETE PAYMENT + Cancel
```

### Key State Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `currency` | `string` | `usd` | Company currency from the POS payload; every amount uses `Helpers.formatMoney`. |
| `taxLines` | `Array` | `[]` | Per-tab server tax breakdown; used after ORDER, discount, and pay. |
| `addedTaxCents` | `number` | `0` | Per-tab tax added on top; tax-included lines do not change the total. |
| `catalogMeta` | `Object` | `{ limit: 50, products_total: 0, services_total: 0 }` | Cap counts for "Showing 50 of N". |
| `viewMode` | `"grid"\|"list"` | `"grid"` | Catalog layout; persisted in localStorage. |
| `locked` | `boolean` | `false` | Server terminal lock state; the overlay is only the visual half. |
| `tabs` | `Array` | `[]` | Per-customer carts; each carries `{ id, name, customer, items, orderId, orderTotalCents, appliedDiscount, cashReceivedCents, awaitingToken, taxLines, addedTaxCents }`. |
| `selectedCategoryName` | `string\|null` | `null` | Active catalog filter (`null` = All). |
| `searchQuery` | `string` | `''` | Search/scan filter; non-blank queries ask the server (Meilisearch). |
| `products` / `services` | `Array` | `[]` | Server cents, `price_set`, `category_*`, per-item `tax`, product `stock_quantity` + `stock_warehouse_name`. |

### Order Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `initiateOrder()` | `async ()` | POSTs product/service ids + quantities; sets the tab order and applies the server's per-item tax snapshots, `tax_lines`, and line prices. |
| `applyDiscount()` / `removeDiscount()` | `async ()` | Reserve/release a code on the pending order and render the server totals. |
| `pay()` | `async ()` | POSTs `{ order_id, payment_method_appointment_id, cash_received_cents }`. `paid` → receipt; `pending` → QR wait + `pos_payment_completed`. |
| `cancelOrder()` | `async ()` | Confirms "Void this order?", calls `POST cancel`, and unlocks the cart only on success. |

### Cart Locking Rules

When `this.orderId` is set, these methods are guarded:
- `addToCart()` — returns immediately (line 130: `if (this.orderId) return`)
- `removeFromCart()` — returns immediately
- `updateQty()` — returns immediately

The locked cart template (in `renderCartItems`) renders items as read-only text without qty adjusters or remove buttons.

### Cart-to-Order Mapping

`initiateOrder()` maps every line, including services, and sends no price:

```javascript
{
  branch_id: this.appointment.branch.id,
  items: this.activeTab.items.map(item =>
    item.kind === "service"
      ? { service_id: item.id, quantity: item.qty }
      : { product_id: item.id, quantity: item.qty }
  )
}
```

The server resolves the product/service, the selling warehouse stock row, the
price, and the tax snapshot. The response refreshes any stale cart line before
COMPLETE PAYMENT is available.

Items without `stockId` (services, non-tracked products) are excluded from the checkout payload.

### Catalog Filters & Customer Lookup

- **Category pills** — `catalogCategories` merges `currentCategories()` (client_cache, `resource_name` = `products`/`services`) with the category names carried by the loaded catalog. Clicking a pill filters products and services by `selectedCategoryName`; `All` resets it.
- **Search / barcode** — the search input filters products and services by name/code in place. Enter tries an exact product `code` match and adds it to the cart (F1 focuses the input).
- **Customer lookup** — `GET /companies/:company_id/operations/pos/:operation_id/customer_lookup?q=&branch_id=` (`PosController#customer_lookup`, authorized by `PosPolicy#customer_lookup?` = `show?`). UUIDs are exact DB lookups; every text query goes through Meilisearch (`Customer.ms_raw_search`, company-filtered) over name, code, email, and `property_string_1..5` (phone-like slots), returning `{ customer: { id, name, code, email, membership } }` or `{ customer: nil }`. The selected customer is stored on the active tab, displayed with its membership tier, and passed as `customer_id` to checkout.

---

## 4. Controller

**File**: `app/controllers/companies/order_processing/v1_controller.rb`
**Class**: `Companies::OrderProcessing::V1Controller < Companies::ApplicationController`

### `checkout`

**POST** `/companies/:company_id/order_processing/v1/checkout`

**Params** (via `checkout_params`):
```ruby
params.permit(:branch_id, :customer_id, items: [ :product_id, :service_id, :quantity ])
```

| Param | Required | Description |
|-------|----------|-------------|
| `branch_id` | Yes | Branch UUID scoped to current company |
| `customer_id` | No | Existing Customer UUID; creates a timestamped Walk-in if absent |
| `items[]` | Yes | At least one product or service line |
| `items[][product_id]` | One of | Product UUID scoped to company + branch |
| `items[][service_id]` | One of | Service UUID scoped to company + branch |
| `items[][quantity]` | Yes | Integer ≥ 1 (string auto-converted via `.to_i`) |

No `unit_price` and no `stock_id` are accepted. The server resolves the
catalog record, its price, and `Pos::SellingStockResolver`'s selling stock row.

**Flow:**
1. `CreateOrderService` resolves items, checks availability against the
   resolved stock, snapshots each line's tax code/rate/treatment, and writes the
   `Order` plus `OrderProductAppointment` / `OrderServiceAppointment` rows in one
   transaction.
2. Returns `201 Created` with `order_id`, `currency`, `subtotal_cents`,
   `tax_cents`, `added_tax_cents`, `total_cents`, `tax_lines`, and authoritative
   `items[]` (`kind`, `id`, `quantity`, `unit_price_cents`, `total_cents`, `tax`).
3. `422 { errors: [...] }` for an unknown/foreign item, unset price, unstocked
   product, quantity < 1, or insufficient stock.

### `apply_discount` / `remove_discount`

**POST** `/companies/:company_id/order_processing/v1/apply_discount`
**POST** `/companies/:company_id/order_processing/v1/remove_discount`

`{ order_id, discount_code }` / `{ order_id }`. Apply reserves a single-use
code on the pending order (`Discounts::ApplyService`); remove releases it
(`Discounts::ReleaseService`). Both return `discount` (`code`,
`amount_cents`, or `null`) plus `subtotal_cents`, `discount_cents`,
`tax_cents`, `added_tax_cents`, `total_cents`, `currency`, `tax_lines`,
`message`. Invalid codes return
`422 { errors: [...] }` without changing the order.

### `pay`

**POST** `/companies/:company_id/order_processing/v1/pay`

**Params:**
```ruby
params.permit(:order_id, :payment_method_appointment_id, :discount_code, :cash_received_cents)
```

**Flow:**
1. Loads the tenant-scoped pending order (paid/cancelled → 422) and the
   branch-level appointment (foreign/inactive → 422).
2. Uses the order's pending discount, or reserves `discount_code` if supplied.
   A new code replaces the old reservation only after the new one succeeds.
3. Computes totals through `OrderTotalsService`: proportional discount
   allocation + per-line tax, then creates the `Invoice` with
   `price_cents = total_cents = subtotal − discount + added tax`, `tax_cents`,
   and `metadata["tax_breakdown"]`.
4. Cash validates `cash_received_cents ≥ total`, stores received/change on the
   transaction, and completes synchronously. QR calls the gateway and returns
   a pending token + `qr_string`.
5. Returns `200 OK` with `status`, `order_id`, `subtotal_cents`,
   `discount_cents`, `tax_cents`, `total_cents`, `currency`,
   `cash_received_cents`, `change_cents`, and the transaction/QR identifiers.

### `cancel`

**POST** `/companies/:company_id/order_processing/v1/cancel`

`{ order_id }` → `CancelOrderService` marks the order `cancelled`, cancels
pending transactions (releasing stock holds and the discount), and voids
unpaid invoices. Paid orders return `422 { errors: [...] }`. The response is
`{ message: "Order voided" }`; already-cancelled orders are idempotent.

### `receipt`

**GET** `/companies/:company_id/orders/:order_id/receipt`

Returns cents, not floats: `invoice_code`, `issued_at`, `payment_status`,
`currency`, `branch_name`, `cashier_name`, line items (`name`, `quantity`,
`unit_price_cents`, `total_cents`, `tax_cents`, `tax_name`, `tax_rate_bp`,
`tax_inclusive`, `kind`), `subtotal_cents`, `discount_cents`/`discount_code`,
`tax_cents`, grouped `tax_lines`, `total_cents`, `payment_method_name`,
`cash_received_cents`, `change_cents`. Invoices without a breakdown fall back
to the order's line snapshots.
404 when the order is unknown or belongs to another company.

### `pay_cancel`

**POST** `/companies/:company_id/order_processing/v1/pay_cancel`

**Params:** `{ transaction_token }`

Cancels an abandoned QR payment: releases reserved stock and marks the pending Transaction `failed`. Returns `{ status: "cancelled" | "not_pending" }`.

### Error Responses

| Scenario | Status | Body |
|----------|--------|------|
| Insufficient stock (checkout) | 422 | `{ errors: ["Insufficient stock for item ..."] }` |
| Insufficient stock (pay) | 422 | `{ errors: ["Insufficient stock for payment"] }` |
| Invalid/inactive/foreign-branch payment method | 422 | `{ errors: ["Payment method is not available for this branch"] }` |
| Invalid discount code (pay) | 422 | `{ errors: ["Discount code not found or already used", ...] }` (`docs/DISCOUNTS.md` §6) |
| Cash received below total | 422 | `{ errors: ["Cash received is less than the total"] }` |
| Paid/cancelled order at pay | 422 | `{ errors: ["Order is not payable"] }` |
| Paid order at cancel | 422 | `{ errors: ["Paid orders cannot be voided here"] }` |
| Locked terminal on a money action | 423 | `{ errors: ["Terminal is locked"] }` |
| Order or appointment not found (pay) | 404 | Rails default 404 |

---

## 5. Services

All services live under `OrderProcessingV1` module and use `self.call(...)` — no instances.

Current POS services:
- `CreateOrderService` — resolves/scopes items, server price, selling stock,
  per-line tax snapshots, product + service lines, cent totals.
- `OrderTotalsService` — proportional discount allocation, per-line tax,
  grouped breakdown, total in integer cents; reads each line's tax snapshot.
- `PersistLineTaxesService` — writes final taxable/tax cents after a discount.
- `CheckAvailabilityService` / `ReserveStockService` — availability and exact
  selling-stock holds.
- `InitiatePaymentService` — pending discount, invoice total/tax snapshot,
  cash validation and cash/change metadata, QR handoff.
- `CancelOrderService` — void-before-paid lifecycle.
- `CancelPaymentService` / `ReleaseReservedStockService` — abandoned QR and
  reservation rollback.

The older §5.3/§5.4 signatures below are historical; the current contracts
are in §1.1 and §4.

### 5.1 `CheckAvailabilityService`

**File**: `app/services/order_processing_v1/check_availability_service.rb`
**Signature**: `call(items:)`

| Param | Type | Description |
|-------|------|-------------|
| `items` | `Array` | `[{ stock_id, quantity }]` |

**Behavior:**
- Reads `stock.available_counter.value` (KRedis integer) for each item
- Returns failure as soon as any item has insufficient quantity
- String quantities are auto-converted via `.to_i`

**Returns:**
```ruby
{ available: true }
# or
{ available: false, failed_item: stock_id }
```

### 5.2 `ReserveStockService`

**File**: `app/services/order_processing_v1/reserve_stock_service.rb`
**Signature**: `call(items:)`

| Param | Type | Description |
|-------|------|-------------|
| `items` | `Array` | `[{ stock_id, quantity }]` |

**Behavior:**
- Opens a `redis.multi` block
- `DECRBY stock:<id>:available` for each item
- **Rollback**: If any decrement produces a negative result, rolls back ALL prior decrements within the same Redis transaction
- **Raises**: `OrderProcessingV1::InsufficientStockError` on failure

**Returns:**
```ruby
{ success: true }
```

### 5.3 `CreateOrderService`

**File**: `app/services/order_processing_v1/create_order_service.rb`
**Signature**: `call(company:, branch:, items:, customer: nil, employee: nil)`

| Param | Type | Description |
|-------|------|-------------|
| `company` | `Company` | Current company scope |
| `branch` | `Branch` | Branch where order is placed |
| `items` | `Array` | `[{ product_id|service_id, quantity }]` |
| `customer` | `Customer\|nil` | Existing customer; creates a timestamped Walk-in if nil |
| `employee` | `Employee\|nil` | Cashier credited on the order |

**Behavior:**
- Resolves each product/service inside `company` + `branch`; rejects foreign or missing items.
- Prices from `price_cents` (rejects unset prices) and resolves the selling stock row.
- Checks availability against the exact stock ids, then creates the `Order` with
  `currency: company.currency` and `business_type: :in_store`.
- Bulk-inserts product lines (`stock_id` persisted) and service lines via
  `insert_all!` inside one transaction, including each line's tax snapshot.
- Returns integer cent totals and authoritative per-line prices.

**Returns:**
```ruby
{ order_id:, currency:, subtotal_cents:, tax_cents:, added_tax_cents:,
  total_cents:, tax_lines:, items: [...] }
```

### 5.4 `InitiatePaymentService`

**File**: `app/services/order_processing_v1/initiate_payment_service.rb`
**Signature**: `call(order:, appointment:, discount_code: nil, employee: nil)`

| Param | Type | Description |
|-------|------|-------------|
| `order` | `Order` | The pending Order to pay |
| `appointment` | `PaymentMethodAppointment` | Branch-level appointment (must match `order.branch`, lifecycle active) |
| `discount_code` | `String\|nil` | Optional single-use discount code — reserved via `Discounts::ApplyService` before stock; invoice created at `gross - discount.amount_cents` (`docs/DISCOUNTS.md` §6) |
| `employee` | `Employee\|nil` | Actor recorded on the discount (`Discount#employee_id`) |

**Behavior:**
- Validates the appointment (branch scope + active) — raises `InvalidPaymentMethodError`
- `discount_code` present → `Discounts::ApplyService` (row-locked reservation); failure raises `InvalidDiscountError` (nothing created yet)
- Maps line items → stocks, reserves via `ReserveStockService` (releases on any later failure; also releases the reserved discount)
- Creates `Invoice` (unpaid defaults, `price_cents = gross - discount.amount_cents`) + `Transaction` (`status: :pending`, `payment_method_id`, `gateway_reference: "POS_<hex16>"`)
- **Cash mode** → `CompletePaymentService.call` synchronously; returns `{ status: "paid" }` — the Invoice payment callback consumes the pending discount
- **QR mode** → resolves `GATEWAY_STRATEGY_CLASSES[strategy]`, invokes the gateway with the appointment's merchant identity, stores `qr_string` in `txn.gateway_payload`; returns `{ status: "pending", qr_string, transaction_token }` (code stays pending until the webhook)

**Returns:** `InitiatePaymentService::Result` struct (`status, order_id, transaction_id, transaction_token, qr_string, discount`)

### 5.4b `CompletePaymentService`

**File**: `app/services/order_processing_v1/complete_payment_service.rb`
**Signature**: `call(transaction:)`

Idempotent — only a **pending** Transaction completes (row-locked):
1. `txn.update!(status: :completed)` → gated callback derives `Invoice.payment_status`
2. Invoice + Order `workflow_status = :paid`
3. Enqueues `FinalizeJob.perform_later(order.id)`

Returns `true` once, `false` afterwards / for non-pending transactions.

### 5.4c `CancelPaymentService` + `ReleaseReservedStockService`

**Files**: `cancel_payment_service.rb`, `release_reserved_stock_service.rb`
**Signature**: `call(transaction_token:, company:)` / `call(order:)`

Cancel: finds the company's Transaction by token (`find_by!` → 404), releases reservations first (`release_reserved!` per line item), then marks the txn `failed`. Only pending transactions cancel — returns `false` otherwise.

### 5.5 `WriteStockLedgerService`

**File**: `app/services/order_processing_v1/write_stock_ledger_service.rb`
**Signature**: `call(order:)`

| Param | Type | Description |
|-------|------|-------------|
| `order` | `Order` | The paid Order |

**Behavior (2026-09-23 — ledger-driven, docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md §5):**
- Iterates `order.order_product_appointments`
- Resolves the Stock row persisted on the line at pay time (`stock_id` FK); legacy lines fall back to branch-scoped then company-scoped resolution
- Per line, calls `StockMovementService::BaseService` (`direction: :remove`, `transaction_type: :export`, `appoint_for: order`, `consume_hold: true` when a pay-time hold exists) — the hardened `StockTransaction` callback IS the quantity write; `insert_all!` removed

**Returns:**
```ruby
{ count: Integer }  # number of ledger rows inserted
```

### 5.6 `UpdateStockBalancesService` — REMOVED (2026-09-23)

The direct-SQL balance writer was deleted. Quantities move ONLY through `StockTransaction`'s
hardened `recalibrate_stock_metrics` callback (see §5.5); the hold release (`pending -= qty`)
is handled by `StockMovementService::BaseService` (`consume_hold: true` → `release_reserved!`
after the ledger row exists).

### 5.7 `FinalizeOrderService`

**File**: `app/services/order_processing_v1/finalize_order_service.rb`
**Signature**: `call(order:)`

| Param | Type | Description |
|-------|------|-------------|
| `order` | `Order` | The paid Order |

**Behavior:**
- Iterates `order.order_product_appointments`
- For each line item, creates a `StockExport` with:
  - `business_type: :sale`
  - `workflow_status: :completed`
  - `code: "EXP-{timestamp}-{random}"`
  - Polymorphic `appoint_for` → Order

**NOT fully idempotent:** Each call creates new `StockExport` records (no uniqueness constraint prevents duplicates). Idempotency is enforced at the Job level (`FinalizeJob` checks `StockExport.exists?` before calling).

**Returns:**
```ruby
{ export_ids: Array<UUID> }
```

---

## 6. Background Job

### `FinalizeJob`

**File**: `app/jobs/order_processing_v1/finalize_job.rb`
**Queue**: `order_finalization`
**Signature**: `perform(order_id)`

**Flow (inside `ActiveRecord::Base.transaction`):**

1. **Idempotency guard 1** — Returns early if `order.workflow_status != "paid"`
2. **Idempotency guard 2** — Returns early if `StockExport.exists?` for this order
3. Calls `WriteStockLedgerService.call(order:)` — stock ledger entries
4. Calls `WriteStockLedgerService.call(order:)` — ledger rows via StockMovementService (callback applies quantity deltas + releases holds)
5. Calls `FinalizeOrderService.call(order:)` — creates export docs

**Triggered by:** `CompletePaymentService` (cash path synchronously, QR path from the mock-bank webhook).

---

## 7. KRedis Stock Tracking

Stock availability runs on a Redis hot counter (`stock:<id>:available`)
mirroring `quantity − pending`, read through `available_count` (see
`docs/KREDIS.md`). Holds live behind `StockPending` rows — one `pos` hold per
pay line via `StockPendings::HoldService`, each with its own anchored `hold`
ledger row whose callback moves `pending`. Full mechanics — the single write
path, healing, reservation flow, and counter lifecycle — live in `docs/STOCK.md`
(§1–§3).

POS usage:

```
Checkout ─► reads availability (Redis counter; heals from DB if missing)
Pay      ─► HoldService per line: StockPending + hold ledger (pending += qty)
Finalize ─► TWO ledger rows per line: pending release + quantity remove
Cancel   ─► ReleaseService per line (pending -= qty, row → completed/cancelled)
```

On reservation failure (any line's hold rejected), prior holds release via
`ReleaseService` and the pay action returns 422.

---

## 8. Related Models

| Model | File | Role in Pipeline |
|-------|------|-----------------|
| `Order` | `app/models/order.rb` | Pending/paid order record; `workflow_status` tracks state |
| `OrderProductAppointment` | `app/models/order_product_appointment.rb` | Atomic line items (Order + Product + optional `stock_id`), stores `quantity`, `unit_price`, `total_price` |
| `Stock` | `app/models/stock.rb` | Inventory record with `quantity`, `pending`, KRedis `available_counter` |
| `StockTransaction` | `app/models/stock_transaction.rb` | Ledger entries; `after_create` recalibrates stock metrics |
| `StockExport` | `app/models/stock_export.rb` | Export documents linked to Order via polymorphic `appoint_for` |
| `Invoice` | `app/models/invoice.rb` | Payment invoice; created by `InitiatePaymentService` (unpaid) |
| `Transaction` | `app/models/transaction.rb` | Payment audit row (`pending/completed/failed`, `payment_method_id`, `gateway_reference`); created by `InitiatePaymentService`, completed by webhook/cash path |

---

## 9. Routes & URL Helpers

### Routes (in `config/routes.rb`)

```ruby
post "order_processing/v1/checkout",        to: "order_processing/v1#checkout"
post "order_processing/v1/pay",             to: "order_processing/v1#pay"
post "order_processing/v1/pay_cancel",      to: "order_processing/v1#pay_cancel"
post "order_processing/v1/apply_discount",  to: "order_processing/v1#apply_discount"
post "order_processing/v1/remove_discount", to: "order_processing/v1#remove_discount"
post "order_processing/v1/cancel",          to: "order_processing/v1#cancel"
get  "operations/pos/:operation_id",                 to: "operations/pos#show"
get  "operations/pos/:operation_id/catalog",         to: "operations/pos#catalog"
get  "operations/pos/:operation_id/customer_lookup", to: "operations/pos#customer_lookup"
post "operations/pos/:operation_id/lock",            to: "operations/pos#lock"
post "operations/pos/:operation_id/unlock",          to: "operations/pos#unlock"
```

All are nested inside `resources :companies` (scoped to `/companies/:company_id/`).

### JavaScript URL Helpers (in `url_helpers.js`)

```javascript
export const order_processing_v1_checkout_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/checkout`

export const order_processing_v1_pay_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/pay`

export const order_processing_v1_pay_cancel_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/pay_cancel`
export const order_processing_v1_apply_discount_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/apply_discount`
export const order_processing_v1_remove_discount_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/remove_discount`
export const order_processing_v1_cancel_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/cancel`

export const receipt_company_order_path = (companyId, orderId) =>
  `/companies/${companyId}/orders/${orderId}/receipt`

const operationPath = (kind, companyId, operationId, params = {}) => {
  const query = new URLSearchParams(params).toString()
  return `/companies/${companyId}/operations/${kind}/${operationId}${query ? `?${query}` : ""}`
}
export const pos_company_operation_path = (companyId, operationId, params = {}) =>
  operationPath("pos", companyId, operationId, params)
export const pos_catalog_company_operation_path = (companyId, operationId, params = {}) => {
  const query = new URLSearchParams(params).toString()
  return `/companies/${companyId}/operations/pos/${operationId}/catalog${query ? `?${query}` : ""}`
}
export const pos_customer_lookup_company_operation_path = (companyId, operationId, params = {}) => {
  const query = new URLSearchParams(params).toString()
  return `/companies/${companyId}/operations/pos/${operationId}/customer_lookup${query ? `?${query}` : ""}`
}
export const pos_lock_company_operation_path = (companyId, operationId) =>
  `/companies/${companyId}/operations/pos/${operationId}/lock`
export const pos_unlock_company_operation_path = (companyId, operationId) =>
  `/companies/${companyId}/operations/pos/${operationId}/unlock`
```



---

## 10. Error Handling & Idempotency

### Error Handling Matrix

| Layer | Error Type | Handler | HTTP Status |
|-------|-----------|---------|-------------|
| Controller | `CheckAvailabilityService` returns unavailable | Returns 422 | 422 |
| Controller | `ReserveStockService` raises `InsufficientStockError` | Rescue in `pay` action | 422 |
| Controller | Order not found | `find!` raises 404 | 404 |
| Service | Gateway failure / invalid appointment | `InitiatePaymentService` raises → rescued in `pay` | 422 |
| Job | Double execution | Idempotency guards (status check + StockExport check) | N/A |

### Idempotency Strategy

| Operation | Idempotent? | Mechanism |
|-----------|-----------|-----------|
| `checkout` | No (creates new Order each call) | Frontend only calls once per order |
| `pay` (controller) | No | Frontend shows COMPLETE PAYMENT once |
| `pay` (service) | No | Invoice name uniqueness blocks second call |
| `apply_discount` | **Yes** for the same pending code | Existing pending code returns its totals; a different code reserves before releasing the old |
| `cancel` / `CancelOrderService` | **Yes** for already-cancelled | `with_lock` + cancelled guard; paid orders refused |
| `pay_cancel` / `CancelPaymentService` | Partial | Only pending transactions cancel; repeats return `not_pending` |
| Webhook completion (`CompletePaymentService`) | **Yes** | Pending-only guard + row lock; cancelled txns are logged no-ops |
| `FinalizeJob` | **Yes** | Checks `workflow_status` + `StockExport.exists?` |
| `FinalizeOrderService` | No | Creates new StockExport each call (guarded by Job) |

---

## 11. Spec Reference

| Spec File | Scenarios | Key Fixture Detail |
|-----------|-----------|-------------------|
| `spec/services/order_processing_v1/check_availability_service_spec.rb` | Basic availability, insufficient stock, string quantity param | 3 products with stock, KRedis counter setup |
| `spec/services/order_processing_v1/create_order_service_spec.rb` | Single item, multiple items, walk-in customer fallback, string quantity param | Company, branch, 3 products |
| `spec/services/order_processing_v1/reserve_stock_service_spec.rb` | Successful reservation, insufficient stock (rollback), string quantity param | Stock records with KRedis counter |
| `spec/services/order_processing_v1/initiate_payment_service_spec.rb` | Cash instant-complete, QR pending + merchant kwargs, rollback, validation | Branch appointments for cash + mock QR |
| `spec/services/order_processing_v1/complete_payment_service_spec.rb` | Completes txn, derives invoice paid, idempotency, failed no-op | Pending Transaction on unpaid Invoice |
| `spec/services/order_processing_v1/cancel_payment_service_spec.rb` (+ release spec) | Cancel fails txn + releases stock, non-pending no-op | Reserved stock + pending transaction |
| `spec/services/order_processing_v1/write_stock_ledger_service_spec.rb` | Ledger rows + callback-driven quantity mutation, hold consumption, stock_id / branch-scoped / legacy fallbacks | Paid order, stock records per product |
| `spec/services/order_processing_v1/finalize_order_service_spec.rb` | Creates stock exports with sale business_type, links to Order via appoint_for | Paid order with order_product_appointments |
| `spec/requests/companies/order_processing/v1_controller_spec.rb` | Checkout success, insufficient stock, missing fields, multiple items, string quantity, non-existent order pay, full checkout+pay flow | Company, branch, products, stock |
| `spec/features/companies/operations/pos_spec.rb` | Operation screen load, dark mode toggle, category filter, customer lookup by id/name/phone + membership tier, lookup not found, add/remove cart, ORDER → COMPLETE PAYMENT, Cancel, cart locked, insufficient stock, empty cart guard | Company, branch, products, stock, Operation + branch appointment, customer + membership |
| `spec/features/mobile/pos_spec.rb` | Mobile Shell-First hydration, catalog, add-to-cart, ORDER → payment → receipt, Operations link, non-POS operations, missing appointment | Company, branch, product, stock, Operation + branch appointment, cash payment method |

---

*End of documentation*
