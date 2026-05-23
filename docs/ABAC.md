# Skycom ABAC Permission System

## 1. Overview
Skycom utilizes an **Attribute-Based Access Control (ABAC)** strategy inspired by AWS IAM. This system decouples permissions from static roles, allowing for granular, dynamic access control based on resource metadata.

## 2. Core Components

### A. Tag Schema
Tags are the fundamental building blocks of the permission engine.
* **Key**: The identifier (e.g., `brand`, `is_promo`).
* **Value**: The specific attribute (e.g., `Apple`). Can be `nil` for binary flags.

```ruby
# Example Tag Record
{ 
  key: "brand", 
  value: "Apple", 
  description: "Manufacturer label",
  code: "BR-001"
}
```
### B. Policy Schema (`tag_conditions`)
Each `Policy` record contains a `jsonb` column named `tag_conditions` that defines the rules for that specific permission.

| Match Type | Logic | Example JSON |
| :--- | :--- | :--- |
| **Requirement (Flag)** | Key **must** exist on resource. | `{"is_featured": true}` |
| **Exclusion (Flag)** | Key **must NOT** exist on resource. | `{"is_dangerous": false}` |
| **Exact Match** | Key must exist **AND** value must match. | `{"brand": "Apple"}` |

---

## 3. The Matcher Logic
The permission engine is housed within the `PermissionConcern`. It performs a three-step evaluation:

1.  **Identity**: Retrieve all policies for the user's assigned roles.
2.  **Filter**: Select policies matching the `Action` (e.g., `update`) and `Resource` (e.g., `Product`).
3.  **Evaluate**: Perform a hash-comparison between the Policy's `tag_conditions` and the Resource's `tags`.

### Implementation (Ruby)
```ruby
def evaluate_tag_conditions(target, conditions)
  return true if conditions.blank?
  return false unless target.respond_to?(:tags)

  # Load target tags into a hash for O(1) lookups
  # Note: Uses the updated .key attribute
  target_tags = target.tags.each_with_object({}) { |t, h| h[t.key] = t.value }

  conditions.all? do |key, required_value|
    key_string = key.to_s
    
    case required_value
    when true
      target_tags.key?(key_string)              # Must exist
    when false
      !target_tags.key?(key_string)             # Must NOT exist
    else
      target_tags[key_string] == required_value.to_s # Exact value match
    end
  end
end
```
## 4. Developer Best Practices

### Prevention of N+1 Queries
Since the matcher iterates through a resource's tags, **always** eager-load the tags association when performing permission checks on collections to avoid database performance degradation.

```ruby
# Correct Usage
@products = Product.includes(:tags).all
@products.select { |p| current_employee.can?(:read, p) }
```
### Advanced Scenarios

* **Virtual Resources**: To target non-model resources (e.g., a "Teacher" role inside the `Employee` table), implement a `policy_resource_name` method in the model.
* **Global Permissions**: A policy with an empty `tag_conditions` hash grants access to all instances of that resource.
* **Complex Exclusions**: Use `false` in `tag_conditions` to create guardrails, such as preventing junior staff from accessing items tagged as `high_value`.

---

## 5. Security Note

**Tag Governance**: Access to create or modify `Tags` and `TagAppointments` should be restricted to high-level Administrative roles. In an ABAC system, the ability to change a tag is functionally equivalent to the ability to grant or revoke permissions.

**Auditing**: Periodically audit policies with empty `tag_conditions` to ensure global access is still intended for those specific roles.

---

## 6. Role-Policy Association (Many-to-Many)

Policies are assigned to Roles via the join table `PolicyAppointment`. This enables a many-to-many relationship where a single policy can be used by multiple roles.

### E-commerce Example
- **Policy**: "Create Order" (resource: `Order`, action: `create`)
- **Assigned to**: `Manager` role, `Seller` role
- **Effect**: Both Manager and Seller employees can create orders, but only for resources matching the policy's `tag_conditions`

### Implementation (Ruby)
```ruby
# In Policy model
has_many :policy_appointments, dependent: :destroy
has_many :roles, through: :policy_appointments, source: :appoint_to

# In Role model
has_many :policy_appointments, dependent: :destroy, as: :appoint_to
has_many :policies, through: :policy_appointments
```

### Cache Invalidation
When a `PolicyAppointment` is created or destroyed, the Role's `updated_at` timestamp is touched (via `after_touch` callback), which propagates to the Company and invalidates the permissions cache automatically.

---

## 7. Permissions UI Endpoint

**Route**: `GET /companies/:id/permissions`

### Purpose
Manage the policy-to-role assignments (PolicyAppointments) via a role-grouped UI. Instead of a role-policy relationship table, this page groups policies by role and displays each policy as a checkbox.

### UI Design Pattern
1. **Group by Role**: Each role is a collapsible section or card
2. **List All Actions**: Within each role, list all available policies (CRUD+, including custom actions)
3. **Checkbox Toggle**:
   - Checked = `workflow_status === 'active'` (policy is active for that role)
   - Unchecked = `workflow_status` is not active (but appointment still exists)

### Example JSON Response
```json
{
  "roles": [
    {
      "id": "role-uuid-1",
      "name": "Manager",
      "policies": [
        { "id": "policy-uuid-1", "name": "Create Order", "resource": "Order", "action": "create", "workflow_status": "active" },
        { "id": "policy-uuid-2", "name": "Read Order", "resource": "Order", "action": "read", "workflow_status": "inactive" },
        { "id": "policy-uuid-3", "name": "Update Order", "resource": "Order", "action": "update", "workflow_status": "active" },
        { "id": "policy-uuid-4", "name": "Delete Order", "resource": "Order", "action": "delete", "workflow_status": "inactive" }
      ]
    }
  ]
}
```

---

## 8. Backend Implementation Requirements

### Controller Actions

| Action | HTTP | Purpose |
|--------|------|---------|
| `index` | GET | Return all roles grouped with their policies (include `workflow_status` for checkbox state) |
| `create` | POST | Create `PolicyAppointment` (assign policy to role) |
| `destroy` | DELETE | Remove `PolicyAppointment` (revoke policy from role) |

### Index Query
- Load all roles for the company via `company.roles.includes(:policies)`
- Eager-load policies to prevent N+1
- Include `workflow_status` in the JSON output for checkbox checked state

### Create Action
```ruby
# Params: { policy_appointment: { policy_id: "...", role_id: "..." } }
policy = company.policies.find(params[:policy_id])
role = company.roles.find(params[:role_id])

# Create the appointment
appointment = PolicyAppointment.find_or_create_by!(
  policy: policy,
  appoint_to: role
)

# Activate the policy
policy.update!(workflow_status: :active)

# Clear permissions cache
company.clear_permissions_cache
```

### Destroy Action
```ruby
# Params: { id: "policy_appointment_id" }
appointment = company.policy_appointments.find(params[:id])
appointment.destroy!

# Clear permissions cache
company.clear_permissions_cache
```

---

## 8. Frontend Implementation Pattern

### Stimulus Controller
`app/javascript/controllers/companies/permissions/index_controller.js`

### Checkbox Toggle Logic
```javascript
${policy.workflow_status === 'active' ? 'checked' : ''}
```

### Form Submission
Use `Helpers.form()` for toggle actions:

```javascript
// Toggle ON (create appointment)
Helpers.form({
  action: Helpers.company_permissions_path(companyId),
  method: 'POST',
  dataAction: 'create',
  html: `
    <input type="hidden" name="policy_appointment[policy_id]" value="${policyId}" />
    <input type="hidden" name="policy_appointment[role_id]" value="${roleId}" />
  `
})

// Toggle OFF (destroy appointment)
Helpers.form({
  action: Helpers.company_permissions_path(companyId, appointmentId),
  method: 'DELETE'
})
```

### Success Handling
- Listen for `form:success` event
- Dispatch `refresh` event to reload the permissions page
- Show success toast notification

---

## 9. Permission Resource Name

Each business entity has a `permission_resource_name` column to identify which resource type a policy applies to. This enables the permission system to know which records a role can access.

### Database Column
```ruby
# In migration (no hardcoded default)
t.string :permission_resource_name
```

### Model-Level Default
We use a Rails attribute with a lambda to automatically set the default value based on the model class name:

```ruby
# In all business entity models (Employee, Customer, Order, etc.)
attribute :permission_resource_name, :string, default: -> { self.name }
```

### How It Works
- When `Employee.new` is created, `_1.class.name` returns `"Employee"`
- When `Order.new` is created, `_1.class.name` returns `"Order"`
- The default is applied automatically at record creation time
- No hardcoding required - DRY principle

### Example Model Implementation
```ruby
# app/models/employee.rb
class Employee < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
end

# app/models/order.rb
class Order < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }
end
```

### Benefits
1. **DRY**: No need to hardcode defaults for each model
2. **Consistent**: All business entities follow the same pattern
3. **Flexible**: Can be overridden if needed per-instance

---

## 12. Shell First Rendering Pattern

This project follows a **Shell First** rendering approach for SPA-like experience.

### Application Rules

| Action Type | Pattern | Example |
|-------------|---------|---------|
| **Show data** (index, show) | Shell First | `respond_to do \|format\| format.html { render html: "", layout: true }` |
| **Support actions** (create, update, destroy, show) | JSON only | Return JSON, let frontend handle UI refresh |

> **Note:** Even `show` action is used to support `index` action - e.g., fetching single record details for modals, inline editing, etc.

### Controller Example

```ruby
# Show data action - Shell First pattern
def index
  respond_to do |format|
    format.html { render html: "", layout: true }  # Returns empty HTML, Stimulus renders content
    format.json { render json: { roles: current_company.permissions } }
  end
end

# Support actions - JSON only
def create
  # Handle create, return JSON for frontend to refresh
end

def show
  # Used to support index - e.g., fetch single record for modal/edit
end
```

### Why This Pattern?

1. **Empty HTML shell** - Server returns minimal HTML
2. **Stimulus hydrates** - JavaScript fetches JSON data and renders content
3. **Fast UX** - No full page reloads, SPA-like experience
4. **JSON for mutations** - create/update/destroy return JSON for frontend to handle success/failure

### Frontend Responsibility

- `index` action: Fetches JSON, renders all UI via `contentHTML()`
- `create/update` actions: On success, dispatches refresh event to reload index data

---

## 11. Stimulus Controller Action Pattern

Always use dynamic identifier for controller actions in HTML templates:

```javascript
// Correct - dynamic identifier (recommended)
data-action="change->${this.identifier}#togglePermission"

// Wrong - hardcoded controller name
data-action="change->index#togglePermission"
```

### Why Use `${this.identifier}`?

1. **Dynamic mapping** - The controller identifier is generated from the class name (e.g., `Companies_Permissions_IndexController` → `companies--permissions--index`)
2. **Consistency** - Ensures actions connect to the correct controller instance
3. **Reusability** - Template can be reused across different controllers without hardcoding

### Pattern Usage

In Stimulus controllers that render HTML via `contentHTML()`, always use:
```javascript
data-action="change->${this.identifier}#methodName"
```

This connects the action to the current controller instance's method.

---

## 12. Frontend Data Fetching: form vs fetchJson

This project has two patterns for handling API calls in Stimulus controllers:

### Pattern 1: Helpers.form() (Preferred for User Actions)

Used when there are HTML form elements that trigger actions:

| Use Case | Example |
|----------|---------|
| Form submissions | Creating, updating, deleting records |
| Button clicks | Toggle switches, checkboxes |
| Any action with UI feedback | FormController handles toast automatically |

**Benefits:**
- Auto injects CSRF token
- Auto handles method spoofing (PATCH, DELETE)
- Auto shows toast on success/error
- Event-driven: `form:success` and `form:error` events

**Example:**
```javascript
// Checkbox wrapped in form
${Helpers.form({
  action: url,
  method: 'PATCH',
  dataAction: 'refresh',
  html: `<input type="checkbox" data-action="change->form#submit" />`
})}
```

---

### Pattern 2: fetchJson (For Initial Data Loading)

Used when there are no HTML elements or for controller initialization:

| Use Case | Example |
|----------|---------|
| Initial data fetch | Loading data on controller connect |
| Complex JSON API | No form UI involved |
| Background requests | Polling, real-time updates |

**Example:**
```javascript
async connect() {
  const response = await fetchJson(url)
  this.data = response.data
}
```

---

### Decision Flowchart

```
Is there an HTML element triggering the action?
├── YES → Use Helpers.form()
│   ├── FormController handles:
│   │   ├── CSRF injection
│   │   ├── Method spoofing
│   │   ├── Toast notifications
│   │   └── Success/error events
│
└── NO → Use fetchJson()
    ├── For connect() initial data loading
    └── For background/API-only operations
```

---

### Key Principles

1. **Prefer form** for any action that originates from UI elements (buttons, links, checkboxes)
2. **Use fetchJson** for loading initial data or when no form element is involved
3. **No direct fetch/ajax** - Always use Helpers.fetchJson or Helpers.form()

---

## 13. Owner Role & Immutable Records

When a company is created, Skycom automatically sets up an owner role with full permissions. This section documents how owner records are protected.

### A. Automatic Owner Setup

When a company is created via `Company#setup_owner_records`, the following records are automatically created:

1. **Owner Role** - Named "owner" with `business_type: :administrative`
2. **Owner Policy** - Full access policy with `resource: "all"`, `action: "all"`
3. **Owner Employee** - The user who created the company is linked as an employee

```ruby
# app/models/company.rb - setup_owner_records
def setup_owner_records
  role = Seed::RoleService.create(company: self, name: "owner", business_type: :administrative)

  policy = Seed::PolicyService.create(
    company: self,
    name: "Owner All Access",
    resource: "all",
    action: "all",
    business_type: :operational,
    lifecycle_status: :active
  )

  # PolicyAppointment with business_type: :owner (immutable)
  Seed::PolicyAppointmentService.create(
    company: self,
    policy: policy,
    appoint_to: role,
    workflow_status: :active,
    business_type: :owner  # <-- marks as owner record
  )

  employee = Seed::EmployeeService.create(company: self, user: user, ...)

  # RoleAppointment with business_type: :owner (immutable)
  Seed::RoleAppointmentService.create(
    company: self,
    role: role,
    appoint_to: employee,
    workflow_status: :active,
    business_type: :owner  # <-- marks as owner record
  )
end
```

### B. business_type Enum

Both `RoleAppointment` and `PolicyAppointment` have a `business_type` enum:

```ruby
# app/models/role_appointment.rb
enum :business_type, { owner: 0 }

# app/models/policy_appointment.rb
enum :business_type, { owner: 0 }
```

### C. Immutable Owner Records

Records with `business_type: "owner"` are protected from modification/deletion:

```ruby
# app/models/role_appointment.rb
before_update :prevent_modification_if_owner
before_destroy :prevent_modification_if_owner

private

def prevent_modification_if_owner
  return unless business_type == "owner"
  raise ActiveRecord::ReadOnlyRecord, "Owner records cannot be modified."
end
```

**Behavior:**
- Attempting to update an owner record raises `ActiveRecord::ReadOnlyRecord`
- Attempting to delete an owner record raises `ActiveRecord::ReadOnlyRecord`
- The Permissions UI filters owner roles from display

### D. Owner Employee Gets All Permissions

Employees with owner role bypass normal permission checks:

```ruby
# app/models/concerns/employee/permission_concern.rb
def can?(action_name, target)
  # Owner employee has all permissions - bypass normal checks
  return true if owner_role?

  # ... rest of normal permission logic ...
end

def owner_role?
  role_appointments.any? { |ra| ra.business_type == "owner" }
end
```

### E. Permissions Page Filtering

The Permissions UI (`GET /companies/:id/permissions`) excludes owner roles:

```ruby
# app/models/concerns/company/permission_concern.rb
def permissions
  # Excludes roles where any RoleAppointment has business_type: :owner
  roles.reject { |role| owner_role?(role) }.map do |role|
    # ...
  end
end

def owner_role?(role)
  role.role_appointments.any? { |ra| ra.business_type == :owner }
end
```

### F. Error Handling

When attempting to modify owner records via API:

```ruby
# app/controllers/companies/permissions_controller.rb
def update
  begin
    appointment.update!(workflow_status: workflow_status)
    # ...
  rescue ActiveRecord::ReadOnlyRecord => e
    render json: { error: e.message }, status: :forbidden
  end
end
```

### Summary

| Feature | Implementation |
|---------|----------------|
| Owner role created | Automatically via `Company#setup_owner_records` |
| Owner policy | `resource: "all"`, `action: "all"` |
| Immutable protection | `business_type: :owner` + callbacks |
| Full permissions | `owner_role?` check in `can?` method |
| Hidden from UI | Filtered in `Company#permissions` |

---

## 14. Owner Uniqueness Validation

Skycom enforces that only ONE employee can be the "owner" in both the Employee table and RoleAppointment table. This ensures proper permission hierarchy and prevents conflicting ownership.

### A. Employee Owner Uniqueness

Only ONE employee with `business_type='owner'` is allowed per company. This validation prevents duplicate owner employees from being created.

**Implementation:**
```ruby
# app/models/employee.rb
validate :only_one_owner_per_company, on: :create

private

def only_one_owner_per_company
  return unless business_type.to_s == "owner" && company_id.present?
  
  # Allow if this employee is updating their own record
  return if persisted? && self.id == Employee.find_by(company_id: company_id, business_type: :owner)&.id

  owner_exists = Employee.where(company_id: company_id, business_type: :owner)
    .where.not(id: self.id)
    .exists?

  if owner_exists
    errors.add(:base, "Only one owner employee is allowed per company.")
  end
end
```

**Behavior:**
| Action | Result |
|--------|--------|
| Create first owner employee | ✅ Allowed |
| Create second owner employee | ❌ Validation error blocked |
| Update existing owner employee | ✅ Allowed |
| Change existing owner to non-owner | ✅ Allowed |

**Error message:**
```
Base: Only one owner employee is allowed per company.
```

---

### B. Owner Employee Cannot Be Deleted

Owner employees are protected from deletion to prevent orphaned companies. Both `.discard!` (soft-delete) and `.destroy!` (hard-delete) are blocked.

**Implementation:**
```ruby
# app/models/employee.rb
before_discard :prevent_discard_if_owner
before_destroy :prevent_destroy_if_owner

private

def prevent_discard_if_owner
  return unless business_type.to_s == "owner"
  errors.add(:base, "Owner employee cannot be discarded.")
  throw(:abort)
end

def prevent_destroy_if_owner
  return unless business_type.to_s == "owner"
  errors.add(:base, "Owner employee cannot be destroyed.")
  throw(:abort)
end
```

**Behavior:**
| Action | Result |
|--------|--------|
| Discard owner employee | ❌ Raises `Discard::RecordNotDiscarded` |
| Destroy owner employee | ❌ Raises error (blocked by callbacks) |
| Discard non-owner employee | ✅ Allowed |
| Update owner employee | ✅ Allowed |

**Why:** Deleting an owner employee would leave a company without an owner, breaking the permission system that relies on owner bypass.

---

### C. RoleAppointment Owner Validation

RoleAppointments with `business_type='owner'` have two constraints:

1. **Only ONE owner role appointment per company** - Prevents multiple role appointments marked as owner
2. **Owner role can only be assigned to employees with business_type='owner'** - Ensures the role assignment matches the employee's type

**Implementation:**
```ruby
# app/models/role_appointment.rb
validate :only_one_owner_appointment_per_company, on: :create

private

def only_one_owner_appointment_per_company
  return unless business_type.to_s == "owner" && company_id.present?

  # Constraint 1: Only one owner appointment per company
  owner_exists = RoleAppointment.where(
    company_id: company_id,
    appoint_to_type: "Employee",
    business_type: :owner
  ).where.not(id: self.id).exists?

  if owner_exists
    errors.add(:base, "Only one owner role assignment is allowed per company.")
  end

  # Constraint 2: Owner role can only be assigned to owner employees
  if appoint_to_type == "Employee" && appoint_to_id.present?
    employee = Employee.find_by(id: appoint_to_id)
    if employee && employee.business_type.to_s != "owner"
      errors.add(:base, "Owner role can only be assigned to owner employees.")
    end
  end
end
```

**Behavior:**
| Action | Result |
|--------|--------|
| Create owner RoleAppointment to owner employee | ✅ Allowed |
| Create second owner RoleAppointment | ❌ Validation error blocked |
| Assign owner role to non-owner employee | ❌ Validation error blocked |
| Update existing owner role appointment | ✅ Allowed |

**Error messages:**
```
Base: Only one owner role assignment is allowed per company.
Base: Owner role can only be assigned to owner employees.
```

---

### C. Seed Service Fix

The `Seed::EmployeeService` is fixed to never randomly select `"owner"` business_type, since owner employees are created via `Company#setup_owner_records`:

```ruby
# app/services/seed/employee_service.rb
business_type ||= (Employee.business_types.keys - ["owner"]).sample
```

**Note:** Use strings (`"owner"`) not symbols (`:owner`) because Rails enums store keys as strings by default.

---

### D. Test Factory Fix

Test factories explicitly use non-owner business types to avoid validation failures:

```ruby
# spec/factories/employees.rb
employee_business_type { ["full_time", "part_time", "contractor", "intern"].sample }
```

**Note:** Use strings, not symbols.

---

### E. Summary

| Validation | Table | Constraint |
|------------|-------|------------|
| Employee uniqueness | `employees` | Only 1 with `business_type='owner'` per company |
| Employee protection | `employees` | Owner employee cannot be discarded or destroyed |
| RoleAppointment uniqueness | `role_appointments` | Only 1 with `business_type='owner'` per company |
| RoleAppointment → Employee | `role_appointments` | Owner role can only point to employees with `business_type='owner'` |

---

## 15. Authorization with Pundit

Skycom integrates **Pundit** with the ABAC system to provide controller-level authorization. This keeps the frontend simple - the BE handles all permission checks and redirects or returns errors appropriately.

### Core Concept

| Response Format | Behavior |
|----------------|----------|
| **HTML** | Redirects to referrer (or root) with flash alert message |
| **JSON** | Returns `{ error, policy, action }` with 403 status |

Frontend does NOT need to handle authorization - the user either sees the data (authorized) or gets redirected/errors (unauthorized).

### A. Companies::Authorizable Concern

Include this in any company-related controller to enable Pundit authorization:

```ruby
# app/controllers/companies/application_controller.rb
class Companies::ApplicationController < ApplicationController
  include Companies::Authorizable
  # ... rest of controller
end
```

This concern:
1. Includes `Pundit::Authorization`
2. Adds a `before_action :authorize_current_employee!` that **auto-derives the policy class** from the controller class name (e.g., `Companies::PropertyMappingsController` → `Companies::PropertyMappingsPolicy`) and calls `authorize` for every action automatically
3. Rescues `Pundit::NotAuthorizedError` and handles unauthorized responses based on format
4. If no matching policy class exists, returns a 500 error with "Security Policy for ... not found."

### B. Implementation

**File**: `app/controllers/concerns/companies/authorizable.rb`

```ruby
# app/controllers/concerns/companies/authorizable.rb
module Companies::Authorizable
  extend ActiveSupport::Concern

  included do
    include Pundit::Authorization
    before_action :authorize_current_employee!
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def authorize_current_employee!
    raise Pundit::NotAuthorizedError unless current_employee

    # Derive policy class from controller name
    # e.g., Companies::PropertyMappingsController → Companies::PropertyMappingsPolicy
    policy_class_name = self.class.name.sub("Controller", "Policy")
    query_method = "#{action_name}?"

    begin
      policy_class = policy_class_name.constantize
      authorize current_employee, query_method, policy_class: policy_class
    rescue NameError
      # If the policy doesn't exist, return a 500 error
      message = "Security Policy for #{policy_class_name} not found."

      respond_to do |format|
        format.html do
          flash[:alert] = message
          redirect_to(request.referrer || root_path)
        end
        format.json do
          render json: { errors: [ message ] }, status: :internal_server_error
        end
      end
    end
  end

  def user_not_authorized(exception)
    message = "You are not authorized to perform this action."

    respond_to do |format|
      format.html do
        flash[:alert] = message
        redirect_to(request.referrer || root_path)
      end
      format.json do
        render json: {
          errors: [ message ],
          policy: exception.policy.class.to_s,
          action: exception.query
        }, status: :forbidden
      end
    end
  end
end
```

### C. Permission Policy

Policies define which actions an employee can perform. They use the ABAC `can?` method:

```ruby
# app/policies/companies/permission_policy.rb
class Companies::PermissionPolicy < ApplicationPolicy
  def index?
    record.can?(:read, PolicyAppointment)
  end

  def create?
    record.can?(:create, PolicyAppointment)
  end

  def update?
    record.can?(:update, PolicyAppointment)
  end
end
```

### D. Usage in Controller

No explicit `authorize` call is needed in controller actions. The `before_action :authorize_current_employee!` in `Companies::Authorizable` automatically authorizes every action — it derives the policy class from the controller name and the query method from the action name:

```ruby
# app/controllers/companies/property_mappings_controller.rb
class Companies::PropertyMappingsController < Companies::ApplicationController
  def index
    # No explicit authorize call — the before_action handles it.
    # Auto-derived: policy_class: Companies::PropertyMappingsPolicy, query: "index?"

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { roles: current_company.permissions } }
    end
  end
end
```

### E. Response Examples

**HTML Request (unauthorized):**
- Redirects to previous page (or root)
- Flash: "You are not authorized to perform this action."

**JSON Request (unauthorized):**
```json
{
  "error": "You are not authorized to perform this action.",
  "policy": "Companies::PermissionPolicy",
  "action": "index?"
}
```
Status: 403 Forbidden

### F. Frontend Pattern

Since authorization is handled BE-side, Stimulus controllers don't need authorization checks:

```javascript
// NO authorization check needed - user only sees this page if authorized
async loadData() {
  const response = await fetchJson(url)
  this.roles = response.roles
  this.renderContent()
}
```

If the API returns 403, the user is redirected by the browser. No special handling required.

### G. Controller-to-Policy Naming Convention

Pundit maps controllers to policies by convention. When you create a new controller, you must also create a matching policy:

| Controller | Policy | Resource in ABAC |
|------------|--------|-----------------|
| `Companies::PermissionsController` | `Companies::PermissionPolicy` | `PolicyAppointment` |
| `Companies::CategoriesController` | `Companies::CategoriesPolicy` | `Category` |
| `Companies::PropertyMappingsController` | `Companies::PropertyMappingsPolicy` | `PropertyMapping` |
| `Companies::BranchesController` | `Companies::BranchesPolicy` | `Branch` |

#### The Rule

Given a controller under `Companies::` namespace, the policy is:
```
Companies::<ControllerName>Policy
```
where `<ControllerName>` matches the controller class name (plural, PascalCase).

#### How Auto-Discovery Works

Since `Companies::Authorizable` includes a `before_action :authorize_current_employee!`, you never need to call `authorize` manually in your controller actions. The method automatically:

1. **Derives the policy class**: `self.class.name.sub("Controller", "Policy")` — e.g., `Companies::PropertyMappingsController` becomes `Companies::PropertyMappingsPolicy`
2. **Derives the query method**: `"#{action_name}?"` — e.g., `"update"` becomes `"update?"`
3. **Calls `authorize`**: `authorize current_employee, query_method, policy_class: policy_class`

This is why every controller under `Companies::` namespace needs a corresponding policy file at `app/policies/companies/`. If the policy file doesn't exist, the `before_action` rescues the `NameError` and returns a 500 error with `"Security Policy for #{policy_class_name} not found."`

#### What Happens If the Policy Is Missing

When `authorize_current_employee!` tries to constantize the policy class, it raises `NameError`:
```
uninitialized constant Companies::PropertyMappingsPolicy
```

This is caught by the `rescue NameError` in `authorize_current_employee!` and returns a 500 error with `"Security Policy for Companies::PropertyMappingsPolicy not found."`

#### Steps to Add a New Policy

1. Create the policy file at `app/policies/companies/<resource>_policy.rb`
2. Define action methods (index?, create?, update?, destroy?)
3. Each method calls `record.can?(:action, ResourceClass)` using ABAC
4. Add the resource name to the seed service's `RESOURCES` constant
5. Add CRUD permissions to the relevant roles in `assign_policies_to_roles`
6. Re-seed the database to create the policy records

### Summary

| Layer | Responsibility |
|-------|----------------|
| **ABAC** | Defines what permissions employees have |
| **Pundit Policy** | Maps actions to ABAC `can?` checks |
| **Controller** | Authorization is automatic via `before_action` in `Authorizable` |
| **Authorizable** | Handles errors (redirect/json) |
| **Frontend** | Simple - just renders data |

(End of file)