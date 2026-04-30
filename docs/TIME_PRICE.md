# Skycom Time-Price System

## 1. Overview

Skycom implements a **shared, immutable reference pattern** for Time and Price. Instead of storing time ranges or monetary values directly in each business entity, we use reference models (`Period`, `Price`) that can be reused across thousands of records.

### The Problem

| Without Reference Models | With Reference Models |
|------------------------|----------------------|
| 10,000 companies store `expired_at` in their `attributes` jsonb → 10,000 duplicate timestamps | 10,000 companies reference 1 shared `Period` record |
| 10,000 products store `price` in a column → 10,000 duplicate prices | 10,000 products reference 1 shared `Price` record |
| No history tracking | Full history via immutable records |

### The Solution

1. **Immutable Records**: Once created, `Period` and `Price` records cannot be edited or deleted
2. **Find-or-Create**: Always use `find_or_create_by!` to reuse existing records

---

## 2. Models

### A. Period Model

**File**: `app/models/period.rb`

Stores time ranges with timezone support.

| Column | Type | Description |
|--------|------|-------------|
| `start_at` | datetime | Start of the period |
| `end_at` | datetime | End of the period (nullable for "until canceled") |
| `timezone` | enum | UTC offset (e.g., +7, -5) |

```ruby
# Example: Valid Period records
Period.find_or_create_by!(
  start_at: Time.current,
  end_at: 1.year.from_now,
  timezone: :plus_7
)

# "Forever" period
Period.find_or_create_by!(
  start_at: Time.current,
  end_at: nil,
  timezone: :plus_7
)
```

**Timezones Available** (defined in config):
```ruby
TIMEZONES = {
  minus_12: -12,
  minus_11: -11,
  # ... (+12 steps)
  plus_7: 7,
  # ...
  plus_12: 12
}
```

### B. Price Model

**File**: `app/models/price.rb`

Stores monetary values with currency support.

| Column | Type | Description |
|--------|------|-------------|
| `amount` | integer | Amount in cents (e.g., 9900 = $99.00) |
| `currency_code` | enum | Currency (usd, vnd, aud, eur) |

```ruby
# Example: Valid Price records
Price.find_or_create_by!(
  amount: 99_00,
  currency_code: :usd
)

Price.find_or_create_by!(
  amount: 2_500_000,
  currency_code: :vnd
)
```

**Accessing formatted value** (via Money-Rails):
```ruby
price = Price.last
price.value.format  # => "$99.00" or "2.500.000 VND"
```

---

## 3. Immutable Record Pattern

Both `Period` and `Price` include `ImmutableRecordConcern`:

**File**: `app/models/concerns/immutable_record_concern.rb`

```ruby
module ImmutableRecordConcern
  included do
    before_update :prevent_modification
    before_destroy :prevent_modification
  end

  private

  def prevent_modification
    raise ActiveRecord::ReadOnlyRecord, "#{self.class} is shared and immutable. You can only create new records."
  end
end
```

### Behavior

| Action | Result |
|--------|--------|
| Update record | Raises `ActiveRecord::ReadOnlyRecord` |
| Delete record | Raises `ActiveRecord::ReadOnlyRecord` |
| Create new record | ✅ Allowed |

### Workflow: Changing a Value

When you need to change a price or period:

```ruby
# WRONG: Update existing record
price = Price.find(id: "...")
price.update!(amount: 100_00)  # ❌ Raises ReadOnlyRecord

# CORRECT: Create new record
new_price = Price.find_or_create_by!(
  amount: 100_00,
  currency_code: :usd
)

# Update the reference
subscription.update!(price: new_price)  # ✅ OK - Subscription is mutable
```

---

## 4. Usage with Subscriptions

The Subscription model directly uses Period and Price:

```ruby
class Subscription < ApplicationRecord
  belongs_to :price
  belongs_to :period
end
```

### Creating a Subscription

```ruby
# 1. Find or create the Period (e.g., 1 year from now)
period = Period.find_or_create_by!(
  start_at: Time.current.beginning_of_day,
  end_at: Time.current.end_of_day + 1.year,
  timezone: :plus_7
)

# 2. Find or create the Price
price = Price.find_or_create_by!(
  amount: 99_00,
  currency_code: :usd
)

# 3. Create Subscription
subscription = Subscription.create!(
  price: price,
  period: period,
  # ... other fields
)
```

**Reading values:**
```ruby
subscription.price.value.format  # => "$99.00"
subscription.period.start_at     # => 2024-01-01
subscription.period.formatted_offset  # => "+07:00"
```

---

## 5. API Summary

### Creating Records

```ruby
# Always use find_or_create_by! to reuse
Period.find_or_create_by!(start_at: ..., end_at: ..., timezone: :plus_7)
Price.find_or_create_by!(amount: ..., currency_code: :usd)
```

### Reading Records

```ruby
subscription.price
subscription.period
```

### Immutability Rules

```ruby
# These will raise ActiveRecord::ReadOnlyRecord
period.update!(...)
price.destroy!
```

---

## 6. Database Schema

### periods table

```ruby
create_table "periods", id: :uuid do |t|
  t.datetime :start_at, null: false
  t.datetime :end_at
  t.integer :timezone, null: false
  t.index ["start_at", "end_at", "timezone"], unique: true
end
```

### prices table

```ruby
create_table "prices", id: :uuid do |t|
  t.integer :amount, null: false
  t.integer :currency_code, null: false
  t.index ["amount", "currency_code"], unique: true
end
```

---

## 7. Best Practices

1. **Always use `find_or_create_by!`** - Never create duplicate Period or Price records
2. **Use timezone enums** - Always specify the timezone explicitly
3. **Store amounts in cents** - Use integer `amount` (e.g., 9900 = $99.00)
4. **Handle nil periods** - Use `nil` end_at for "forever" periods

---

*End of documentation*