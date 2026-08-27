# Skycom Order Processing V1

## 1. Overview

The **Order Processing V1** pipeline is a multi-step POS order lifecycle that connects the retail cashier frontend to backend services, a controller API, a background job, and KRedis-based stock tracking.

### Core Flow

```
Cart (local state) → checkout (create Order) → pay (reserve stock + invoice) → finalize (async: ledger + balances + export)
```

### Architecture Layers

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Frontend** | `controllers/companies/pages/retail_cashier_controller.js` | Cart state machine, two-phase ORDER/COMPLETE PAYMENT buttons |
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
        body: { branch_id, items: [{stock_id, product_id, quantity, unit_price}] }
        │
        ▼
    V1Controller#checkout
      │
      ├── CheckAvailabilityService.call(items:)
      │     └── reads stock.available_counter (KRedis)
      │         └── failure → 422 { error: "Insufficient stock for item ..." }
      │
      ├── CreateOrderService.call(company:, branch:, items:, customer:)
      │     ├── Order.create!(workflow_status: :pending)
      │     ├── OrderAppointment.insert_all!(items)
      │     └── creates "Walk-in Customer" if none provided
      │
      └── 201 { order_id, total_price }  ◄── stored in frontend state

pay()                              PAY
  │
  └── POST /order_processing/v1/pay
        body: { order_id, payment_method_appointment_id }
        │
        ▼
    V1Controller#pay
      │
      ├── PaymentMethodAppointment.branch_level.find_by!(id:, company_id:)   ← branch-scoped
      │
      └── InitiatePaymentService.call(order:, appointment:)
            │
            ├── validates: appoint_to == order.branch + lifecycle active
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
                                                    │     └── StockTransaction.insert_all(direction: :remove)
                                                    │
                                                    ├── UpdateStockBalancesService.call(order:)
                                                    │     └── SQL UPDATE quantity -= qty, pending -= qty
                                                    │         └── triggers Stock#after_save → sync_available_counter
                                                    │
                                                    └── FinalizeOrderService.call(order:)
                                                          └── StockExport.create!(business_type: :sale)
                                                              └── links to Order via appoint_for
```

---

## 3. Frontend — Retail Cashier Controller

**File**: `app/javascript/controllers/companies/pages/retail_cashier_controller.js`
**Class**: `Companies_Pages_RetailCashierController`
**Extends**: `Controller` (standalone, not layout)

### 3.1 Cart → Order Link (click item to DB)

Clicking a product/service card does **not** hit the backend — it mutates local `tabs[].items[]` only. The DB link is created later by `ORDER`.

```
Card (renderProductCard) ── data-action="click->...#addToCart" + params {id, name, price, stockId}
        │
        ▼ addToCart(event) :64
        ├── if (this.orderId) return  // locked after checkout
        ├── existing ? qty++ : push({ id, name, price, qty:1, stockId })
        └── renderContent() → cart + Subtotal/Tax/Total (client-side)
        │
        ▼ initiateOrder() :125 — only here does the cart flush to DB
        items = activeTab.items.filter(i=>i.stockId).map(i=>({ stock_id, product_id, quantity: i.qty, unit_price: i.price }))
        POST /order_processing/v1/checkout { branch_id, items } → CreateOrderService
                └── Order.create! + OrderAppointment.insert_all!({ order_id, appoint_to_type:"Product", quantity, unit_price, total_price: qty*unit_price })
        pay later reads order.order_appointments.sum(:total_price) — never trusts the click params again.
```

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
| `orderId` | `string\|null` | `null` | Active Order UUID after checkout; gates all cart mutations |
| `orderTotal` | `number` | `0` | Total price from checkout response |
| `activePaymentMethod` | `string` | `'cash'` | `'cash'` or `'card'` |
| `cashReceived` | `number` | `0` | Cash input for change calculation |
| `tabs` | `Array` | `[]` | Multi-customer tabs, each with `{ id, name, items: [] }` |
| `products` / `services` | `Array` | `[]` | Loaded from server JSON on connect |

### Order Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `initiateOrder()` | `async ()` | POSTs cart items to `checkout`, sets `orderId`/`orderTotal` from response. Shows toast on success/error. |
| `pay()` | `async ()` | POSTs `{ order_id, payment_method_appointment_id }` to `pay`. `paid` → clears cart; `pending` → renders QR wait screen + subscribes to `pos_payment_completed`. |
| `cancelOrder()` | `()` | Resets `orderId`/`orderTotal` to null/0. No API call — unlocks cart locally. |

### Cart Locking Rules

When `this.orderId` is set, these methods are guarded:
- `addToCart()` — returns immediately (line 130: `if (this.orderId) return`)
- `removeFromCart()` — returns immediately
- `updateQty()` — returns immediately

The locked cart template (in `renderCartItems`) renders items as read-only text without qty adjusters or remove buttons.

### Cart-to-Order Mapping

`initiateOrder()` filters items to those with a `stockId`, then maps:

```javascript
{
  branch_id: this.page.branch_id,
  items: this.activeTab.items
    .filter(item => item.stockId)
    .map(item => ({
      stock_id: item.stockId,
      product_id: item.id,
      quantity: item.qty,
      unit_price: item.price
    }))
}
```

Items without `stockId` (services, non-tracked products) are excluded from the checkout payload.

---

## 4. Controller

**File**: `app/controllers/companies/order_processing/v1_controller.rb`
**Class**: `Companies::OrderProcessing::V1Controller < Companies::ApplicationController`

### `checkout`

**POST** `/companies/:company_id/order_processing/v1/checkout`

**Params** (via `checkout_params`):
```ruby
params.permit(:branch_id, :customer_id, items: [ :stock_id, :product_id, :quantity, :unit_price ])
```

| Param | Required | Description |
|-------|----------|-------------|
| `branch_id` | Yes | Branch UUID scoped to current company |
| `customer_id` | No | Existing Customer UUID; creates "Walk-in" if absent |
| `items[]` | Yes | Array of line item hashes |
| `items[][stock_id]` | Yes | Stock UUID (used for availability check) |
| `items[][product_id]` | Yes | Product UUID |
| `items[][quantity]` | Yes | Integer quantity (string is auto-converted via `.to_i`) |
| `items[][unit_price]` | Yes | Float unit price |

**Flow:**
1. Calls `CheckAvailabilityService.call(items:)` — returns 422 `{ error: "Insufficient stock for item ..." }` if insufficient
2. Calls `CreateOrderService.call(company:, branch:, items:, customer:)`
3. Returns `201 Created` with `{ order_id: "uuid", total_price: 49.99 }`

### `pay`

**POST** `/companies/:company_id/order_processing/v1/pay`

**Params:**
```ruby
params.permit(:order_id, :payment_method_appointment_id)
```

**Flow:**
1. Loads `current_company.orders.find(params[:order_id])` — returns 404 if not found
2. Loads the branch-level appointment scoped to `current_company` — 404 if unknown, 422 `{ errors: [...] }` if it belongs to another branch / is inactive
3. Calls `InitiatePaymentService.call(order:, appointment:)`
4. Cash → instant completion; QR → gateway call returning `qr_string`; both create Invoice + pending Transaction audit row
5. Returns `200 OK`:
   - Cash: `{ status: "paid", order_id, transaction_id, message }`
   - QR: `{ status: "pending", order_id, transaction_token, qr_string, message }`

### `receipt`

**GET** `/companies/:company_id/orders/:order_id/receipt`

POS receipt payload for the post-payment panel: invoice code, issued_at,
payment_status, item lines (snapshot name/qty/unit/total), subtotal from
`invoice.price_cents`, cart-mirrored 10% tax, total, and payment method name.
404 when the order is unknown or belongs to another company.

### `pay_cancel`

**POST** `/companies/:company_id/order_processing/v1/pay_cancel`

**Params:** `{ transaction_token }`

Cancels an abandoned QR payment: releases reserved stock and marks the pending Transaction `failed`. Returns `{ status: "cancelled" | "not_pending" }`.

### Error Responses

| Scenario | Status | Body |
|----------|--------|------|
| Insufficient stock (checkout) | 422 | `{ error: "Insufficient stock for item ..." }` |
| Insufficient stock (pay) | 422 | `{ error: "Insufficient stock for payment" }` |
| Invalid/inactive/foreign-branch payment method | 422 | `{ errors: ["Payment method is not available for this branch"] }` |
| Order or appointment not found (pay) | 404 | Rails default 404 |

---

## 5. Services

All services live under `OrderProcessingV1` module and use `self.call(...)` — no instances.

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
**Signature**: `call(company:, branch:, items:, customer: nil)`

| Param | Type | Description |
|-------|------|-------------|
| `company` | `Company` | Current company scope |
| `branch` | `Branch` | Branch where order is placed |
| `items` | `Array` | `[{ product_id, quantity, unit_price }]` |
| `customer` | `Customer\|nil` | Existing customer; creates "Walk-in Customer" if nil |

**Behavior:**
- Calculates `total_price = sum(quantity * unit_price)`
- Creates "Walk-in Customer" if none provided (name: `"Walk-in Customer"`)
- Creates `Order` with `workflow_status: :pending, currency_code: :usd, business_type: :in_store`
- Bulk-inserts `OrderAppointment` records via `insert_all!`
- String quantity values are converted via `.to_i`

**Returns:**
```ruby
{ order_id: "uuid", total_price: 49.99 }
```

### 5.4 `InitiatePaymentService`

**File**: `app/services/order_processing_v1/initiate_payment_service.rb`
**Signature**: `call(order:, appointment:)`

| Param | Type | Description |
|-------|------|-------------|
| `order` | `Order` | The pending Order to pay |
| `appointment` | `PaymentMethodAppointment` | Branch-level appointment (must match `order.branch`, lifecycle active) |

**Behavior:**
- Validates the appointment (branch scope + active) — raises `InvalidPaymentMethodError`
- Maps line items → stocks, reserves via `ReserveStockService` (releases on any later failure)
- Creates `Invoice` (unpaid defaults) + `Transaction` (`status: :pending`, `payment_method_id`, `gateway_reference: "POS_<hex16>"`)
- **Cash mode** → `CompletePaymentService.call` synchronously; returns `{ status: "paid" }`
- **QR mode** → resolves `GATEWAY_STRATEGY_CLASSES[strategy]`, invokes the gateway with the appointment's merchant identity, stores `qr_string` in `txn.gateway_payload`; returns `{ status: "pending", qr_string, transaction_token }`

**Returns:** `InitiatePaymentService::Result` struct (`status, order_id, transaction_id, transaction_token, qr_string`)

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

**Behavior:**
- Iterates `order.order_appointments`
- Looks up `Stock` record by product for each line item
- Bulk-inserts `StockTransaction` rows with `direction: :remove`, `transaction_type: :export`, `appoint_for: order`

**Returns:**
```ruby
{ count: Integer }  # number of ledger rows inserted
```

### 5.6 `UpdateStockBalancesService`

**File**: `app/services/order_processing_v1/update_stock_balances_service.rb`
**Signature**: `call(order:)`

| Param | Type | Description |
|-------|------|-------------|
| `order` | `Order` | The paid Order |

**Behavior:**
- Iterates `order.order_appointments`
- For each line item, runs direct SQL `UPDATE stocks SET quantity = quantity - qty, pending = pending - qty`
- Uses `update_all` with array SQL fragment

**Returns:**
```ruby
{ updated: Array<Integer> }  # list of affected stock IDs
```

### 5.7 `FinalizeOrderService`

**File**: `app/services/order_processing_v1/finalize_order_service.rb`
**Signature**: `call(order:)`

| Param | Type | Description |
|-------|------|-------------|
| `order` | `Order` | The paid Order |

**Behavior:**
- Iterates `order.order_appointments`
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
4. Calls `UpdateStockBalancesService.call(order:)` — decrements DB stock balances
5. Calls `FinalizeOrderService.call(order:)` — creates export docs

**Triggered by:** `CompletePaymentService` (cash path synchronously, QR path from the mock-bank webhook).

---

## 7. KRedis Stock Tracking

### `Stock.available_counter`

**File**: `app/models/stock.rb`

```ruby
kredis_counter :available_counter, key: ->(s) { "stock:#{s.id}:available" }
```

The counter is synced from the database via (accessed only through model
wrappers — see `docs/KREDIS.md`):

```ruby
after_save :sync_available_counter,
  if: -> { saved_change_to_quantity? || saved_change_to_pending? }

# private
def sync_available_counter
  target = [ quantity - pending, 0 ].max
  delta = target - available_counter.value
  return if delta.zero?

  delta.positive? ? available_counter.increment(by: delta) : available_counter.decrement(by: -delta)
end
```

This keeps the Redis counter consistent with the DB after any stock save.
`update_all` bypasses callbacks — the order pipeline keeps Redis and DB in step
explicitly. If a counter key goes missing (Redis restart/flush),
`Stock#available_count` heals it from `quantity - pending` on first read.

### Atomic Reservation Flow

Reservation lives on the model (`Stock#reserve_stock!`) — an atomic Redis
decrement that returns false and reverts itself when stock is insufficient:

1. `ReserveStockService` heals missing keys via `available_count`, then calls
   `reserve_stock!(qty)` per item
2. On the first `false`, all previously reserved items are rolled back via
   `release_reserved!(qty)`
3. `InsufficientStockError` is raised → the pay action returns 422

On success, each `reserve_stock!` also increments the DB `pending` column so
`quantity - pending` reflects the reservation between pay and finalize.

### Counter Lifecycle

```
Checkout ─► reads availability (Redis counter; heals from DB if missing)
Pay      ─► reserve_stock!: DECRBY available_counter + DB pending += qty
Finalize ─► UPDATE DB quantity -= qty, pending -= qty
```

---

## 8. Related Models

| Model | File | Role in Pipeline |
|-------|------|-----------------|
| `Order` | `app/models/order.rb` | Pending/paid order record; `workflow_status` tracks state |
| `OrderAppointment` | `app/models/order_appointment.rb` | Polymorphic line items (Product/Service), stores `quantity`, `unit_price`, `total_price` |
| `Stock` | `app/models/stock.rb` | Inventory record with `quantity`, `pending`, KRedis `available_counter` |
| `StockTransaction` | `app/models/stock_transaction.rb` | Ledger entries; `after_create` recalibrates stock metrics |
| `StockExport` | `app/models/stock_export.rb` | Export documents linked to Order via polymorphic `appoint_for` |
| `Invoice` | `app/models/invoice.rb` | Payment invoice; created by `InitiatePaymentService` (unpaid) |
| `Transaction` | `app/models/transaction.rb` | Payment audit row (`pending/completed/failed`, `payment_method_id`, `gateway_reference`); created by `InitiatePaymentService`, completed by webhook/cash path |

---

## 9. Routes & URL Helpers

### Routes (in `config/routes.rb`)

```ruby
post "order_processing/v1/checkout", to: "order_processing/v1#checkout"
post "order_processing/v1/pay",        to: "order_processing/v1#pay"
post "order_processing/v1/pay_cancel", to: "order_processing/v1#pay_cancel"
```

Both are nested inside `resources :companies` (scoped to `/companies/:company_id/`).

### JavaScript URL Helpers (in `url_helpers.js`)

```javascript
export const order_processing_v1_checkout_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/checkout`

export const order_processing_v1_pay_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/pay`

export const order_processing_v1_pay_cancel_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/pay_cancel`

export const receipt_company_order_path = (companyId, orderId) =>
  `/companies/${companyId}/orders/${orderId}/receipt`
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
| `spec/services/order_processing_v1/write_stock_ledger_service_spec.rb` | Creates stock transactions with correct direction/type | Paid order, stock records per product |
| `spec/services/order_processing_v1/update_stock_balances_service_spec.rb` | Decrements quantity and pending, multiple items | Paid order with order_appointments |
| `spec/services/order_processing_v1/finalize_order_service_spec.rb` | Creates stock exports with sale business_type, links to Order via appoint_for | Paid order with order_appointments |
| `spec/requests/companies/order_processing/v1_controller_spec.rb` | Checkout success, insufficient stock, missing fields, multiple items, string quantity, non-existent order pay, full checkout+pay flow | Company, branch, products, stock |
| `spec/features/companies/pages/retail_cashier_spec.rb` | Page load, add/remove cart, ORDER → COMPLETE PAYMENT, Cancel, cart locked, insufficient stock, empty cart guard | Company, branch, products, stock, page record |

---

*End of documentation*
