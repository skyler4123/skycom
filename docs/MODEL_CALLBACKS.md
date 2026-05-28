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

Managed attribute caching in Rails.cache. Keeps model attributes synchronized with the cache store.

| Callback | Line | Method | Description |
|----------|------|--------|-------------|
| `after_commit :write_attribute_cache, on: [ :create, :update ]` | 7 | `write_attribute_cache` | Writes model attributes hash to `Rails.cache` after successful create or update. Cache key pattern: `"#{plural_model_name}_#{id}"`. |
| `after_commit :remove_attribute_cache, on: :destroy` | 8 | `remove_attribute_cache` | Deletes model attributes hash from `Rails.cache` after successful destroy. |

**Included in (5 models):** `Company`, `Employee`, `Session`, `User`, `RoleAppointment`

**Usage example:** `User.cached_find(id)` or `Employee.cached_where(company_id: id)` use the cache populated by these callbacks.

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

## 3. Summary Table

| Callback Type | Count | Models with Direct Declarations |
|--------------|-------|---------------------------------|
| `before_validation` | 3 | Address, User, (SetDefaultCompanyConcern → 34+ appointment models) |
| `after_initialize` | 1 | Branch |
| `before_create` | 1 | Session |
| `after_create` | 4 | Category, Company, PolicyAppointment, RoleAppointment |
| `after_update` | 2 | Policy, User (block) |
| `after_update` (conditional) | 1 | PolicyAppointment |
| `before_update` | 3 | PolicyAppointment, RoleAppointment, (ImmutableRecordConcern → 5 models) |
| `before_destroy` | 5 | Employee, System, PolicyAppointment, RoleAppointment, (ImmutableRecordConcern → 5 models) |
| `before_discard` | 1 | Employee |
| `after_touch` | 2* | Role (duplicate declaration on lines 30 and 87) |
| `after_commit` | 2 | (Cache::RecordsConcern → 5 models) |

**Total unique callback declarations: ~25 directly across 12 model files + 3 concern files propagating to ~40+ models.**

---

*Last updated: 2026-05-28. Auto-generated by codebase exploration.*
