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

## 7. Client Cache System

Skycom caches company data in the browser's `localStorage` for fast frontend access across all Stimulus controllers.

### Storage Keys
| Key | Description |
|-----|------------|
| `client_cache_data` | JSON blob containing `companies`, `employees`, `enums`, etc. |
| `client_cache_version` | Timestamp version for cache invalidation |

### Backend Endpoint
`ClientCacheController#index` returns the cached data:

```json
{
  "user": { "id": "...", "email": "..." },
  "companies": [{ "id": "...", "name": "...", "branches": [], "departments": [], "roles": [] }],
  "enums": { "employee": { "lifecycle_statuses": [{ "name": "Active", "value": "active" }] } },
  "employees": [...]
}
```

### Frontend Helpers (`auth_helpers.js`)
```javascript
// Get cached company data
const companies = Helpers.currentCompanies()      // → Company[]
const company = Helpers.currentCompany()           // → Company | null
const branches = Helpers.currentBranches()           // → Branch[]
const roles = Helpers.currentRoles()                   // → Role[]
const enums = Helpers.Enums()                    // → Enums object

// Full cache access
const cache = Helpers.getCache()                   // → { user, companies, enums, employees }
const currentUser = Helpers.currentUser()         // → User | null
```

### Usage in Stimulus Controllers
```javascript
import { currentCompany, currentRoles } from "controllers/helpers/auth_helpers"

export default class Companies_ProductsIndexController extends Companies_LayoutController {
  async loadData() {
    const roles = currentRoles()
    // Use roles for permission checks or UI filtering
  }
}
```

---

## 8. Permissions UI Endpoint

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

## 9. Backend Implementation Requirements

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

### Cache Clearing
After any create/destroy, call `company.clear_permissions_cache` to invalidate both:
- `permissions` cache
- `permissions_by_resource` cache

This ensures the ABAC permission checks always use fresh data.

---

## 10. Frontend Implementation Pattern

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

## 11. Permission Resource Name

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
attribute :permission_resource_name, :string, default: -> { _1.class.name }
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
  attribute :permission_resource_name, :string, default: -> { _1.class.name }
end

# app/models/order.rb
class Order < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { _1.class.name }
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

## 13. Stimulus Controller Action Pattern

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

(End of file)