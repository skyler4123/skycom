# Skycom Dynamic Name Mapping

> **Status**: Live (2026-08-29). This document is the project rule for how dynamic property names are handled across the three layers — Backend, Frontend, and the End User. Follow it for every feature that touches dynamic properties (search, filters, forms, tables, exports).

---

## 1. The Rule (Three Layers)

Dynamic properties live in raw database columns (`property_string_1`, `property_integer_1`, ...). Their **meaning** is defined per-category in `PropertyMapping.property_metadata` (e.g. `property_string_1` means "Color" for Cosmetics, but "Corporate Level" for Management employees).

Without a fixed rule for who resolves the friendly name, the system breaks: the BE can't know a friendly name, the FE can't trust a raw key, and the user sees `property_string_1` in the UI. This document fixes that.

| Layer | Responsibility | Example |
|-------|----------------|---------|
| **Backend (BE)** | **Raw values only.** Store, read, serialize, index, and query `record.property_string_1 = "red"`. Never resolve or store friendly names. | DB column `property_string_1` = `"red"`; API JSON key `property_string_1` = `"red"`; Meilisearch document `property_string_1` = `"red"` |
| **End User** | **Friendly names only.** Always shown the display name and value ("Color: red"). Never sees raw keys. | UI renders `Color` (label) with value `red` |
| **Frontend (FE)** | **The mapping layer — this is where the logic lives.** Translates friendly → raw when talking to the BE (user picks "Color = red" → sends `property_string_1: "red"`), and raw → friendly when rendering (BE returns `property_string_1: "red"` → shows "Color: red"). The mapping data comes from the client cache, never hardcoded. | `name="product[property_string_1]"` in forms; `mappingLookup[col.key]?.type` for type-aware rendering |

**The invariant:** the raw key is the single source of truth at the storage/transport layer. The friendly name exists **only** in `PropertyMapping.property_metadata` and **only** the FE ever resolves it.

---

## 2. Where the Mapping Data Lives

### 2.1 Source of truth: `PropertyMapping.property_metadata`

**File**: `app/models/property_mapping.rb` (JSONB column `property_metadata`, exposed via `store_accessor :metadata, :properties`)

Each category has one PropertyMapping (`Category#default_property_mapping`). Its `property_metadata` is an array of config hashes:

```json
[
  {
    "key": "property_string_1",
    "name": "Color",
    "type": "string",
    "validates": {}
  },
  {
    "key": "property_integer_1",
    "name": "Volume (ml)",
    "type": "integer",
    "validates": { "numericality": { "only_integer": true, "greater_than_or_equal_to": 0 } }
  }
]
```

| Key | Meaning |
|-----|---------|
| `key` | The raw DB column (stable, never renamed) |
| `name` | The **friendly display name** shown to end users |
| `type` | `string` / `integer` / `decimal` / `boolean` / `datetime` |
| `validates` | Dynamic validation rules (see `docs/DYNAMIC_VALIDATION.md`) |

Renaming a property in the PropertyMapping UI changes **only** `name` — the `key` stays stable. This is exactly why the index/transport layer can always rely on raw keys (see §5).

### 2.2 Delivery to the FE: client cache

The mapping data ships to the browser inside the client cache (`GET /client_cache` → `localStorage["client_cache_data"]`, see `docs/CACHE.md` §6). FE accessors in `app/javascript/controllers/helpers/auth_helpers.js`:

```javascript
export const currentPropertyMappings = () => {
  return currentCompany()?.property_mappings || []
}
```

The `property_metadata` array is reachable on each mapping. **The FE must build its name map from this data — never hardcode a key ↔ name table.**

### 2.3 Existing FE pattern: `mappingLookup`

All dynamic index controllers (products, branches, employees, services, customers, ...) already build a lookup hash from the cache for type-aware rendering — reuse this pattern:

```javascript
// app/javascript/controllers/companies/products/index_controller.js:68
const mappingLookup = (propertyMapping?.metadata?.properties || []).reduce((acc, field) => {
  acc[field.key] = field   // { property_string_1: { key, name: "Color", type: "string", ... } }
  return acc
}, {})
```

---

## 3. Direction Examples

### 3.1 Raw → Friendly (BE → FE → User rendering)

The BE serializes raw keys; the FE resolves `name`/`type` from the cache; the user sees friendly labels.

```ruby
# BE — serializes raw values only
def format_product(product)
  product.as_json(only: [ :id, :name, :property_string_1, :property_integer_1 ])
end
```

```javascript
// FE — renders the friendly name from property_metadata
const field = mappingLookup["property_string_1"]        // { key, name: "Color", type: "string" }
`<th>${field.name}</th>`                                 // "Color"
`<td>${product.property_string_1}</td>`                  // "red"
```

The `table()` helper (`app/javascript/controllers/helpers/ui_helpers.js:783`) already does this — headers come from `TableConfig.columns_metadata[].name` (synced from PropertyMapping), and `renderCellContent` uses `mappingLookup[col.key]?.type` for type-aware cells (boolean badge, formatted numbers, datetime, ...).

### 3.2 Friendly → Raw (User → FE → BE forms, filters, search)

The FE translates the user's choice into the raw key before any API call. Forms already do this:

```html
<!-- FE renders the friendly label; the input name is ALWAYS the raw key -->
<label>Color</label>
<input name="product[property_string_1]" value="red">
```

```ruby
# BE — strong params accept raw keys; storage is raw
def product_params
  params.require(:product).permit(:name, :property_string_1, :property_integer_1, ...)
end
```

A future filter/search UI must do the same: user picks `Color = red` → FE maps to `property_string_1: "red"` → API/Meilisearch query uses `property_string_1`.

---

## 4. Rule Interactions

### 4.1 Meilisearch (search)

The search index follows the BE rule — raw keys only (`docs/MEILISEARCH.md` §1). `property_string_1` is indexed as `property_string_1`, searchable and filterable. Why this is safe:

- Index settings (`searchable_attributes` / `filterable_attributes`) are static and must match stable keys.
- Renaming a property (`name` in `property_metadata`) never breaks the index — the FE maps friendly → raw key at query time.

A future search UI: FE takes the user's friendly filter (e.g. `Color = red`), maps it to `property_string_1`, and queries:

```javascript
// FE — friendly → raw, then tenant-scoped query
const rawKey = "property_string_1"   // resolved from currentPropertyMappings()
fetchJson(url, { params: { q: "red", filter: `company_id = ${currentCompany().id} AND ${rawKey} = "red"` } })
```

```ruby
# BE — search endpoint stays raw
Product.ms_raw_search(params[:q], filter: params[:filter])
```

### 4.2 Dynamic validation

`DynamicValidationConcern` validates `property_*` columns directly (raw) — no mapping involved. The FE must display validation errors with friendly names (map `property_string_1` → "Color" before showing the error to the user).

### 4.3 Language/translation

Property display names come from `PropertyMapping.property_metadata`, not from `dictionary.js`. If a feature needs localized property names, do it FE-side at render time (map friendly name through `translate()`), keeping the stored `name` as the canonical English label.

---

## 5. Forbidden Patterns

| Pattern | Why it's forbidden |
|---------|--------------------|
| **BE resolves friendly names** — e.g. a BE serializer emitting `{ color: "red" }` or a model method `product.color` | The BE cannot know which category a record belongs to at the column level; two categories can map the same `property_string_1` to different meanings. It also couples BE to PropertyMapping data, violating the "BE keeps simple" rule. |
| **Storing display names** — writing `"Color"` into a `property_*` column, or using a friendly name as a Meilisearch attribute | Corrupts data and breaks index settings; renaming a property would orphan old values. |
| **FE hardcoding key ↔ name maps** — e.g. `{ property_string_1: "Color" }` written in a controller | Drifts from `PropertyMapping`; a rename in the admin UI silently breaks the UI. Always read from `currentPropertyMappings()`. |
| **Showing raw keys to users** — rendering `property_string_1` as a label | Exactly the confusion this rule exists to prevent. |

---

## 6. Checklist for New Features

Any feature that touches dynamic properties (search, filters, new dashboards, exports, mobile) must satisfy:

- [ ] **BE**: stores, serializes, and queries raw keys only (`property_string_1`). No friendly-name resolution, no display-name columns.
- [ ] **FE**: builds the name map from `currentPropertyMappings()` (via `mappingLookup` or similar) — never hardcoded.
- [ ] **FE**: user-facing labels and values are always the friendly `name` from `property_metadata`.
- [ ] **FE**: any outgoing request (form, filter, search) maps friendly → raw key before sending.
- [ ] **Search**: Meilisearch index stays raw-keyed; friendly → raw mapping happens FE-side at query time, always with `company_id` filter.
- [ ] **Errors**: validation errors from the BE (raw keys) are displayed with friendly names by the FE.
- [ ] If the feature adds new settings to the search index, follow `docs/MEILISEARCH.md` §5 (reindex, backfill).

---

## 7. File Reference

| File | Purpose |
|------|---------|
| `app/models/property_mapping.rb` | `property_metadata` JSONB — the mapping source of truth (`key`, `name`, `type`, `validates`) |
| `app/javascript/controllers/helpers/auth_helpers.js` | `currentPropertyMappings()` / `currentTableConfigs()` — cache accessors |
| `app/javascript/controllers/companies/{resource}/index_controller.js` | `mappingLookup` build + type-aware rendering (reference pattern) |
| `app/javascript/controllers/helpers/ui_helpers.js` | `table()` helper — friendly headers + type-aware cells |
| `app/models/concerns/dynamic_search_concern.rb` | Meilisearch index — raw keys only |
| `docs/MEILISEARCH.md` | Search integration + index schema updates |
| `docs/CATEGORY_DYNAMIC_SCHEMA.md` | Category / PropertyMapping / TableConfig data model |

---

## 8. See Also

- `docs/CATEGORY_DYNAMIC_SCHEMA.md` — the data model behind the mapping (Category → PropertyMapping → TableConfig)
- `docs/DYNAMIC_TABLE.md` — dynamic column tables + how `mappingLookup`/`columns_metadata` render
- `docs/DYNAMIC_VALIDATION.md` — dynamic validation rules (raw columns)
- `docs/MEILISEARCH.md` — search indexing (raw keys, schema updates)
- `docs/CACHE.md` — client cache delivery of `property_mappings` to the FE

---

*End of document*