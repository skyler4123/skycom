# Skycom `store_accessor` Convention

## Rule
When a JSONB column stores multiple distinct values, use `store_accessor` to expose each value as a standard model attribute. Never dig into `metadata["key"]` manually in service or controller code.

## Why

Skycom consolidates all JSONB data into a single `metadata` column per table instead of spreading it across many separate JSONB columns. This keeps the schema lean — one JSONB column instead of three or more.

`store_accessor` is Rails' built-in bridge between Ruby attributes and JSONB keys. It generates standard getter, setter, and predicate methods so the rest of the codebase never needs to know it's backed by JSONB.

### Without `store_accessor`

```ruby
# Writing — must know metadata is a hash
txn.metadata["gateway_payload"] = { qr_string: "..." }
txn.save

# Reading — nil-safe digging
payload = txn.metadata["gateway_payload"] || {}
```

### With `store_accessor`

```ruby
store_accessor :metadata, :gateway_payload

# Writing — looks like a regular column
txn.update!(gateway_payload: { qr_string: "..." })

# Reading — looks like a regular column
payload = txn.gateway_payload || {}
```

The imperative is simple: **if you can write `model.some_key = value`, do not write `model.metadata["some_key"] = value`.**

## How to Use

### 1. Declare in the Model

Add one line at the top of the model, after the class declaration:

```ruby
class BillingTransaction < ApplicationRecord
  store_accessor :metadata, :gateway_payload
  # ...
end
```

Multiple keys can be declared at once:

```ruby
store_accessor :metadata, :gateway_payload, :callback_data, :provider_response
```

### 2. Use as Regular Attributes

Read and write the accessor just like any database column:

```ruby
# Write
txn.update!(gateway_payload: { qr_string: "000201010212..." })

# Read
payload = txn.gateway_payload || {}
payload["redirect_url"] if payload.present?

# Predicate
txn.gateway_payload?  # => true if metadata["gateway_payload"] is present
```

### 3. The JSONB Column Name

The first argument is always the JSONB column name (`:metadata` in Skycom). The remaining arguments are the keys within that JSONB document:

```ruby
store_accessor :metadata, :gateway_payload, :callback_data
#             ^column     ^key1           ^key2
```

## Where It's Used

| Model | JSONB Column | Accessors | Purpose |
|-------|-------------|-----------|---------|
| `BillingTransaction` | `metadata` | `gateway_payload` | Gateway response payload (QR string, redirect URL, etc.) |
| `PropertyMapping` | `metadata` | `properties` | Dynamic property metadata array (key, name, type, validates) |
| `TableConfig` | `metadata` | `columns` | Column display configuration (key, name, visible, width, align, etc.) |
| `Policy` | `metadata` | `tag_conditions` | ABAC permission conditions hash (key-value rules) |
| `CompanyDailyUsage` | `metadata` | `h0`..`h23` | Hourly credit usage (dynamically declared: `store_accessor :metadata, *(0..23).map { |i| "h#{i}" }`) |
| `CompanyMonthlyUsage` | `metadata` | `d1`..`d31` | Daily credit usage (dynamically declared: `store_accessor :metadata, *(1..31).map { |i| "d#{i}" }`) |

For any future JSONB-backed attribute, first check if the target model already uses `store_accessor`. If it does, add your key to the existing declaration. If it doesn't, add a new `store_accessor` line.

## Why Not a Separate Column?

Every separate JSONB column adds:
- Schema bloat (more columns per table)
- Migration overhead (add/drop columns for each new feature)
- Cognitive load (which JSONB column holds what?)

A single `metadata` column with `store_accessor` gives the same developer experience as separate columns without the schema cost. The trade-off: all keys share the same JSONB column, so large payloads can inflate the column size — keep individual payloads reasonable (<10KB each).
