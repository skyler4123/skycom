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
        body: { order_id }
        │
        ▼
    V1Controller#pay
      │
      ├── ReserveStockService.call(items:)
      │     └── KRedis DECRBY stock:<id>:available
      │         ├── success → continues
      │         └── negative → rollback + InsufficientStockError → 422
      │
      ├── ProcessPaymentService.call(order:)
      │     ├── Invoice.create!(workflow_status: :paid)
      │     ├── Payment.create!(workflow_status: :completed)
      │     └── Order.update!(workflow_status: :paid)
      │
      ├── FinalizeJob.perform_later(order.id)
      │
      └── 200 { status: "paid", order_id, payment_id }

                                                    ┌─ FinalizeJob#perform(order_id)
                                                    │   (idempotent guards)
                                                    │   ├── order.workflow_status == "paid"?
                                                    │   └── StockExport.exists? for this order?
                                                    │
                                                    ├── WriteStockLedgerService.call(order:)
                                                    │     └── StockTransaction.insert_all(direction: :remove)
                                                    │
                                                    ├── UpdateStockBalancesService.call(order:)
                                                    │     └── SQL UPDATE quantity -= qty, reserved_quantity -= qty
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
| `pay()` | `async ()` | POSTs `{ order_id }` to `pay`. On success: clears cart, resets state, re-renders. |
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
params.permit(:order_id)
```

**Flow:**
1. Loads `current_company.orders.find(params[:order_id])` — returns 404 if not found
2. Maps `order.order_appointments` to items `{ stock_id, quantity }`
3. Calls `ReserveStockService.call(items:)` — rescues `InsufficientStockError` → 422 `{ error: "Insufficient stock for payment" }`
4. Calls `ProcessPaymentService.call(order:)` — creates Invoice + Payment, marks Order as paid
5. Enqueues `FinalizeJob.perform_later(order.id)`
6. Returns `200 OK` with `{ status: "paid", order_id: "uuid", payment_id: "uuid" }`

### Error Responses

| Scenario | Status | Body |
|----------|--------|------|
| Insufficient stock (checkout) | 422 | `{ error: "Insufficient stock for item ..." }` |
| Insufficient stock (pay) | 422 | `{ error: "Insufficient stock for payment" }` |
| Order not found (pay) | 404 | Rails default 404 |

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

### 5.4 `ProcessPaymentService`

**File**: `app/services/order_processing_v1/process_payment_service.rb`
**Signature**: `call(order:)`

| Param | Type | Description |
|-------|------|-------------|
| `order` | `Order` | The pending Order to process payment for |

**Behavior:**
- Creates `Invoice` with `workflow_status: :paid`, `code: "INV-{timestamp}-{random}"`
- Creates `Payment` with `workflow_status: :completed`, `business_type: :standard_payment`
- Updates `Order.workflow_status` to `:paid`

**NOT idempotent:** Calling `pay` twice on the same order creates a duplicate Invoice with `name: "Invoice for Order #{order.id}"` — fails with `ActiveRecord::RecordInvalid` on the uniqueness validation.

**Returns:**
```ruby
{ payment_id: "uuid" }
```

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
- For each line item, runs direct SQL `UPDATE stocks SET quantity = quantity - qty, reserved_quantity = reserved_quantity - qty`
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

**Triggered by:** `V1Controller#pay` via `perform_later(order.id)`.

---

## 7. KRedis Stock Tracking

### `Stock.available_counter`

**File**: `app/models/stock.rb`

```ruby
kredis_integer :available_counter
```

The Redis key pattern is `stock:<id>:available`. The counter is synced from the database via:

```ruby
after_save :sync_available_counter

def sync_available_counter
  available_counter.value = [ quantity - reserved_quantity, 0 ].max
end
```

This ensures the Redis counter is always consistent with the DB after any stock mutation.

### Atomic Reservation Flow

`ReserveStockService` uses a Redis `MULTI` block to atomically decrement counters. If any decrement produces a negative result:

1. All prior decrements within the `MULTI` block are rolled back
2. `InsufficientStockError` is raised
3. The pay action returns 422

### Counter Lifecycle

```
Checkout ─► reads available_counter (check only)
Pay      ─► DECRBY available_counter (reserves stock)
Finalize ─► UPDATE DB quantity, reserved_quantity
         ─► after_save syncs available_counter from DB
```

---

## 8. Related Models

| Model | File | Role in Pipeline |
|-------|------|-----------------|
| `Order` | `app/models/order.rb` | Pending/paid order record; `workflow_status` tracks state |
| `OrderAppointment` | `app/models/order_appointment.rb` | Polymorphic line items (Product/Service), stores `quantity`, `unit_price`, `total_price` |
| `Stock` | `app/models/stock.rb` | Inventory record with `quantity`, `reserved_quantity`, KRedis `available_counter` |
| `StockTransaction` | `app/models/stock_transaction.rb` | Ledger entries; `after_create` recalibrates stock metrics |
| `StockExport` | `app/models/stock_export.rb` | Export documents linked to Order via polymorphic `appoint_for` |
| `Invoice` | `app/models/invoice.rb` | Payment invoice; created by `ProcessPaymentService` |
| `Payment` | `app/models/payment.rb` | Payment transaction; created by `ProcessPaymentService` |

---

## 9. Routes & URL Helpers

### Routes (in `config/routes.rb`)

```ruby
post "order_processing/v1/checkout", to: "order_processing/v1#checkout"
post "order_processing/v1/pay",      to: "order_processing/v1#pay"
```

Both are nested inside `resources :companies` (scoped to `/companies/:company_id/`).

### JavaScript URL Helpers (in `url_helpers.js`)

```javascript
export const order_processing_v1_checkout_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/checkout`

export const order_processing_v1_pay_path = (companyId) =>
  `/companies/${companyId}/order_processing/v1/pay`
```

---

## 10. Error Handling & Idempotency

### Error Handling Matrix

| Layer | Error Type | Handler | HTTP Status |
|-------|-----------|---------|-------------|
| Controller | `CheckAvailabilityService` returns unavailable | Returns 422 | 422 |
| Controller | `ReserveStockService` raises `InsufficientStockError` | Rescue in `pay` action | 422 |
| Controller | Order not found | `find!` raises 404 | 404 |
| Service | `ProcessPaymentService` double-call | `ActiveRecord::RecordInvalid` (no rescue) | 500 |
| Job | Double execution | Idempotency guards (status check + StockExport check) | N/A |

### Idempotency Strategy

| Operation | Idempotent? | Mechanism |
|-----------|-----------|-----------|
| `checkout` | No (creates new Order each call) | Frontend only calls once per order |
| `pay` (controller) | No | Frontend shows COMPLETE PAYMENT once |
| `pay` (service) | No | Invoice name uniqueness blocks second call |
| `FinalizeJob` | **Yes** | Checks `workflow_status` + `StockExport.exists?` |
| `FinalizeOrderService` | No | Creates new StockExport each call (guarded by Job) |

---

## 11. Spec Reference

| Spec File | Scenarios | Key Fixture Detail |
|-----------|-----------|-------------------|
| `spec/services/order_processing_v1/check_availability_service_spec.rb` | Basic availability, insufficient stock, string quantity param | 3 products with stock, KRedis counter setup |
| `spec/services/order_processing_v1/create_order_service_spec.rb` | Single item, multiple items, walk-in customer fallback, string quantity param | Company, branch, 3 products |
| `spec/services/order_processing_v1/reserve_stock_service_spec.rb` | Successful reservation, insufficient stock (rollback), string quantity param | Stock records with KRedis counter |
| `spec/services/order_processing_v1/process_payment_service_spec.rb` | Creates invoice + payment, updates order status, double-call raises error | Pending order with order_appointments |
| `spec/services/order_processing_v1/write_stock_ledger_service_spec.rb` | Creates stock transactions with correct direction/type | Paid order, stock records per product |
| `spec/services/order_processing_v1/update_stock_balances_service_spec.rb` | Decrements quantity and reserved_quantity, multiple items | Paid order with order_appointments |
| `spec/services/order_processing_v1/finalize_order_service_spec.rb` | Creates stock exports with sale business_type, links to Order via appoint_for | Paid order with order_appointments |
| `spec/requests/companies/order_processing/v1_controller_spec.rb` | Checkout success, insufficient stock, missing fields, multiple items, string quantity, non-existent order pay, full checkout+pay flow | Company, branch, products, stock |
| `spec/features/companies/pages/retail_cashier_spec.rb` | Page load, add/remove cart, ORDER → COMPLETE PAYMENT, Cancel, cart locked, insufficient stock, empty cart guard | Company, branch, products, stock, page record |

---

*End of documentation*
