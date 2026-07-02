# Skycom Dynamic Validation System

## 1. Overview

The Dynamic Validation system allows property-level validation rules to be defined in the PropertyMapping UI and applied automatically at the record level. Instead of hardcoding validations in each model, you define the rules in the `validates` hash of each `property_metadata` entry.

### How It Works

```
PropertyMapping.property_metadata
  └── entry: { "key" => "property_string_1", "validates" => { "presence" => true } }
        │
        ▼
  DynamicValidationConcern (auto-included via PropertyMappingConcern)
        │
        ▼
  validate :dynamic_property_validations  →  Product.valid?  →  checks property_string_1
```

## 2. Supported Validators

| Validator Key | Hash Format | Example |
|--------------|-------------|---------|
| `presence` | `true` | `{ "presence": true }` |
| `numericality` | Hash with keys: `only_integer`, `greater_than`, `greater_than_or_equal_to`, `less_than`, `less_than_or_equal_to` | `{ "numericality": { "only_integer": true, "greater_than_or_equal_to": 0 } }` |
| `inclusion` | Hash with `in` array | `{ "inclusion": { "in": [true, false] } }` |
| `format` | Hash with `with` or `without` regex string | `{ "format": { "with": "^SKU-" } }` |
| `length` | Hash with `minimum` and/or `maximum` | `{ "length": { "minimum": 2, "maximum": 50 } }` |

### Format Notes

- All keys and values use JSON types (strings, numbers, booleans, arrays)
- `numericality` supports integer/float comparisons — not `odd`, `even`, or `other_numericality` options
- `format` regex strings are passed to `Regexp.new()` — use Ruby-compatible regex syntax
- `length` checks the string length of `.to_s` on the value
- An empty validates hash `{}` means no validation is applied

## 3. How to Add Validates Rules

1. Navigate to **Dynamic Properties** → select a Property Mapping → **Edit**
2. In the **Validates** column, type raw JSON into the textarea
3. Click **Save Changes**

The validation rules take effect immediately on all records using that Property Mapping.

## 4. Which Models Are Affected

All models that include `PropertyMappingConcern` (48 models: products, services, branches, employees, customers, etc.) automatically get dynamic validation via `DynamicValidationConcern`.

## 5. Seeded Defaults

When a Property Mapping is created via `Seed::CategoryService`, it seeds type-appropriate validates:

| Type | Seeded Validates |
|------|-----------------|
| `string` | `{ "presence" => true }` |
| `integer` | `{ "numericality" => { "only_integer" => true, "greater_than_or_equal_to" => 0 } }` |
| `decimal` | `{ "numericality" => { "greater_than_or_equal_to" => 0 } }` |
| `boolean` | `{ "inclusion" => { "in" => [true, false] } }` |
| `text` / `datetime` | `{}` (no validation) |

## 6. File Reference

| File | Purpose |
|------|---------|
| `app/models/concerns/dynamic_validation_concern.rb` | The concern implementation |
| `app/models/concerns/property_mapping_concern.rb` | Includes DynamicValidationConcern for all property-mapped models |
| `app/services/seed/category_service.rb` | Seeds validates hashes via `build_validates(type)` |
