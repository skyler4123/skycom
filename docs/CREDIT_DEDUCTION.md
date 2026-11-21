# Skycom Credit Deduction System

> **Status**: Live. All credit OUT flows through
> `CompanyCreditDeduction::DeductionService`, callable from controllers, models,
> jobs, and mailers. Page prices live in `CREDIT_DEDUCTION_RATES` keyed by
> `controller#action`.
>
> **Suspended-company rule**: a deduction skips a suspended company by default.
> A caller that must charge while suspended passes `allow_suspended: true`
> explicitly. Page deductions always use the default.

---

## 1. Overview

Every credit-consuming action must leave a trail: the wallet balance moves and
usage is metered. This document defines how charges are triggered, priced, and
executed.

### The Entry Point

```ruby
CompanyCreditDeduction::DeductionService.call(
  company: company,
  amount: 3,
  action_type: "access_pos_console",
  description: "POS console access",
  source: nil,
  allow_suspended: false,
  external_id: nil
)
```

| Argument | Required | Meaning |
|---|---|---|
| `company` | ✅ | Wallet owner |
| `amount` | ✅ | Positive integer credits |
| `action_type` | ✅ | Must exist in `CREDIT_DEDUCTION_ACTION_TYPES` |
| `description` | optional | Audit text; defaults to the humanized action type |
| `source` | optional | Domain record written to wallet/usage logs; defaults to company |
| `allow_suspended` | optional | `false` skips a suspended company |
| `external_id` | optional | Retry key; a repeated key does not charge twice |

The service returns `true` when it charged, `false` when it skipped.

### One Write Path

| Path | May deduct? | How |
|---|---|---|
| Controller page load | ✅ | `Companies::CreditDeductionConcern` → service |
| Controller action (API) | ✅ | Service directly, or `charge_on: :every_request` rule |
| Model | ✅ | Service directly |
| Background job | ✅ | Service directly; suspended skipped unless opted in |
| Mailer | ✅ | Service directly; suspended skipped unless opted in |
| Seed | ❌ | Seeds may meter demo usage, never deduct |

`deduct_from!` is the wallet primitive behind the service. Nothing outside
`CompanyCreditDeduction::*` calls it directly
(`spec/services/credit_deduction_boundary_spec.rb` enforces this).

---

## 2. Page Pricing

**File**: `config/initializers/constants.rb`

```ruby
CREDIT_DEDUCTION_RATES = {
  "companies/dashboards#index" => {
    cost: 2, action_type: "access_dashboard",
    description: "Dashboard access", charge_on: :first_json
  }.freeze,
  "companies/analytics#index" => {
    cost: 2, action_type: "access_analytics",
    description: "Analytics access", charge_on: :first_json
  }.freeze,
  "companies/operations/pos#show" => {
    cost: 3, action_type: "access_pos_console",
    description: "POS console access", charge_on: :first_json
  }.freeze
  # booking, inventory, reception, store_manager
}.freeze
```

| `charge_on` | Behavior |
|---|---|
| `:first_json` | HTML shell free; first successful matching JSON charges once; later JSON free |
| `:html` | Successful HTML page request charges; JSON free (available for later) |
| `:every_request` | Every successful JSON request charges (available for API pricing) |
| `:none` | Never charge |

Current prices:

| Page | Cost |
|---|---:|
| Dashboard index | 2 |
| Analytics index | 2 |
| POS console | 3 |
| Booking console | 3 |
| Inventory console | 3 |
| Reception console | 3 |
| Store Manager console | 3 |

Mobile operation shells use the same rule: the concern drops the `mobile/`
prefix before lookup, and the web JSON endpoint consumes the mobile shell's
token.

---

## 3. Page-Load Flow (`:first_json`)

1. A successful `GET` HTML request for a priced page mints a signed page token
   (`CompanyCreditDeduction::PageTokenService`) containing the page key, company
   id, employee id, nonce, and a one-hour expiry.
2. The token is rendered into `<body data-credit-page-token="…">`.
3. `Helpers.fetchJson()` forwards it as `X-Credit-Page-Token` on same-origin
   requests.
4. The first successful JSON request whose `controller#action` matches the
   token page claims the token atomically (Kredis `SET NX` via
   `Company#claim_credit_page_token!`) and calls `DeductionService`.
5. Later JSON requests with the same token do not charge: polling, period
   changes, and sub-resource calls are free.
6. A new page load mints a new token, so it charges again.
7. A JSON request without a token is free. API pricing can opt into
   `:every_request` later.
8. If the deduction raises, the claim is released so a retry can charge.

The concern never contains deduction math. It resolves the rule, validates the
token, and delegates.

---

## 4. The Two-Balance Wallet

**File**: `app/models/company_wallet.rb`

The wallet stores credit balance numbers only. The deduction service owns the
priority rules.

| Column | Purpose | Top-up target? | Deduct order |
|--------|---------|----------------|--------------|
| `main_credit_balance` | Purchased credits (top-ups land here) | ✅ Yes (`add_credits!`) | 2nd |
| `promo_credit_balance` | Promotional credits (signup bonus, campaigns) | ❌ No | **1st** |

- New companies get `SIGNUP_PROMO_CREDITS` (**1,000,000**) in the promo balance
  at creation. System-owned companies receive the same grant; only their
  suspension exemption is special.
- Existing companies are not backfilled.
- Both columns are BIGINT and may be negative. A negative total derives
  `workflow_status: suspend`.

### Low-Level API

```ruby
wallet.add_credits!(amount:, source:, description:)                    # top-up → main only
wallet.add_to!(balance: :promo, amount:, source:, description:)        # grant promo credits
wallet.deduct_from!(balance: :main, amount:, source:, description:,
                    action_type:, external_id:)                         # service only
```

- Every mutation runs inside `with_lock` (transaction + `FOR UPDATE`).
- `deduct_from!` subtracts the full amount and may make the balance negative.
- Every mutation writes a `CompanyWalletLog` audit row with `balance_type` and
  before/after snapshots, then calls `company.sync_credit_status!`.
- `external_id` is an optional retry key mirrored on the wallet log.

### Company Credit Status

| Value | Meaning | Web/API/mobile | Background jobs | Set when |
|-------|---------|----------------|-----------------|----------|
| `active` | Normal company with usable credit | Allowed | Processed | `total > 0` |
| `disabled` | Owner no longer uses Skycom | Not suspension-blocked | Skipped | Manual |
| `suspend` | No usable credit (`total <= 0`) | Web redirects to top-up; JSON/mobile 403 | Processed; deductions skip by default | `total <= 0` |

- System companies are exempt from credit suspension.
- Any credit movement can move a `disabled` company back to `active`.

---

## 5. Warning & Balance Display

The deduction service only deducts. Insufficient-balance feedback is separate.
The dashboard JSON exposes wallet numbers:

```json
{
  "wallet": {
    "main_credit_balance": 98,
    "promo_credit_balance": 0,
    "currency": "USD"
  }
}
```

The old `credit_warning` key is gone.

### 5.1 Opt-in Detail Logging

Per-action detail rows (`CompanyUsageLog`) are opt-in. The Usage page
(`GET /companies/:id/usage`) exposes the toggle:

| Control | Endpoint | Effect |
|---------|----------|--------|
| **Enable Logging** | `POST .../usage/enable_logging` | Opens a 5-minute recording window |
| **Stop Logging** | `POST .../usage/disable_logging` | Closes it immediately |

`CompanyUsageLog.action_type` accepts `CREDIT_DEDUCTION_ACTION_TYPES` keys plus
`top_up` / `deduction`.

---

## 5.2 Suspended Company — Request Blocking

| Request | Result |
|---------|--------|
| Web HTML (company pages) | `302` → `new_company_top_up_path` |
| Web JSON (company pages) | `403` + `{ errors: [...] }` |
| Mobile company pages | `403` with a mobile-layout notice |
| Top-Up / Billing / Usage | Allowed |
| Sign-in / root / client cache / webhooks | Allowed |

`Companies::SuspendedCompanyConcern` and
`Mobile::Companies::SuspendedCompanyConcern` enforce this. The deduction
service has a second guard: `allow_suspended` defaults to `false`.

### Shortfall guard

The first overdraw (`0 → -2`) is silent. A later deduction that starts while
the balance is already negative logs
`[CompanyCreditDeduction] deduction while negative ...` and rechecks
`workflow_status`.

---

## 6. Adding a Deduction Point

### 6.1 A new page

1. Add the `controller#action` key to `CREDIT_DEDUCTION_RATES` with `cost`,
   `action_type`, `description`, and `charge_on: :first_json`.
2. Add the action type to `CREDIT_DEDUCTION_ACTION_TYPES` if it is not already
   derived from the rules (the constant is derived from `CREDIT_DEDUCTION_RATES`
   plus `top_up` / `deduction`; non-page actions are appended).
3. No controller code is needed. The concern picks up the rule.
4. Add request coverage: HTML free; first JSON charges once; later JSON free.

For a new Operation type, add the rule for
`"companies/operations/<type>#show"`. The rates spec fails until every
`OPERATION_TYPES` key has one.

### 6.2 A job, model, or mailer charge

```ruby
CompanyCreditDeduction::DeductionService.call(
  company: company,
  amount: 1,
  action_type: "send_email",
  description: "Email sent",
  source: email_record,
  allow_suspended: false,
  external_id: "email-#{email_record.id}"
)
```

Add a stable action type and pass an `external_id` when the work can retry.

---

## 7. Testing

- Page costs: `spec/services/company_credit_deduction/deduction_rates_spec.rb`
- Service contract: `spec/services/company_credit_deduction/deduction_service_spec.rb`
- Token signing: `spec/services/company_credit_deduction/page_token_service_spec.rb`
- Page flows: `spec/requests/companies/credit_deduction_spec.rb`,
  `spec/requests/companies/credit_deduction_pages_spec.rb`
- Feature proof: dashboard, analytics, and operation feature specs
- E2E chain: `spec/features/companies/credit_deduction_e2e_spec.rb`

New companies start with `SIGNUP_PROMO_CREDITS` in promo. Use the
`:without_signup_promo` factory trait or `seed_random_wallet!` when a test needs
a known baseline.

### State transitions

| State transition | Expected status | Covered by |
|---|---|---|
| Signup init (promo 1,000,000) | `active` | `company_credit_status_spec` |
| `0` | `suspend` | `company_credit_status_spec`, `company_wallet_spec` |
| `0` → positive | `active` | `company_credit_status_spec` |
| positive → `0` | `suspend` | `company_credit_status_spec`, `company_wallet_spec` |
| positive → negative | `suspend` | `company_credit_status_spec`, `company_wallet_spec` |
| negative → positive | `active` | `company_credit_status_spec`, `company_wallet_spec` |
| `disabled` → positive | `active` | `company_credit_status_spec` |
| System company at `0` or negative | stays `active` | `company_credit_status_spec` |

---

## 8. File Reference

| File | Purpose |
|------|---------|
| `app/services/company_credit_deduction/deduction_service.rb` | Public, layer-agnostic deduction API + suspended guard + retry key |
| `app/services/company_credit_deduction/base_service.rb` | Deduction core: priority, logs, metering, status sync |
| `app/services/company_credit_deduction/page_token_service.rb` | Signed one-time page tokens |
| `app/controllers/concerns/companies/credit_deduction_concern.rb` | Page rule lookup, token mint/claim, `charge_on` switch |
| `app/controllers/mobile/companies/base_controller.rb` | Includes the concern for mobile shells |
| `app/models/company.rb` | `claim_credit_page_token!`, `release_credit_page_token!`, signup promo, status sync |
| `app/models/company_wallet.rb` | Wallet primitives + audit logs |
| `app/models/company_usage_log.rb` | Opt-in per-action detail log |
| `app/services/cache_key_service.rb` | `company_credit_page_token` Kredis key |
| `app/services/dashboards/overview_service.rb` | Dashboard `access_cost` from the page rule |
| `app/views/layouts/application.html.erb` | `data-credit-page-token` |
| `app/views/layouts/mobile.html.erb` | `data-credit-page-token` |
| `app/javascript/controllers/helpers/ui_helpers.js` | Forwards `X-Credit-Page-Token` |
| `config/initializers/constants.rb` | `CREDIT_DEDUCTION_RATES`, `CREDIT_DEDUCTION_ACTION_TYPES`, `CREDIT_PAGE_TOKEN_TTL`, `SIGNUP_PROMO_CREDITS` |
| `spec/services/credit_deduction_boundary_spec.rb` | Mechanical guard: only deduction services call `deduct_from!` |

---

## 9. See Also

- `docs/ATOMIC_PURPOSE.md` — credit chain and atomic-purpose pattern
- `docs/CONSTANTS.md` — constant conventions
- `docs/MONEY_FLOW.md` — money lifecycle
- `docs/OPERATION_PAGES.md` — Operation page contract

---

*End of document*
