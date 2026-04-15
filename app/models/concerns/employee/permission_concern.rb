# app/models/concerns/employee/permission_concern.rb

module Employee::PermissionConcern
  extend ActiveSupport::Concern

  included do
    # =========================================================================
    # PERMISSIONS (ABAC) - Tag-Supported Structure
    # =========================================================================

    # 1. The Public Check
    # Now supports instance-level checks: current_employee.can?(:update, @product)
    def can?(action_name, target)
      action   = action_name.to_s
      # Handle both Class (Product) and Instance (@product)
      resource = target.is_a?(Class) ? target.name : target.class.name

      # 1. Find all policies for this resource + action across all roles
      matching_policies = []
      permissions.each_value do |role_data|
        role_data[:policies].each do |p|
          matching_policies << p if p[:resource] == resource && p[:action] == action
        end
      end

      return false if matching_policies.empty?
      
      # 2. If it's just a Class check (e.g., can I see the page?), return true
      return true if target.is_a?(Class)

      # 3. Instance-level check: Evaluate tag_conditions
      matching_policies.any? { |policy| evaluate_tag_conditions(target, policy[:tag_conditions]) }
    end

    # 2. The ABAC Engine
    def evaluate_tag_conditions(target, conditions)
      return true if conditions.blank?
      return false unless target.respond_to?(:tags)

      # Map target tags into a hash for O(1) lookups: { "key" => "value" }
      target_tags = target.tags.each_with_object({}) { |t, h| h[t.key] = t.value }

      conditions.all? do |key, required_value|
        key_string = key.to_s
        
        case required_value
        when true
          target_tags.key?(key_string)              # Must have tag key
        when false
          !target_tags.key?(key_string)             # Must NOT have tag key
        else
          target_tags[key_string] == required_value.to_s # Exact value match
        end
      end
    end

    # 3. The Cache Layer (Remains the same)
    def permissions
      cache_key = "#{cache_key_with_version}/permissions"
      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        load_permissions_from_db
      end
    end

    # 4. Updated Database Logic to include tag_conditions
    def load_permissions_from_db
      roles.includes(:policies).each_with_object({}) do |role, hash|
        hash[role.name] = {
          id: role.id,
          description: role.description,
          policies: role.policies.map do |policy|
            {
              id: policy.id,
              resource: policy.resource,
              action: policy.action,
              name: policy.name,
              # Added the new ABAC column here
              tag_conditions: policy.tag_conditions || {},
              business_type: policy.business_type
            }
          end
        }
      end
    end

    def clear_permissions_cache
      Rails.cache.delete("#{cache_key_with_version}/permissions")
      touch
    end
  end
end