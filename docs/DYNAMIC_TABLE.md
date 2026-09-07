# Skycom Dynamic Table System

> **Prerequisites**: Read `CATEGORY_DYNAMIC_SCHEMA.md` for the PropertyMapping/TableConfig data model. Read `DASHBOARD_PATTERN.md` for the base dashboard architecture.
>
> This document covers only the dynamic column system — how `property_*` columns get their display names, how tables render them, and how modals generate form fields.

---

## 1. Data Flow

```
ProductsController#index
  └─ format_product() — emits all 60 property_* columns + category_id
        │
        ▼
  ClientCache (localStorage)
  ├─ categories[]         — available categories per resource_name
  ├─ property_mappings[]  — property_metadata (name, type per slot)
  └─ table_configs[]      — columns_metadata (visible columns, order, alignment)
        │
        ▼
  IndexController.connect()
  1. URL param or defaultFilterCategory() → category_id
  2. Resolve propertyMappingIdValue ← currentPropertyMappings().find(category_id match)
  3. Resolve tableConfigIdValue     ← currentTableConfigs().find(property_mapping_id match)
  4. fetchJson({ params: { category_id } }) → products[]
  5. Two-phase render: filter shell → data table
```

---

## 2. Index Controller — Three Resolutions

### 2.1 Category → PropertyMapping → TableConfig

```javascript
async connect() {
  super.connect()

  this.categoryIdValue = new URLSearchParams(window.location.search).get('category_id')
    || this.defaultFilterCategory()?.id

  // Resolve PropertyMapping from cache
  const propertyMapping = currentPropertyMappings().find(m => m.category_id === this.categoryIdValue)
  if (propertyMapping) this.propertyMappingIdValue = propertyMapping.id

  // Resolve TableConfig from cache (by property_mapping_id, not category_id)
  const tableConfig = currentTableConfigs().find(c => c.property_mapping_id === this.propertyMappingIdValue)
  if (tableConfig) this.tableConfigIdValue = tableConfig.id

  // Fetch data — the full page query string (category_id, q, filters[...]) is passed through:
  const urlParams = new URLSearchParams(window.location.search)
  if (!urlParams.get('category_id') && this.categoryIdValue) urlParams.set('category_id', this.categoryIdValue)
  const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)
  this.products = response.products || []

  // Two-phase render
  poll(() => {
    if (this.hasContentTarget) {
      this.renderContent()
      return true
    }
    return false
  })
}
```

**Key rules:**
- `propertyMappingIdValue` and `tableConfigIdValue` are **Stimulus values** set in `connect()` and read by the lifecycle helpers in `LayoutController`.
- TableConfigs are indexed by `property_mapping_id`, not `category_id` — always traverse through the PropertyMapping.
- `currentPropertyMappings()` and `currentTableConfigs()` read from `currentCompany().property_mappings` / `.table_configs` in the client cache.

### 2.2 Name Resolution

The `name` value from `TableConfig.columns_metadata[].name` is used directly as the table header display text. For `property_*` columns, the `name` in `columns_metadata` is validated to match the `name` in `PropertyMapping.property_metadata`, and the edit field is read-only — changes must be made via the PropertyMapping edit page.

```javascript
// In ui_helpers.js table() helper:
<th>${col.name || "N/A"}</th>
```

| Column Type | Source |
|-------------|--------|
| `property_*` (dynamic) | `TableConfig.columns_metadata[].name` (synced from PropertyMapping) |
| Standard (name, code, workflow_status) | `TableConfig.columns_metadata[].name` |

### 2.3 Type-Aware Cell Rendering

`renderCellContent(product, col, mappedField)` renders cells based on `mappedField.type`:

| Type | Rendering |
|------|-----------|
| `boolean` | Badge — `Yes` (emerald) / `No` (slate) |
| `integer` | Locale-formatted number (`1,234`) |
| `decimal` | 2 decimal places, blue (`1,234.00`) |
| `string` / default | Raw value, or `—` for null |
| `name` key | Icon + name layout |
| `code` key | Monospace badge |
| `workflow_status` key | `Helpers.statusBadge()` |

### 2.4 Page-Navigation Category Switch

Category filter uses a `<form method="get">` with the Search button for full page navigation:

```javascript
<form method="get" action="${pathname()}">
  <select name="category_id">
    ${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
  </select>
  <button type="submit">Search</button>
</form>
```

The `<select>` has no JS change handler — changing the category requires clicking "Search" to navigate to `?category_id=X` (full page reload).

### 2.5 Dynamic Search & Filter (Column Settings)

Each `columns_metadata[]` entry may additionally carry two optional keys (absent = disabled,
backward compatible):

| Key | Type | Allowed on | Meaning |
|-----|------|-----------|---------|
| `search` | Boolean | `name` / `description` / `code` / `property_string_*` | Column participates in the index page keyword search box |
| `filter` | Hash | `property_integer_*` / `property_decimal_*` / `property_boolean_*` / `property_datetime_*` | Column renders a filter dropdown on the index page |

`filter` shape by column type (validated in `TableConfig` — `active` is **required** and gates
everything: the filter only renders/applies while `"active": true`):

```jsonc
// integer / decimal — half-open buckets [from, to), null = open side
{ "type": "range", "active": true, "buckets": [[null, 100], [100, 500], [500, null]] }
// integer with PropertyMapping input_type=select — options render from PM options[]
{ "type": "enum", "active": true }
// boolean — dropdown labels; yes_no wins if both true
{ "type": "boolean", "active": true, "true_false": true, "yes_no": false }
// datetime — year buckets, half-open ([2024, 2025] == the year 2024)
{ "type": "date", "active": true, "buckets": [[null, 2024], [2024, 2025], [2025, null]] }
```

**Editor** (`companies/table_configs/edit_controller.js`): per-row **Search** checkbox
(disabled for non-string keys) + **Filter** cell = **Active checkbox** (writes `filter.active`,
legacy configs without the key render as checked) above a **JSON textarea** (type-aware
skeleton as placeholder). The textarea submits raw JSON text; `TableConfigsController#normalize_column_types`
parses it back to a hash and merges the checkbox as `active` (checkbox always wins; submissions
without the checkbox key backfill `active: true` — legacy-safe). Invalid JSON stays a string →
model validation rejects the save → flash alert. API/JSON writes must include `active` explicitly.

**Index page (Products + Customers today):** the search input (always the **first** control in the filter
row, before the Category select) + one `<select>` per filter column render inside
the existing GET form via the shared helpers `dynamicSearchHTML` / `dynamicFiltersHTML` (`ui_helpers.js`).
Option values encode buckets as `min:max` (`:100`, `100:500`, `500:`,
years likewise); booleans `true|false`; enums the PM option value. Keys travel on the wire
(`filters[property_integer_1]=:100`); display names are render-time only. BE execution:
per-resource `X::SearchQueryService` subclasses of `DynamicSearch::BaseQueryService` whitelist params
against the TableConfig, build the Meilisearch filter string (always `company_id`-scoped), and return
ids fed into pagy via `in_order_of`. Disabled filters (`active: false`) are skipped on **both** sides —
no dropdown renders, no filter applies. Rolling the pattern out to another page: **§8**.
See `docs/MEILISEARCH.md` §4 and `docs/superpowers/specs/2026-09-06-dynamic-search-filter-design.md`.

**Seeding default:** `Seed::TableConfigService.field_hash` turns ON every applicable option
(`search: true` for string-capable columns; active `range`/`boolean`/`date` filters for
integer/decimal/boolean/datetime) — so every new company starts fully searchable/filterable and
owners dial it back per column. Enum filters stay off (no seeded `input_type=select` properties yet).

---

## 3. Category Filtering

### 3.1 No "All Categories"

Every product belongs to a category. Dynamic columns have no meaning without a category (`property_string_1` could mean anything). Therefore:
- **No "All Categories" option** in the `<select>`
- `selectOptionsHTML()` is called **without a default label** (3rd arg omitted)
- The first category from `productsCategories()` is the default

```javascript
const categoryFilter = this.productsCategories()  // filtered by resource_name === "products"
const categoryValue = this.categoryIdValue || this.defaultFilterCategory()?.id
```

### 3.2 Race Condition

`currentCategories()` returns `[]` if the cache hasn't loaded yet (`currentCompany()` returns null). `defaultFilterCategory()` safely returns `undefined`, and `undefined?.id` resolves to `undefined` → `fetchJson` skips the param. Once the cache loads, `connect()` re-runs via the two-phase render.

---

## 4. New Modal — Dynamic Property Fields

The `NewModalController` reads `PropertyMapping.property_metadata` and renders form fields per type:

```javascript
renderField({ key, name, type }) {
  switch (type) {
    case 'boolean':
      return `<input type="checkbox" name="product[${key}]" value="true">
              <input type="hidden" name="product[${key}]" value="false">`
    case 'integer':
    case 'decimal':
      return `<input type="number" name="product[${key}]" step="${type === 'decimal' ? '0.01' : '1'}">`
    case 'datetime':
      return `<input type="datetime-local" name="product[${key}]">`
    default:
      return `<input type="text" name="product[${key}]">`
  }
}
```

**Input naming**: Always `product[property_string_1]` (bracket notation for Rails Strong Params).

**Hidden category_id**: `<input type="hidden" name="product[category_id]" value="${this.categoryId}">` ensures the new product is assigned to the current category.

---

## 5. Show Modal — Dynamic Editable Properties

The `ShowModalController` renders dynamic property fields using `Helpers.editable()`:

```javascript
this.propertyMetadata.map(field => {
  const inputType = field.type === 'integer' || field.type === 'decimal' ? 'number'
    : field.type === 'datetime' ? 'datetime-local'
    : field.type === 'boolean' ? 'checkbox'
    : 'text'

  return Helpers.editable({
    dispatch: "updateProduct",
    resource: "product",
    name: field.key,
    id: p.id,
    value: p[field.key],
    url: Helpers.edit_company_product_path(currentCompany().id, p.id),
    type: inputType,
    html: this.formatDisplayValue(p[field.key], field.type),
    confirmMessage: `Change ${field.name} to '{{value}}'?`,
    successMessage: `${field.name} updated!`,
  })
})
```

**`formatDisplayValue(value, type)` renders the display-state based on type:**

| Type | Display |
|------|---------|
| `boolean` | Yes/No badge |
| `integer` | `Number(value).toLocaleString()` |
| `decimal` | `Number(value).toFixed(2)` |
| `datetime` | `new Date(value).toLocaleString()` |
| `null/undefined` | `—` (em dash) |
| default | Raw string |

---

## 6. Cache & Test Patterns

### 6.1 Why Cache Matters

The IndexController reads `currentPropertyMappings()` and `currentTableConfigs()` from the client cache (localStorage). If cache data is stale or missing, the table renders with fallback columns (name, code, status only).

### 6.2 Test Fixture Setup

```ruby
before do
  page.execute_script("localStorage.clear()")

  # CRITICAL: reset ActiveRecord associations before serializing to JSON.
  # Inner let! blocks execute after outer before hooks in RSpec, so
  # company.table_configs may be cached with only partial data.
  company_data = JSON.parse(company.to_json).merge(
    "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
    "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
    "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
    "branches" => [],
    "departments" => [],
    "roles" => []
  )

  page.execute_script("localStorage.setItem('client_cache_data', arguments[0])",
    { user: owner.as_json, companies: [ company_data ], enums: {}, employees: [] }.to_json)

  # Prevent ClientCacheController.sync() from overwriting localStorage
  page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
  page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
end
```

**Three critical steps:**
1. **`.reset`** — forces ActiveRecord to re-fetch from DB, bypassing the cached association set that was loaded before inner `let!` blocks ran
2. **`localStorage.clear()`** — removes stale data from previous tests
3. **Cookie version sync** — `client_cache_version` cookie must match the localStorage version, otherwise `ClientCacheController.sync()` fetches server data (which may have different test company data) and overwrites the manually-seeded cache

### 6.3 Dynamic Product Names

Avoid `Faker::Commerce.product_name` for products in the same company — `name` has a uniqueness validation scoped to `company_id`. Use deterministic names:

```ruby
let!(:products_cosmetics) do
  names = [ "Gorgeous Steel Plate", "Practical Wool Shoes" ]
  names.map do |nm|
    Product.new(company: company, name: nm, ...).tap { |p| p.save! }
  end
end
```

---

## 7. Adding a New Dynamic Table

To replicate this pattern for a new resource (e.g., `branches`):

### 7.1 Backend

1. **Controller** — include all `property_*` columns in `format_<resource>` and `permit` in `<resource>_params`:

```ruby
def format_branch(branch)
  branch.as_json(only: [ :id, :name, :category_id,
    :property_string_1, ..., :property_string_10,
    :property_integer_1, ..., :property_integer_20,
    # ... etc
  ]).merge(
    category: branch.category&.as_json(only: [ :id, :name ])
  )
end
```

2. **Routes** — standard RESTful resource under `Companies::` namespace.
3. **Seed** — add `METADATA_CATEGORIES` entries in the seed service with `properties` and `visible_columns`.

### 7.2 Frontend

1. **IndexController** — `extends Companies_LayoutController`, implement:
   - `connect()` with PM/TC resolution
   - `contentHTML()` with dynamic `visibleColumns.map()`
   - `renderCellContent()` with type-aware switch
   - Category filter via `<form method="get">` + Search button (page navigation)
   - `productsCategories()` / `defaultFilterCategory()` helpers

2. **NewModalController** — `extends Controller`, implement:
   - `renderField({ key, name, type })` for all 5 types
   - `handleSubmit()` with `fetchJson` + `reloadThenToast`

3. **ShowModalController** — `extends Controller`, implement:
   - `formatDisplayValue(value, type)` for all 5 types
   - Dynamic `Helpers.editable()` fields from `propertyMetadata`

4. **LayoutController** — register in sidebar navigation.

### 7.3 Tests

1. Seed categories + property_mappings + table_configs in `let!` blocks
2. Use `.reset` before serializing associations to JSON for cache seeding
3. Lock cookie version to prevent `ClientCacheController` overwrite
4. Use deterministic product names (no Faker)
5. Assert dynamic column headers by name (e.g., `have_selector('th', text: 'Skin Type')`)

---

## 8. Rolling Out Dynamic Search/Filter to Another Index Page

The engine is generic — `DynamicSearch::BaseQueryService` (BE) + `dynamicSearchHTML` /
`dynamicFiltersHTML` (FE, `ui_helpers.js`). **Products** and **Customers** are wired; any other
dynamic-table page adopts in 4 steps (~30 min incl. specs). Design context:
`docs/superpowers/specs/2026-09-06-dynamic-search-filter-design.md`.

**Step 0 — TableConfig: nothing to do.** The editor is resource-agnostic; per category/PM/TableConfig
the owner toggles Search/Filter for that resource's columns already (see §2.5).

**Step 1 — BE service subclass** (3 lines; `model` + `fallback_resource_name` only):

```ruby
# app/services/<resources>/search_query_service.rb
class Orders::SearchQueryService < DynamicSearch::BaseQueryService
  def self.model = Order
  def self.fallback_resource_name = "orders"
end
```

**Step 2 — controller index block** (paste into the `format.json` of `<X>sController#index`,
after the existing scope filters; replace class/ivar names):

```ruby
search = Orders::SearchQueryService.new(company: current_company, params: params)
if search.active?
  begin
    ids = search.record_ids
  rescue Meilisearch::Error => e
    Rails.logger.error("[Orders::SearchQueryService] #{e.message}")
    return render json: { errors: [ "Search is temporarily unavailable. Please try again." ] },
      status: :service_unavailable
  end
  scope = Order.where(id: ids).in_order_of(:id, ids)
end
```

Update the file-header `Serves Stimulus:` comment with the new param support (AGENTS.md rule).

**Step 3 — FE index controller** (2 edits, copy from `companies/customers/index_controller.js`):

```javascript
// connect(): replace the fetch so the whole query string (q, filters[...]) passes through
const urlParams = new URLSearchParams(window.location.search)
if (!urlParams.get('category_id') && this.categoryIdValue) urlParams.set('category_id', this.categoryIdValue)
const response = await fetchJson(`${pathname()}.json?${urlParams.toString()}`)

// contentHTML(): render from the raw config columns and inject into the existing GET form
const searchHTML = dynamicSearchHTML({ searchCols: rawColumns.filter(c => c.search === true), urlParams })
const filtersHTML = dynamicFiltersHTML({
  filterCols: rawColumns.filter(c => c.filter && typeof c.filter === "object" && c.filter.type && c.filter.active !== false),
  urlParams, mappingLookup
})
// ... inside the filter row: ${searchHTML} FIRST (before the Category select), then the
// existing Category/Branch selects, then ${filtersHTML} after them, then the Search button.
// The keyword input is the first control so it reads "search → narrow with dropdowns".
```

**Step 4 — specs:**

| Spec | Do |
|------|----|
| `spec/services/orders/search_query_service_spec.rb` | 10 lines: `it_behaves_like "dynamic search query service"` with `service_class` / `resource_name` / `index_class` / `record` lets (see customers version) |
| `spec/requests/companies/orders_controller_spec.rb` | DB-path unchanged without params; `?q=`; `?filters[...]`; 503 on `Meilisearch::Error` (stub) — template: `customers_controller_spec.rb` |
| `spec/features/companies/orders/search_filter_spec.rb` | config → input/dropdown render → q + bucket filter E2E — template: `customers/search_filter_spec.rb` |

Meilisearch fixtures: call `record.ms_index!(true)` explicitly (transactional tests suppress the
after_commit auto-sync) and `Model.ms_clear_index!` before/after — see `docs/MEILISEARCH.md` §6.

---

## 9. File Reference

| File | Purpose |
|------|---------|
| `app/javascript/controllers/companies/products/index_controller.js` | Main dynamic table controller |
| `app/javascript/controllers/companies/products/new_modal_controller.js` | Dynamic form fields |
| `app/javascript/controllers/companies/products/show_modal_controller.js` | Dynamic editable fields |
 | `app/controllers/companies/products_controller.rb` | JSON API with all `property_*` columns |
 | `app/services/products/search_query_service.rb` | TableConfig → Meilisearch search/filter query translation |
 | `app/javascript/controllers/companies/table_configs/edit_controller.js` | Column editor incl. Search/Filter settings |
 | `spec/features/companies/products/search_filter_spec.rb` | Dynamic search + filter dropdowns E2E |
| `app/javascript/controllers/companies/layout_controller.js` | `currentTableConfig()`, `currentPropertyMapping()` helpers |
| `app/javascript/controllers/helpers/auth_helpers.js` | `currentPropertyMappings()`, `currentTableConfigs()` |
| `app/javascript/controllers/client_cache_controller.js` | localStorage seeding (must be locked in tests) |
| `spec/features/companies/products/index_spec.rb` | 21 scenarios covering the full dynamic table system |
| `docs/CATEGORY_DYNAMIC_SCHEMA.md` | Data model for Category/PropertyMapping/TableConfig |
| `docs/DASHBOARD_PATTERN.md` | Base dashboard architecture (modals, forms, layout) |
