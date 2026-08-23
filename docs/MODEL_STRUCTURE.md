# Skycom Model Structure Convention

> **Purpose**: Every `app/models/*.rb` file follows one canonical section order.
> This doc is the single source of truth — AI agents and developers MUST follow it
> when creating or editing any model.

---

## 1. Canonical Section Order

```ruby
# frozen_string_literal: true  # if present — keep as first line

class Model < ApplicationRecord
  # 1. Concerns — all `include` / `extend` / `prepend`, EXACT relative order preserved
  include FooConcern
  include BarConcern

  # 2. Constants — UPPER_SNAKE, class_attribute, nested error classes
  MY_CONSTANT = 123
  class_attribute :skip_init, default: false
  class MyError < StandardError; end

  # 3. Attributes — attribute macros
  attribute :permission_resource_name, :string, default: -> { self.name }
  store_accessor :metadata, :some_key
  normalizes :email, with: -> { _1.strip.downcase }

  # 4. Enums — ALL enums in ONE group
  # --- Enums ---
  enum :country, COUNTRY_CODES, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :business_type, { foo: 0, bar: 1 }

  # 5. Other macros — monetize, kredis_*, has_secure_password, generates_token_for
  monetize :price_cents, as: "price"
  kredis_counter :credit_usage
  kredis_integer :available_counter
  has_secure_password
  generates_token_for :email_verification, expires_in: 2.days do ... end

  # 6. Associations — belongs_to → has_one → has_many (relative order preserved inside each)
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  has_one :profile
  has_many :items, dependent: :destroy

  # 7. Scopes
  scope :active, -> { where(lifecycle_status: :active) }

  # 8. Validations — validates / validate / normalizes (if not in Attributes)
  # --- Validations ---
  validates :name, presence: true
  validate :custom_check

  # 9. Callbacks — before_* / after_* / around_*
  before_validation :do_something, on: :create
  after_create :initialize_things
  before_discard :prevent_if_owner

  # 10. Public instance methods
  def foo
  end

  private

  # 11. Private methods
  def bar
  end
end
```

---

## 2. Section Details

| # | Section | What goes here | Comment header |
|---|---------|----------------|----------------|
| 1 | **Concerns** | `include`, `extend`, `prepend` only. Keep existing relative order — this is the method-resolution order. | None (top of class) |
| 2 | **Constants** | `CONST =`, `class_attribute`, nested `class X < StandardError` | None |
| 3 | **Attributes** | `attribute`, `store_accessor`, `normalizes`, `class_attribute` if not in Constants | None |
| 4 | **Enums** | Every `enum` declaration — consolidated into one block | `# --- Enums ---` |
| 5 | **Other macros** | `monetize`, `kredis_counter`, `kredis_integer`, `has_secure_password`, `generates_token_for`, `has_paper_trail` | None |
| 6 | **Associations** | `belongs_to` then `has_one` then `has_many` / `has_and_belongs_to_many`. Preserve relative order inside each sub-group (destroy cascades fire in declaration order). | `# --- Associations ---` |
| 7 | **Scopes** | `scope` | None |
| 8 | **Validations** | `validates`, `validate`, `validates_associated` | `# --- Validations ---` |
| 9 | **Callbacks** | `before_validation`, `before_create`, `after_create`, `after_commit`, `before_discard`, `after_touch`, `belongs_to touch: true` is an association, not a callback | None |
| 10 | **Public methods** | `def` above `private` | None |
| 11 | **Private** | `private` keyword then private `def`s | `private` |

**Blank lines**: One blank line between sections. No blank line needed between consecutive lines inside the same section.

---

## 3. Safety Rules (Behavior Preservation)

Reordering MUST NOT change runtime behavior:

| Rule | Why | Action |
|------|-----|--------|
| **Include order is frozen** | Later `include` wins on method conflicts; inclusion order defines MRO | Never reorder `include` lines relative to each other |
| **Same-type callback order is frozen** | `before_validation :a` then `before_validation :b` → `a` runs first | Preserve relative order among callbacks of the same type |
| **`has_many` order is frozen** | `dependent: :destroy` fires in declaration order; FK constraints can make order matter | Preserve relative order inside each association sub-group |
| **Order-coupled files are exceptions** | Example: `Stock` registers `before_validation :inherit_category_from_product` *before* `include PropertyMappingConcern` — moving the `include` above the callback flips which `before_validation` runs first and can break category-less stock creation. | Keep the effective hook-registration order; add a one-line `# NOTE: ...` comment explaining the exception |

General principle: **behavior preservation beats grouping**. When in doubt, keep the original relative order and document the exception.

---

## 4. Comment Handling

- Every `# --- Section ---` comment moves **with** its block.
- Commented-out code stays adjacent to its live counterpart (e.g., disabled enum validations in `Branch` stay under `Validations`).
- Decorative divider lines with no associated code (e.g., lone `# ----` at EOF) may be removed — they add noise after reordering.
- File-path header comments (`# app/models/foo.rb`) and `frozen_string_literal` stay on line 1.

---

## 5. What Is NOT in Scope

- `app/models/concerns/**` — concern internals are not reordered by this convention (only their inclusion sites in models are).
- No logic changes, no renames, no dead-code removal.
- No migration/schema changes.

---

## 6. Enforcement

`Layout/ClassStructure` in `.rubocop.yml` is scoped to `app/models/*.rb` and mirrors the order above via `Categories` + `ExpectedOrder`. Run `bin/rubocop` — violations fail CI.

```
bin/rubocop          # lint all
bin/rubocop app/models/company.rb   # single file
```

---

## 7. Example Transformation

**Before** (`user.rb` excerpt — concerns after validations, stray include mid-file):
```ruby
validates :email, presence: true
normalizes :email, with: -> { _1.strip.downcase }
before_validation if: :email_changed?, on: :update do ... end
# ----
include Cache::RecordsConcern
has_many :companies
enum :system_role, { ... }
include User::RetailConcern
def accessible_companies; end
```

**After** (canonical order, comments preserved):
```ruby
include Cache::RecordsConcern
include User::CacheConcern
include User::AvatarConcern
include AddressConcern
include User::OmniauthConcern
include User::RetailConcern

attribute :permission_resource_name, :string, default: -> { self.name }
normalizes :email, with: -> { _1.strip.downcase }

# --- Enums ---
enum :system_role, { ... }
enum :country, COUNTRY_CODES, prefix: true

has_secure_password
generates_token_for :email_verification, expires_in: EMAIL_VERIFICATION_TOKEN_EXPIRY do ... end

# --- Associations ---
has_many :sessions, dependent: :destroy
has_many :companies, dependent: :destroy
belongs_to :parent_user, class_name: "User", optional: true

# --- Validations ---
validates :email, presence: true
validates :name, uniqueness: true, allow_blank: true

before_validation if: :email_changed?, on: :update do ... end
after_update if: :password_digest_previously_changed? do ... end

def company_owner; end
def accessible_companies; end

private
```

---

*Last updated: 2026-08-23. Keep this doc in sync with `.rubocop.yml` ExpectedOrder.*
