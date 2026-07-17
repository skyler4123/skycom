# Skycom Address System (Legacy: Period-Price-Address)

> **⚠️ 2026-07-17:** Price and Period models have been removed. Product price is now stored directly via `price_cents` column with money-rails. The Address system continues unchanged. See `docs/ADDRESS.md` for the current Address documentation.

## 1. Overview

Skycom implements a **shared, immutable reference pattern** for Period, Price, and Address. These are reference models that can be reused across thousands of business entities using many-to-many associations via appointment join tables.

### The Pattern

| Reference Model | Purpose | Example Usage |
|----------------|---------|---------------|
| **Period** | Time ranges with timezone | Subscription validity, product effective dates |
| **Price** | Monetary values with currency | Product prices, order totals |
| **Address** | Physical locations | Company HQ, branch locations, shipping addresses |

### Architecture

Each reference model uses:
1. **Immutable Records** - Cannot be modified once created
2. **Appointment Join Tables** - Many-to-many relationship with business entities
3. **Setter Methods** - Convenient syntax like `product.price = {...}`

---

## 2. The Concerns

Skycom provides three concerns that you can include in any model to add Period, Price, and Address functionality:

### A. PeriodConcern

**File**: `app/models/concerns/period_concern.rb`

Manages time ranges with timezone support.

```ruby
class Product < ApplicationRecord
  include PeriodConcern
end
```

**Associations added:**
```ruby
has_many :period_appointments, as: :appoint_to, dependent: :destroy
has_many :periods, through: :period_appointments
has_one :current_period_appointment, -> { where(lifecycle_status: :active) }
has_one :db_period, through: :current_period_appointment, source: :period
```

**Getter:**
```ruby
product.current_period  # Returns cached Period record
product.periods          # All periods (including archived)
```

**Setter:**
```ruby
product.period = {
  start_at: Time.current,
  end_at: 1.month.from_now,
  timezone: :plus_7
}
```

### B. PriceConcern

**File**: `app/models/concerns/price_concern.rb`

Manages monetary values with currency support.

```ruby
class Product < ApplicationRecord
  include PriceConcern
end
```

**Associations added:**
```ruby
has_many :price_appointments, as: :appoint_to, dependent: :destroy
has_many :prices, through: :price_appointments
has_one :current_price_appointment
has_one :db_price, through: :current_price_appointment, source: :price
```

**Getter:**
```ruby
product.price  # Returns Money object (e.g., $99.00)
```

**Setter:**
```ruby
# Accepts decimal amounts
product.price = { amount: 99.00, currency_code: :usd }
product.price = { amount: 2500000, currency_code: :vnd }
```

### C. AddressConcern

**File**: `app/models/concerns/address_concern.rb`

Manages physical addresses.

```ruby
class Company < ApplicationRecord
  include AddressConcern
end
```

**Associations added:**
```ruby
has_many :address_appointments, as: :appoint_to, dependent: :destroy
has_many :addresses, through: :address_appointments
has_one :current_address_appointment
has_one :db_address, through: :current_address_appointment, source: :address
```

**Getter:**
```ruby
company.address  # Returns Address record
```

**Setter:**
```ruby
company.address = {
  line_1: "123 Main Street",
  line_2: "Suite 100",
  city: "Ho Chi Minh City",
  state_or_province: "Vietnam",
  country_code: :vn,
  postal_code: "700000"
}
```

---

## 3. How It Works

### Setter Method Pattern

Each concern provides a setter that accepts a hash and handles the logic:

```ruby
# What happens when you call:
product.price = { amount: 99.00, currency_code: :usd }

# Internally:
# 1. Convert amount to cents (9900)
# 2. Find or create immutable Price record
# 3. Archive old price appointment of same business_type
# 4. Create new PriceAppointment linking product to price
# 5. Touch product to invalidate cache
```

### Find-or-Create + Archive

The setter uses a two-step pattern:

1. **Find or Create** - Look up existing Period/Price/Address by unique attributes. If exists, reuse it. If not, create new.

2. **Archive Old** - Before creating new appointment, archive any existing appointment of the same `business_type`. This preserves history while keeping current reference.

```ruby
# PriceConcern#attach_price implementation
def attach_price(amount:, currency_code: :usd, **options)
  # 1. Find or create immutable Price (reuses existing if identical)
  target_price = Price.find_or_create_by!(
    amount: amount,
    currency_code: currency_code.to_s.downcase.to_sym
  )

  self.transaction do
    # 2. Archive old appointment of same business_type
    b_type = options[:business_type] || :base
    price_appointments.where(business_type: b_type)
                      .where.not(lifecycle_status: :archived)
                      .update_all(lifecycle_status: :archived)

    # 3. Create new appointment
    price_appointments.create!(
      price: target_price,
      lifecycle_status: :active,
      business_type: b_type
    )

    self.touch if self.persisted?
  end
end
```

---

## 4. Usage Examples

### Product with Price

```ruby
product = Product.create!(name: "Premium Widget")

# Set price using setter
product.price = { amount: 99.99, currency_code: :usd }

# Read price (returns Money object)
product.price.format  # => "$99.99"

# Update price (automatically archives old, creates new)
product.price = { amount: 79.99, currency_code: :usd }

# Both prices exist - history preserved
product.prices.count  # => 2
product.prices.where(lifecycle_status: :archived).count  # => 1
```

### Subscription with Period and Price

```ruby
subscription = Subscription.create!(name: "Annual Plan")

# Set period
subscription.period = {
  start_at: Time.current.beginning_of_day,
  end_at: 1.year.from_now,
  timezone: :plus_7
}

# Set price
subscription.price = {
  amount: 299.00,
  currency_code: :usd
}

# Read values
subscription.period.start_at    # => 2024-01-01 00:00:00
subscription.period.end_at     # => 2025-01-01 00:00:00
subscription.price.format      # => "$299.00"
```

### Company with Address

```ruby
company = Company.create!(name: "Acme Corp")

# Set address
company.address = {
  line_1: "456 Tech Boulevard",
  city: "San Francisco",
  state_or_province: "CA",
  country_code: :us,
  postal_code: "94105"
}

# Read address
company.address.line_1         # => "456 Tech Boulevard"
company.address.city           # => "San Francisco"
```

---

## 5. Business Types

Each appointment can have a `business_type` to categorize different uses:

| Concern | Default business_type | Other Examples |
|---------|----------------------|----------------|
| PeriodConcern | `:base` | `:subscription`, `:warranty`, `:effective` |
| PriceConcern | `:base` | `:sale`, `:retail`, `:wholesale` |
| AddressConcern | `:office` | `:billing`, `:shipping`, `:headquarters` |

```ruby
# Using custom business_type
product.price = {
  amount: 50.00,
  currency_code: :usd
}
# Creates PriceAppointment with business_type: :base

product.price = {
  amount: 45.00,
  currency_code: :usd,
  business_type: :wholesale
}
# Archives :wholesale appointment, creates new one
```

---

## 6. Immutable Record Pattern

Period, Price, and Address records are **immutable** - they cannot be modified or deleted after creation. This ensures:
- **Deduplication** - Same values reuse same records
- **Audit Trail** - Historical data preserved
- **Data Integrity** - No accidental modifications

**File**: `app/models/concerns/immutable_record_concern.rb`

```ruby
module ImmutableRecordConcern
  included do
    before_update :prevent_modification
    before_destroy :prevent_modification
  end

  private

  def prevent_modification
    raise ActiveRecord::ReadOnlyRecord, "#{self.class} is shared and immutable."
  end
end
```

### Behavior

| Action | Result |
|--------|--------|
| Update Period/Price/Address | Raises `ActiveRecord::ReadOnlyRecord` |
| Delete Period/Price/Address | Raises `ActiveRecord::ReadOnlyRecord` |
| Create new record | ✅ Allowed |

### Changing Values

To change a value, create a new reference and update the appointment:

```ruby
# WRONG - trying to modify immutable record
price = Price.find(id: "...")
price.update!(amount: 100_00)  # ❌ Raises ReadOnlyRecord

# CORRECT - create new price and update appointment
product.price = { amount: 100.00, currency_code: :usd }  # ✅ Creates new Price + updates appointment
```

---

## 7. Database Schema

### Reference Tables

```ruby
# Periods - time ranges
create_table "periods", id: :uuid do |t|
  t.datetime :start_at, null: false
  t.datetime :end_at
  t.integer :timezone, null: false
  t.index ["start_at", "end_at", "timezone"], unique: true
end

# Prices - monetary values
create_table "prices", id: :uuid do |t|
  t.integer :amount, null: false
  t.integer :currency_code, null: false
  t.index ["amount", "currency_code"], unique: true
end

# Addresses - physical locations
create_table "addresses", id: :uuid do |t|
  t.string :line_1, null: false
  t.string :line_2
  t.string :city, null: false
  t.string :state_or_province
  t.string :postal_code
  t.integer :country_code
  t.string :fingerprint, null: false
  t.index ["fingerprint"], unique: true
end
```

### Appointment Join Tables

```ruby
# PeriodAppointment - links any resource to a Period
create_table "period_appointments", id: :uuid do |t|
  t.references :period, null: false, type: :uuid
  t.references :appoint_to, polymorphic: true, null: false
  t.integer :business_type
  t.integer :lifecycle_status
  t.integer :workflow_status
  t.datetime :appoint_from
  t.datetime :appoint_for
  t.references :appoint_by, polymorphic: true
  t.string :name
  t.text :description
end

# PriceAppointment - links any resource to a Price
create_table "price_appointments", id: :uuid do |t|
  t.references :price, null: false, type: :uuid
  t.references :period, type: :uuid  # Optional linked period
  t.references :appoint_to, polymorphic: true, null: false
  t.integer :business_type
  t.integer :lifecycle_status
  t.integer :workflow_status
end

# AddressAppointment - links any resource to an Address
create_table "address_appointments", id: :uuid do |t|
  t.references :address, null: false, type: :uuid
  t.references :appoint_to, polymorphic: true, null: false
  t.integer :business_type
  t.integer :lifecycle_status
  t.integer :workflow_status
end
```

---

## 8. Best Practices

1. **Use Setter Methods** - Always use `product.price = {...}` instead of manually creating appointments
2. **Use find_or_create_by!** - The concerns handle this automatically; never manually create Period/Price/Address records
3. **Store amounts in cents** - The PriceConcern converts decimal to cents internally (e.g., $99.99 → 9999)
4. **Specify business_type** - Use business_type to distinguish between different uses (retail vs wholesale prices)
5. **Handle nil end_at** - Use `nil` end_at for "forever" periods (e.g., permanent subscription)
6. **Use timezone enums** - Always specify timezone explicitly (e.g., `:plus_7`, `:minus_5`)

---

## 9. Including Concerns

To add Period/Price/Address to any model:

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  include PriceConcern
  include PeriodConcern
  # AddressConcern optional - only if product needs physical location
end

# app/models/company.rb
class Company < ApplicationRecord
  include AddressConcern
  # PeriodConcern if company has validity period
  # PriceConcern if company has subscription fee
end
```

The concerns automatically add all necessary associations and setter methods.

---

*End of documentation*