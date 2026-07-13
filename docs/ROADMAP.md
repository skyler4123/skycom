# Skycom Platform Roadmap

> This roadmap documents every feature Skycom offers and how they combine with the usage-based billing engine. Features are organized into progressive phases — each unlocks new business capabilities. Use this to track where you are and what comes next.

---

## Preface: The Pay-for-Use Architecture

Skycom uses a **decoupled billing model**: what features you can **access** is separate from what you **pay for usage** on.

- **Access** is governed by `BillingContract.enabled_features` — controls which UI modules and API endpoints are available
- **Usage billing** is governed by `BillingContract.included_allowance` + `unit_prices` — controls how much you pay for exceeding limits

This means Skycom can charge for premium features today, and **flip a single switch** tomorrow to make all features free while keeping usage-based billing. No code changes needed.

### The Pay-As-You-Go Model

Pricing is linear and consumption-based, like AWS S3:

| What | How It's Charged | Example |
|------|-----------------|---------|
| **Core features** (Tier 1) | Always free | pos_basic, inventory_basic, crm_basic, finance_basic |
| **Advanced features** (Tiers 2-4) | Per-feature monthly add-on | inventory_advanced: $3/mo, analytics_dashboard: $5/mo |
| **Usage overage** | Pay-as-you-go per unit | $0.10 per extra order, $0.01 per extra MB |
| **Enterprise** | Custom negotiated contract | All features + custom allowances + custom pricing |

### Money Flow Diagram

```
[User completes an action] ──► Platform records 1 usage unit
         │
         ▼
   [Redis daily counter increments: orders_today +1]
         │
    ─ ─ midnight ─ ─
         │
   [DailyUsageLog snapshot: 45 orders today]
         │
    ─ ─ month end ─ ─
         │
   [BillingContract check: allowance vs actual]
         ├── Within allowance ► $0 charge
         └── Over allowance   ► total_charge calculated
                                │
                   [Apply promo_balance credit first]
                                │
                   [Apply main_balance credit second]
                                │
                   [remaining > 0?]
                   ├── No ► Done (covered by credits)
                   └── Yes ►
                            ├── [VISA card on file?]
                            │   ├── Yes ► Auto-charge card
                            │   │         ├── Success ► Done
                            │   │         └── Declined ► Retry daily
                            │   │                       ├── Paid within grace ► Done
                            │   │                       └── Still failing ► Send QR
                            │   └── No ► Send QR for bank transfer
                            │
                            └── [Company pays via QR] ► Done
```

Every business action (order placed, employee added, file uploaded) is a countable resource. The platform meters it, tallies it, and generates a charge at month end. The company's credit balances (promo + main) offset the charge first; any remaining amount is paid via auto-charge to registered card, with QR/bank transfer as fallback.

---

## Architecture: How Feature Access is Evaluated

```
[User clicks "Advanced Analytics"]
                    │
                    ▼
        [Company.is_accessible?]  (suspension_at nil or future)
           ├── No  ► Redirect to /billing
           └── No  ► Continue
                    │
                    ▼
        [Company.active_billing_contract
           .feature_enabled?("analytics_dashboard")]
           ├── False ► "Enable for $5/mo"
           └── True ► Grant access
                      │
                      ▼
              [Execute action, meter usage]
```

The source of truth for feature gating is **always** the company's active BillingContract — never hardcoded plan tiers, never role checks.

---

## Phase 0: Foundation Already Built

Skycom's core business domain is production-ready and operational.

### Core Infrastructure
- **Multi-tenant architecture**: All data scoped by `company_id` with full data isolation across 61 managed resource tables
- **ABAC permission system**: Attribute-based access control with policies, roles, and tag conditions — inspired by AWS IAM
- **Owner protection**: Owner roles/policies are immutable, only one owner per company, cannot be deleted
- **Shell-First SPA**: Stimulus + JSON API architecture — server returns empty HTML shell, JavaScript fetches JSON and renders client-side
- **Dynamic schema system**: Categories + PropertyMappings let different industries define different data fields on the same `property_*` columns
- **Multi-language**: 5-language client-side translation system (EN, ES, FR, DE, VI)
- **Client cache**: localStorage-based cache for fast frontend data access across all Stimulus controllers
- **Dual caching**: Server-side Solid Cache (SQLite) for per-server data + Redis for cross-cluster shared state

### Working Features

| Feature | Description |
|---------|-------------|
| **Products Catalog** | Full CRUD with dynamic properties per category, brands, product groups |
| **Services Catalog** | Service offerings with dynamic properties, service groups |
| **Stock Management** | Per-warehouse stock levels, imports (receiving), exports (write-offs), transfers between warehouses |
| **Order Processing V1** | Full checkout-to-payment pipeline with atomic Redis stock reservation, invoice + payment creation, async finalization via background job |
| **Customer Management** | Customer profiles, groups, purchase history |
| **Branches** | Multi-location structure with branch-specific data scoping |
| **Departments** | Organizational hierarchy |
| **Employees** | Staff records with role assignments and attendance tracking (shifts, daily/monthly logs) |
| **ABAC Permissions UI** | Role-based permission management with policy-to-role checkbox interface |
| **Dynamic Tables** | Category-filtered tables with configurable visible columns via TableConfig |
| **Inline Editing** | Click-to-edit fields with state-to-template reactivity and event-driven synchronization |
| **Address System** | Shared immutable address records with fingerprint-based deduplication |
| **Period/Price System** | Shared immutable time-range and monetary-value records with polymorphic join |
| **Image Processing** | ActiveStorage-backed avatar system with variants (thumb, medium, profile, full) |
| **Operating Pages** | Dedicated full-screen POS interfaces — retail cashier is the reference implementation |
| **Dashboard Pattern** | Full CRUD shell-first dashboards for all major resources |

---

## Phase 1: Core Platform Infrastructure (The Base)

> Establish the circuit breaker, the BillingContract (source of truth for gating), and feature gating itself.

### 1A — Company Circuit Breaker

Every Company's `lifecycle_status` + `suspension_at` control operational state:

| Status | Behavior | Trigger |
|--------|----------|---------|
| `active` | Full operations — all features work normally | Default; reached via `try_reactivate!` when all invoices paid |
| `suspended` | Blocked — `is_accessible?` returns false, redirected to billing page | SyncSuspensionJob sets this when `suspension_at` deadline has passed |
| `disabled` | Terminal — no transitions out | Company deletion request |

The lifecycle flow:

```
flag_unpaid! — sets has_unpaid_invoices_at + suspension_at (end of month)
    active ──► active (has_unpaid_invoices flag set, suspension deadline ahead)
       │
       │  suspension_at passes → SyncSuspensionJob
       ▼
    suspended  ──► is_accessible? returns false → redirects to /billing
       ▲
       │  try_reactivate! (all invoices paid)
       └──────────── active (suspension_at cleared, has_unpaid_invoices cleared)
```

The `check_accessable` before_action (in `Companies::Authorizable`) checks `current_company&.is_accessible?` on every request:
- `is_accessible?` returns `false` when `lifecycle_status_suspended?`
- `suspended` → not accessible → redirects to `/billing`
- `active` / `disabled` → accessible (disabled is terminal but still reachable)

**UI behavior when access is blocked:**
- Access-protected actions redirect to `/billing`
- A persistent flash warning displays: *"Your account has outstanding invoices. Please settle them to avoid suspension."*
- Only navigation and data viewing remain functional
- `hide_billing_alerts` (boolean on Company) suppresses the warning banner when set to `true`

### 1B — BillingContract (The Source of Truth)

Every company has exactly one active `BillingContract`. This single record controls **everything** about what the company can do and what they pay. It is created automatically during company signup (free tier by default).

**The `enabled_features` field** is a JSONB key-value map where each feature key is mapped to `true` (enabled) or `false` (disabled). Each advanced feature has a corresponding price in `feature_prices`:

```json
{
  "enabled_features": {
    "pos_basic": true,
    "inventory_basic": true,
    "crm_basic": true,
    "hrm_attendance": false,
    "inventory_advanced": false,
    "analytics_dashboard": false
  },
  "feature_prices": {
    "hrm_attendance": 2,
    "inventory_advanced": 3,
    "analytics_dashboard": 5,
    "crm_loyalty": 2,
    "multi_branch": 4,
    "automation_engine": 3,
    "payment_gateways": 3,
    "hrm_payroll_commissions": 3,
    "audit_logs": 3,
    "custom_roles": 5,
    "open_api": 7,
    "sso_saml": 10
  },
  "included_allowance": {
    "orders": 200,
    "storage_mb": 500,
    "employees": 3,
    "branches": 1
  },
  "unit_prices": {
    "orders": 0.10,
    "storage_mb": 0.01,
    "employees": 5,
    "branches": 10
  },
  "soft_debt_threshold": -200,
  "contract_type": "basic"
}
```

Prices are stored per-company on the BillingContract, allowing custom pricing for promotions or negotiations. When a company enables an advanced feature, the UI shows its price before confirmation: "Enable inventory_advanced for $3/mo?"

**`feature_enabled?(:key)`** is the single entry point used everywhere:

| Layer | Check |
|-------|-------|
| **Backend (Ruby)** | `Company#feature_enabled?(:analytics_dashboard)` → checks `active_billing_contract.enabled_features` |
| **Frontend (JS)** | `currentContract().feature_enabled?("analytics_dashboard")` → from client cache |
| **API** | Endpoint returns 403 with `{ error: "Feature not available" }` |

### 1C — Feature Gating

Every feature has a unique key (e.g., `pos_basic`, `inventory_advanced`). The runtime check follows this chain:

```
Company
  └── active_billing_contract
        └── enabled_features
              └── feature_enabled?(:analytics_dashboard) → true/false
```

**Platform layer**: All controllers, services, and model callbacks call `Company#feature_enabled?(:key)` before executing. If disabled, the operation returns a "feature not available" response.

**UI layer**: Sidebar items, action buttons, and tabs conditionally render based on `currentContract().enabled_features` from the client cache. A disabled feature is never shown — not hidden, not grayed out, simply absent.

### 1D — Subscription Lifecycle (Plan Catalog)

`BillingContract` is the source of truth for gating. Plan templates define the default `enabled_features`, `feature_prices`, `included_allowance`, and `unit_prices` for new contracts.

| Concept | Description |
|---------|-------------|
| **Plan** | A market-aware template with default `enabled_features`, `feature_prices`, `included_allowance`, and `unit_prices` per country |
| **Subscription** | Links a company to a plan with start/end dates |
| **Plan change** | Creates a new BillingContract from the new plan's template — features enable/disable immediately |
| **Expiration** | Expired subscription → `flag_unpaid!` sets billing flags; `SyncSuspensionJob` suspends if unpaid |

New companies start with a **Free plan** BillingContract at signup.

---

## Phase 2: Core ERP Features (The Value)

> The baseline feature set that every business needs. Organized into four progressive tiers.
>
> **Core features** (Tier 1) are enabled on every free-tier BillingContract.
> **Advanced features** (Tiers 2-4) are gated by `enabled_features` — paid today, flippable to free tomorrow.

### Tier 1: The Solo Shop (Core — Always Free)

Essentials for a single-location business. Included in every new company's BillingContract by default.

#### `pos_basic` — Point of Sale & Invoicing
- Quick checkout flow with product/service lookup
- Cash and transfer payment tracking
- Digital receipt generation
- Basic invoice creation (code: INV-xxxxx)
- Full order lifecycle: cart → checkout → payment → finalize

**Disabled behavior:** All cart, checkout, invoice, and payment UIs are hidden. No orders can be created.
**Dependencies:** None

#### `inventory_basic` — Single-Location Inventory
- Product catalog with dynamic property fields per category
- Stock counts per warehouse with low-stock alerts
- Barcode/SKU tracking for physical goods
- Simple stock imports (supplier receipts) and exports (write-offs, damages)
- Stock levels visible per product

**Disabled behavior:** Products, stocks, stock transfers, stock imports/exports menus are hidden.
**Dependencies:** None

#### `crm_basic` — Customer Directory
- Customer profile management (name, phone, birthday, contact info)
- Purchase history view per customer
- Customer group segmentation for marketing
- Walk-in customer auto-creation at checkout

**Disabled behavior:** Customers menu and customer-related appointment UIs are hidden.
**Dependencies:** None

#### `finance_basic` — Income & Expense Tracking
- Daily sales summaries
- Manual expense logging
- Invoice history and payment tracking
- Single-currency with configurable timezone

**Disabled behavior:** Financial reports, invoice history dashboards are hidden.
**Dependencies:** `pos_basic`

---

### Tier 2: The Growing Team (Advanced — Add-on $2/mo)

For businesses that hire employees and need operational tooling. Each feature in this tier can be enabled individually for a monthly add-on fee.

#### `hrm_attendance` ($2/mo) — Time & Attendance
- Employee clock-in/clock-out tracking
- Shift definition and scheduling
- Daily and monthly attendance summaries
- Branch-based location verification for attendance

**Disabled behavior:** Shifts, attendance logs, attendance days/months UIs are hidden. Clock-in/out buttons are removed.
**Dependencies:** None

#### `hrm_payroll_commissions` ($3/mo) — Payroll & Commissions
- Commission engine: ties employee ID to order line items, auto-calculates commissions per sale
- Base salary components in employee metadata
- Leave management workflows (request → approve → log)

**Disabled behavior:** Payroll config, commission rules, leave request UIs are hidden.
**Dependencies:** `hrm_attendance`, `pos_basic`

#### `inventory_advanced` ($3/mo) — Multi-Warehouse & Supplier Management
- Stock transfers between warehouses
- Supplier purchase order (PO) creation and fulfillment tracking
- Bin location tracking per warehouse
- Cost of Goods Sold (COGS) calculation per product
- Batch/expiry tracking for sensitive products

**Disabled behavior:** Stock transfer, supplier management, purchase order, batch tracking UIs are hidden.
**Dependencies:** `inventory_basic`

#### `crm_loyalty` ($2/mo) — Loyalty & Rewards Program
- Store credits and points multipliers
- Automated customer tiering (Silver, Gold, Platinum) based on spending
- Reward catalog linking points to free products or service discounts
- Wishlist and saved-items tracking per customer

**Disabled behavior:** Loyalty points display, reward redemption, tier badges on customer profiles are hidden.
**Dependencies:** `crm_basic`, `pos_basic`

---

### Tier 3: The Multi-Branch Retailer (Advanced — Paid Today)

For businesses operating multiple locations or high-volume operations. Each feature in this tier can be enabled individually for a monthly add-on fee.

#### `multi_branch` ($4/mo) — Multi-Branch Management
- Branch switcher in header allows viewing data per location
- Branch-specific operating hours, warehouse assignments, and staff rosters
- Global financial visibility for owner across all branches
- Branch-level inventory isolation with cross-branch transfer

**Disabled behavior:** Branch switcher in header is hidden. Company operates as single-branch only.
**Dependencies:** `inventory_advanced`

#### `automation_engine` ($3/mo) — Automated Workflows
- Rule-based triggers: "When stock drops below 10, create PO draft for Supplier X"
- Automated customer reminders: Zalo/Email/SMS 2 hours before appointment
- Post-service follow-up scheduling
- Webhook configuration for external integrations

**Disabled behavior:** Automation rules UI, webhook configuration are hidden.
**Dependencies:** `inventory_advanced`, `crm_basic`

#### `analytics_dashboard` ($5/mo) — Advanced Analytics
- Profit-margin deep dives per product/category
- Inventory velocity and turnover analysis
- Shift-efficiency and staff performance reports
- Customer lifetime value (CLV) tracking
- Financial reporting per branch
- Month-over-month trend charts

**Disabled behavior:** Analytics tabs, report generation buttons are hidden.
**Dependencies:** `multi_branch` or `inventory_advanced`

#### `payment_gateways` ($3/mo) — Integrated Payments
- Native integration with MoMo, ZaloPay, VNPay
- Automated QR code generation per invoice
- Refund workflow to original payment source
- Multi-currency support for international customers

**Disabled behavior:** Payment gateway configuration, non-cash payment options in POS are hidden.
**Dependencies:** `pos_basic`

---

### Tier 4: The Enterprise (Advanced — Paid Today)

For large operations requiring audit trails, custom permissions, and developer access. Each feature in this tier can be enabled individually for a monthly add-on fee.

#### `audit_logs` ($3/mo) — Advanced Auditing
- Tamper-evident log of every resource modification
- Track who changed a price, stock count, employee role, or permission
- Version history with before/after diff view
- Exportable audit trails for compliance

**Disabled behavior:** Audit log viewer, version history tabs are hidden.
**Dependencies:** None

#### `custom_roles` ($5/mo) — Granular RBAC
- Custom policy creation with specific action/resource rules
- Role-to-policy assignment with workflow status toggling
- Beyond basic roles: build permission matrices using the ABAC system
- Complex tag-condition rules for granular resource-level access

**Disabled behavior:** Custom role editor, policy builder UI are hidden. Falls back to default fixed role set.
**Dependencies:** None

#### `open_api` ($7/mo) — Developer API & Access Tokens
- Public REST API for custom integrations
- API token management with rate limits
- Webhook event type configuration
- Developer documentation and sandbox environment

**Disabled behavior:** API tokens section in settings, API documentation links are hidden.
**Dependencies:** `audit_logs`

#### `sso_saml` ($10/mo) — Single Sign-On
- Centralized login via Okta, Azure AD, Google Workspace
- SAML/SSO configuration UI
- Identity provider management
- Automatic user provisioning and de-provisioning

**Disabled behavior:** SSO settings page, identity provider configuration are hidden.
**Dependencies:** `custom_roles`

---

### Feature Dependency Graph

```
Tier 1 (Core — Always Free)
├── pos_basic
├── inventory_basic
├── crm_basic
└── finance_basic → pos_basic

Tier 2 (Advanced — Add-on $2-3/mo)
├── hrm_attendance ($2/mo)
├── hrm_payroll_commissions ($3/mo) → hrm_attendance + pos_basic
├── inventory_advanced ($3/mo) → inventory_basic
└── crm_loyalty ($2/mo) → crm_basic + pos_basic

Tier 3 (Advanced — Add-on $3-5/mo)
├── multi_branch ($4/mo) → inventory_advanced
├── automation_engine ($3/mo) → inventory_advanced + crm_basic
├── analytics_dashboard ($5/mo) → multi_branch | inventory_advanced
└── payment_gateways ($3/mo) → pos_basic

Tier 4 (Advanced — Add-on $3-10/mo)
├── audit_logs ($3/mo)
├── custom_roles ($5/mo)
├── open_api ($7/mo) → audit_logs
└── sso_saml ($10/mo) → custom_roles
```

---

## Phase 3: The Metering Subsystem (The Counters)

> Count every business action so Skycom knows what each company is using.

### Countable Resources

Every feature generates countable usage. These are the metered resources:

| Resource | Unit | Counted When | Example |
|----------|------|--------------|---------|
| `orders` | per order | Order is marked as paid | 450 orders this month |
| `storage_mb` | MB per day | File uploaded to ActiveStorage | 320 MB stored |
| `employees` | per active employee | Employee has active lifecycle_status | 12 active employees |
| `branches` | per active branch | Branch is created and active | 3 branches |
| `customers` | per customer record | Customer is created | 890 customers |
| `api_calls` | per API request | API token is used | 12,400 API calls |
| `stock_mutations` | per stock change | Stock import/export/transfer is created | 230 operations |

### Real-Time Counters (Redis)

Every countable action fires an atomic `INCR` on a daily-keyed Redis key:

```
skycom:orders:company_<uuid>:20260623
skycom:storage:company_<uuid>:20260623
skycom:employees:company_<uuid>:20260623
```

These keys are lightweight, never block the main operation, and are the source of truth for the current day's usage.

### Daily Snapshots (PostgreSQL)

Every hour, `SyncDailyUsageJob` syncs Redis counters to `DailyUsageLog`:
1. Reads counters via `company.meter_usage` (Kredis proxy with DB fallback on restart)
2. Upserts one `DailyUsageLog` row per company per resource per day
3. Keys remain in Redis with 36h TTL — no manual deletion needed

This creates a permanent, queryable history. The `DailyUsageLog` table stores:
- `company_id`, `resource_name`, `logged_date`
- `quantity` (total for that day)
- `created_at` / `updated_at`

### Monthly Rollup & Billing Trigger

At month end (or on-demand):
1. `SUM` all `DailyUsageLog` rows for the billing period
2. Compare against the company's `BillingContract` allowances
3. Compute overage charges
4. Total = overage + feature add-ons, offset by promo/main balance credits; collect any remaining via card or QR

### Usage Analytics API

**`GET /companies/:id/usage`** returns current month usage vs allowances plus 6-month history. Powers the frontend usage charts and the 80%/95% guardrail warnings.

---

## Phase 4: Flexible Billing Engine (The Money)

> Convert metered usage into charges and automate the deduction cycle.

### BillingContract (Full Definition)

Each company has one active `BillingContract` that controls everything:

| Field | Type | Description |
|-------|------|-------------|
| `enabled_features` | JSONB | Feature key → boolean (e.g., `{"analytics_dashboard": true}`) |
| `feature_prices` | JSONB | Per-feature monthly add-on prices in cents (e.g., `{"analytics_dashboard": 5000}`) |
| `included_allowance` | JSONB | Per-resource monthly limits (e.g., 200 orders, 500MB storage) |
| `unit_prices` | JSONB | Per-resource overage pricing (e.g., $0.10/additional order) |
| `soft_debt_threshold` | integer | Max negative balance before auto-suspend |
| `contract_type` | enum | `basic`, `enterprise`, `custom` |

#### Contract Examples

| Type | enabled_features | feature_prices (add-ons) | Allowances | Overage Pricing |
|------|-----------------|--------------------------|------------|-----------------|
| **Free Tier** | Core only (Tier 1) | Per-feature add-on prices apply | 200 orders, 500MB, 3 employees, 1 branch | $0.10/order, $0.01/MB |
| **Enterprise** | All features | Included (no add-on charges) | Unlimited orders, 50GB, unlimited employees | No overage — everything included |
| **Custom** | Per deal | Per deal | Per deal | Negotiated |

### Dual-Wallet System

Each company has two balance accounts. These are **credit balances** — they offset the month-end charge rather than being auto-deducted in real time:

| Balance | Source | Applied at Month End |
|---------|--------|----------------------|
| **`promo_balance`** | Promotional credits from Skycom (e.g., +$10 new company bonus) | Deducted FIRST from total charge |
| **`main_balance`** | Company deposits from past payments or overpayments | Deducted SECOND |

Every balance change is recorded in `BillingTransaction`:
- **Type**: `top_up`, `deduction`, `refund`, `promo_credit`
- **Amounts**: Before/after snapshots of both balances
- **Reference**: Links to the triggering event (order, invoice, top-up)
- **Description**: Human-readable explanation

### The Deduction Algorithm

When billing runs (month-end or on-demand):

```
1. total_charge = Σ(overage_units × unit_price) + Σ(enabled_feature_prices)
2. If total_charge == 0: done (within allowance)
3. Deduct from promo_balance first:
     if promo_balance >= total_charge:
         promo_balance -= total_charge; remaining = 0
     else:
         remaining = total_charge - promo_balance; promo_balance = 0
4. Deduct from main_balance second:
     if main_balance >= remaining:
         main_balance -= remaining; remaining = 0
     else:
         remaining -= main_balance; main_balance = 0
5. If remaining > 0:
     ┌─ [VISA card registered?]
     ├── Yes ► Auto-charge card
     │         ├── Success ► Done (overpayment → main_balance)
     │         └── Declined ► Retry daily for grace period
     │                       ├── Paid ► Done
     │                       └── Still failing ► Send QR
     └── No ► Send QR for bank transfer
              └── Company pays ► Done
6. Record BillingTransaction for audit
```

The `Σ(enabled_feature_prices)` component is what companies pay for **premium add-on features** (Tiers 2-4) they've enabled. The overage component is what they pay for **exceeding usage limits**. Both are summed together as the total charge, which is offset by credits (promo + main) and then collected via card auto-charge or QR bank transfer.

**Mid-cycle proration**: When a feature is enabled mid-cycle, its price is prorated by days remaining:

```
proration_factor = days_remaining_in_cycle / total_days_in_cycle
current_cycle_charge = feature_price × proration_factor
```

The prorated amount is recorded at enable time and included in the next billing run. From the following cycle onward, the full `feature_price` applies automatically.

### Auto-Suspend & Recovery

When billing runs and the wallet is insufficient to cover the charge:
1. **Invoice created as overdue**: `flag_unpaid!` sets `suspension_at` to the end of the current month (runway)
2. **QR fallback**: A QR code is generated for bank transfer — sent to the owner's email and displayed in-app
3. **If paid before `suspension_at`** → company remains active; overpayment credits go to `main_balance`
4. **If `suspension_at` passes unpaid** → `is_accessible?` returns false → `check_accessable` redirects all access-protected actions to `/billing`
5. **Recovery**: Owner tops up wallet → `after_update` callback triggers `auto_settle_unpaid_invoices` → invoice paid → `try_reactivate!` sets `lifecycle_status: :active`, clears `suspension_at`

---

## Phase 5: Monetization Funnel (The Onboarding & Growth)

> Guide new users from signup to paying usage, with clear guardrails and upgrade paths.

### Free-Tier Onboarding

Every new company starts with a **Free Tier** BillingContract:

| Setting | Value |
|---------|-------|
| `enabled_features` | Core only (Tier 1: pos_basic, inventory_basic, crm_basic, finance_basic) |
| Orders included | 200/month |
| Storage included | 500 MB |
| Employees included | 3 |
| Branches included | 1 |
| Overage pricing | Standard per-unit rates |
| Contract type | `basic` |

No credit card required. The free tier is not a trial — it's a permanent usage tier. The company simply pays for what they use beyond the included allowance.

### Usage Guardrails

As a company approaches resource limits, the UI provides progressive warnings:

| Threshold | Behavior |
|-----------|----------|
| **80% of allowance** | Subtle inline indicator: "187/200 orders used this month" |
| **95% of allowance** | Warning toast: "You've used 95% of your monthly order allowance. Overage charges apply beyond 200 orders." Upgrade CTA in sidebar. |
| **100% (overage begins)** | Banner appears: "Pay-for-use is now active for orders." |
| **Balance approaching threshold** | Warning toast + email: "Your wallet balance is low. Top up to avoid service restriction." |

### Top-Up Flow (Manual)

When a company needs to add funds:
1. Owner navigates to Billing → Top Up
2. Selects an amount ($10, $20, $50, $100, $500 or custom)
3. System provides payment instructions (bank transfer details)
4. Owner transfers the amount
5. Owner contacts support to confirm
6. Support credits `main_balance`
7. If company was `suspended`, auto-reactivates to `active` via `try_reactivate!`

### Feature Add-on Flow

Company owners can enable individual add-on features from the billing or settings page:
1. Billing → Feature Store shows each available add-on with its monthly price
2. Each add-on card displays: feature description, price, and dependency warnings
3. Enabling is instant — `BillingContract.enabled_features` updates immediately, feature gates open
4. Disabling hides/restricts features at next billing cycle — no proration or refund
5. Add-on charges appear as line items in the monthly deduction algorithm (`Σ(enabled_feature_prices)`)
6. **Mid-cycle enable** — first month is prorated by days remaining in the current billing cycle; full price applies from next cycle onward

---

## Phase 6: Enterprise & Scaling (The Expansion)

> Handle large accounts, platform growth, and the future pivot to pure usage-based pricing.

### 6A — Enterprise Contracts

Large accounts get custom `BillingContract` entries:
- **`enabled_features`**: All features set to `true`
- **Unlimited allowances** (orders: 999999999, storage: 999999 GB)
- **No overage charges** — everything included in the fixed fee
- **Custom support SLA** (dedicated account manager, priority support)

The billing engine handles these identically — same deduction algorithm, same wallet system. It simply never finds overage charges because allowances are effectively infinite.

### 6B — Scenario B: The Free Features Flip

This is the architectural flexibility that `BillingContract.enabled_features` provides. When you decide to make all features free:

**Step 1**: Update the default BillingContract template for new signups:
```json
{
  "enabled_features": {
    "pos_basic": true,
    "inventory_basic": true,
    "crm_basic": true,
    "finance_basic": true,
    "hrm_attendance": true,
    "inventory_advanced": true,
    "analytics_dashboard": true,
    "custom_roles": true,
    "open_api": true
  },
  "included_allowance": { "orders": 200, "storage_mb": 500, "employees": 3, "branches": 1 },
  "unit_prices": { "orders": 1000, "storage_mb": 100 },
  "contract_type": "basic"
}
```

**Step 2**: Run a one-off migration to update existing companies' BillingContracts with the same `enabled_features` map.

**Step 3**: Remove paid tiers from the plans catalog (or keep them for historical accounts).

**Result**: The `Company#feature_enabled?(:analytics_dashboard)` check returns `true` for every company. Monetization shifts entirely to usage overage. Zero backend code changes.

### Tenant Growth

The meter-plus-bill architecture scales with the platform:

| Scale | Infrastructure |
|-------|----------------|
| **Up to 100 companies** | Single Redis instance, single DailyUsageLog table |
| **Up to 1,000 companies** | Partition DailyUsageLog by month, single Redis |
| **10,000+ companies** | Shard Redis by company_id range, archive old logs to cold storage |

No changes to billing contracts, feature gating, or deduction algorithms are needed at any scale — only the storage layer scales.

### Multi-Market Readiness

The billing engine is currency-aware and supports multiple markets:

| Market | Currency | Typical Price Range |
|--------|----------|-------------------|
| Vietnam | VND | Thousands to millions |
| United States | USD | Dollars to hundreds |
| Future markets | Local currency | Configurable per contract |

Contract allowances and feature access are universal; only the unit prices and feature add-on prices are localizable per market.

#### Country-Based Pricing Templates

When a company signs up, the system detects its market (via `country_code` on the company record) and applies the appropriate pricing template. Each market has its own set of default prices for features and overage:

| Market | Currency | `hrm_attendance` | `analytics_dashboard` | Overage: per order |
|--------|----------|-------------------|----------------------|--------------------|
| US | USD | $2/mo | $5/mo | $0.10 |
| VN | VND | 50,000/mo | 125,000/mo | 2,500 |

These templates live alongside the default contract configuration. When creating a `BillingContract` at signup, the country-specific `feature_prices` and `unit_prices` are populated from the matching template. Prices can still be overridden per-company for promotions or custom negotiated deals.

---

## Appendix: Feature Key Reference

Every feature in Skycom has a unique key used for gating, billing, and documentation:

| Key | Tier | Type | Default in Free Tier | Description |
|-----|------|------|---------------------|-------------|
| `pos_basic` | 1 | Core feature | ✅ Enabled | Point of Sale & Invoicing |
| `inventory_basic` | 1 | Core feature | ✅ Enabled | Single-location inventory |
| `crm_basic` | 1 | Core feature | ✅ Enabled | Customer directory |
| `finance_basic` | 1 | Core feature | ✅ Enabled | Income & expense tracking |
| `hrm_attendance` | 2 | Advanced feature | ❌ Disabled | Time & attendance |
| `hrm_payroll_commissions` | 2 | Advanced feature | ❌ Disabled | Payroll & commissions |
| `inventory_advanced` | 2 | Advanced feature | ❌ Disabled | Multi-warehouse & supplier management |
| `crm_loyalty` | 2 | Advanced feature | ❌ Disabled | Loyalty & rewards program |
| `multi_branch` | 3 | Advanced feature | ❌ Disabled | Multi-branch management |
| `automation_engine` | 3 | Advanced feature | ❌ Disabled | Automated workflows |
| `analytics_dashboard` | 3 | Advanced feature | ❌ Disabled | Advanced analytics |
| `payment_gateways` | 3 | Advanced feature | ❌ Disabled | Integrated payment processing |
| `audit_logs` | 4 | Advanced feature | ❌ Disabled | Advanced auditing |
| `custom_roles` | 4 | Advanced feature | ❌ Disabled | Granular RBAC |
| `open_api` | 4 | Advanced feature | ❌ Disabled | Developer API |
| `sso_saml` | 4 | Advanced feature | ❌ Disabled | Single sign-on |

---

## Appendix: Pay-for-Use Architecture Reference

### Decoupled Dimensions

Skycom separates **access** from **usage billing**:

| Dimension | Controls | Field on BillingContract |
|-----------|----------|--------------------------|
| **What features you can use** | UI visibility + API access | `enabled_features` |
| **What you pay monthly** | Per-feature add-on prices for premium features | `feature_prices` |
| **What usage is included** | Free allowance before overage | `included_allowance` |
| **What overage costs** | Per-unit pricing | `unit_prices` |
| **What stops you** | Unpaid balance after grace period | `soft_debt_threshold` |

### Pay-for-Use Pure Model (The Flip)

When all features are free, the architecture simplifies:

```
total_bill = Σ(overage × unit_price) for all resources

remaining = apply_credits(total_bill, promo_balance, main_balance)
if remaining > 0:
    collect(remaining) via card or QR
```

No feature gates ever return `false`. Monetization is 100% consumption-based.

---

## How to Read This Roadmap

| Phase | What It Covers | Status |
|-------|----------------|--------|
| **Phase 0** | Features already built and working | ✅ Live |
| **Phase 1** | Infrastructure: circuit breaker, BillingContract, feature gating, subscription lifecycle | ⬜ Next |
| **Phase 2** | Business features organized into 4 tiers (core free + advanced paid) | 🔄 In progress |
| **Phase 3** | Metering: count every business action (Redis + DailyUsageLog) | ⬜ Future |
| **Phase 4** | Billing: contract pricing, wallets, deduction algorithms | ⬜ Future |
| **Phase 5** | Commercial: free tier, top-ups, plan upgrades | ⬜ Future |
| **Phase 6** | Enterprise: custom contracts, tenant growth, the Free Features Flip | ⬜ Future |

At any point you can ask: *"What features does company X have?"* → check `BillingContract.enabled_features`.  
*"How much do they owe?"* → metering × BillingContract overage + feature add-on prices.

---

*End of document*
