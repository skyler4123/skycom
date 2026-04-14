module Employee::PermissionConcern
  extend ActiveSupport::Concern

  included do
    # =========================================================================
    # PERMISSIONS (RBAC) - Standardized Rich Structure
    # =========================================================================

    # 1. The Public Check
    # Updated to navigate the new nested structure: roles -> policies -> resource
    def can?(action_name, resource_name)
      action   = action_name.to_s
      resource = resource_name.is_a?(Class) ? resource_name.name : resource_name.to_s

      # Search through all roles to find if any policy matches
      permissions.any? do |_role_name, role_data|
        role_data[:policies].any? do |p| 
          p[:resource] == resource && p[:action] == action 
        end
      end
    end

    # 2. The Cache Layer
    def permissions
      # Using cache_key_with_version for consistency with Company
      cache_key = "#{cache_key_with_version}/permissions"
      
      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        load_permissions_from_db
      end
    end

    # 3. The Rich Database Logic (Matching Company)
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
