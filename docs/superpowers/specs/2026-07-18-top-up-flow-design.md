# Top-Up Flow with Mock QR Payment

> Status: Approved design
> Date: 2026-07-18

## 1. Overview

Enable company wallet top-ups via a self-service page. Users select from available B2B payment methods (filtered by company country), confirm an amount, and pay via Mock QR code. Payment confirmation arrives via a webhook from the Mock API server, which triggers a WebSocket notification and wallet credit.

## 2. Architecture

```
Top-Up Page (Browser)         Backend                        Mock API (Go)       Centrifugo
        │                       │                                │                  │
        │── POST /top_ups ──────│── BillingInvoice (deposit)     │                  │
        │                       │── BillingTransaction (top_up)  │                  │
        │                       │── InitiateService              │                  │
        │                       │    └── MockQrGateway ──────────│── qr-generate    │
        │                       │                                │    └── webhook ──│
        │◄── { qr_string,       │                                │                  │
        │       websocket_url,  │                                │                  │
        │       token, channel }│                                │                  │
        │                       │                                │                  │
        │── render QR ────►     │                                │                  │
        │                       │                                │                  │
        │── subscribe WS ───────│─────────────────────────────────────── subscribe │
        │                       │                                │                  │
        │                       │◄──── webhook POST ─────────────│── goroutine ────│
        │                       │    /webhooks/bank_payment      │                  │
        │                       │       │                        │                  │
        │                       │    └── update wallet           │                  │
        │                       │    └── publish WS ─────────────│─────────────────│
        │◄── WS: top_up.completed │                              │                  │
        │                       │                                │                  │
        │── redirect /billing ──│                                │                  │
```

## 3. Components

### 3.1 Migration: Add Gateway Columns to BillingTransaction

| Column | Type | Constraints |
|--------|------|-------------|
| `status` | integer (enum) | `pending: 0`, `completed: 1`, `failed: 2` |
| `gateway_reference` | string | Unique index, nullable |
| `gateway_payload` | jsonb | Default `{}` |

### 3.2 BillingTransaction Model Updates

Add:
- `enum :status, { pending: 0, completed: 1, failed: 2 }, default: :pending`
- `validates :gateway_reference, uniqueness: true, allow_nil: true`

### 3.3 TopUpsController#new (JSON)

Returns available BillingPaymentMethods for the company's country:

```json
{
  "billing_payment_methods": [
    {
      "id": "uuid",
      "name": "QR Bank Transfer",
      "description": "Pay via QR code and bank transfer",
      "code": "QR_BANK_TRANSFER",
      "strategy": "mock_qr_gateway",
      "payment_mode": "qr"
    },
    {
      "id": "uuid",
      "name": "Redirect Payment",
      "description": "Pay via hosted redirect session",
      "code": "REDIRECT_SESSION",
      "strategy": "mock_redirect_gateway",
      "payment_mode": "redirect"
    }
  ]
}
```

Filter: `BillingPaymentMethod.where(business_type: :b2b).where(strategy: [:mock_qr_gateway, :mock_redirect_gateway])`

### 3.4 TopUpsController#create

Params: `{ amount_cents, billing_payment_method_id }`

Flow:
1. Call `TopUps::CreateService.call(company, amount_cents:, billing_payment_method:)`
2. Return `{ qr_string, websocket_url, websocket_token, websocket_channel }`

### 3.5 TopUps::CreateService

Steps:
1. Generate `gateway_reference` = `"TOPUP_#{SecureRandom.hex(16)}"`
2. Snapshot current wallet balances
3. Create `BillingInvoice`:
   - `movement_type: :deposit`, `target_balance: :main_balance`
   - `created_by: :customer`, `price_cents: amount_cents`
   - `payment_status: :unpaid`, `billing_contract: company.active_billing_contract`
4. Create `BillingTransaction`:
   - `transaction_type: :top_up`, `amount_cents: amount_cents`
   - `billing_invoice: invoice`, `billing_payment_method: bpm`
   - `gateway_reference: gateway_reference`, `status: :pending`
   - `balance_before_cents / after`: wallet snapshots
   - `promo_balance_before_cents / after`: wallet snapshots
5. Call `InitiateService.new(transaction: billing_txn).call`:
   - Dispatches to `MockQrGateway`
   - `MockQrGateway` sends POST to `http://localhost:4000/api/v1/bank/qr-generate`
   - Body includes `transaction_token: gateway_reference`
   - Response stored in `billing_txn.update!(gateway_payload: { qr_string: ... })`
6. Generate Centrifugo token for channel `company:{company.id}:top_up`
7. Return `{ qr_string, websocket_url: "ws://localhost:8000/connection/websocket", websocket_token, websocket_channel: "company:#{company.id}:top_up" }`

### 3.6 MockQrGateway Updates

Add `transaction_token` to the initializer params. Include it in the POST body to the mock API.

### 3.7 Webhook Endpoint: `Webhooks::BankPaymentController`

Route: `POST /webhooks/bank_payment` (at root level, not under companies)

Flow:
1. Validate `X-Skycom-Bank-Signature` == `local_secure_dev_secret`
2. Decode payload
3. Find `BillingTransaction` by `gateway_reference: data.transaction_token`
4. `ActiveRecord::Base.transaction`:
   - Update `BillingTransaction.status` → `:completed`, `gateway_reference` → `data.transaction_id` (the mock bank's txn ID)
   - Load `company.billing_wallet`, increment `main_balance_cents += data.amount`
   - Update `BillingTransaction.balance_after_cents` to new wallet balance
5. Publish to Centrifugo: `Websocket.publish(channel: "company:#{company.id}:top_up", data: { event: "top_up.completed", amount_cents: data.amount })`
6. Return `200 OK`

### 3.8 Frontend: `companies/top_ups/new_controller.js`

**connect():**
- Call `fetchJson` on current URL to load `billing_payment_methods`
- Store as `this.paymentMethods`

**contentHTML():**
- Amount input (number, min 1)
- Card-style payment method grid:
  - Each card shows: strategy-based icon, name, description
  - `mock_qr_gateway` cards: clickable, highlights on select
  - `mock_redirect_gateway` cards: show "Coming soon" badge, not clickable
  - Other strategies: rendered but disabled with "Not available" label
- "Confirm Top Up" button (disabled until amount + method selected)

**handleSubmit():**
1. POST to `create_company_top_ups_path(cid)` with `{ amount_cents, billing_payment_method_id }`
2. On success, re-render page content:
   - Hide the form
   - Show QR code via `renderQrCode(container, qr_string)`
   - Show "Scan to pay" + amount confirmation
   - Initialize Centrifuge: `new Centrifuge(websocket_url, { token: websocket_token })` → `newSubscription(websocket_channel)` → `on('publication', ...)` → redirect to `/billing`
3. On error: show toast with error message

### 3.9 Centrifugo Channel Security

- Channel name: `company:{company_id}:top_up` (private by convention)
- Token issued per-top-up, only included in the create response
- Only the browser that initiated the top-up receives the token
- Webhook publishes to the channel; only the subscribed client receives it

## 4. Data Flow (End-to-End)

```
1. GET /companies/:id/top_ups/new.json
   → BillingPaymentMethod.where(business_type: :b2b, strategy: [:mock_qr_gateway, :mock_redirect_gateway])

2. POST /companies/:id/top_ups { amount_cents: 1000, billing_payment_method_id: "qr-bank-transfer-uuid" }
   → TopUps::CreateService.call
     → BillingInvoice.create!(movement_type: :deposit, target_balance: :main_balance, price_cents: 1000, payment_status: :unpaid)
     → BillingTransaction.create!(transaction_type: :top_up, amount_cents: 1000, gateway_reference: "TOPUP_abc123...", status: :pending)
     → Payments::InitiateService.new(transaction: billing_txn).call
       → Payments::MockQrGateway.new(... transaction_token: "TOPUP_abc123...").call
         → POST http://localhost:4000/api/v1/bank/qr-generate { amount: 1000, invoice_id: "...", transaction_token: "TOPUP_abc123...", memo: "..." }
         ← { success: true, qr_string: "0002010102123858...", received: {...} }
       → billing_txn.update!(gateway_payload: { qr_string: "..." }, status: :pending)
   → Centrifugo token generated
   ← { qr_string: "...", websocket_url: "ws://localhost:8000/connection/websocket", websocket_token: "jwt...", websocket_channel: "company:uuid:top_up" }

3. (simultaneous, from mock API goroutine)
   POST http://<host>:3000/webhooks/bank_payment
     headers: { X-Skycom-Bank-Signature: "local_secure_dev_secret" }
     body: { event: "transaction.completed", data: { transaction_id: "TXN_QR_...", invoice_id: "...", transaction_token: "TOPUP_abc123...", amount: 1000, paid_at: "..." } }

4. Webhooks::BankPaymentController#create
   → Validate signature
   → BillingTransaction.find_by!(gateway_reference: "TOPUP_abc123...")
   → ActiveRecord::Base.transaction
     → billing_txn.update!(status: :completed, gateway_reference: "TXN_QR_...")
     → company.billing_wallet.increment!(:main_balance_cents, 1000)
     → billing_txn.update!(balance_after_cents: wallet.main_balance_cents)
   → Websocket.publish(channel: "company:uuid:top_up", data: { event: "top_up.completed", amount_cents: 1000 })
   → 200 OK

5. Browser receives Centrifugo publication
   → event: "top_up.completed"
   → window.location.href = company_billing_path(cid)
```

## 5. Files Changed/Added

| Action | File | Description |
|--------|------|-------------|
| **Add** | `db/migrate/*_add_gateway_columns_to_billing_transactions.rb` | Add status, gateway_reference, gateway_payload |
| **Modify** | `app/models/billing_transaction.rb` | Add enum, validation, attr |
| **Add** | `app/services/top_ups/create_service.rb` | Top-up orchestration |
| **Modify** | `app/controllers/companies/top_ups_controller.rb` | Implement create + new JSON |
| **Add** | `app/controllers/webhooks/bank_payment_controller.rb` | Webhook handler |
| **Add** | `config/initializers/webhooks.rb` | Webhook secret constant |
| **Modify** | `app/services/payments/mock_qr_gateway.rb` | Add transaction_token |
| **Modify** | `app/services/payments/initiate_service.rb` | Handle BillingTransaction columns |
| **Modify** | `app/javascript/controllers/companies/top_ups/new_controller.js` | Full rewrite with QR + WS |
| **Modify** | `app/javascript/controllers/helpers/dictionary.js` | Add new translation keys |
| **Modify** | `config/routes.rb` | Add webhook route |
| **Add** | `app/policies/companies/top_ups_policy.rb` | Pundit policy for top-ups |

## 6. Security Considerations

- Webhook signature validation prevents unauthorized wallet credits
- `gateway_reference` is a secure random token (16 bytes), not guessable
- Centrifugo channel token is scoped per-channel, issued per-top-up
- BillingTransaction status prevents double-crediting (webhook marks as `:completed`, second call skips)
- Company scope on all queries prevents cross-company manipulation
