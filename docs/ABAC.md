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