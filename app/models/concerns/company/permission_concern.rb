module Company::PermissionConcern
  extend ActiveSupport::Concern

  included do
    # =========================================================================
    # PERMISSIONS (RBAC)
    # =========================================================================

    def permissions
      # REASON: cache_key_with_version includes the 'updated_at' timestamp.
      # If any Role or PolicyAppointment is touched, this key changes, 
      # forcing Rails to skip the cache and re-run the heavy database query.
      cache_key = "#{cache_key_with_version}/permissions"

      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
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
    end

    def permissions_by_resource
      cache_key = "#{cache_key_with_version}/permissions_by_resource"

      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        roles.includes(:policies).each_with_object({}) do |role, hash|
          role_permissions = role.policies.group_by(&:resource).transform_values do |policies|
            policies.map(&:action)
          end
          
          hash[role.name] = role_permissions
        end
      end
    end
  end
end
