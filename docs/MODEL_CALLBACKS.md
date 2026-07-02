# Skycom Model Callback Reference

> **⚠️ MANDATORY**: This document must be updated whenever a model or concern callback is added, removed, or modified. Keeping this in sync ensures the entire team (and AI agents) understand the system's behavior.

---

## Table of Contents

1. [Direct Model Callbacks](#1-direct-model-callbacks)
2. [Concern Callbacks (inherited by inclusion)](#2-concern-callbacks)
3. [Summary Table](#3-summary-table)

---

## 1. Direct Model Callbacks

Callbacks defined directly in the model file (not inherited from a concern).

---

### Address (`app/models/address.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :generate_fingerprint` | 24 | `generate_fingerprint` | Generates SHA256 hexdigest from normalized (downcased, stripped) address fields (`line_1`, `line_2`, `city`, `state_or_province`, `postal_code`, `country_code`). Used for deduplication via unique fingerprint index. |

---

### Branch (`app/models/branch.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_initialize :set_defaults_from_company, if: :new_record?` | 97 | `set_defaults_from_company` | Copies `timezone` and `currency_code` from parent `Company` to new Branch records (only on new record creation, not on find). |

---

### Category (`app/models/category.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create :create_default_property_mapping` | 9 | `create_default_property_mapping` | Auto-creates a `PropertyMapping` record named `"#{name} mappings"` linked to the category. Guarantees every category has a dedicated PropertyMapping. |

---

### Company (`app/models/company.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create :setup_owner_records` | 104 | `setup_owner_records` | Creates owner infrastructure: (1) Owner `Role` with `business_type: :owner`, (2) "Owner All Access" `Policy` with `resource: "all"` / `action: "all"`, (3) Owner `Employee` linked to the creating user, (4) Both `PolicyAppointment` and `RoleAppointment` with `business_type: :owner`. |

---

### Employee (`app/models/employee.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_discard :prevent_discard_if_owner` | 54 | `prevent_discard_if_owner` | Blocks soft-delete (Discard) if `business_type == "owner"`. Adds error and `throw(:abort)`. Owner employees cannot be discarded to prevent orphaned companies. |
| `before_destroy :prevent_destroy_if_owner` | 55 | `prevent_destroy_if_owner` | Blocks hard-delete if `business_type == "owner"`. Adds error and `throw(:abort)`. Owner employees cannot be destroyed. |

---

### Policy (`app/models/policy.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_update :touch_roles` | 48 | `touch_roles` | Iterates all associated `Role` records and calls `.touch` on each. Triggers `Role#after_touch :invalidate_employee_caches` which cascades timestamps to all employees. Used for cache invalidation when policy name/action/resource changes. |

---

### PropertyMapping (`app/models/property_mapping.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :normalize_string_values` | 62 | `normalize_string_values` | Auto-wraps plain string values on all `property_*` columns into `{"label" => value}` hashes to support the JSONB object format used by the frontend. Only wraps values that are strings (not hashes). |

---

### PolicyAppointment (`app/models/policy_appointment.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create :clear_company_permissions_cache` | 16 | `clear_company_permissions_cache` | Clears company-level permissions cache when a policy is newly assigned to a role. |
| `after_update :clear_company_permissions_cache, if: :workflow_status_changed?` | 17 | `clear_company_permissions_cache` | Clears permissions cache when appointment `workflow_status` changes (e.g., active ↔ inactive toggle). |
| `before_update :prevent_modification_if_owner` | 18 | `prevent_modification_if_owner` | Raises `ActiveRecord::ReadOnlyRecord` if `business_type == "owner"`. Owner policy appointments are immutable. |
| `before_destroy :prevent_modification_if_owner` | 19 | `prevent_modification_if_owner` | Same guard — blocks deletion of owner policy appointments. |

---

### Role (`app/models/role.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_touch :invalidate_employee_caches` | 30, 87 | `invalidate_employee_caches` | Bulk-updates `updated_at` on all associated employees via `employees.update_all(updated_at: Time.current)` — avoids loading records. Triggered when the Role is touched (e.g., by `Policy#touch_roles` or `PolicyAppointment` `touch: true`). |

> **Note**: Line 87 is a duplicate declaration of the same callback. Both refer to the same private method.

---

### RoleAppointment (`app/models/role_appointment.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create :clear_company_permissions_cache` | 19 | `clear_company_permissions_cache` | Clears company-level permissions cache when a role is assigned to an employee. |
| `before_update :prevent_modification_if_owner` | 20 | `prevent_modification_if_owner` | Raises `ActiveRecord::ReadOnlyRecord` if `business_type == "owner"`. Owner role appointments are immutable. |
| `before_destroy :prevent_modification_if_owner` | 21 | `prevent_modification_if_owner` | Same guard — blocks deletion of owner role appointments. |

---

### Session (`app/models/session.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_create :set_request_details` | 8 | `set_request_details` | Sets `user_agent` and `ip_address` from `Current` attributes (`Current.user_agent`, `Current.ip_address`) before creating the session record. |

---

### Stock (`app/models/stock.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :inherit_category_from_product, on: :create` | 3 | `inherit_category_from_product` | Sets `category` from `product.category` if category is nil on create. Ensures stock inherits its product's category. |
| `validate :category_must_match_product_category` | 4 | `category_must_match_product_category` | Validates that stock's `category_id` matches `product.category_id`. Prevents stocks from belonging to a different category than their product. |

---

### System (`app/models/system.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_destroy :prevent_destruction` | 16 | `prevent_destruction` | Blocks deletion of the singleton System record. Adds error and `throw(:abort)`. The System record is permanent. |

---

### User (`app/models/user.rb`)

| Callback | Line | Block/Method | Description |
|----------|------|-------------|-------------|
| `before_validation if: :email_changed?, on: :update do` | 23 | Block | Invalidates email verification by setting `self.verified = false` when the email address is changed on an update. |
| `after_update if: :password_digest_previously_changed? do` | 27 | Block | Invalidates all other sessions (except current session) when the password changes. Uses `sessions.where.not(id: current_session).delete_all` for security. |

---

## 2. Concern Callbacks

Callbacks defined in shared concerns that apply to any model that includes them.

---

### Cache::RecordsConcern (`app/models/concerns/cache/records_concern.rb`)

Managed attribute caching in `Rails.local_cache` (Solid Cache SQLite). Keeps model attributes synchronized with the per-server cache store.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_commit :write_attribute_cache, on: [ :create, :update ]` | 7 | `write_attribute_cache` | Writes model attributes hash to `Rails.local_cache` after successful create or update. Cache key pattern: `"#{plural_model_name}_#{id}"`. |
| `after_commit :remove_attribute_cache, on: :destroy` | 8 | `remove_attribute_cache` | Deletes model attributes hash from `Rails.local_cache` after successful destroy. |

**Included in (5 models):** `Company`, `Employee`, `Session`, `User`, `RoleAppointment`

**Usage example:** `User.cached_find(id)` or `Employee.cached_where(company_id: id)` use the cache populated by these callbacks.

---

### Session::GlobalCacheConcern (`app/models/concerns/session/global_cache_concern.rb`)

Manages global session cache lifecycle. Writes session ID to `Rails.global_session_cache` (Redis) on creation, removes on destruction. Enables cross-instance session invalidation.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create_commit :write_session_to_global_cache` | 7 | `write_session_to_global_cache` | Writes session ID to Redis with `COOKIE_EXPIRY` TTL after successful creation. Powers cross-instance session existence checks in `set_current_session`. |
| `after_commit :remove_session_from_global_cache, on: :destroy` | 8 | `remove_session_from_global_cache` | Deletes session ID from Redis after successful destruction. Ensures other instances reject the session immediately on next request. |

**Included in (1 model):** `Session`

---

### BillingInvoice (`app/models/billing_invoice.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_update :try_reactivate_company, if: -> { saved_change_to_payment_status? && paid? }` | 22 | `try_reactivate_company` | When an invoice's `payment_status` changes to `paid`, calls `company.try_reactivate!`. If no unpaid invoices remain, the company's lifecycle_status transitions back to `:active`, `suspension_at` is cleared, and `has_unpaid_invoices` is set to `false`. |
| `after_create_commit :attempt_auto_settlement, if: -> { unpaid? }` | 23 | `attempt_auto_settlement` | When a new unpaid invoice is committed to the database, calls `company.auto_settle_unpaid_invoices` → `SettlementService.settle_all`. Attempts to pay the invoice from the company's wallet (promo_balance first, then main_balance). |

---

### Company::CircuitBreakerConcern (`app/models/concerns/company/circuit_breaker_concern.rb`)

Manages Company lifecycle transitions based on unpaid invoices. `suspension_at` is the deadline before automatic suspension — `SyncSuspensionJob` runs daily at midnight to mark companies as `suspended` when their deadline passes. `is_accessible?` checks `lifecycle_status_suspended?`. On wallet balance change, automatically attempts to settle outstanding invoices via `SettlementService.settle_all`.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_update :auto_settle_unpaid_invoices, if: -> { saved_change_to_main_balance_cents? \|\| saved_change_to_promo_balance_cents? }` | 29 | `auto_settle_unpaid_invoices` | When company balance changes (top-up or settlement), attempts to settle all unpaid invoices oldest-first via `SettlementService.settle_all`. Idempotent — returns early if no unpaid invoices exist, no wallet balance, or company is `disabled`. Re-entry guarded via `Thread.current[:__settling_company_id]`. |

**Included in (1 model):** `Company` only.

**Methods added:**
- `flag_unpaid!` — sets `has_unpaid_invoices_at: Time.current`, sets `suspension_at` to end of month (raises if `disabled`); idempotent. Does NOT change `lifecycle_status`
- `mark_suspended!` — sets `lifecycle_status: :suspended`. Called by `SyncSuspensionJob`
- `try_reactivate!` — checks for unpaid/overdue invoices; if none remain, transitions to `:active`, clears `suspension_at`, and sets `has_unpaid_invoices_at: nil`
- `is_accessible?` — returns `true` when not `lifecycle_status_suspended?`
- `auto_settle_unpaid_invoices` — public method; called by the `after_update` callback and by `BillingInvoice#attempt_auto_settlement`. Guards: skips if already settling, disabled, no positive balance, or no unpaid invoices.

---

### ImmutableRecordConcern (`app/models/concerns/immutable_record_concern.rb`)

Renders records read-only after creation. Prevents both updates and deletion.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_update :prevent_modification` | 7 | `prevent_modification` | Raises `ActiveRecord::ReadOnlyRecord` with message: `"#{self.class} is shared and immutable. You can only create new records."` |
| `before_destroy :prevent_modification` | 10 | `prevent_modification` | Same guard applied to deletion. |

**Included in (5 models):** `Address`, `Period`, `Price`, `SubscriptionGroup`, `Membership`

---

### SetDefaultCompanyConcern (`app/models/concerns/set_default_company_concern.rb`)

Auto-derives `company_id` on Appointment records from the associated polymorphic resource.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :set_default_company_from_resource` | 36 | `set_default_company_from_resource` | Derives `company_id` from the associated resource (e.g., `role.company_id` for `RoleAppointment`). Only sets if not already present. Uses class name convention: removes `"Appointment"` suffix, underscores, and calls that association. |

**Included in (34+ models):** All `*_appointment` models: `RoleAppointment`, `PolicyAppointment`, `TagAppointment`, `DepartmentAppointment`, `EmployeeAppointment`, `EmployeeGroupAppointment`, `CustomerAppointment`, `CustomerGroupAppointment`, `ProductAppointment`, `ProductGroupAppointment`, `ServiceAppointment`, `ServiceGroupAppointment`, `OrderAppointment`, `OrderGroupAppointment`, `CartAppointment`, `PaymentMethodAppointment`, `FacilityAppointment`, `FacilityGroupAppointment`, `ProjectAppointment`, `ProjectGroupAppointment`, `TaskAppointment`, `TaskGroupAppointment`, `NotificationAppointment`, `NotificationGroupAppointment`, `ExamAppointment`, `EventAppointment`, `EventGroupAppointment`, `SettingAppointment`, `SettingGroupAppointment`, `DocumentAppointment`, `DocumentGroupAppointment`, `ArticleAppointment`, `ArticleGroupAppointment`, `ReservationAppointment`, `SubscriptionPlanAppointment`, and others.

---

### CategoryConcern (`app/models/concerns/category_concern.rb`)

Auto-assigns a default category on create if none is provided. Ensures every resource record has a category for dynamic property resolution and ABAC permission evaluation.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :ensure_category, on: :create` | 10 | `ensure_category` | If `category` is nil and `company` is present, finds or creates a default `Category` record using `find_or_create_by!(company:, resource_name:)` with the model's plural name. Uses the same `find_or_create_for` pattern as seed services. |

**Included in (17 models):** `Branch`, `Brand`, `Customer`, `Department`, `Employee`, `EmployeeGroup`, `Facility`, `Invoice`, `Order`, `Product`, `PropertyMapping`, `Service`, `StockExport`, `StockImport`, `StockTransfer`, `TableConfig`, `Warehouse`

---

### DynamicValidationConcern (`app/models/concerns/dynamic_validation_concern.rb`)

Reads `validates` hashes from `property_mapping.property_metadata` and applies them as record-level validations on each `property_*` column. Supports `presence`, `numericality` (with `only_integer`, `greater_than`, `greater_than_or_equal_to`, `less_than`, `less_than_or_equal_to`), `inclusion`, `format` (with `with`/`without`), and `length` (with `minimum`/`maximum`). Auto-included via `PropertyMappingConcern`.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `validate :dynamic_property_validations` | 12 | `dynamic_property_validations` | Iterates `property_mapping.property_metadata`, reads each entry's `validates` hash, and applies matching Rails validation logic to the corresponding `property_*` column. Empty `validates` (`{}`) is skipped. |

**Included in (48 models):** All models including `PropertyMappingConcern` (products, services, branches, employees, customers, etc.)

---

### PropertyMappingConcern (`app/models/concerns/property_mapping_concern.rb`)

Auto-assigns a default property_mapping on create if none is provided. Derives `property_mapping` from `category.default_property_mapping`.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :ensure_property_mapping, on: :create` | 10 | `ensure_property_mapping` | If `property_mapping` is nil and `category` is present, sets `self.property_mapping = category.default_property_mapping`. Ensures every resource record has a property_mapping for dynamic property resolution. |
| `validate :category_matches_property_mapping_category` | 11 | `category_matches_property_mapping_category` | Ensures the resource's `category_id` matches the `property_mapping.category_id`. Prevents inconsistency on update or manual assignment. Returns early if either association is blank. |

**Included in (48 models):** All models that include `CategoryConcern` (18 models) plus additional managed resources: `Answer`, `Article`, `ArticleGroup`, `Cart`, `CartGroup`, `CustomerGroup`, `Document`, `DocumentGroup`, `Event`, `EventGroup`, `Exam`, `ExamGroup`, `FacilityGroup`, `Membership`, `Notification`, `NotificationGroup`, `OrderGroup`, `Payment`, `ProductGroup`, `Project`, `ProjectGroup`, `Purchase`, `PurchaseItem`, `Question`, `Reservation`, `ServiceGroup`, `Setting`, `SettingGroup`, `Task`, `TaskGroup`

---

### ImageConcern per-model (`app/models/concerns/{resource}/image_concern.rb`)

Each business resource gets its own namespaced `ImageConcern` (e.g., `Branch::ImageConcern`, `Brand::ImageConcern`). Provides `has_many_attached :image_attachments` with validation for file size, content type, and count.

Each concern defines the same callback:

| Callback | Method | Description |
|----------|--------|-------------|
| `validate :acceptable_image_attachments` | `acceptable_image_attachments` | Validates each attached image: max 3 images total, max 1MB per file, only JPEG/PNG/GIF types allowed. |

**Included in (6 models + Product):**
- `Branch::ImageConcern` → `Branch`
- `Brand::ImageConcern` → `Brand`
- `Customer::ImageConcern` → `Customer`
- `Department::ImageConcern` → `Department`
- `Employee::ImageConcern` → `Employee`
- `Service::ImageConcern` → `Service`
- `Product::ImageConcern` → `Product` (pre-existing)

---

## 3. Summary Table

| Callback Type | Count | Models with Direct Declarations |
|--------------|-------|---------------------------------|
| `before_validation` | 5 | Address, User, (SetDefaultCompanyConcern → 34+ appointment models), (CategoryConcern → 18 models), (PropertyMappingConcern → 48 models) |
| `after_initialize` | 1 | Branch |
| `before_create` | 1 | Session |
| `after_create` | 4 | Category, Company, PolicyAppointment, RoleAppointment |
| `after_update` | 2 | Policy, User (block) |
| `after_update` (conditional) | 3 | PolicyAppointment, BillingInvoice, (Company::CircuitBreakerConcern → 1 model) |
| `before_update` | 3 | PolicyAppointment, RoleAppointment, (ImmutableRecordConcern → 5 models) |
| `before_destroy` | 5 | Employee, System, PolicyAppointment, RoleAppointment, (ImmutableRecordConcern → 5 models) |
| `before_discard` | 1 | Employee |
| `after_touch` | 2* | Role (duplicate declaration on lines 30 and 87) |
| `after_commit` | 3 | (Cache::RecordsConcern → 5 models), (Session::GlobalCacheConcern → 1 model) |
| `validate` | 3 | (DynamicValidationConcern → 48 models), (PropertyMappingConcern → 48 models), (ImageAttachmentsConcern → 6 models + Product) |

**Total unique callback declarations: ~29 directly across 13 model files + 7 concern files propagating to ~63+ models.**

> **Note:** `ImageAttachmentsConcern` in the validate row covers the 6 per-model ImageConcern files (Branch, Brand, Customer, Department, Employee, Service) + the pre-existing `Product::ImageConcern`, all of which define the same `validate :acceptable_image_attachments` callback.

---

*Last updated: 2026-07-02. Auto-generated by codebase exploration.*
