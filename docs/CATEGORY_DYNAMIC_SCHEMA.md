# Skycom Category Dynamic Schema System

## 1. Overview

The **Category + PropertyMapping + TableConfig** system provides a complete **Dynamic Schema + Display Configuration** for the UI. It defines:
- **What** data the `property_*` columns represent (via PropertyMapping `property_metadata` array)
- **Which** columns to show, their display properties, and ordering (via TableConfig `columns_metadata`)

### Core Concept

| Table | Purpose | Stores |
|-------|---------|--------|
| **Category** | Taxonomy grouping (name, description, resource_name) | — |
| **PropertyMapping** | Defines what `property_*` database slots mean | **JSONB array** of config objects (name, type, validates) |
| **TableConfig** | Defines visible columns, layout, and permissions | **JSONB array** of column hashes (e.g., `[{ "key": "name", "name": "Name", "visible": true, ... }]`) |
| **Resource (Product, Employee, etc.)** | Stores actual data | **Typed values** (string, integer, boolean, etc.) in individual `property_*` columns |

Each Category `has_one` PropertyMapping — they are created together. The `after_create` callback on Category guarantees every category has a dedicated PropertyMapping. Each Category also `has_many` TableConfigs (with `default_table_config` returning `.first`).

The same `property_string_1` column can mean "Skin Type Suitability" for Cosmetics products, but "Corporate Level" for Management employees — determined by the PropertyMapping attached to the Category. The TableConfig then decides whether that column is visible in the table view.

---

## 2. Database Schema

### Category Table

```ruby
create_table "categories", id: :uuid do |t|
  t.uuid     "company_id",        null: false
  t.string   "name"               # Category name (e.g., "Cosmetics")
  t.string   "description"
  t.string   "resource_name"     # Links to resource type: "products", "employees", "branches", etc.
end
```

### PropertyMapping Table

```ruby
create_table "property_mappings", id: :uuid do |t|
  t.uuid     "company_id",         null: false
  t.uuid     "category_id"
  t.string   "name"                # Human name (e.g., "Cosmetics mappings")
  t.string   "description"
  t.string   "resource_name"

  # Single JSONB array holding all dynamic property configs
  # Each element: { "key", "type", "name", "validates" }
  t.jsonb    "property_metadata", null: false, default: []

  # --- System Fields ---
  t.integer  :lifecycle_status
  t.integer  :workflow_status
  t.integer  :business_type
  t.datetime :expiration_date
  t.jsonb    :metadata,        default: {}
  t.datetime :discarded_at
  t.string   :permission_resource_name

  t.timestamps
end
```

### TableConfig Table

```ruby
create_table "table_configs", id: :uuid do |t|
  t.uuid     "company_id",                       null: false
  t.uuid     "category_id"
  t.uuid     "property_mapping_id"
  t.string   "name"
  t.string   "description"
  t.string   "resource_name"

  # Display Configuration (JSONB array of hashes — each hash defines a column's layout, behavior, and permissions)
  t.jsonb    "columns_metadata", default: []

  # --- System Fields ---
  t.integer  :lifecycle_status
  t.integer  :workflow_status
  t.integer  :business_type
  t.datetime :expiration_date
  t.jsonb    :metadata,        default: {}
  t.datetime :discarded_at
  t.string   :permission_resource_name

  t.timestamps
end
```

### Resource Tables (e.g., Product)

```ruby
create_table "products", id: :uuid do |t|
  t.uuid     "category_id"        # Links to Category

  # Actual Data (typed columns — each holds a single value)
  t.string   "property_string_1"  # e.g., "Oily Skin" (actual data, not display name)
  t.integer  "property_integer_1" # e.g., 150 (volume in ml)
  t.boolean  "property_boolean_1" # e.g., true
  # ... same column names, but typed for actual data storage
end
```

---

## 3. How It Works

### Step 1: Define Category (Schema)

A Category record is created, and its PropertyMapping is auto-generated via callback:

```ruby
# Category record for "Cosmetics" (products)
category = Category.create!(
  name: "Cosmetics",
  resource_name: "products"
)
# => PropertyMapping is auto-created with name "Cosmetics mappings"

# Update property names on the mapping (array of config objects)
category.default_property_mapping.update!(
  property_metadata: [
    { "key" => "property_string_1",
      "type" => "string", "name" => "Skin Type Suitability", "validates" => {} },
    { "key" => "property_string_2",
      "type" => "string", "name" => "Key Ingredients", "validates" => {} },
    { "key" => "property_integer_1",
      "type" => "integer", "name" => "Volume (ml)", "validates" => {} },
    { "key" => "property_boolean_1",
      "type" => "boolean", "name" => "Organic Certified", "validates" => {} }
  ]
)
```

### Step 2: Assign Category to Resource

A Product belongs to a Category:

```ruby
product = Product.create!(
  name: "Face Cream",
  category: cosmetics_category,  # Links to "Cosmetics" category
  # Actual data values:
  property_string_1: "Oily Skin", # Matches property_metadata entry with key "property_string_1"
  property_integer_1: 150,         # Matches property_metadata entry with key "property_integer_1"
  property_boolean_1: true         # Matches property_metadata entry with key "property_boolean_1"
)
```

### Step 3: Configure Table Display

Each Category has a TableConfig that defines which columns are visible, their display properties, and ordering:

```ruby
# TableConfig for the Cosmetics category
cosmetics_category.default_table_config.columns_metadata
# => [{ "key" => "name", "name" => "Name", "visible" => true, "sortable" => true, "align" => "left", "pinned" => "left", "width" => 250, "roles" => [], "is_virtual" => false, "render_config" => {} },
#     { "key" => "property_string_1", "name" => "Skin Type Suitability", "visible" => true, "sortable" => true, "align" => "left", ... },
#     ...]

# The first item is always "name" (set as default attribute on the model)
# Columns are rendered in this exact order in the table
```

The `columns_metadata` array stores structured column definitions. The frontend reads these directly — no manual merge needed.

### Step 4: UI Renders Dynamically

The UI reads `name` from the Category's PropertyMapping `property_metadata` and `columns_metadata` to render headers and form fields:

```
Product: Face Cream (Category: Cosmetics)

UI reads PropertyMapping property_metadata:
  - { key: "property_string_1",  name: "Skin Type Suitability" }
  - { key: "property_integer_1", name: "Volume (ml)" }
  - { key: "property_boolean_1", name: "Organic Certified" }

Renders:
  ┌─────────────────────────┐
  │ Skin Type Suitability  │  ← name from property_metadata
  │ [ Oily Skin          ]  │  ← Value from Product.property_string_1
  └─────────────────────────┘

  ┌─────────────────────────┐
  │ Volume (ml)             │  ← name from property_metadata
  │ [ 150                 ]  │  ← Value from Product.property_integer_1
  └─────────────────────────┘

  ┌─────────────────────────┐
  │ Organic Certified      │  ← name from property_metadata
  │ [✓]                    │  ← Value from Product.property_boolean_1
  └─────────────────────────┘
```

---

## 4. The Three-Table Flow (Runtime Merge)

When the frontend boots up to render a table, it combines all three tables into a single column config:

```
TableConfig.columns_metadata        PropertyMapping.property_metadata (array)
        │                               │
        ▼                               ▼
  [{ key: "name",             [{ key: "property_string_1", name: "Skin Type" },
    name: "Name" },           { key: "property_integer_1", name: "Volume (ml)" }]
   { key: "property_string_1",
     name: "..." },
   { key: "property_integer_1",
     name: "..." }]
        │                               │
        └───────────────────────┬───────┘
                                ▼
                  Columns payload for JS table:
        [{ field: "name",               title: "Name" },
         { field: "property_string_1",  title: "Skin Type" },
         { field: "property_integer_1", title: "Volume (ml)" },
         { field: "workflow_status",    title: "Workflow Status" }]

# Each element in columns_metadata already contains its own name, width, alignment,
# pinned state, sortability, and roles. The frontend reads `table_config.columns_metadata`
# directly — no merge with PropertyMapping names is necessary for the table view.
```

### Example JSON Payload

```json
{
  "resource": "Product",
  "columns": [
    { "field": "name", "title": "Product Name" },
    { "field": "property_string_1", "title": "Skin Type Suitability" },
    { "field": "property_integer_1", "title": "Volume (ml)" },
    { "field": "workflow_status", "title": "Status" }
  ]
}
```

### Responsibility Split

| Table | Job | Example |
|-------|-----|---------|
| **Category** | Groups resources + links PropertyMapping and TableConfig | "Cosmetics" → products |
| **PropertyMapping** | Defines what `property_*` columns mean via `property_metadata` | `[{ key: "property_string_1", name: "Skin Type", ... }]` |
| **TableConfig** | Defines column visibility + order | Show name, skin type, volume; hide shelf life |

This separation means you can define a property name in PropertyMapping but choose not to show it in the table by setting `visible: false` in the table config's column hash. The data exists, the name exists, but it's hidden from the table view.

---

## 5. Supported Resources

Category can define schemas for these resources (via `resource_name`):

| resource_name | Example Categories | Typical Properties |
|---------------|-------------------|--------------------|
| `products` | Cosmetics, Perfumes, Beauty Tools | Skin Type, Ingredients, Volume, Weight |
| `employees` | Management, Sales Specialist, Cashier | KPI Target, Commission Tier, POS Station |
| `branches` | Flagship Store, Mall Kiosk, Warehouse | Maximum Occupancy, POS Tills, Lease Size |
| `departments` | Operations, Finance, HR | Regional Scope, Accounting Standard |
| `brands` | Luxury, Mass Market, Indie | Tier Level, MOQ |
| `customers` | VIP, Regular, Wholesale | Loyalty Points, Credit Limit |
| `services` | Skincare Consultation, Spa Treatment | Duration, Room Required |
| `facilities` | Retail Floor, Storage Room | Floor Space, Capacity |

---

## 6. Property Column Mapping

### Type Reference

| Property Metadatas Entry Key | Resource Column | Type in Resource |
|------------------------------|-----------------|------------------|
| `"key": "property_string_1"` | `property_string_1` | `t.string` |
| `"key": "property_text_1"` | `property_text_1` | `t.text` |
| `"key": "property_integer_1"` | `property_integer_1` | `t.integer` |
| `"key": "property_decimal_1"` | `property_decimal_1` | `t.decimal(15,4)` |
| `"key": "property_boolean_1"` | `property_boolean_1` | `t.boolean` |
| `"key": "property_datetime_1"` | `property_datetime_1` | `t.datetime` |

### Per-Config Object Schema

Each element in `property_metadata` is a Hash with these keys:

| Key | Type | Description |
|-----|------|-------------|
| `key` | String | The resource column this config describes (e.g. `"property_string_1"`). Required. |
| `type` | String | Data type: `string`, `text`, `integer`, `decimal`, `boolean`, or `datetime`. Derivable from the key prefix. |
| `name` | String | Human-readable display name. Required. |
| `validates` | Hash | Validation rules (future use, currently `{}`). |

### Column Count Per Type

| Type | Slots Available | Example Keys |
|------|----------------|--------------|
| String | 10 | `property_string_1` through `property_string_10` |
| Text | 5 | `property_text_1` through `property_text_5` |
| Integer | 20 | `property_integer_1` through `property_integer_20` |
| Decimal | 10 | `property_decimal_1` through `property_decimal_10` |
| Boolean | 10 | `property_boolean_1` through `property_boolean_10` |
| DateTime | 10 | `property_datetime_1` through `property_datetime_10` |

---

## 7. Seed Data Example

### METADATA_CATEGORIES Structure

Properties are defined as a hash of `slot_key => name_string` in the seed data. `Seed::CategoryService` converts this into the `property_metadata` array format:

```ruby
METADATA_CATEGORIES = {
  products: {
    "Cosmetics" => {
      properties: {
        property_string_1: "Skin Type Suitability",
        property_string_2: "Key Ingredients",
        property_integer_1: "Volume (ml)",
        property_boolean_1: "Organic Certified"
      },
      visible_columns: %w[name code property_string_1 property_string_2 property_integer_1 property_boolean_1]
    },
    "Perfumes" => {
      properties: {
        property_string_1: "Scent Profile / Notes",
        property_integer_1: "Volume (ml)",
        property_boolean_1: "Includes Tester Unit"
      },
      visible_columns: %w[name code property_string_1 property_integer_1 property_boolean_1]
    }
  },
  # ... etc
}
```

### Seed Service Flow

```ruby
# Seed::CategoryService creates the Category (auto-generates PropertyMapping via callback)
# then converts the properties hash to the property_metadata array format:
#
#   { property_string_1: "Skin Type Suitability" }
#     → [{ "key" => "property_string_1",
#          "type" => "string", "name" => "Skin Type Suitability", "validates" => {} }]
#
Seed::CategoryService.create(
  company: company,
  name: "Cosmetics",
  resource_name: "products",
  properties: {
    property_string_1: "Skin Type Suitability",
    property_integer_1: "Volume (ml)",
    property_boolean_1: "Organic Certified"
  }
)

# Seed::TableConfigService is called after categories are created.
# visible_columns string keys are auto-converted to structured field hashes.
Seed::TableConfigService.create(
  company: company,
  resource_name: "products",
  category: cosmetics_category,
  columns_metadata: %w[name code property_string_1 property_integer_1 property_boolean_1].map { |k|
    { "key" => k, "name" => k.humanize, "visible" => true, "sortable" => true,
      "align" => "left", "pinned" => nil, "width" => nil, "roles" => [],
      "is_virtual" => false, "render_config" => {} }
  }
)
```

Since `properties` and `visible_columns` live in the same `METADATA_CATEGORIES` entry, they are always in sync. Adding a new property means updating one hash — the table config automatically follows.

---

## 8. UI Implementation Guidelines

### Fetching Property Names

Names live in the `property_metadata` array on the PropertyMapping record:

```javascript
// Get category for current product
const category = product.category
const mapping = category.property_mappings?.[0] || {}

// Build name map from property_metadata array
const nameMap = {}
for (const config of (mapping.property_metadata || [])) {
  nameMap[config.key] = config.name
}
// Result: { property_string_1: "Skin Type Suitability", property_integer_1: "Volume (ml)" }
```

### Three-Table Column Merge

The frontend combines `TableConfig.columns_metadata` with `PropertyMapping` names to render table headers:

```javascript
// Load table config + property mapping to build column array
const config = category.table_configs?.[0]
const columns = (config?.columns_metadata || []).map(f => ({
  field: f.key,
  title: f.name || f.key,
  width: f.width,
  align: f.align,
  pinned: f.pinned,
  sortable: f.sortable,
  visible: f.visible
}))
// Result: [{ field: "name", title: "Name", width: 250, align: "left", pinned: "left", ... }, ...]
```

### Rendering Dynamic Form

```javascript
function renderDynamicFields(product, category) {
  const mapping = category.property_mappings?.[0] || {}
  const metadatas = mapping.property_metadata || []

  return metadatas.map(config => {
    const { key, name, type } = config
    const value = product[key]
    return { type: type, name: name, value: value, key: key }
  })
}
```

---

## 9. Best Practices

1. **Use consistent naming** - Property keys should be numbered sequentially (1, 2, 3...) per category type
2. **Keep names short** - UI names should be concise (e.g., "Volume (ml)" not "Product Volume in Milliliters")
3. **Type matching** - Ensure the `type` in `property_metadata` matches the database column type (string, integer, boolean, etc.)
4. **Empty = Skip** - If a property has no name, don't render that field in UI
5. **Separate concerns** - PropertyMapping defines what data means via `property_metadata`; TableConfig defines what's visible via `columns_metadata`. A named property can be hidden from the table by setting `visible: false` in the column hash
6. **Keep in sync** - Properties and their table visibility live in the same `METADATA_CATEGORIES` entry — never define them separately
7. **`name` is universal** - The `name` column is prepended automatically by `TableConfig`'s default. Always include it first in the seed `visible_columns` array

---

## 10. Model Relationships

### Category Model

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  belongs_to :company

  has_many :property_mappings, dependent: :destroy
  has_many :table_configs, dependent: :destroy

  after_create :create_default_property_mapping

  def default_property_mapping
    property_mappings.first
  end

  def default_table_config
    table_configs.first
  end

  has_many :products
  has_many :services
  has_many :employees
  has_many :branches
  has_many :departments
  has_many :brands
  has_many :customers
  has_many :facilities
  has_many :warehouses
  has_many :stocks

  validates :name, uniqueness: { scope: [ :company_id, :resource_name ] }

  private

  def create_default_property_mapping
    create_property_mapping!(company: company, name: "#{name} mappings")
  end
end
```

### PropertyMapping Model

```ruby
# app/models/property_mapping.rb
class PropertyMapping < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :category

  has_many :table_configs, dependent: :destroy

  # property_metadata stores an array of config hashes:
  # [{ "key" => "property_string_1",
  #    "type" => "string", "name" => "Skin Type", "validates" => {} }]
end
```

### TableConfig Model

```ruby
# app/models/table_config.rb
class TableConfig < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :columns_metadata, :jsonb, default: -> {
    [{ "key" => "name", "name" => "Name", "visible" => true, "sortable" => true,
       "align" => "left", "pinned" => nil, "width" => nil, "roles" => [],
       "is_virtual" => false, "render_config" => {} }]
  }

  belongs_to :company
  belongs_to :category
  belongs_to :property_mapping
end
```

### Resource Models (e.g., Product)

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :brand, optional: true

  # Dynamic properties (typed data storage)
  # property_string_1 through property_string_10
  # property_integer_1 through property_integer_20
  # property_boolean_1 through property_boolean_10
  # etc.
end
```

---

## 11. Default Category Filter (Dashboard Index)

All resource index dashboards (products, branches, employees, etc.) apply a **default category filter** on initial load. This is not optional — dynamic property display depends on knowing which category the resource belongs to.

### Why Always Filter by Category?

Every resource record must have a `category_id`. The dynamic `property_*` columns derive their meaning from the Category's PropertyMapping. Without a category, you cannot know what `property_string_1` represents. Therefore:

- **"All Categories" is meaningless** — you cannot render a unified view across categories because the column names differ per category
- **The first category is always pre-selected** — the dashboard loads filtered to the first category from `currentCategories()`

### Frontend Implementation

Each index controller has this pattern in `connect()`:

```javascript
const urlParams = new URLSearchParams(window.location.search)
const response = await fetchJson({
  params: { category_id: urlParams.get('category_id') || this.defaultFilterCategory()?.id }
})
```

If the URL already has a `category_id` (user applied a filter), that value is preserved. Otherwise, the first available category for that resource is used as the default.

### Helper Methods

Each controller defines two methods:

```javascript
branchesCategories() {
  return currentCategories().filter(c => c.resource_name === "branches")
}

defaultFilterCategory() {
  return this.branchesCategories()[0]
}
```

- `{resource}Categories()` — filters available categories by the resource's plural name
- `defaultFilterCategory()` — returns the first category (used as the default filter and for the dropdown's selected value)

### Category Dropdown (No "All Categories")

Because every resource belongs to a category, the filter dropdown has no "All Categories" option:

```javascript
const categoryValue = urlParams.get('category_id') || this.defaultFilterCategory()?.id
${selectOptionsHTML(cloneNewKey(categoryFilter, "id", "value"), categoryValue)}
```

If `defaultText` is omitted (3rd arg), `selectOptionsHTML` skips rendering the default `<option value="">` row.

### Race Condition Safety

The `currentCategories()` helper is null-safe because `currentCompany()` may not be available yet when `connect()` fires:

```javascript
export const currentCategories = () => {
  return currentCompany()?.categories || []
}
```

This returns `[]` when the cache hasn't loaded, so `defaultFilterCategory()` returns `undefined`, `undefined?.id` resolves to `undefined`, and `fetchJson` skips the param (via `isDefined` check). Once the cache loads, subsequent renders use real category data.

---

## 12. Summary

| Concept | Description |
|---------|-------------|
| **Purpose** | Dynamic schema mapping — defines what property columns mean per resource type |
| **Category stores** | Taxonomy grouping (name, description, resource_name) |
| **PropertyMapping stores** | `property_metadata` JSONB array of config objects (name, type per slot) |
| **TableConfig stores** | `columns_metadata` JSONB array of column display configs |
| **Resource stores** | Actual typed data in individual `property_*` columns |
| **Link** | `category_id` on resource tables; `property_mapping.category_id` on PropertyMapping; `table_config.category_id` on TableConfig |
| **Category ↔ PropertyMapping** | `has_one` — auto-created via `after_create` callback |
| **Category ↔ TableConfig** | `has_many` — explicitly seeded from `visible_columns`, auto-converted to field hashes |
| **PropertyMapping ↔ TableConfig** | `has_many` — `default_table_config` returns `.first` |
| **Uniqueness** | `name` + `resource_name` scoped to `company_id` |

This system allows different industries (retail, clinic, etc.) to have completely different metadata schemas for the same generic `property_*` columns without code changes.

---

*End of documentation*
