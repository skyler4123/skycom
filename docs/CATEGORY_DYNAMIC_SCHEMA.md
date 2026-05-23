# Skycom Category Dynamic Schema System

## 1. Overview

The **Category + PropertyMapping** system acts as a **Dynamic Schema Mapping** for UI display. It defines what each generic `property_*` column represents in the UI for a specific domain (products, employees, branches, etc.).

### Core Concept

| Table | Purpose | Property Columns Store |
|-------|---------|------------------------|
| **Category** | Creates taxonomy grouping (name, description, resource_name) | — |
| **PropertyMapping** | Defines UI labels | **String** labels (e.g., "Skin Type Suitability", "Volume (ml)") |
| **Resource (Product, Employee, etc.)** | Stores actual data | **Typed values** (string, integer, boolean, etc.) |

Each Category `has_one` PropertyMapping — they are created together. The `after_create` callback on Category guarantees every category has a dedicated PropertyMapping.

The same `property_string_1` column can mean "Skin Type Suitability" for Cosmetics products, but "Corporate Level" for Management employees — determined by the PropertyMapping attached to the Category.

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
  t.uuid     "category_id"         # Optional — standalone or linked to a Category
  t.string   "name"                # Human name (e.g., "Cosmetics mappings")

  # UI Labels (all :string type - storing display names)
  t.string   "property_string_1"   # e.g., "Skin Type Suitability"
  t.string   "property_string_2"
  # ... (20 string properties)

  t.string   "property_text_1"     # e.g., "Full Description"
  # ... (5 text properties)

  t.string   "property_integer_1"  # e.g., "Volume (ml)"
  # ... (20 integer properties)

  t.string   "property_decimal_1"  # e.g., "Weight (Grams)"
  # ... (10 decimal properties)

  t.string   "property_boolean_1"  # e.g., "Organic Certified"
  # ... (10 boolean properties)

  t.string   "property_datetime_1" # e.g., "Operation Start Date"
  # ... (10 datetime properties)
end
```

### Resource Tables (e.g., Product)

```ruby
create_table "products", id: :uuid do |t|
  t.uuid     "category_id"        # Links to Category

  # Actual Data (typed columns — different from PropertyMapping's string labels)
  t.string   "property_string_1"  # e.g., "Oily Skin" (data, not label!)
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

# Update property labels on the mapping
category.property_mapping.update!(
  property_string_1: "Skin Type Suitability",  # Label for property_string_1
  property_string_2: "Key Ingredients",         # Label for property_string_2
  property_integer_1: "Volume (ml)",             # Label for property_integer_1
  property_boolean_1: "Organic Certified"        # Label for property_boolean_1
)
```

### Step 2: Assign Category to Resource

A Product belongs to a Category:

```ruby
product = Product.create!(
  name: "Face Cream",
  category: cosmetics_category,  # Links to "Cosmetics" category
  # Actual data values:
  property_string_1: "Oily Skin", # Matches category.property_mapping's property_string_1 label
  property_integer_1: 150,         # Matches category.property_mapping's property_integer_1 label
  property_boolean_1: true         # Matches category.property_mapping's property_boolean_1 label
)
```

### Step 3: UI Renders Dynamically

The UI looks up the Category's PropertyMapping to get labels, then renders form fields:

```
Product: Face Cream (Category: Cosmetics)

UI reads PropertyMapping labels via category.property_mapping:
  - property_string_1 = "Skin Type Suitability"
  - property_integer_1 = "Volume (ml)"
  - property_boolean_1 = "Organic Certified"

Renders:
  ┌─────────────────────────┐
  │ Skin Type Suitability  │  ← Label from PropertyMapping
  │ [ Oily Skin          ]  │  ← Value from Product
  └─────────────────────────┘

  ┌─────────────────────────┐
  │ Volume (ml)             │  ← Label from PropertyMapping
  │ [ 150                 ]  │  ← Value from Product
  └─────────────────────────┘

  ┌─────────────────────────┐
  │ Organic Certified      │  ← Label from PropertyMapping
  │ [✓]                    │  ← Value from Product
  └─────────────────────────┘
```

---

## 4. Supported Resources

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

## 5. Property Column Mapping

### Type Reference

| PropertyMapping Column (Label) | Product/Resource Column (Data) | Type in Resource |
|-------------------------------|--------------------------------|------------------|
| `property_string_1` | `property_string_1` | `t.string` |
| `property_text_1` | `property_text_1` | `t.text` |
| `property_integer_1` | `property_integer_1` | `t.integer` |
| `property_decimal_1` | `property_decimal_1` | `t.decimal(15,4)` |
| `property_boolean_1` | `property_boolean_1` | `t.boolean` |
| `property_datetime_1` | `property_datetime_1` | `t.datetime` |

### Column Count

| Type | Count |
|------|-------|
| String | 20 |
| Text | 5 |
| Integer | 20 |
| Decimal | 10 |
| Boolean | 20 |
| DateTime | 10 |

---

## 6. Seed Data Example

### METADATA_CATEGORIES Structure

```ruby
METADATA_CATEGORIES = {
  products: {
    "Cosmetics" => {
      property_string_1: "Skin Type Suitability",
      property_string_2: "Key Ingredients",
      property_integer_1: "Volume (ml)",
      property_boolean_1: "Organic Certified"
    },
    "Perfumes" => {
      property_string_1: "Scent Profile / Notes",
      property_integer_1: "Volume (ml)",
      property_boolean_1: "Includes Tester Unit"
    }
  },
  employees: {
    "Management" => {
      property_string_1: "Corporate Level",
      property_decimal_1: "KPI Target Bonus %"
    },
    "Sales Specialist" => {
      property_string_1: "Assigned Product Line",
      property_decimal_1: "Commission Tier %"
    }
  },
  # ... etc
}
```

### Seed Service

```ruby
# Seed::CategoryService creates the Category (which auto-generates PropertyMapping via callback)
# then updates the PropertyMapping with the properties parameter
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
```

---

## 7. UI Implementation Guidelines

### Fetching Category Labels

Labels live on `category.property_mapping`, not directly on `category`:

```javascript
// Get category for current product
const category = product.category
const mapping = category.property_mapping || {}

// Map of field name to label
const labelMap = {
  property_string_1: mapping.property_string_1,
  property_string_2: mapping.property_string_2,
  property_integer_1: mapping.property_integer_1,
  property_boolean_1: mapping.property_boolean_1,
  // ... etc
}
```

### Rendering Dynamic Form

```javascript
function renderDynamicFields(product, category) {
  const fields = []
  const mapping = category.property_mapping || {}

  // Only render properties that have labels defined
  for (let i = 1; i <= 20; i++) {
    const label = mapping[`property_string_${i}`]
    const value = product[`property_string_${i}`]
    if (label) {
      fields.push({ type: 'text', label, value, key: `property_string_${i}` })
    }
  }

  // Render boolean fields
  for (let i = 1; i <= 20; i++) {
    const label = mapping[`property_boolean_${i}`]
    const value = product[`property_boolean_${i}`]
    if (label) {
      fields.push({ type: 'boolean', label, value, key: `property_boolean_${i}` })
    }
  }

  return fields
}
```

### Form Input Generation

| PropertyMapping Property Type | Input Type |
|------------------------------|------------|
| `property_string_*` | `<input type="text">` |
| `property_text_*` | `<textarea>` |
| `property_integer_*` | `<input type="number">` |
| `property_decimal_*` | `<input type="number" step="0.0001">` |
| `property_boolean_*` | `<input type="checkbox">` |
| `property_datetime_*` | `<input type="datetime-local">` |

---

## 8. Best Practices

1. **Use consistent naming** - Property keys should be numbered sequentially (1, 2, 3...) per category type
2. **Don't skip numbers** - Leave gaps makes it confusing which properties are active
3. **Keep labels short** - UI labels should be concise (e.g., "Volume (ml)" not "Product Volume in Milliliters")
4. **Type matching** - Ensure PropertyMapping label slot matches the data type (e.g., use property_integer_* for numeric values)
5. **Empty = Skip** - If a property label is `nil` or empty, don't render that field in UI

---

## 9. Model Relationships

### Category Model

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  belongs_to :company

  has_one :property_mapping, dependent: :destroy

  after_create :create_default_property_mapping

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
  belongs_to :category, optional: true
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
  # property_string_1 through property_string_20
  # property_integer_1 through property_integer_20
  # property_boolean_1 through property_boolean_20
  # etc.
end
```

---

## 10. Summary

| Concept | Description |
|---------|-------------|
| **Purpose** | Dynamic schema mapping — defines what property columns mean per resource type |
| **Category stores** | Taxonomy grouping (name, description, resource_name) |
| **PropertyMapping stores** | UI labels (as strings) |
| **Resource stores** | Actual typed data |
| **Link** | `category_id` on resource tables; `property_mapping.category_id` on PropertyMapping |
| **Category ↔ PropertyMapping** | `has_one` — auto-created via `after_create` callback |
| **Uniqueness** | `name` + `resource_name` scoped to `company_id` |

This system allows different industries (retail, clinic, etc.) to have completely different metadata schemas for the same generic `property_*` columns without code changes.

---

*End of documentation*
