# Dashboard Redesign — Company Profile + Category-Grouped Charts

## Objective
Replace the existing hardcoded ApexCharts demo on the company dashboard with a live dashboard showing:
1. Full company profile details
2. 5 separate ApexCharts bar charts showing counts of Products, Stocks, Services, Orders, Employees grouped by category name

## Files Changed

### 1. `app/controllers/companies/dashboards_controller.rb`
Add `format.json` block to the `index` action returning company details + aggregated counts.

**Controller pattern** (follows the Shell-First convention):
```ruby
def index
  respond_to do |format|
    format.html { render html: "", layout: true }
    format.json do
      render json: {
        company: format_company(current_company),
        counts: {
          products:  count_by_category(current_company.products),
          stocks:    count_by_category(current_company.stocks),
          services:  count_by_category(current_company.services),
          orders:    count_by_category(current_company.orders),
          employees: count_by_category(current_company.employees)
        }
      }
    end
  end
end
```

**Two private helpers:**
- `format_company(company)` — `as_json(only: [...])` with owner info merged
- `count_by_category(scope)` — `scope.joins(:category).group("categories.name").count` returning `{ "Category Name" => count }`

### 2. `app/javascript/controllers/companies/dashboards/index_controller.js`
Full rewrite:

| Concern | Action |
|---------|--------|
| **Class name** | Fix from `Companies_Branches_EmployeesController` → `Companies_Dashboards_IndexController` |
| **Import** | Keep `ApexCharts` import, remove hardcoded data |
| **Targets** | `companyDetails` and `chartsContainer` targets alongside existing `chartContainer` |
| **connect()** | `fetchJson()` with `.json` suffix → store company + counts → poll for contentTarget → `renderContent()` + `renderCharts()` |
| **renderCharts()** | Loop over 5 resource types, create ApexCharts bar instances in each chart container |

**Layout structure (contentHTML)**
Company Profile Card with name, code, business type badge, status badge, address, phone, email, website, owner info, created date, currency, timezone.
Grid of 5 chart cards (3 cols on desktop): each card has title, total count badge, chart container div.

**Chart config per resource:**
```javascript
{
  series: [{ name: "Products", data: [12, 8, 15] }],
  chart: { height: 250, type: 'bar', toolbar: { show: false } },
  colors: ['#008FFB', '#00E396', '#FEB019', '#FF4560', '#775DD0', '#546E7A', '#26a69a', '#D10CE8'],
  plotOptions: { bar: { columnWidth: '45%', distributed: true } },
  dataLabels: { enabled: false },
  legend: { show: false },
  xaxis: { categories: ["Cosmetics", "Perfumes", "Skincare"], labels: { style: { colors: [...], fontSize: '11px' } } }
}
```

### 3. `app/policies/companies/dashboards_policy.rb`
No changes needed — `index?` returning `true` is sufficient since this is the only action.

## Data Flow
```
User visits /companies/:id/dashboards
  → Rails returns empty HTML shell + layout
  → Stimulus Companies_Dashboards_IndexController connects
  → fetchJson(`/companies/:id/dashboards.json`)
  → Server runs: 5 SQL GROUP BY queries (products, stocks, services, orders, employees)
  → Returns JSON: { company: {...}, counts: { products: {...}, stocks: {...}, ... } }
  → Frontend renders company card + 5 ApexCharts
```

## SQL Queries
Each count is a single query:
```sql
SELECT categories.name, COUNT(*) FROM products
JOIN categories ON categories.id = products.category_id
WHERE products.company_id = '<company_id>'
GROUP BY categories.name
```
No N+1 — each resource is one `joins(:category).group(...)` call.

## Edge Cases
- **No categories exist** → charts show empty state ("No data")
- **Category has 0 records** → category won't appear in the count hash (GROUP BY excludes zeros). Charts simply won't have that bar.
- **Company has no records in a resource** → empty chart with "No data" message
- **Cache not loaded yet** → `poll()` pattern ensures render waits for layout

## Considerations
- ApexCharts is already pinned in `config/importmap.rb` at `#5.3.6` — no new dependencies
- The dashboard controller stays thin (delegates to `format_company` and `count_by_category` helpers)
- No new models, routes, or services needed
