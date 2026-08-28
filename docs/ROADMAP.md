# Skycom Platform Roadmap

> **Status**: Live. This roadmap reflects the **credit pay-as-you-go** era. The earlier paid-feature billing model (BillingContract/BillingResource/feature gating/metering/circuit-breaker) was removed in `404053ca` (2026-08-12) and replaced by the credit system (`94474db2`+). Feature *access* is now unconditional — every company gets the whole platform; each **consuming action** costs **credits** drawn from a multi-balance wallet. See `docs/CREDIT_DEDUCTION.md` and `docs/ATOMIC_PURPOSE.md` for the architecture.

---

## Preface: The Credit Pay-As-You-Go Model

Skycom is a multi-tenant retail ERP with a **usage-based credit** monetization model:

| Concept | Mechanism | Where |
|---------|-----------|-------|
| **Access** | Unconditional — no paid tiers, no feature gating. All modules render for every company. | `docs/ROADMAP.md` (this doc) |
| **Consumption** | Each consuming action costs a fixed credit amount (`CREDIT_USAGE_RATES`): `access_dashboard: 2`, `create_order: 10`, `create_customer: 7` | `config/initializers/constants.rb` |
| **Deduction** | After a successful JSON response, the declared `CompanyCreditDeduction::*` service drains promo balance first, then main; any shortfall is absorbed by debt | `docs/CREDIT_DEDUCTION.md` |
| **Top-up** | Company buys credit packs via `CREDIT_RATES[country]` (money → credits) through the chain `CompanyOrder → CompanyInvoice → CompanyTransaction → CompanyWallet`, paid by Mock QR / Mock Redirect gateway | `app/services/top_ups/create_service.rb` |
| **Metering** | Kredis counter `company.record_credit_usage!` → drained to `CompanyDailyUsage`/`CompanyMonthlyUsage` by `CompanyUsageSyncJob` | `docs/ATOMIC_PURPOSE.md` § Hot Path Rule |

### Money Flow Diagram

```
[User completes a consuming action]
        │
        ▼
[CompanyCreditDeduction::* after_action]   ← cost = CREDIT_USAGE_RATES[action_type]
        │  deduct promo → main → debt
        │  company.record_credit_usage!(cost)   (Kredis delta)
        ▼
   [Redis delta accumulated]
        │  CompanyUsageSyncJob (periodic)
        ▼
   [CompanyDailyUsage / CompanyMonthlyUsage snapshots]
        │
        ▼
   [Wallet runs low?]
        ├── Yes ► Usage page shows balance; low-balance warnings (Phase 1)
        └── No  ► Continue operating
        │
        ▼
   [Company tops up]
        ├── Select CREDIT_RATES tier
        ├── CompanyOrder → CompanyInvoice → CompanyTransaction (pending)
        ├── Gateway: Mock QR (scan) or Mock Redirect (hosted page)
        ├── Webhook completes transaction
        │     └── after_update → invoice paid → order complete! → wallet.add_credits!
        └── Wallet refreshed (main balance + credits)
```

---

## Current State (Built & Live)

### Core Infrastructure

| Layer | Status | Notes |
|-------|--------|-------|
| Multi-tenant Rails 8 + Hybrid SPA (Stimulus + Tailwind, importmap) | ✅ | Shell-First JSON API; client cache in localStorage |
| ABAC permission system (Policies, Roles, tag conditions, Pundit) | ✅ | `docs/ABAC.md`; owner records immutable |
| Dynamic schema (Category → PropertyMapping → TableConfig) | ✅ | `docs/CATEGORY_DYNAMIC_SCHEMA.md`, `docs/DYNAMIC_TABLE.md` |
| Multi-language (EN/VI dictionary + `translate()`) | ✅ | `docs/LANGUAGE.md` |
| Sync cache + pub/sub invalidation, Kredis counters | ✅ | `docs/CACHE.md`, `docs/KREDIS.md` |
| WebSocket (Centrifugo v5) company/user channels | ✅ | `docs/WEBSOCKET.md` |
| Mock API server (Go) for QR/redirect gateways | ✅ | `docs/MOCK_API.md` |
| Admin namespace (companies, payment methods) + Mobile namespace (early) | ✅ | `app/controllers/admin/`, `app/controllers/mobile/` |

### Feature Matrix

| Feature | Status | Notes |
|---------|--------|-------|
| **Credit wallet** (main/promo/debt, atomic `with_lock` mutations) | ✅ | `CompanyWallet`, `docs/CREDIT_DEDUCTION.md` |
| **Credit chain** (`CompanyOrder → CompanyInvoice → CompanyTransaction`) | ✅ | `docs/ATOMIC_PURPOSE.md`; invoice `payment_status` derived from transaction sum |
| **Top-up** (Mock QR + Mock Redirect gateways, webhooks, WS `top_up_completed`) | ✅ | `app/controllers/companies/top_ups_controller.rb`, `app/services/top_ups/create_service.rb` |
| **Usage metering** (Kredis delta → `CompanyUsageSyncJob` → Daily/Monthly) | ✅ | `docs/ATOMIC_PURPOSE.md` Hot Path Rule |
| **Usage page** (7-day + monthly totals, opt-in detail logging toggle) | ✅ | `app/controllers/companies/usage_controller.rb` |
| **Billing page** (wallet snapshot + purchase history) | ✅ | `app/controllers/companies/billing_controller.rb` |
| **Credit deduction** (service hierarchy + `after_action` DSL) | ⚠️ Partial | Only `access_dashboard` (Dashboards#index) wired; `create_order`/`create_customer` rates defined but no services yet |
| **POS Order Processing V1** (cart → checkout → pay → finalize) | ✅ | `docs/ORDER_PROCESSING_V1.md`; cash + Mock QR modes, receipt, `pos_payment_completed` WS event |
| **Retail cashier operating page** | ✅ | `docs/OPERATING_PAGES.md`; multi-customer tabs, two-phase ORDER/PAY |
| **Stock management** (warehouses, imports, exports, transfers, Kredis available counter) | ✅ | `docs/ORDER_PROCESSING_V1.md` §7 |
| **HR / Attendance** (shift templates, schedules, 3-tier logs, geofence check-in/out) | ✅ | `docs/HR.md` |
| **Analytics dashboard** (revenue, margins, inventory velocity, staff, CLV) | ✅ | `app/services/analytics/dashboard_service.rb` |
| **Payment methods** (global catalog + company/branch appointments, merchant identity) | ✅ | `docs/PAYMENT_METHODS.md` |
| Product / Service / Brand / Customer / Invoice / Order dashboards | ✅ | `docs/DASHBOARD_PATTERN.md` |
| Categories / Dynamic Properties / Dynamic Tables dashboards | ✅ | `docs/DYNAMIC_TABLE.md` |
| Permissions / Policies dashboards | ✅ | `docs/ABAC.md` |

---

## Phase 1 — Complete the Credit Loop (Next)

> Goal: make the monetization engine whole — every consuming action actually deducts, users can see their balance and get warned, and debt behavior is decided. Retail-first.

### 1.1 Wire `create_order` + `create_customer` deductions
- **Status**: ⬜ Not started | **Complexity**: M
- Add `CompanyCreditDeduction::Companies::Orders::CreateService` (`action_type: "create_order"`, cost 10) and `CompanyCreditDeduction::Companies::Customers::CreateService` (`action_type: "create_customer"`, cost 7)
- Declare `deduct_company_credits_for :create, with: ...` on `OrdersController` and `CustomersController`
- Follow the reference implementation (`Dashboards::IndexService`) + `docs/CREDIT_DEDUCTION.md` §6
- **Done when**: POS checkout (`OrderProcessingV1::V1Controller#checkout`? or `Orders#create`?) and customer creation each deduct the right amount; spec coverage per `docs/CREDIT_DEDUCTION.md` §7

### 1.2 Credit / low-balance UI surfacing
- **Status**: ⬜ Not started | **Complexity**: S
- Surface `main/promo/debt` balance in the layout header (persistent, not just on Usage page)
- Low-balance warning toast when `total_credit_balance` crosses a threshold (constant in `config/initializers/constants.rb`)
- **Done when**: user always sees their balance; low balance triggers a visible warning

### 1.3 Debt enforcement decision
- **Status**: ⬜ Not started (TBD) | **Complexity**: M
- Decide what `debt_credit_balance > 0` means: block consuming actions? hard ceiling? repayment flow?
- **Done when**: documented behavior + enforcement (currently debt silently absorbs shortfalls)

### 1.4 Top-up polish
- **Status**: ⬜ Not started | **Complexity**: S
- Resolve the payment-method "Configured" heuristic (`docs/TODO.md` § Payment Method "Configured" Logic) — per-payment-mode required fields
- Cancel robustness for in-flight top-ups
- **Done when**: top-up UX matches the configured-state reality; no dead-end states

### 1.5 Usage guardrails
- **Status**: ⬜ Not started | **Complexity**: S
- Progressive warnings on the Usage page (e.g. "balance below X credits")
- **Done when**: warnings render from the usage payload

---

## Phase 2 — Retail Business Features

> Capabilities on top of the complete credit loop. Ordered by business value.

### 2.1 Multi-branch switcher
- **Status**: ⬜ Not started | **Complexity**: L
- Branch selector in header, data scoped by branch, owner cross-branch visibility

### 2.2 Commission engine
- **Status**: ⬜ Not started | **Complexity**: M
- Tie employee to order line items, auto-calculate commissions per sale; payroll-adjacent

### 2.3 Loyalty program
- **Status**: ⬜ Not started | **Complexity**: L
- Points, tiers (Silver/Gold/Platinum), reward catalog, redemption

### 2.4 Low-stock alerts
- **Status**: ⬜ Not started | **Complexity**: S
- Add a dedicated `min_stock` threshold column (never decremented by the pipeline); red-highlight + optional WS `stock_low` event (`docs/TODO.md` § Low-Stock Alert Threshold)

### 2.5 Automation engine
- **Status**: ⬜ Not started | **Complexity**: XL
- Rule-based triggers ("stock < 10 → create PO draft"), customer reminders, webhook config

### 2.6 Audit log viewer
- **Status**: ⬜ Not started | **Complexity**: M
- PaperTrail (`versions`) already active; build a viewer with before/after diffs

### 2.7 Open API
- **Status**: ⬜ Not started | **Complexity**: XL
- Public REST API, token management, rate limiting, developer docs

---

## Phase 3 — HR Completion

> The HR module is largely built (see `docs/HR.md`). Remaining work is the mobile/background layer.

| # | Task | Complexity | Notes |
|---|------|-----------|-------|
| 3.1 | Mobile check-in/out API + geofence | M | REST endpoints under mobile namespace; currently only a basic check-in exists |
| 3.2 | Nightly `SyncAttendanceJob` | M | Auto-close stale sessions (>16h), aggregate days → months |
| 3.3 | Daily resolution engine job | M | Background fusion of logs → segments → policy match (currently strategy classes exist) |
| 3.4 | Attendance policies UI | M | CRUD for per-branch geofence config |
| 3.5 | Payroll integration | M | Link `attendance_months` to commissions |
| 3.6 | Employee self-service | M | Employee-facing attendance dashboard |

---

## Phase 4 — Future Business Types

> Retail is the focus. Restaurant / hospital / education / hotel / fitness remain future tracks — each would follow the same init/enrich pattern (`Seed::RetailInitService` / `Seed::RetailEnrichService`) + operating pages (`docs/OPERATING_PAGES.md`).

| Type | Init/Enrich pair | Operating pages |
|------|------------------|-----------------|
| Restaurant | `Seed::Restaurant*Service` (future) | cashier, waiter, kitchen staff |
| Hospital | `Seed::Hospital*Service` (partial) | receptionist, doctor, nurse |
| Education | `Seed::Education*Service` (partial) | — |
| Hotel | `Seed::Hotel*Service` (partial) | — |
| Fitness | `Seed::FitnessService` (partial) | — |

---

## Housekeeping (tracked — no code yet)

| Item | Description | Reference |
|------|-------------|-----------|
| Dead routes with no controllers | `reports`, `documents`, `announcements`, `discounts`, `events`, `payslips`, `tasks`, `settings`, `subscription_plan_appointments`, `transactions` — either build or remove | `config/routes.rb` |
| Dead sidebar `featureKey` param | `link(featureKey, ...)` accepts a key that no longer gates anything | `layout_controller.js:46` |
| `transaction_token` / `gateway_reference` naming | Unify the seam between the API param and the DB column | `docs/TODO.md` |
| Payment-method "Configured" heuristic | Decide required merchant fields per payment mode | `docs/TODO.md` |

---

## Progress Tracker

| Date | Item | Status | Notes |
|------|------|--------|-------|
| 2026-08-12 | Remove paid-feature billing system (BillingContract/Resource, gating, metering, circuit breaker, suspension) | ✅ | `404053ca` |
| 2026-08-18 | Credit chain: wallet, orders/invoices/transactions, usage tables, Kredis counter + sync job, atomic-purpose pattern | ✅ | `docs/ATOMIC_PURPOSE.md`, `docs/CREDIT_DEDUCTION.md` |
| 2026-08-18 | Top-up with Mock QR + Mock Redirect gateways; webhooks; `top_up_completed` WS event | ✅ | |
| 2026-08-21 | Deduction via `after_action` + `CompanyCreditDeduction` service hierarchy; multi-balance wallet | ✅ | `docs/CREDIT_DEDUCTION.md` |
| 2026-08-23 | Randomized wallet seeding helper + E2E credit deduction spec | ✅ | `spec/support/credit_wallet_helper.rb` |
| 2026-08-24 | Usage page labels + opt-in usage logging toggle; sidebar Company/System split | ✅ | |
| 2026-08-25 | POS pay accepts branch payment methods; merchant identity in QR; `pos_payment_completed` | ✅ | `docs/ORDER_PROCESSING_V1.md` |
| 2026-08-26 | POS receipt panel; inline QR wait; one-click Mock QR payment | ✅ | |
| 2026-08-27 | Roadmap rewritten for the credit era; stale billing docs removed | ✅ | This doc |

---

## File Reference

| Doc | Covers |
|-----|--------|
| `docs/CREDIT_DEDUCTION.md` | Credit deduction system (after_action DSL, service hierarchy, multi-balance wallet, testing) |
| `docs/ATOMIC_PURPOSE.md` | Credit chain models + hot-path usage counter pattern |
| `docs/MONEY_FLOW.md` | Canonical money chain, PaymentMethod bridge, gateway architecture, POS/commerce flow |
| `docs/ORDER_PROCESSING_V1.md` | POS order pipeline (checkout → pay → finalize) |
| `docs/HR.md` | Shift/attendance module + dashboards |
| `docs/PAYMENT_METHODS.md` | Global payment method catalog + appointments |

---

*End of document*
