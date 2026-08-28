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
| `after_create :initialize_payment_methods` | 107 | `initialize_payment_methods` | Auto-creates a **branch-level** `PaymentMethodAppointment` for each **active** company-level appointment (`company.payment_method_appointments.company_level` with `lifecycle_status: :active`). Copies the company appointment's name (suffixed `" for #{branch.name}"`), code (suffixed `-BR-<hex>`), `business_type`, `workflow_status`, and merchant fields; sets `lifecycle_status: :active`. Ensures every new branch inherits the company's payment methods. |

---

### Category (`app/models/category.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create :create_default_property_mapping` | 9 | `create_default_property_mapping` | Auto-creates a `PropertyMapping` record named `"#{name} mappings"` linked to the category. Guarantees every category has a dedicated PropertyMapping. |

---

### Company (`app/models/company.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create :setup_owner_records` | 104 | `setup_owner_records` | Creates owner infrastructure: (1) Owner `Role` with `business_type: :owner`, (2) "Owner All Access" `Policy` with `resource: "all"` / `action: "all"`, (3) Owner `Employee` linked to the creating user, (4) Both `PolicyAppointment` and `RoleAppointment` with `business_type: :owner`, (5) Sets `user.system_role` to `company_owner` so `accessible_companies` returns the new company. |
| `after_create :initialize_company` | 126 | `initialize_company` | Also creates the company's `CompanyWallet` (`credit_balance: 0`, `walletable: company`) — unconditional, like the owner records. The wallet is the chain's bottom node: `CompanyTransaction → CompanyInvoice → CompanyOrder → CompanyWallet`. Also seeds the default company-appointed `Setting` (`code: SETTINGS-DEFAULT`) via `create_default_setting` — unconditional, right after the wallet. |

---

### CompanyInvoice (`app/models/company_invoice.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :generate_invoice_number, on: :create` | — | `generate_invoice_number` | Auto-generates `INV-YYYYMM-HEX` when `invoice_number` is blank. |
| `after_update :complete_order_if_paid!, if: :saved_change_to_payment_status? && paid?` | — | `complete_order_if_paid!` | When the invoice's `payment_status` transitions to `paid`, completes the linked `CompanyOrder` (idempotent — `complete!` no-ops when already completed). Part of the credit chain. |

---

### CompanyTransaction (`app/models/company_transaction.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create :sync_invoice_payment_status, if: :completed?` | — | `sync_invoice_payment_status` | Derives the invoice's `payment_status` from `SUM(money_amount_cents)` of its `completed` `payment` transactions: `>= invoice.money_amount_cents → paid`, else `unpaid`. Never set directly — this is the credit chain's entry point. |
| `after_update :sync_invoice_payment_status, if: :completed?` | — | `sync_invoice_payment_status` | Same derivation when a pending transaction is completed by a gateway webhook (top-up flow). |
| `after_destroy :sync_invoice_payment_status` | — | `sync_invoice_payment_status` | Re-derives (reverts to `unpaid`) when a payment is destroyed. |

---

### Transaction (`app/models/transaction.rb`) — B2C POS sales

Mirrors the `CompanyTransaction` gating: the invoice's `payment_status` is derived from `SUM(price_cents)` of `completed` transactions only, so pending Mock QR payments never pay the invoice early. The model also carries a `status` enum (`pending/completed/failed`, DB default 0) and `store_accessor :metadata, :gateway_payload` for raw gateway responses.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_create :sync_invoice_payment_status, if: -> { completed? && !price_cents.zero? }` | — | `sync_invoice_payment_status` | Derives `Invoice.payment_status` from `SUM(transactions.price_cents)` — fires only when the transaction is created already `completed` (instant cash path). Pending QR creations are silent. |
| `after_update :sync_invoice_payment_status, if: :completed?` | — | `sync_invoice_payment_status` | Same derivation when a webhook completes a pending transaction (`OrderProcessingV1::CompletePaymentService`). |
| `after_destroy :sync_invoice_payment_status` | — | `sync_invoice_payment_status` | Re-derives (reverts to `unpaid`) when any transaction row is destroyed. |

---

### Branch (`app/models/branch.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `belongs_to :company, touch: true` | 18 | ActiveRecord `touch` | Touches the parent `Company` (bumps `updated_at`) on create, update, and destroy of a Branch. Invalidates the client cache for all users who have this company in their accessible companies. |

---

### Department (`app/models/department.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `belongs_to :company, touch: true` | 29 | ActiveRecord `touch` | Touches the parent `Company` on create, update, and destroy of a Department. Invalidates the client cache. |

---

### Category (`app/models/category.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `belongs_to :company, touch: true` | 4 | ActiveRecord `touch` | Touches the parent `Company` on create, update, and destroy of a Category. Invalidates the client cache. |

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
| `belongs_to :company, touch: true` | 55 | ActiveRecord `touch` | Touches the parent `Company` on create, update, and destroy of a PropertyMapping. Invalidates the client cache. |
| `after_create :create_default_table_config` | 60 | `create_default_table_config` | Auto-creates a default `TableConfig` (with default `columns_metadata`) linked to the same `company` and `category`. Guarantees every PropertyMapping has at least one TableConfig. |
| `validate :must_have_table_config` | 117 | `must_have_table_config` | Safety net — validates that at least one `TableConfig` exists for persisted records. Skipped for new records (where `after_create` hasn't run yet). |

---

### PaymentMethodAppointment (`app/models/payment_method_appointment.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :default_appoint_to_to_company` | 30 | `default_appoint_to_to_company` | Sets `appoint_to` to the appointment's `company` if `appoint_to` is blank. Guarantees every appointment resolves to a polymorphic source type (Company by default, or Branch when passed explicitly). |
| `after_update :cascade_lifecycle_to_branch_appointments, if: :company_level_lifecycle_change?` | 31 | `cascade_lifecycle_to_branch_appointments` | When a **company-level** appointment's `lifecycle_status` changes, mirrors that status to all **branch-level** appointments for the same company + payment method via `update_all(lifecycle_status:)`. Runs only when `appoint_to_type == "Company"` and `saved_change_to_lifecycle_status?` — branch-level updates never recurse. |
| `validate :payment_method_must_be_active_in_company` | 32 | `payment_method_must_be_active_in_company` | Only for `appoint_to_type == "Branch"` — requires an active (`lifecycle_status: :active`) **company-level** appointment for the same company + payment method. Adds `appoint_to: "payment method is not active at the company level"` otherwise. |

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

### Setting (`app/models/setting.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :derive_company_from_appoint_to` | — | `derive_company_from_appoint_to` | Derives `company_id` from the polymorphic `appoint_to`: Company → `appoint_to.id`, otherwise `appoint_to.company_id`. Only sets when `company_id` is blank. |

---

### Stock (`app/models/stock.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_validation :inherit_category_from_product, on: :create` | 3 | `inherit_category_from_product` | Sets `category` from `product.category` if category is nil on create. Ensures stock inherits its product's category. |
| `validate :category_must_match_product_category` | 4 | `category_must_match_product_category` | Validates that stock's `category_id` matches `product.category_id`. Prevents stocks from belonging to a different category than their product. |

---

### TableConfig (`app/models/table_config.rb`)

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `belongs_to :company, touch: true` | 12 | ActiveRecord `touch` | Touches the parent `Company` on create, update, and destroy of a TableConfig. Invalidates the client cache. |

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

Managed attribute caching in `Rails.sync_cache` (Solid Cache SQLite + Redis pub/sub invalidation). Keeps model attributes synchronized across all server instances. Reads are local SQLite only (no Redis per request); writes and deletes broadcast invalidation via Redis pub/sub so all instances evict stale keys.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_commit :write_attribute_cache, on: [ :create, :update ]` | 7 | `write_attribute_cache` | Writes model attributes hash to `Rails.sync_cache` after successful create or update. Cache key pattern: `"#{plural_model_name}_#{id}"`. Also publishes pub/sub invalidation for cross-instance sync. |
| `after_commit :remove_attribute_cache, on: :destroy` | 8 | `remove_attribute_cache` | Deletes model attributes hash from `Rails.sync_cache` after successful destroy. Also publishes pub/sub invalidation so other instances evict immediately. |

**Included in (5 models):** `Company`, `Employee`, `Session`, `User`, `RoleAppointment`

**Usage example:** `User.cached_find(id)` or `Employee.cached_where(company_id: id)` use `Rails.sync_cache` populated by these callbacks.

---

### ImmutableRecordConcern (`app/models/concerns/immutable_record_concern.rb`)

Renders records read-only after creation. Prevents both updates and deletion.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `before_update :prevent_modification` | 7 | `prevent_modification` | Raises `ActiveRecord::ReadOnlyRecord` with message: `"#{self.class} is shared and immutable. You can only create new records."` |
| `before_destroy :prevent_modification` | 10 | `prevent_modification` | Same guard applied to deletion. |

**Included in (3 models):** `Address`, `SubscriptionGroup`, `Membership`

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

**Included in (47 models):** All models that include `CategoryConcern` (17 models) plus additional managed resources: `Answer`, `Article`, `ArticleGroup`, `Cart`, `CartGroup`, `CustomerGroup`, `Document`, `DocumentGroup`, `Event`, `EventGroup`, `Exam`, `ExamGroup`, `FacilityGroup`, `Membership`, `Notification`, `NotificationGroup`, `OrderGroup`, `Payment`, `ProductGroup`, `Project`, `ProjectGroup`, `Purchase`, `PurchaseItem`, `Question`, `Reservation`, `ServiceGroup`, `SettingGroup`, `Task`, `TaskGroup`

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
| `before_validation` | 5 | Address, User, (SetDefaultCompanyConcern → 34+ appointment models), (CategoryConcern → 17 models), (PropertyMappingConcern → 47 models) |
| `after_initialize` | 1 | Branch |
| `before_create` | 1 | Session |
| `after_create` | 6 | Category, Company, Branch, PolicyAppointment, PropertyMapping, RoleAppointment |
| `belongs_to :company, touch: true` | 6 | Branch, Department, Category, PropertyMapping, TableConfig, Role |
| `after_update` (conditional) | 2 | PaymentMethodAppointment, PolicyAppointment |
| `before_update` | 3 | PolicyAppointment, RoleAppointment, (ImmutableRecordConcern → 3 models) |
| `before_destroy` | 5 | Employee, System, PolicyAppointment, RoleAppointment, (ImmutableRecordConcern → 3 models) |
| `before_discard` | 1 | Employee |
| `after_touch` | 2* | Role (duplicate declaration on lines 30 and 87) |
| `after_commit` | 2 | (Cache::RecordsConcern → 5 models) |
| `validate` | 5 | PaymentMethodAppointment, PropertyMapping, (DynamicValidationConcern → 48 models), (PropertyMappingConcern → 48 models), (ImageAttachmentsConcern → 6 models + Product) |

**Total unique callback declarations: ~34 directly across 15 model files + 7 concern files propagating to ~63+ models.**

> **Note:** `ImageAttachmentsConcern` in the validate row covers the 6 per-model ImageConcern files (Branch, Brand, Customer, Department, Employee, Service) + the pre-existing `Product::ImageConcern`, all of which define the same `validate :acceptable_image_attachments` callback.

---

*Last updated: 2026-08-10. Auto-generated by codebase exploration.*
