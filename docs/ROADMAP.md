# Skycom Platform Roadmap: Feature-Tier Growth Model

This roadmap organizes Skycom's capabilities into four progressive feature tiers. Each tier unlocks new functionality as a company grows — from a solo shop to a multi-branch enterprise. Features are stored as an array of objects in the `features` JSONB column on the `Company` record, enabling programmatic gating of UI and backend behavior.

---

## Feature Object Schema

Each feature in the `features` array:

```json
{
  "key": "pos_basic",
  "enabled": true
}
```

---

## Tier 1: The Solo Shop (Essential Core)

**Turned on by default for every new company.** Lightweight, fast, and simple — covers the essentials of running a single-location business.

### `pos_basic` — Basic Point of Sale & Invoicing
Quick checkout flow, cash/transfer payment tracking, digital receipt generation, and basic invoice creation. Covers the full order lifecycle from cart creation through payment confirmation.

**Dependencies:** None

**Disabled behavior:** All cart, checkout, invoice, and payment UIs are hidden. No orders can be created.

---

### `inventory_basic` — Single-Location Inventory
Basic product catalog with categories and dynamic property fields. Stock counts, low-stock alerts, simple stock imports/exports, and stock write-offs. Barcode/SKU tracking for physical goods.

**Dependencies:** None

**Disabled behavior:** Products, stocks, stock transfers, stock imports/exports menus are hidden.

---

### `crm_basic` — Customer Directory
Simple customer profile management — capture name, phone, birthday, and contact info. Purchase history view. Basic customer group segmentation.

**Dependencies:** None

**Disabled behavior:** Customers menu and customer-related appointment UIs are hidden.

---

### `finance_basic` — Income & Expense Tracking
Basic cash flow tracking, daily sales summaries, manual expense logging, and invoice history. Single-currency support with configurable timezone.

**Dependencies:** `pos_basic` (for income data)

**Disabled behavior:** Financial reports, invoice history dashboards are hidden.

---

## Tier 2: The Growing Team (Operations & Teamwork)

Unlocked when a store hires its first employees and expands operations.

### `hrm_attendance` — Time & Attendance
Employee clock-in/out tracking, shift logs, attendance summaries (daily/monthly), and location/IP verification for branch presence. Shift definition and scheduling.

**Dependencies:** None

**Disabled behavior:** Shifts, attendance logs, attendance days/months UIs are hidden. Clock-in/out buttons are removed.

---

### `hrm_payroll_commissions` — Payroll & Sales Commissions
Base salary components in employee metadata. Commission engine that ties order processing to employee IDs for performance bonuses and service commissions (e.g., 5% per treatment session). Leave management workflows.

**Dependencies:** `hrm_attendance`, `pos_basic`

**Disabled behavior:** Payroll config, commission rules, leave request UIs are hidden.

---

### `inventory_advanced` — Multi-Warehouse & Supplier Management
Stock transfers between rooms/warehouses, supplier purchase orders (POs), bin location tracking, Cost of Goods Sold (COGS) calculation, batch/expiry management for sensitive products.

**Dependencies:** `inventory_basic`

**Disabled behavior:** Stock transfer, supplier management, purchase order, batch tracking UIs are hidden.

---

### `crm_loyalty` — Loyalty & Rewards Program
Store credits, points multipliers, automated customer tiering (Gold, Platinum, etc.). Reward catalog linking points to free products or service discounts. Wishlist and saved-items tracking.

**Dependencies:** `crm_basic`, `pos_basic`

**Disabled behavior:** Loyalty points display, reward redemption, tier badges on customer profiles are hidden.

---

## Tier 3: The Multi-Branch Retailer (Scale & Control)

For businesses managing multiple physical storefronts or high-volume operations.

### `multi_branch` — Multi-Branch Management
Isolates data views by branch while keeping global financial visibility for the owner. Branch-specific operating hours, warehouse assignments, and staff rosters.

**Dependencies:** `inventory_advanced`

**Disabled behavior:** Branch switcher in header is hidden. Company operates as single-branch only.

---

### `automation_engine` — Automated Workflows
Webhooks or background jobs that trigger actions (e.g., "When stock drops below threshold, auto-generate a Purchase Order draft to Supplier X"). Automated customer reminders (Zalo/Email 2 hours before service). Post-service follow-up scheduling.

**Dependencies:** `inventory_advanced`, `crm_basic`

**Disabled behavior:** Automation rules UI, webhook configuration are hidden.

---

### `analytics_dashboard` — Advanced Analytics & Reporting
Profit-margin deep dives, predictive inventory velocity, shift-efficiency reports, staff performance (service ratings, booking volume per doctor), customer lifetime value (CLV), financial reporting per branch, inventory turnover analysis.

**Dependencies:** `multi_branch` or `inventory_advanced`

**Disabled behavior:** Analytics tabs, report generation buttons are hidden.

---

### `payment_gateways` — Integrated Payment Processing
Native integrations with hardware card terminals, payment gateways (MoMo, ZaloPay, VNPay), automated QR code generation, multi-currency support, refund workflow to original payment source.

**Dependencies:** `pos_basic`

**Disabled behavior:** Payment gateway configuration, non-cash payment options in POS are hidden.

---

## Tier 4: The Enterprise (Compliance, Security & Customization)

For multi-million-dollar operations requiring strict governance, heavy auditing, and custom integrations.

### `audit_logs` — Advanced Auditing
Tamper-evident log of every resource modification, permission change, or financial edit. PaperTrail version history. Track who changed a product price, stock count, or employee role.

**Dependencies:** None

**Disabled behavior:** Audit log viewer, version history tabs are hidden.

---

### `custom_roles` — Granular RBAC
Beyond basic Admin/Manager/Staff roles — allows enterprise IT teams to build completely custom permission matrices using the ABAC system. Custom policy creation, role-to-policy assignment UI, workflow status toggling for permissions.

**Dependencies:** None

**Disabled behavior:** Custom role editor, policy builder UI are hidden. Falls back to the default fixed role set.

---

### `open_api` — Developer API & Access Tokens
Public API endpoints for internal IT teams to integrate Skycom with legacy systems or ERPs. API access token management, rate limits, webhook event types configuration.

**Dependencies:** `audit_logs`

**Disabled behavior:** API tokens section in settings, API documentation links are hidden.

---

### `sso_saml` — Single Sign-On
Centralized login control via Okta, Azure AD, or Google Workspace for enterprise employees. SAML/SSO configuration UI, identity provider management, automatic user provisioning.

**Dependencies:** `custom_roles`

**Disabled behavior:** SSO settings page, identity provider configuration are hidden.

---

## Feature Dependency Graph

```
Tier 1 (Default)
├── pos_basic
├── inventory_basic
├── crm_basic
└── finance_basic → pos_basic

Tier 2
├── hrm_attendance
├── hrm_payroll_commissions → hrm_attendance + pos_basic
├── inventory_advanced → inventory_basic
└── crm_loyalty → crm_basic + pos_basic

Tier 3
├── multi_branch → inventory_advanced
├── automation_engine → inventory_advanced + crm_basic
├── analytics_dashboard → multi_branch | inventory_advanced
└── payment_gateways → pos_basic

Tier 4
├── audit_logs
├── custom_roles
├── open_api → audit_logs
└── sso_saml → custom_roles
```

---

## Gating Strategy

| Layer | Mechanism |
|-------|-----------|
| **Backend (Ruby)** | `Company#feature_enabled?(:pos_basic)` — gate controllers, services, and model callbacks |
| **Frontend (JS)** | `currentFeatures()` from client cache — conditionally render sidebar items, buttons, and tabs |
| **API (JSON)** | Feature presence in `/client_cache` response — frontend reads and reacts |
| **Seed** | Default features assigned at company creation in `setup_owner_records` |

---

*End of document*
