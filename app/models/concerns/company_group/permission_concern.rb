module CompanyGroup::PermissionConcern
  extend ActiveSupport::Concern

  included do
    # =========================================================================
    # PERMISSIONS (RBAC)
    # =========================================================================

    def permissions
      # Eager load roles and their associated policies to prevent N+1 queries
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

    def permissions_by_resource
      roles.includes(:policies).each_with_object({}) do |role, hash|
        role_permissions = role.policies.group_by(&:resource).transform_values do |policies|
          policies.map(&:action)
        end
        
        hash[role.name] = role_permissions
      end
    end
  end
end
