# Skycom Billing Dashboard

## 1. Purpose

The Billing Dashboard is a self-service portal for company owners to view billing status, monitor usage against allowances, and pay outstanding invoices. It is accessible even when the company's access is blocked (`is_accessible?` returns false), so blocked companies can still view their billing information and pay to restore service.

## 2. Route & Access

**Route**: `GET /companies/:company_id/billing`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/companies/:id/billing` | GET | Returns billing dashboard JSON |
| `/companies/:id/billing.json` | GET | Same as above (JSON format) |
| `/companies/:id/billing/pay_all` | POST | Settles all outstanding invoices |

**Access**: Both endpoints are exempt from the `check_accessable` before_action (`skip_before_action :check_accessable`), so suspended/past-due companies can still reach the billing portal.

**Route config** (`config/routes.rb:58`):
```ruby
resource :billing, only: :show, controller: :billing do
  post :pay_all, on: :collection
end
```

All routes are nested inside `resources :companies`.

---

## 3. Architecture

```
Browser                          Server
  │                                │
  ├─ GET /companies/:id/billing.json
  │                                ├─ billing_show_json
  │                                │   ├─ Load Company, BillingContract
  │                                │   ├─ Compute wallet balances
  │                                │   ├─ Compute usage totals + projections
  │                                │   ├─ Load catalog addon features
  │                                │   ├─ Load outstanding invoices
  │                                │   └─ Return JSON response
  │                                │
  │  ◄── JSON response ────────────┘
  │
  ├─ ShowController.connect()
  │   ├─ Store currency, company, wallet, invoices, metrics, features
  │   ├─ renderContent() → Shell-First HTML
  │   └─ renderCharts() → ApexCharts (usage bar + cost donut)
  │
  │  (user clicks "Pay All")
  │
  ├─ POST /companies/:id/billing/pay_all
  │                                ├─ SettlementService.settle_all
  │                                │   ├─ Deduct from promo_balance first
  │                                │   ├─ Deduct from main_balance second
  │                                │   ├─ Mark invoices paid/overdue
  │                                │   └─ try_reactivate! if all paid
  │                                └─ Return { paid_count, remaining_cents }
  │
  │  ◄── Re-fetch /billing.json ────┘
  │  ├─ Re-render all sections
  │  └─ Re-render charts
```

---

## 4. JSON Response

**File**: `app/controllers/companies/billing_controller.rb` — `billing_show_json`

### Response Structure

```json
{
  "currency": "USD",

  "company": {
    "id": "uuid",
    "name": "Grocery 1",
    "lifecycle_status": "active",
    "suspension_at": null,
    "is_accessible": true
  },

  "billing_contract": {
    "contract_type": "basic",
    "included_allowance": {
      "orders": 200,
      "storage_mb": 500
    },
    "unit_prices": {
      "orders": 10,
      "storage_mb": 1
    },
    "feature_prices": {
      "analytics_dashboard": 500
    }
  },

  "wallet": {
    "main_balance_cents": 0,
    "promo_balance_cents": 1000,
    "total_cents": 1000,
    "currency": "USD"
  },

  "invoices": [
    {
      "id": "uuid",
      "invoice_number": "INV-202606-A1B2C3",
      "price_cents": 1500,
      "price_currency": "USD",
      "payment_status": "unpaid",
      "created_at": "2026-06-25T..."
    }
  ],

  "daily_metric_totals": {
    "orders": {
      "current": 145,
      "allowance": 200,
      "usage_pct": 72.5,
      "projected": 310,
      "overage_cents": 0,
      "projected_overage_cents": 1100,
      "unit_price_cents": 10,
      "display_unit": null
    },
    "api_calls": {
      "current": 8200,
      "allowance": 10000,
      "usage_pct": 82.0,
      "projected": 17500,
      "overage_cents": 0,
      "projected_overage_cents": 0,
      "unit_price_cents": 0,
      "display_unit": "x1000"
    }
  },

  "catalog_addon_features": [
    {
      "key": "analytics_dashboard",
      "name": "Advanced analytics and reporting",
      "monthly_price_cents": 500,
      "currency": "USD",
      "active": true,
      "active_days": 25
    }
  ],

  "estimate": {
    "total_cents": 500,
    "days_remaining": 5,
    "breakdown": {
      "features_cents": 500,
      "overage_cents": 0,
      "base_cents": 0
    }
  }
}
```

### Field Reference

| Top-level Key | Source | Description |
|---------------|--------|-------------|
| `currency` | `company.currency_code.to_s.upcase` | Company's currency (e.g., "USD", "VND") |
| `company` | Company record | Lifecycle status, suspension, accessibility |
| `billing_contract` | Active BillingContract | Allowances, unit prices, feature prices |
| `wallet` | Company balance columns | Main/promo balances with currency |
| `invoices` | BillingInvoice (unpaid/overdue) | Outstanding invoices sorted by creation date |
| `daily_metric_totals` | DailyMetricLog | Per-metric usage vs allowance with projections |
| `catalog_addon_features` | BillingResource (addon_feature) | All available add-on features for the company's country |
| `estimate` | Computed from contract data | Estimated total cost with breakdown |

### Per-Metric Fields (`daily_metric_totals`)

| Field | Description |
|-------|-------------|
| `current` | Total usage for the current month so far |
| `allowance` | Free allowance included in the contract |
| `usage_pct` | `(current / allowance) * 100` |
| `projected` | Linear projection to end of month |
| `overage_cents` | Cost of usage exceeding allowance |
| `projected_overage_cents` | Projected overage cost at EOM |
| `unit_price_cents` | Price per unit of overage |
| `display_unit` | `"x1000"` for api_calls, null otherwise |

---

## 5. Backend Implementation

**File**: `app/controllers/companies/billing_controller.rb`

### skip_before_action

The controller skips `check_accessable` so that suspended/past-due companies can still reach the billing portal. Without this, blocked companies would be redirected away from the only page that lets them pay.

### billing_show_json

The `show` action is Shell-First — it renders an empty HTML shell for the Stimulus controller and serves JSON via `billing_show_json`.

Key computations in `billing_show_json`:

- **Days elapsed/remaining**: Computed from `Time.current.beginning_of_month` and `Time.current.end_of_month`
- **Usage projection**: `(current / days_elapsed) * total_days` — linear projection to end of month
- **Overage**: `max(current - allowance, 0) * unit_price_cents`
- **Estimate**: Sum of feature flat prices + overage costs
- **Catalog features**: Scoped to `(country_code: company.country_code)` so VN companies see VND-priced features

### pay_all

Delegates to `SettlementService.settle_all` which deducts from promo balance first, then main balance. Returns `paid_count` and `remaining_cents`. After settlement, re-fetches `/billing.json` on the frontend side.

---

## 6. Frontend Implementation

**File**: `app/javascript/controllers/companies/billing/show_controller.js`
**Class**: `Companies_Billing_ShowController`
**Extends**: `Companies_LayoutController`

### Targets

| Target | Element | Purpose |
|--------|---------|---------|
| `usageChart` | `<div>` | ApexCharts bar chart container |
| `costChart` | `<div>` | ApexCharts donut chart container |

### Controller Properties

| Property | Type | Source |
|----------|------|--------|
| `currency` | string | `response.currency` (defaults to "USD") |
| `company` | object | `response.company` |
| `billingContract` | object | `response.billing_contract` |
| `wallet` | object | `response.wallet` |
| `invoices` | array | `response.invoices` |
| `dailyMetricTotals` | object | `response.daily_metric_totals` |
| `catalogAddonFeatures` | array | `response.catalog_addon_features` (sorted) |
| `estimate` | object | `response.estimate` |

### Lifecycle

1. **`connect()`** — Fetches `/companies/:id/billing.json`, stores all properties, polls for `contentTarget`, renders HTML + charts
2. **`renderContent()`** — Calls `this.element.innerHTML = this.contentHTML()`
3. **`renderCharts()`** — Calls `renderUsageChart()` and `renderCostChart()` after a 100ms delay (to ensure DOM is ready)

---

## 7. Dashboard Sections

The dashboard renders 7 sections:

### 7.1 Summary Cards (Top Row)

Three cards in a 3-column grid:

**Billing Status**
- Lifecycle badge (active/past_due/disabled)
- Contract type (basic/enterprise)
- Suspended warning banner (when `is_accessible` is false)

**Wallet Balance**
- Total balance in currency-aware format
- Main and promo balances broken out

**This Month Estimate**
- Estimated total cost for the current billing period
- Days remaining count

### 7.2 Usage vs Allowance Chart

ApexCharts bar chart comparing current usage (blue) against allowance (gray) for all metered resources. Spans 2/3 of the row.

### 7.3 Cost Breakdown Chart

ApexCharts donut chart breaking down costs into Base Plan, Add-ons, and Overage. Tooltips and total use currency-aware `formatCents`.

### 7.4 Usage Metrics Table

Full-width table with 7 columns per metric:

| Column | Description |
|--------|-------------|
| Metric | Resource name (humanized) |
| Current | Usage so far this month |
| Allowance | Free allowance limit |
| Unit Price | Overage unit price (currency-aware) |
| Current Cost | Overage cost so far (currency-aware) |
| Usage | Progress bar with percentage |
| Projected EOM | Linear projection to month end |

Progress bar color thresholds:
- `< 80%` — emerald (green)
- `80-99%` — amber (yellow)
- `>= 100%` — red

API calls use `display_unit: "x1000"` — values are displayed divided by 1000, labels show "(x1000)".

### 7.5 Add-on Features Catalog

Two-column section with a table of available add-on features:

| Column | Description |
|--------|-------------|
| Add-on Feature | Feature name/description |
| Price/mo | Monthly flat price (currency-aware) |
| Status | Enabled/Disabled badge |
| Active Days | Days active this month |

Features are sourced from `BillingResource.addon_feature.where(country_code: company.country_code)` — so VN companies see VND-priced features and US companies see USD-priced features.

### 7.6 Outstanding Invoices + Pay All

Right column showing up to 5 unpaid/overdue invoices with their amounts. A "Pay All Outstanding" button at the bottom triggers `payAll()`.

When no invoices are outstanding, shows a green checkmark with "All invoices paid".

---

## 8. Currency-Aware Display

**Method**: `formatCents(cents)` at `show_controller.js:193`

The display adapts to `this.currency` which is set from `response.currency`:

| Currency | Format | Example |
|----------|--------|---------|
| `USD` | `$X,XXX.XX` | `$22.39` |
| `VND` | `X,XXX₫` | `2,155₫` |

- **USD**: Divides by 100 (cents → dollars), 2 decimal places, `$` prefix
- **VND**: Displays raw amount, no decimals, `vi-VN` locale for thousand separators, `₫` suffix

This applies to all monetary displays: wallet balances, invoice amounts, unit prices, overage costs, estimate totals, and feature prices.

### Adding a New Currency

To add a new currency (e.g., EUR), add a branch to `formatCents` in `show_controller.js`:

```javascript
if (currency === "EUR") {
  return `${Number(cents / 100).toLocaleString("de-DE", { minimumFractionDigits: 2 })}€`
}
```

---

## 9. Pay All Flow

1. User clicks "Pay All Outstanding" button
2. `payAll(event)` POSTs to `/companies/:id/billing/pay_all`
3. Backend calls `SettlementService.settle_all(current_company)`:
   - Deducts from promo balance first, then main balance
   - Marks invoices as `paid` or `overdue`
   - Calls `try_reactivate!` if all invoices paid
4. Frontend re-fetches `/companies/:id/billing.json`
5. All controller properties are updated
6. `renderContent()` and `renderCharts()` re-render the dashboard

---

## 10. File Reference

| File | Lines | Purpose |
|------|-------|---------|
| `app/controllers/companies/billing_controller.rb` | 186 | Backend: JSON API + pay_all action |
| `app/javascript/controllers/companies/billing/show_controller.rb` | 414 | Frontend: Stimulus controller, rendering, charts |
| `config/routes.rb` | 58-60 | Route definition (nested under companies) |
| `docs/BILLING.md` | 498 | Backend billing system (contracts, metering, settlement) |

---

## 11. Key Models Referenced

| Model | Role in Dashboard |
|-------|-------------------|
| `BillingContract` | Source of allowances, unit prices, feature prices |
| `ContractMetric` | Links contract to volumetric resource with allowance + unit price |
| `ContractFeature` | Links contract to add-on feature with monthly flat price |
| `DailyMetricLog` | Current month usage counts per metric |
| `DailyFeatureLog` | Active day counts per feature |
| `BillingInvoice` | Invoice records with payment status |
| `BillingResource` | Catalog of all metered resources and add-on features per country |
| `Company` | Wallet balances, lifecycle status, suspension, currency |

---

*End of document*
