# Skycom Time-Price System

## 1. Overview

Skycom implements a **shared, immutable reference pattern** for Time and Price. Instead of storing time ranges or monetary values directly in each business entity, we use reference models (`Period`, `Price`, `PeriodPrice`) that can be reused across thousands of records.

### The Problem

| Without Reference Models | With Reference Models |
|------------------------|----------------------|
| 10,000 companies store `expired_at` in their `attributes` jsonb → 10,000 duplicate timestamps | 10,000 companies reference 1 shared `Period` record |
| 10,000 products store `price` in a column → 10,000 duplicate prices | 10,000 products reference 1 shared `Price` record |
| No history tracking | Full history via immutable records |

### The Solution

1. **Immutable Records**: Once created, `Period` and `Price` records cannot be edited or deleted
2. **Find-or-Create**: Always use `find_or_create_by!` to reuse existing records
3. **Polymorphic Associations**: `PeriodPrice` links any resource to time and price

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

### C. PeriodPrice Model

**File**: `app/models/period_price.rb`

Join table that combines Period + Price for any resource.

| Column | Type | Description |
|--------|------|-------------|
| `period_priceable_type` | string | Polymorphic resource (e.g., "Subscription") |
| `period_priceable_id` | uuid | ID of the resource |
| `period_id` | uuid | Reference to Period |
| `price_id` | uuid | Reference to Price |

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

# Update the PeriodPrice reference
period_price.update!(price: new_price)  # ✅ OK - PeriodPrice is mutable
```

---

## 4. Adding Time-Price to Any Resource

### A. Include PeriodPriceConcern

Add the concern to any model that needs time-based pricing:

```ruby
# app/models/subscription.rb
class Subscription < ApplicationRecord
  include PeriodPriceConcern
end
```

This adds:

```ruby
has_many :period_prices, as: :period_priceable
has_many :periods, through: :period_prices
has_many :prices, through: :period_prices
```

### B. API Methods

| Method | Description | Example Return |
|--------|-------------|----------------|
| `period_price_at(time)` | Find PeriodPrice active at a specific time | `PeriodPrice` object |
| `current_period_price` | Get the active PeriodPrice (now) | `PeriodPrice` object |
| `current_price` | Get the active Price | `Price` object |
| `current_period` | Get the active Period | `Period` object |

---

## 5. Usage Examples

### Example A: Subscription (Simple Time + Price)

A subscription has a fixed period and price:

```ruby
# 1. Find or create the Period (e.g., 1 year from now)
period = Period.find_or_create_by!(
  start_at: Time.current,
  end_at: 1.year.from_now,
  timezone: :plus_7
)

# 2. Find or create the Price
price = Price.find_or_create_by!(
  amount: 99_00,
  currency_code: :usd
)

# 3. Link to Subscription
subscription.period_prices.find_or_create_by!(
  period: period,
  price: price
)
```

**Checking current price:**
```ruby
subscription.current_price.value.format  # => "$99.00"
subscription.current_period.start_at    # => 2024-01-01
```

### Example B: Hotel Pricing (Multiple Periods)

Hotels charge different prices for different seasons:

```ruby
# Off-peak: Jan - Mar
off_peak_period = Period.find_or_create_by!(
  start_at: Date.new(2025, 1, 1),
  end_at: Date.new(2025, 3, 31),
  timezone: :plus_7
)
off_peak_price = Price.find_or_create_by!(
  amount: 50_00,
  currency_code: :usd
)

# Peak: Jul - Aug
peak_period = Period.find_or_create_by!(
  start_at: Date.new(2025, 7, 1),
  end_at: Date.new(2025, 8, 31),
  timezone: :plus_7
)
peak_price = Price.find_or_create_by!(
  amount: 120_00,
  currency_code: :usd
)

# Holiday: Dec 20 - Jan 5
holiday_period = Period.find_or_create_by!(
  start_at: Date.new(2025, 12, 20),
  end_at: Date.new(2026, 1, 5),
  timezone: :plus_7
)
holiday_price = Price.find_or_create_by!(
  amount: 200_00,
  currency_code: :usd
)

# Link all to Room model
room = Room.find(id: "...")
room.period_prices.find_or_create_by!(period: off_peak_period, price: off_peak_price)
room.period_prices.find_or_create_by!(period: peak_period, price: peak_price)
room.period_prices.find_or_create_by!(period: holiday_period, price: holiday_price)
```

**Getting price for a specific date:**
```ruby
room.period_price_at(Date.new(2025, 2, 15))  # => off-peak ($50)
room.period_price_at(Date.new(2025, 7, 4))     # => peak ($120)
room.period_price_at(Date.new(2025, 12, 25))     # => holiday ($200)
```

---

## 6. API Summary

### Creating Records

```ruby
# Always use find_or_create_by! to reuse
Period.find_or_create_by!(start_at: ..., end_at: ..., timezone: :plus_7)
Price.find_or_create_by!(amount: ..., currency_code: :usd)
PeriodPrice.find_or_create_by!(period_priceable: resource, period: p, price: c)
```

### Reading Records

```ruby
# Current values
resource.current_price
resource.current_period

# Values at specific time
resource.period_price_at(date)
resource.current_period_price
```

### Immutability Rules

```ruby
# These will raise ActiveRecord::ReadOnlyRecord
period.update!(...)
price.destroy!
period_price.update!(period: new_period)  # Period is immutable, PeriodPrice is mutable
```

---

## 7. Database Schema

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

### period_prices table

```ruby
create_table "period_prices", id: :uuid do |t|
  t.uuid :period_id, null: false
  t.uuid :price_id, null: false
  t.references :period_priceable, polymorphic: true, null: false
end
```

---

## 8. Best Practices

1. **Always use `find_or_create_by!`** - Never create duplicate Period or Price records
2. **PeriodPrice is mutable** - Only the join records can be updated
3. **Use timezone enums** - Always specify the timezone explicitly
4. **Store amounts in cents** - Use integer `amount` (e.g., 9900 = $99.00)
5. **Check current values** - Use `current_price` / `current_period` for display
6. **Handle nil periods** - Use `nil` end_at for "forever" periods

---

*End of documentation*