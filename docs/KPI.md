# Employee KPI

## 1. Scope

KPI v1 measures **paid orders per salesperson**. It is a visibility tool:

- No result snapshots, reviews, bonuses, or payroll link.
- Scores are computed on demand for any date range.
- Adding another resource later (tasks, projects, attendance) is a new metric
  class, not a new domain.

## 2. Attribution

`orders.salesperson_id` points at `employees.id`. One order has at most one
salesperson — there is no split-credit table.

- POS checkout (`OrderProcessingV1::CreateOrderService`) sets the salesperson
  from `current_employee`.
- The web order form exposes a salesperson picker, defaulted to the signed-in
  employee (`OrdersController#new` returns `employees`).
- Historical orders stay `NULL` and appear as **unattributed** on the
  Performance page. They are excluded from employee scores, so a low score
  caused by missing attribution is visible instead of silent.

A salesperson from another company is rejected by
`Order#salesperson_belongs_to_company`.

## 3. Tables

### `kpi_configs`

One row is one rule: metric + target + weight + period + optional scope.

| Column | Meaning |
|---|---|
| `company_id` | Tenant owner |
| `name`, `description` | Display copy |
| `metric_key` | Registry key (`orders_count`, `orders_revenue_cents`) |
| `direction` | `higher_better` / `lower_better` |
| `period_type` | `month` / `quarter` / `year` (default view) |
| `target_value` | Nullable; null = show the number without scoring |
| `weight` | Composite weight (default `1`) |
| `category_id`, `branch_id`, `department_id`, `role_id` | Optional scope; all blank = every employee |
| System fields | `lifecycle_status`, `workflow_status`, `business_type`, `expiration_date`, `metadata`, `discarded_at`, `permission_resource_name` |

`KpiConfig#applies_to?(employee)` requires every configured scope to match.
`KpiConfig.active` = `workflow_status: active` + `discarded_at: nil`.

## 4. Metric registry

`Kpi::Metrics` (`app/services/kpi/metrics.rb`) is the extension point. A metric
is a class exposing:

```ruby
def self.key   = "orders_count"
def self.label = "Orders sold"
def self.unit  = "count" # or "currency_cents"
def self.call(company:, employee_ids:, from:, to:) = { employee_id => value }
```

Adding a metric:

1. Add the class under `app/services/kpi/metrics/`.
2. Add its key to `Kpi::Metrics::METRIC_KEYS`.
3. Add the label to `dictionary.js`.

No arbitrary SQL or user-authored formulas are stored in the database. Manual
or external metrics would be added as another metric class that reads a stored
value; the registry stays the whitelist.

### V1 metrics

| Key | Unit | Source |
|---|---|---|
| `orders_count` | count | Paid, non-discarded orders grouped by `salesperson_id` |
| `orders_revenue_cents` | currency_cents | `Analytics::RevenueCalculator` over the same orders |

Both use `created_at` inside the selected range, matching the dashboard's
revenue window.

## 5. Scoring

Per rule:

```
achievement = actual / target            (higher_better)
achievement = target / actual            (lower_better; actual 0 = 100%)
```

- Uncapped, rounded to one decimal — overachievement stays visible.
- Null target → row shown, `achievement_pct` null, excluded from the composite.
- Composite = weighted average of scored rows, `sum(achievement × weight) / sum(weight)`.
- No scored rows → composite null.

`Kpi::Scoring` owns this math so the scorecard and leaderboard cannot drift.

## 6. Periods

`Kpi::PeriodRange` resolves `period`, `from`, `to`:

| Key | Window |
|---|---|
| `this_month` | Current month (default) |
| `last_month` | Previous month |
| `this_quarter` | Current quarter |
| `last_quarter` | Previous quarter |
| `this_year` | Current year |
| `custom` | `from` / `to` dates (inclusive) |

Invalid or incomplete input falls back to `this_month`.

## 7. Services

| Service | Purpose |
|---|---|
| `Kpi::ScorecardService.call(company:, employee:, from:, to:)` | One employee: rows + composite |
| `Kpi::LeaderboardService.call(company:, from:, to:)` | All employees, one grouped pass per metric + unattributed totals |
| `Kpi::Scoring` | Row shape, achievement, composite |
| `Kpi::PeriodRange` | Preset/custom windows |

`LeaderboardService` also reports `unattributed: { orders_count, revenue_cents }`
for paid orders without a salesperson.

## 8. Permissions (ABAC)

KpiConfig is a normal ABAC resource:

- **Owner** bypasses checks (`Employee#can?`).
- **Manager** role has `KpiConfig` read seeded by the retail/hotel/hospital
  init services.
- Every other role has no access until the company grants it on the
  Permissions page.
- Manager is **read-only**: create/update/delete require the matching policy.

Policies:

| Controller | Policy | Check |
|---|---|---|
| `Companies::KpiConfigsController` | `Companies::KpiConfigsPolicy` | read/create/update/delete on `KpiConfig` |
| `Companies::PerformanceController` | `Companies::PerformancePolicy` | read on `KpiConfig` |

New companies get the policies from `Company::DEFAULT_RESOURCE_NAMES` plus the
Manager appointment in their init service. The project is not released yet, so
there is no backfill path: re-seed the dev/test company to pick up the policies.

## 9. Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/companies/:company_id/kpi_configs(.json)` | Config list + metric/scope options + `can_manage` |
| POST | `/companies/:company_id/kpi_configs` | Create |
| PATCH | `/companies/:company_id/kpi_configs/:id` | Update |
| DELETE | `/companies/:company_id/kpi_configs/:id` | Delete |
| GET | `/companies/:company_id/performance(.json)?period&from&to` | Leaderboard |
| GET | `/companies/:company_id/performance/:id(.json)?period&from&to` | Employee scorecard |

Errors always use `{ errors: [...] }` (`docs/API_ERROR_FORMAT.md`).

## 10. Frontend

| Surface | Stimulus controller |
|---|---|
| KPI settings (modal CRUD) | `Companies_KpiConfigs_IndexController` + new/edit modals |
| Performance leaderboard | `Companies_Performance_IndexController` |
| Employee scorecard | `Companies_Performance_ShowController` |

- Sidebar: **Organization → Performance**.
- KPI Settings is linked from the Performance header only when `can_manage`.
- Revenue targets are entered in major units and converted to cents on submit.
- Currency units are formatted with `Helpers.formatMoney`.

## 11. Out of scope (v1)

Task/project/attendance metrics, per-employee target overrides, frozen score
snapshots, review workflows, bonus/commission/payroll integration, employee
self-view, CSV export, and arbitrary formula/SQL authoring.

## 12. Tests

- Feature: `spec/features/companies/performance/index_spec.rb`,
  `show_spec.rb`, `spec/features/companies/kpi_configs/index_spec.rb`,
  `spec/features/companies/orders/salesperson_spec.rb`
- Model: `spec/models/kpi_config_spec.rb`, `spec/models/order_spec.rb`
- Services: `spec/services/kpi/**`
- Request: `spec/requests/companies/kpi_configs_controller_spec.rb`,
  `performance_controller_spec.rb`, `orders_salesperson_spec.rb`

Run `bundle exec parallel_rspec -n 14` in feature → model → request order
(`docs/TEST_PRIORITY.md`).
