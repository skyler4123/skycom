# Skycom Property Slot Validation

## 1. Overview

Skycom no longer supports user-defined dynamic validations. A category's
`property_metadata` describes which `property_*` slots exist and what they mean;
the real database column is the source of truth for what each slot can hold.

```
PropertyMapping.metadata["properties"]
  └── entry: { "key" => "property_string_1", "name" => "Brand", "type" => "string" }
        │
        ▼
  PropertySlotValidationConcern (included via PropertyMappingConcern)
        │
        ▼
  validate :property_slot_type_validations  →  Product.valid?
```

## 2. Built-in Rules

| Column type | Rule |
|-------------|------|
| `string` | Maximum 255 characters (the conventional varchar limit; property string columns are unbounded varchar in PostgreSQL) |
| `integer` | Whole number within the column's byte range — 32-bit for `property_integer_*` (`-2,147,483,648 … 2,147,483,647`) |
| `decimal` | Precision/scale from the column — `property_decimal_*` is `numeric(15,4)`, so max `99,999,999,999.9999` and at most 4 decimal places |
| `boolean` | `true` or `false` |
| `datetime` | A valid date/time value |

Blank values are allowed. There is no required/presence rule unless the
underlying model column itself is non-nullable.

## 3. How It Works

`PropertySlotValidationConcern` iterates `property_mapping.properties`, looks up
each key in the model's `columns_hash`, and applies the matching rule:

- Slots that do not exist on the model (for example metadata-only `extra_*`
  columns) are skipped.
- Slots that are not listed in the mapping are not validated.
- Decimal scale is checked against the originally assigned value because
  ActiveRecord rounds decimals to the column scale before validation.
- Datetime validity is checked against the raw assigned value because invalid
  input is cast to `nil`.

## 4. What Was Removed

- The `validates` key is no longer supported in `property_metadata`. The
  PropertyMapping edit page no longer renders a validation editor, and the
  update controller drops any submitted `validates` key.
- `presence`, `numericality`, `inclusion`, `format`, and `length` are no longer
  read from metadata. The only validation is the column-type rule above.
- The old `DynamicValidationConcern` file and spec were removed.

## 5. Auto-Population

`before_validation :auto_populate_property_fields` still lives in
`PropertyMappingConcern` and still fills empty property slots with seed-time
random values on normal creates/updates. Imports set
`record.skip_property_auto_population = true` so blank CSV cells stay blank.

This is seed/demo behavior, not validation. Type validation runs after
auto-population and skips blank values.

## 6. Which Models Are Affected

All models that include `PropertyMappingConcern` (products, services, branches,
employees, customers, and the other dynamic resources) get the type validation
automatically.

## 7. File Reference

| File | Purpose |
|------|---------|
| `app/models/concerns/property_slot_validation_concern.rb` | The column-type validation implementation |
| `app/models/concerns/property_mapping_concern.rb` | Includes the validation concern and owns auto-population |
| `app/services/seed/category_service.rb` | Seeds property metadata without `validates` |
| `app/controllers/companies/property_mappings_controller.rb` | Merges edits while preserving unowned metadata keys and dropping `validates` |
| `app/services/imports/schema_resolver.rb` | Marks property headers as optional |
