# Skycom Payment Methods

## 1. Overview

Skycom has two distinct concepts around payments:

| Concept | Model | Scope | What It Is |
|---------|-------|-------|------------|
| **Payment Method** | `PaymentMethod` | **Global catalog** (no `company_id`) | Defines *how* money moves (Cash, MoMo, ZaloPay, VNPay, Credit Card, QR bank transfer, wallet auto-debit). Business type (`b2c`/`b2b`) and `payment_mode` (`qr`/`redirect`/`cash`) describe the gateway interaction. |
| **Payment Method Appointment** | `PaymentMethodAppointment` | **Per-tenant** (`company_id`) | Links a global `PaymentMethod` to a tenant scope — either a **Company** (default) or a **Branch** — via the polymorphic `appoint_to`. |

`PaymentMethodAppointment` is the bridge between the global catalog and a tenant's operational context. It controls which payment methods a company (or a specific branch of that company) can offer, plus the merchant credentials needed to actually collect money.

---

## 2. The Two Levels

Each appointment resolves to exactly one `appoint_to` target:

| Level | `appoint_to_type` | Created By | Purpose |
|-------|-------------------|------------|---------|
| **Company-level** | `"Company"` | `Company#setup_payment_method_appointments` (on company init) + the Payments dashboard | Default scope. Defines the payment methods available to the whole company for its market. |
| **Branch-level** | `"Branch"` | `Branch#after_create` (`initialize_payment_methods`) | Per-branch scope. Auto-inherited from the company's active company-level appointments; can hold branch-specific merchant credentials. |

### 2.1 Default `appoint_to` is the Company

The `before_validation :default_appoint_to_to_company` callback sets `appoint_to = company` when no `appoint_to` is supplied. This means any appointment created with just `company:` + `payment_method:` resolves to a company-level appointment automatically — no explicit `appoint_to` required.

```ruby
# Company-level (implicit — appoint_to defaults to the company)
PaymentMethodAppointment.create!(company: company, payment_method: pm_cash)

# Branch-level (explicit)
PaymentMethodAppointment.create!(
  appoint_to: branch, company: company, payment_method: pm_cash
)
```

---

## 3. Tenant Derivation (`company_id`)

Every appointment carries a `company_id` column (NOT NULL) that scopes the record to its tenant. It is derived automatically from `appoint_to` via an override of `SetDefaultCompanyConcern#set_default_company_from_resource`:

```ruby
def set_default_company_from_resource
  return if company.present?
  return if company_id.present?

  case appoint_to
  when Company
    self.company_id = appoint_to.id   # Company uses UUID PK (no company_id column)
  when Branch
    self.company_id = appoint_to.company_id
  end
end
```

> **Note:** `Company` uses a UUID primary key and has no `company_id` column, so the Company case reads `appoint_to.id` directly. Branch delegates to `appoint_to.company_id`.

---

## 4. Schema

**File**: `db/schema.rb:3059` (migration `db/migrate/20251123012320_create_payment_method_appointments.rb`)

```ruby
create_table "payment_method_appointments", id: :uuid do |t|
  t.uuid    "company_id", null: false          # Tenant scope (always)
  t.uuid    "payment_method_id", null: false   # FK to global PaymentMethod
  t.string  "appoint_to_type", null: false     # "Company" | "Branch"
  t.uuid    "appoint_to_id", null: false
  t.string  "appoint_from_type" / "appoint_from_id"   # optional
  t.string  "appoint_for_type" / "appoint_for_id"     # optional
  t.string  "appoint_by_type" / "appoint_by_id"       # optional
  t.string  "name"
  t.string  "description"
  t.string  "code"

  # --- Merchant Bank Account Credentials ---
  t.string  "merchant_number"    # Merchant's bank account number
  t.string  "merchant_name"      # Merchant's bank account holder name
  t.string  "merchant_id"        # Terminal / Merchant ID given by gateway

  # --- System Fields ---
  t.integer :lifecycle_status, index: true
  t.integer :workflow_status, index: true
  t.integer :business_type, index: true
  t.datetime :expiration_date
  t.jsonb    :metadata
  t.datetime :discarded_at, index: true
  t.string   :permission_resource_name

  t.timestamps
end

add_index :payment_method_appointments, [ :payment_method_id, :company_id ]
```

### Indexes

| Index | Purpose |
|-------|---------|
| `[payment_method_id, company_id]` | Fast lookup of a company's appointment for a given method |
| `appoint_to_type + appoint_to_id` | Polymorphic lookup (company-level / branch-level scopes) |
| `discarded_at` | Soft-delete filtering |

---

## 5. Model Behavior

**File**: `app/models/payment_method_appointment.rb`

### 5.1 Associations

```ruby
belongs_to :payment_method
belongs_to :company
belongs_to :appoint_to, polymorphic: true   # Company (default) or Branch
```

### 5.2 Scopes

| Scope | Where Clause | Use |
|-------|--------------|-----|
| `company_level` | `appoint_to_type: "Company"` | Company-wide methods (Payments dashboard index, branch inheritance source) |
| `branch_level` | `appoint_to_type: "Branch"` | Per-branch methods |

### 5.3 Validations

1. `name` — presence, max 255
2. `code` — presence, unique within the company
3. `business_type` — presence (`online` | `in_store` | `recurring`)
4. **`payment_method_country_matches_company`** — the appointment's `PaymentMethod` country must match the `Company` country (a US company can only link US payment methods)
5. **`payment_method_must_be_active_in_company`** — only for `appoint_to_type == "Branch"`:

```ruby
def payment_method_must_be_active_in_company
  return unless appoint_to_type == "Branch"
  return if PaymentMethodAppointment.company_level
    .where(company_id: company_id, payment_method_id: payment_method_id)
    .exists?(lifecycle_status: LIFECYCLE_STATUS.fetch(:active))

  errors.add(:appoint_to, "payment method is not active at the company level")
end
```

A branch appointment can only exist if the company has an **active** company-level appointment for the same company + payment method. This prevents branch inheritance from diverging from what the company has actually enabled.

### 5.4 Lifecycle Cascade

```ruby
after_update :cascade_lifecycle_to_branch_appointments, if: :company_level_lifecycle_change?

def company_level_lifecycle_change?
  persisted? && appoint_to_type == "Company" && saved_change_to_lifecycle_status?
end

def cascade_lifecycle_to_branch_appointments
  PaymentMethodAppointment.branch_level
    .where(company_id: company_id, payment_method_id: payment_method_id)
    .update_all(lifecycle_status: lifecycle_status)
end
```

When a **company-level** appointment's `lifecycle_status` changes (e.g., active → inactive), the status is mirrored to all **branch-level** appointments for the same company + payment method. The guard (`appoint_to_type == "Company"` + `saved_change_to_lifecycle_status?`) ensures:

- Branch-level updates never recurse (they don't match the guard).
- Only genuine lifecycle transitions propagate.

> **Note:** The cascade uses `update_all`, which bypasses ActiveRecord callbacks — this is intentional (no recursion, no per-row overhead).

---

## 6. Branch Integration

**File**: `app/models/branch.rb`

```ruby
has_many :payment_method_appointments, as: :appoint_to, dependent: :destroy
has_many :payment_methods, through: :payment_method_appointments

after_create :initialize_payment_methods
```

When a branch is created, `initialize_payment_methods` copies every **active** company-level appointment to the new branch:

```ruby
def initialize_payment_methods
  return unless company

  company.payment_method_appointments.company_level
    .where(lifecycle_status: LIFECYCLE_STATUS.fetch(:active))
    .find_each do |appointment|
      PaymentMethodAppointment.find_or_create_by!(
        appoint_to: self,
        payment_method: appointment.payment_method,
        company: company
      ) do |a|
        a.name = "#{appointment.name} for #{name}"
        a.code = "#{appointment.code}-BR-#{SecureRandom.hex(3).upcase}"
        a.business_type = appointment.business_type
        a.lifecycle_status = :active
        a.workflow_status = appointment.workflow_status
        a.merchant_number = appointment.merchant_number
        a.merchant_name = appointment.merchant_name
        a.merchant_id = appointment.merchant_id
      end
    end
end
```

### Inheritance Rules

| Attribute | Inherited? | Notes |
|-----------|-----------|-------|
| `payment_method` | ✅ | Same global method |
| `name` | ✅ (suffixed) | `"<company name> for <branch name>"` |
| `code` | ✅ (suffixed) | `"<company code>-BR-<hex>"` — unique per branch |
| `business_type` | ✅ | Copied from company appointment |
| `workflow_status` | ✅ | Copied from company appointment |
| `merchant_number` / `merchant_name` / `merchant_id` | ✅ | Copied (branch can override later) |
| `lifecycle_status` | ✅ | Set to `:active` on copy |

Inactive company-level appointments are **not** copied to new branches. If the company later activates the method, the existing branches will not auto-create it — new branches inherit it; existing branches would need the appointment created explicitly (or via re-sync).

---

## 7. Company Integration

**File**: `app/models/company.rb:204`

```ruby
has_many :payment_method_appointments, as: :appoint_to, dependent: :destroy
has_many :payment_methods, through: :payment_method_appointments

def setup_payment_method_appointments
  country_payment_methods = PaymentMethod.where(country: country_before_type_cast)
  country_payment_methods.each do |pm|
    PaymentMethodAppointment.find_or_create_by!(
      appoint_to: self,   # explicit — resolves to company-level
      company: self,
      payment_method: pm
    ) do |a|
      a.name = "#{pm.name} for #{name}"
      a.code = "#{pm.code}-#{SecureRandom.hex(4).upcase}"
      a.business_type = :in_store
      a.lifecycle_status = if pm.strategy_cash? || pm.strategy_mock_qr_gateway? || pm.strategy_mock_redirect_gateway?
        :active
      else
        :inactive
      end
      apply_merchant_identity(a, pm)   # private — placeholder merchant identity per payment_mode
    end
  end
end
```

Called automatically on company creation. Seeds one appointment per country-matching `PaymentMethod`, with cash/mock strategies started `active` and external gateways started `inactive` (until the owner configures merchant credentials).

### 7.1 Merchant Identity Seeding (init-time placeholders)

`apply_merchant_identity` fills placeholder merchant credentials on every appointment at creation, so POS/gateway flows work out of the box (owners replace them later via the Payments dashboard):

| payment_mode | merchant_number | merchant_name | merchant_id |
|--------------|-----------------|---------------|-------------|
| `qr` | generated 10-digit account number | company name | `T-<hex4>` |
| `redirect` | — | — | `MID-<hex4>` |
| `cash` | — | — | — |

Branches inherit these values through copy-on-create (`Branch#initialize_payment_methods` copies all three merchant columns). The POS pay pipeline (`OrderProcessingV1::InitiatePaymentService`) forwards them to the gateway so the mock bank can embed merchant identity in generated QR strings (`ACC:`/`NAME:`/`MCC:` segments).

---

## 8. Controller Scoping

**File**: `app/controllers/companies/payment_method_appointments_controller.rb`

```ruby
format.json do
  appointments = current_company.payment_method_appointments.company_level.includes(:payment_method)
  # ...
end
```

The Payments dashboard **index is scoped to `company_level`** — branch-level appointments are management detail and never listed in the dashboard. `edit`/`update` still resolve appointments within `current_company` scope.

### 8.1 Branch Payment Methods Modal

Branch pages (show + edit) expose a **"Payment Methods"** button that opens a modal listing the branch's appointments.

- **Trigger**: `app/javascript/controllers/companies/branches/show_controller.js` + `edit_controller.js` → `openPaymentMethodsModal()`
- **Controller**: `app/javascript/controllers/companies/branches/payment_method_appointments_modal_controller.js`
- **Index request**: `GET /companies/:id/payment_method_appointments?branch_id=<uuid>` — the `index` action scopes to `branch.payment_method_appointments` when `branch_id` is present, and each item includes `company_level_active` (whether the company has an active company-level appointment for that method).

The modal shows each appointment with a lifecycle toggle. When `company_level_active` is `false` (the company has disabled the method company-wide), the toggle is rendered **disabled** with an "Enable at company level first" hint — the model validation `payment_method_must_be_active_in_company` would reject a branch activation anyway, so the UI prevents the attempt up front.

- **Toggle request**: `PATCH /companies/:id/payment_method_appointments/:id` with `{ payment_method_appointment: { lifecycle_status: "active"|"inactive" } }` — uses `reloadThenToast()` so the branch page refreshes and reflects the new state.

---

## 9. Design Rules / Invariants

1. **`appoint_to` is always resolved** — every appointment is company-level or branch-level; never nil.
2. **`company_id` is always derived** — from `appoint_to`, never contradictory to it.
3. **A branch appointment requires an active company-level appointment** for the same method — branch methods can't exist if the company hasn't enabled the method.
4. **Company lifecycle flips propagate to branches** — enabling/disabling a method at company level mirrors to all branches of that company.
5. **The dashboard is company-level only** — branch assignments are an implementation detail, not a dashboard concern.
6. **Branch inheritance is a copy-on-create snapshot** — subsequent company changes don't retroactively add methods to existing branches (only lifecycle status cascades).

---

## 10. File Reference

| File | Purpose |
|------|---------|
| `app/models/payment_method.rb` | Global payment gateway registry (b2b + b2c, payment_mode, strategy) |
| `app/models/payment_method_appointment.rb` | Polymorphic Company/Branch link + tenant derivation + lifecycle cascade |
| `app/models/branch.rb` | `as: :appoint_to` association + `after_create :initialize_payment_methods` |
| `app/models/company.rb` | `as: :appoint_to` association + `setup_payment_method_appointments` |
| `app/services/seed/payment_method_appointment_service.rb` | Seed service (accepts `appoint_to:`, defaults to company) |
| `app/controllers/companies/payment_method_appointments_controller.rb` | Payments dashboard (index scoped to `company_level`; `branch_id` param scopes to a branch) |
| `app/javascript/controllers/companies/branches/payment_method_appointments_modal_controller.js` | Branch payment methods modal (list + lifecycle toggles) |
| `db/migrate/20251123012320_create_payment_method_appointments.rb` | Schema (polymorphic + merchant fields) |
| `db/schema.rb:3059` | Current schema |
| `spec/models/payment_method_appointment_spec.rb` | Model specs (23 examples: defaults, scopes, validations, cascade) |
| `spec/models/branch_spec.rb` | Branch inheritance specs |
| `spec/requests/companies/payment_method_appointments_controller_spec.rb` | Request specs (incl. branch-excluded-from-index) |
| `spec/features/companies/payment_method_appointments/index_spec.rb` | Feature specs (dashboard) |

---

*See also: `docs/MONEY_FLOW.md` §7 (PaymentMethod: The Global Bridge), `docs/MODEL_CALLBACKS.md` (Branch `after_create` + PaymentMethodAppointment callbacks).*
