# Skycom Address System

## 1. Overview

Skycom implements a **shared, immutable reference pattern** for Addresses. Instead of storing address fields directly in each business entity, we use a single `Address` model that can be reused across thousands of records (companies, branches, employees, customers, etc.).

### The Problem

| Without Shared Addresses | With Shared Address |
|---------------------|-----------------|
| 10,000 companies store address in `attributes` jsonb → duplicates | 10,000 companies reference 1 shared `Address` record |
| No deduplication | Fingerprint-based deduplication |
| No address history | Immutable records preserve history |

### The Solution

1. **Immutable Records**: Once created, `Address` records cannot be edited or deleted
2. **Fingerprint Deduplication**: SHA256 hash auto-generated from address fields
3. **Polymorphic Associations**: `AddressAppointment` links any resource to an address

---

## 2. Address Model

**File**: `app/models/address.rb`

### Columns

| Column | Type | Description |
|--------|------|-------------|
| `line_1` | string | Street address (required) |
| `line_2` | string | Apartment, suite, unit, etc. |
| `city` | string | City (required) |
| `state_or_province` | string | State or province |
| `postal_code` | string | ZIP or postal code |
| `country_code` | enum | 2-letter ISO country code (e.g., US, VN) |
| `fingerprint` | string | SHA256 hash for deduplication (auto-generated) |

### Model Relationships

```ruby
has_many :address_appointments, dependent: :destroy
has_many :users, through: :address_appointments, source: :appoint_to, source_type: "User"
has_many :companies, through: :address_appointments, source: :appoint_to, source_type: "Company"
has_many :branches, through: :address_appointments, source: :appoint_to, source_type: "Branch"
has_many :employees, through: :address_appointments, source: :appoint_to, source_type: "Employee"
has_many :customers, through: :address_appointments, source: :appoint_to, source_type: "Customer"
has_many :departments, through: :address_appointments, source: :appoint_to, source_type: "Department"
```

---

## 3. Fingerprint Deduplication

### How It Works

Before validation, a fingerprint is auto-generated from address fields:

```ruby
# Raw string before hashing: "123 main st|apt 4|new york|ny|10001|us"
# Fingerprint: SHA256 hash of lowercase, stripped components
```

**Example:**
```
Input: "123 Main St", "Apt 4", "New York", "NY", "10001", "US"
Fingerprint: "a1b2c3d4..." (unique hash)
```

### Why Fingerprint?

1. **Case insensitive**: "Main St" and "main st" → same fingerprint
2. **Whitespace insensitive**: "Main St" and "Main St " → same fingerprint
3. **Unique constraint**: Only one Address record per unique fingerprint
4. **Automatic**: Generated via `before_validation` callback

---

## 4. Immutable Record Pattern

`Address` includes `ImmutableRecordConcern`:

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

---

## 5. Usage Examples

### Basic: Find or Create Address

```ruby
# Find existing or create new address
address = Address.find_or_create_by!(
  line_1: "123 Le Loi",
  city: "District 1",
  state_or_province: "Ho Chi Minh City",
  country_code: :vn
)

# Running the same code again returns the EXISTING record (fingerprint match)
same_address = Address.find_or_create_by!(
  line_1: "123 le loi",  # lowercase - same fingerprint
  city: "District 1",
  state_or_province: "Ho Chi Minh City",
  country_code: "vn"
)

same_address.id == address.id  # => true
```

### With Seed Service

```ruby
# Using Seed::AddressService for test data
Seed::AddressService.create(
  line_1: "456 Tech Street",
  city: "San Francisco",
  state_or_province: "CA",
  postal_code: "94105",
  country_code: :us
)
```

### Direct Field Access

```ruby
address = Address.last
address.line_1              # => "123 Main St"
address.city               # => "New York"
address.state_or_province    # => "NY"
address.postal_code        # => "10001"
address.country_code      # => :us
address.fingerprint    # => "a1b2c3d4..."
```

---

## 6. Linking to Resources

### AddressAppointment Model

**File**: `app/models/address_appointment.rb`

Polymorphic join table that links any resource to an address:

| Column | Type | Description |
|--------|------|-------------|
| `appoint_to_type` | string | Polymorphic resource (e.g., "Company") |
| `appoint_to_id` | uuid | ID of the resource |
| `address_id` | uuid | Reference to Address |
| `business_type` | enum | Type of appointment (e.g., :billing, :shipping) |
| `lifecycle_status` | enum | Active/inactive |

### Linking Example

```ruby
# Link a company to an address
company = Company.find(id: "...")

AddressAppointment.find_or_create_by!(
  appoint_to: company,
  address: address,
  business_type: :billing
)
```

---

## 7. Database Schema

### addresses table

```ruby
create_table "addresses", id: :uuid do |t|
  t.string "line_1", null: false
  t.string "line_2"
  t.string "city", null: false
  t.string "state_or_province"
  t.string "postal_code"
  t.integer "country_code"
  t.string "fingerprint", null: false
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["fingerprint"], name: "index_addresses_on_fingerprint", unique: true
end
```

### address_appointments table

```ruby
create_table "address_appointments", id: :uuid do |t|
  t.uuid :address_id, null: false
  t.references :appoint_to, polymorphic: true, null: false
  t.integer :business_type
  t.integer :lifecycle_status
  t.integer :workflow_status
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

---

## 8. Best Practices

1. **Always use `find_or_create_by!`** - Never create duplicate addresses
2. **Let fingerprint handle deduplication** - Don't manually set the fingerprint
3. **Use country_code enum** - Validates 2-letter ISO codes
4. **Address is immutable** - When address changes, create a new record
5. **Use AddressAppointment for links** - Don't add address_id directly to resources
6. **Handle nil fields gracefully** - line_2, state, postal_code can be nil

---

## 9. Comparison with Time-Price

| Feature | Address | Period | Price |
|---------|---------|--------|-------|
| Deduplication | Fingerprint (SHA256) | (start_at, end_at, timezone) | (amount, currency_code) |
| Join table | AddressAppointment | PeriodPrice | PeriodPrice |
| Immutable | Yes | Yes | Yes |
| Use case | Physical locations | Time ranges | Monetary values |

---

*End of documentation*