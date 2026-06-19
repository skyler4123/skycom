# Skycom Dynamic Table System

> **Prerequisites**: Read `CATEGORY_DYNAMIC_SCHEMA.md` for the PropertyMapping/TableConfig data model. Read `DASHBOARD_PATTERN.md` for the base dashboard architecture.
>
> This document covers only the dynamic column system — how `property_*` columns get their labels, how tables render them, and how modals generate form fields.

---

## 1. Data Flow

```
ProductsController#index
  └─ format_product() — emits all 55 property_* columns + category_id
        │
        ▼
  ClientCache (localStorage)
  ├─ categories[]         — available categories per resource_name
  ├─ property_mappings[]  — property_metadata (label, type per slot)
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

  // Fetch products
  const response = await fetchJson({ params: { category_id: this.categoryIdValue } })
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

### 2.2 Label Resolution

```javascript
const mappingLookup = (propertyMapping?.property_metadata || []).reduce((acc, field) => {
  acc[field.key] = field
  return acc
}, {})

const resolvedLabel = col.key.startsWith("property_")
  ? (mappedField?.label || col.label || col.key)   // PropertyMapping > TableConfig > raw key
  : (col.label || col.key)                          // TableConfig > raw key
```

| Column Type | Priority Order |
|-------------|----------------|
| `property_*` (dynamic) | `PropertyMapping.label` > `TableConfig.columns_metadata[].label` > raw key |
| Standard (name, code, workflow_status) | `TableConfig.columns_metadata[].label` > raw key |

### 2.3 Type-Aware Cell Rendering

`renderCellContent(product, col, mappedField)` renders cells based on `mappedField.type`:

| Type | Rendering |
|------|-----------|
| `boolean` | Badge — `Yes` (emerald) / `No` (slate) |
| `integer` | Locale-formatted number (`1,234`) |
| `decimal` | 2 decimal places, blue (`1,234.00`) |
| `text` / `string` / default | Raw value, or `—` for null |
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
renderField({ key, label, type }) {
  switch (type) {
    case 'boolean':
      return `<input type="checkbox" name="product[${key}]" value="true">
              <input type="hidden" name="product[${key}]" value="false">`
    case 'integer':
    case 'decimal':
      return `<input type="number" name="product[${key}]" step="${type === 'decimal' ? '0.01' : '1'}">`
    case 'datetime':
      return `<input type="datetime-local" name="product[${key}]">`
    case 'text':
      return `<textarea name="product[${key}]" rows="3"></textarea>`
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
    confirmMessage: `Change ${field.label} to '{{value}}'?`,
    successMessage: `${field.label} updated!`,
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
   - `renderField({ key, label, type })` for all 6 types
   - `handleSubmit()` with `fetchJson` + `reloadThenToast`

3. **ShowModalController** — `extends Controller`, implement:
   - `formatDisplayValue(value, type)` for all 6 types
   - Dynamic `Helpers.editable()` fields from `propertyMetadata`

4. **LayoutController** — register in sidebar navigation.

### 7.3 Tests

1. Seed categories + property_mappings + table_configs in `let!` blocks
2. Use `.reset` before serializing associations to JSON for cache seeding
3. Lock cookie version to prevent `ClientCacheController` overwrite
4. Use deterministic product names (no Faker)
5. Assert dynamic column headers by label (e.g., `have_selector('th', text: 'Skin Type')`)

---

## 8. File Reference

| File | Purpose |
|------|---------|
| `app/javascript/controllers/companies/products/index_controller.js` | Main dynamic table controller |
| `app/javascript/controllers/companies/products/new_modal_controller.js` | Dynamic form fields |
| `app/javascript/controllers/companies/products/show_modal_controller.js` | Dynamic editable fields |
| `app/controllers/companies/products_controller.rb` | JSON API with all `property_*` columns |
| `app/javascript/controllers/companies/layout_controller.js` | `currentTableConfig()`, `currentPropertyMapping()` helpers |
| `app/javascript/controllers/helpers/auth_helpers.js` | `currentPropertyMappings()`, `currentTableConfigs()` |
| `app/javascript/controllers/client_cache_controller.js` | localStorage seeding (must be locked in tests) |
| `spec/features/companies/products/index_spec.rb` | 21 scenarios covering the full dynamic table system |
| `docs/CATEGORY_DYNAMIC_SCHEMA.md` | Data model for Category/PropertyMapping/TableConfig |
| `docs/DASHBOARD_PATTERN.md` | Base dashboard architecture (modals, forms, layout) |
