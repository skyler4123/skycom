# Computed Index Columns

> **Prerequisites**: Read `docs/DYNAMIC_TABLE.md` (TableConfig columns, index pages) and `docs/CATEGORY_DYNAMIC_SCHEMA.md` (Category/PropertyMapping/TableConfig).
>
> This document is the canonical guide for adding and extending **computed columns** — read-only index columns calculated by a model from related data. The first adoption is `Product#quantity` summed from `Stock`.

---

## 1. What a computed column is

A computed column is:

- derived from related data, not stored on the record;
- declared by the resource model, not by a PropertyMapping property;
- shown in the index table through the normal TableConfig visibility/order fields;
- **not searchable and not filterable**;
- read-only for end users.

Examples: `Product#quantity` (sum of stock rows), `Customer#order_count`, `Warehouse#sku_count`.

---

## 2. One key, source resolved per resource

The column **key is plain** — `quantity`, not `computed_quantity`. The resource decides what the key means:

| Resource | `quantity` source | Editor group | Search/Filter |
|---|---|---|---|
| Product | `Product#quantity` (computed from Stock) | Computed | Locked |
| Stock | `stocks.quantity` (real DB column) | Standard | Range filter as today |

Resolution order for a resource model and key:

1. **Real DB column** → standard.
2. **Model declares `computed_column` with that key** → computed.
3. **Neither** → ghost; dropped from the TableConfig on the next save.

**A model must never declare a computed key that is also a real DB column.** The real column always wins; a model spec flags the duplicate declaration.

This is what makes the pattern extensible:

- The same key can be computed on one resource and standard on another.
- If a computed key later becomes a real DB column, existing TableConfigs keep working: the key stays `quantity`, the editor source flips from Computed to Standard, and search/filter become available.
- Removing a computed declaration drops the column from existing configs lazily on the next save.

---

## 3. Backend contract

### 3.1 Model registry

Include the concern and declare each computed method:

```ruby
class Product < ApplicationRecord
  include ComputedColumnsConcern

  computed_column :quantity, name: "Quantity", type: :integer

  def quantity
    return @computed_quantity if defined?(@computed_quantity)

    stocks.sum(:quantity)
  end

  # One grouped query per index page; optional but required for query-backed columns.
  def self.preload_computed_columns(records)
    return if records.empty?

    totals = Stock.where(product_id: records.map(&:id)).group(:product_id).sum(:quantity)
    records.each do |record|
      record.instance_variable_set(:@computed_quantity, totals[record.id] || 0)
    end
  end
end
```

Public class methods:

```ruby
Product.computed_columns
# => [{ "key" => "quantity", "name" => "Quantity", "type" => "integer" }]

Product.available_computed_columns
# => declarations minus keys that are real DB columns
```

Instance method:

```ruby
product.computed_column_values
# => { "quantity" => 8 }
```

### 3.2 Resolver

`ComputedColumns` maps a category's `resource_name` to the owning model:

```ruby
ComputedColumns.for("products")
# => Product.available_computed_columns

ComputedColumns.for("stocks")
# => nil (Stock has no computed declarations)

ComputedColumns.model_for("products")
# => Product
```

The resolver uses `safe_constantize` and requires an `ApplicationRecord` subclass. Only models that include `ComputedColumnsConcern` expose a catalog.

### 3.3 Index controller

The index controller must preload once and merge the values into each record:

```ruby
def format_products(products)
  Product.preload_computed_columns(products)
  products.map { |product| format_product(product) }
end

def format_product(product)
  product.as_json(only: [...]).merge(
    category: ...,
    **product.computed_column_values
  )
end
```

The wire key is the plain column key. The table renderer already reads `record[col.key]`.

### 3.4 TableConfig and PropertyMapping

`TableConfigsController#format_config` returns two disjoint catalogs:

```jsonc
{
  "standard_columns": [
    { "key": "name", "name": "Name", "type": "string" },
    { "key": "code", "name": "Code", "type": "string" }
  ],
  "computed_columns": [
    { "key": "quantity", "name": "Quantity", "type": "integer" }
  ]
}
```

`PropertyMappingsController#format_mapping` returns `computed_columns` only, for the read-only card.

`TableConfig` normalization:

- standard key → canonical name, keep search/filter, remove any stale `type`;
- computed key → canonical name/type from the model, strip `search`/`filter`, keep `visible`;
- ghost standard key for a resolved model → drop;
- property/extra → existing behavior.

Validation also rejects `search: true` and any `filter` on a computed key.

---

## 4. Frontend contract

`table_config_helpers.js` receives a catalog:

```javascript
const catalog = {
  standard: config.standard_columns, // authoritative real columns
  computed: config.computed_columns  // model-computed methods
}
```

It resolves `columnSource`, `columnName`, `columnType`, `isSearchableColumn`, and `filterTypeOptions` from the catalog. Legacy configs without a catalog fall back to the global standard map.

### Table Config editor

- Add Column groups: **Standard columns / Property columns / Computed columns / Extra columns**.
- Computed rows show a **Computed** badge.
- Search and Filter cells are locked with tooltips.
- Adding a computed column stores `{ key, name, visible: true, type }`; no search/filter.
- `captureColumnsFromDOM` deletes search/filter for computed rows.
- Show/hide, reorder, and remove work exactly like other columns.

### Table Config show

- Computed badge.
- Search `—`.
- Filter `No filter` with a tooltip.

### Property Mapping show/edit

- Read-only **Computed columns** card with Display Name, Type, Source = Computed.
- No inputs, no delete, no metadata storage.

### Table renderer

```javascript
const fieldType = mappingLookup[col.key]?.type || col.type
```

Computed integers get the existing number formatting.

---

## 5. End-user flow

1. Open Products.
2. Open the Product Table Config.
3. Add Column → **Computed columns** → Quantity.
4. Save.
5. The table shows Quantity summed across all warehouses.
6. Move it with the up/down buttons; hide it with **Visible**; remove it from this table only.
7. Search and Filter stay locked because the value is calculated.
8. Open the Stock table: Quantity is still a **Standard**, filterable column.
9. Open Property Mapping: Quantity appears as a read-only computed reference.

Nothing is auto-added to existing layouts. New-company retail seeds include Quantity visible; other companies add it from the editor.

---

## 6. Add another computed column to an existing model

1. Define the method on the model (e.g. `available_quantity`).
2. Declare it:
   ```ruby
   computed_column :available_quantity, name: "Available quantity", type: :integer
   ```
3. If the method queries, extend `self.preload_computed_columns(records)` and use a `@computed_*` ivar in the method.
4. Add the key to seed lists if it should be visible by default.
5. Add a model/feature spec and a dictionary entry for the display name.
6. No TableConfig, PropertyMapping, or frontend change is needed — the catalogs pick it up.

**Do not** declare a key that already exists as a real DB column. The real column wins; a spec flags the duplicate.

---

## 7. Adopt a new model

1. Include `ComputedColumnsConcern`.
2. Declare `computed_column` entries.
3. Implement the instance methods.
4. Implement `self.preload_computed_columns` for bulk loading.
5. In that model's index controller, preload once and merge `computed_column_values`.
6. Add seeds if the columns should be visible by default.
7. Add specs and documentation.
8. No generic TableConfig/editor changes — `ComputedColumns.for(resource_name)` resolves the model from the category's `resource_name`.

Checklist:

- [ ] Category `resource_name` matches the model's plural name.
- [ ] The model has no computed key that is a real DB column.
- [ ] Index controller preloads once.
- [ ] Feature spec proves the index value.
- [ ] Table Config editor shows the computed group for that resource.
- [ ] Property Mapping shows the read-only card.
- [ ] Dictionary entries added.

---

## 8. Product `quantity` example

```ruby
# app/models/product.rb
include ComputedColumnsConcern

computed_column :quantity, name: "Quantity", type: :integer

def self.preload_computed_columns(records)
  return if records.empty?

  totals = Stock.where(product_id: records.map(&:id)).group(:product_id).sum(:quantity)
  records.each { |r| r.instance_variable_set(:@computed_quantity, totals[r.id] || 0) }
end

def quantity
  return @computed_quantity if defined?(@computed_quantity)

  stocks.sum(:quantity)
end
```

Resulting TableConfig entry on a Product config:

```json
{ "key": "quantity", "name": "Quantity", "visible": true, "type": "integer" }
```

Stock keeps its real column and filter:

```json
{ "key": "quantity", "name": "Quantity", "visible": true,
  "filter": { "type": "range", "active": true, "buckets": [[null, 100], [100, null]] } }
```

---

## 9. Testing recipe

### Feature (primary proof)

- Product index shows the computed value and no filter dropdown.
- Table Config editor shows the column only under Computed for Product.
- Stock Table Config shows Quantity only under Standard and keeps the range filter.
- Hide/reload persists.
- Property Mapping show/edit displays the read-only card.

### Model

- The computed method returns the expected aggregate.
- `preload_computed_columns` sets the cached value.
- `computed_columns` has the expected shape.
- No computed key overlaps a real DB column.
- Normalization sets name/type and strips search/filter for computed keys.
- Standard quantity on Stock keeps its filter.

### Request

- Index JSON includes the computed key.
- TableConfig show JSON includes `standard_columns` and `computed_columns`.
- PropertyMapping show JSON includes `computed_columns`.

---

## 10. Performance and caching

- Preload once per page. Never call a query-backed computed method per row.
- One grouped aggregate per index request is the baseline.
- No cache in the first implementation. If the aggregate becomes hot, change only the model method (denormalized counter, `Rails.cache`, etc.). TableConfig and the UI do not change.
- Export requests load more records; the same grouped query applies. Monitor large exports.

---

## 11. Pitfalls

- **Duplicate key**: never declare a computed key that is a real DB column.
- **Resource name mismatch**: `ComputedColumns.for` resolves via `resource_name.classify`; the category/TableConfig resource name must match the model's plural.
- **Per-row queries**: always implement `preload_computed_columns` when the method queries.
- **Branch filters**: `Product#quantity` sums all warehouses; a branch filter does not change the value. Label it as total on-hand or add a separate branch-aware column later.
- **Digital/service products**: `Product#quantity` shows `0` today. Return `nil` later if that is clearer for non-physical products.
- **Stale configs**: a removed computed declaration disappears from existing configs on the next save, not immediately.
- **Search/filter expectations**: computed columns are never indexed in Meilisearch and never render search/filter controls.

---

## 12. Out of scope

- Search, filter, or sort for computed columns.
- Rendering computed values on show pages.
- Auto-adding new computed columns to existing layouts.
- Real-time/denormalized counters.
- Mobile parity.

---

## 13. File reference

| File | Purpose |
|---|---|
| `app/models/concerns/computed_columns_concern.rb` | Model DSL, registry, values, preload hook. |
| `app/models/computed_columns.rb` | `resource_name` → model resolver. |
| `app/models/product.rb` | First adoption: `quantity`. |
| `app/models/table_config.rb` | Source resolution, normalization, validation, catalogs. |
| `app/models/property_mapping.rb` | `effective_resource_name` for the read-only catalog. |
| `app/controllers/companies/products_controller.rb` | Preload + merge computed values. |
| `app/controllers/companies/table_configs_controller.rb` | `standard_columns` + `computed_columns` JSON. |
| `app/controllers/companies/property_mappings_controller.rb` | `computed_columns` JSON. |
| `app/javascript/controllers/helpers/table_config_helpers.js` | Catalog-aware column helpers. |
| `app/javascript/controllers/companies/table_configs/edit_controller.js` | Computed group, badge, locks. |
| `app/javascript/controllers/companies/table_configs/show_controller.js` | Read-only computed badges. |
| `app/javascript/controllers/companies/property_mappings/{show,edit}_controller.js` | Read-only computed card. |
| `app/services/seed/table_config_service.rb` | `field_hash_for` keeps computed keys out of search/filter. |
| `spec/models/computed_columns_spec.rb` | Resolver + real-column precedence. |
