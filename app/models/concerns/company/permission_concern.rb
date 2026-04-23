module Company::PermissionConcern
  extend ActiveSupport::Concern

  included do
    # =========================================================================
    # PERMISSIONS (RBAC)
    # =========================================================================

    # Returns all roles with ALL company policies
    # Each policy includes policy_appointment (if exists) with workflow_status
    # Used for Permissions UI page - shows all policies with their assignment status
    # Excludes owner role (business_type = :owner)
    def permissions
      cache_key = "#{cache_key_with_version}/permissions"

      Rails.cache.fetch(cache_key, expires_in: 1.minutes) do
        all_policies = policies.to_a

        roles.reject { |role| owner_role?(role) }.map do |role|
          role_policies = role.policy_appointments.includes(:policy).to_a

          {
            id: role.id,
            name: role.name,
            description: role.description,
            policies: all_policies.map do |policy|
              appointment = role_policies.find { |a| a.policy_id == policy.id }

              {
                id: policy.id,
                name: policy.name,
                description: policy.description,
                code: policy.code,
                resource: policy.resource,
                action: policy.action,
                business_type: policy.business_type,
                policy_appointment: appointment ? {
                  id: appointment.id,
                  workflow_status: appointment.workflow_status
                } : nil
              }
            end
          }
        end
      end
    end

    def owner_role?(role)
      role.role_appointments.any? { |ra| ra.business_type == "owner" }
    end

    # Only active PolicyAppointments - used for actual permission checks (can?)
    def permissions_by_role
      cache_key = "#{cache_key_with_version}/permissions_by_role"

      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        roles.includes(:policy_appointments).each_with_object({}) do |role, hash|
          active_appointments = role.policy_appointments.active.includes(:policy)

          hash[role.name] = {
            id: role.id,
            description: role.description,
            policies: active_appointments.map do |appointment|
              {
                id: appointment.policy.id,
                policy_appointment_id: appointment.id,
                resource: appointment.policy.resource,
                action: appointment.policy.action,
                name: appointment.policy.name,
                business_type: appointment.policy.business_type
              }
            end
          }
        end
      end
    end

    def permissions_by_resource
      cache_key = "#{cache_key_with_version}/permissions_by_resource"

      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        roles.includes(:policy_appointments).each_with_object({}) do |role, hash|
          active_appointments = role.policy_appointments.active.includes(:policy)
          role_permissions = active_appointments.group_by { |a| a.policy.resource }.transform_values do |appointments|
            appointments.map { |a| a.policy.action }
          end

          hash[role.name] = role_permissions
        end
      end
    end

    def clear_permissions_cache
      Rails.cache.delete("#{cache_key_with_version}/permissions")
      Rails.cache.delete("#{cache_key_with_version}/permissions_by_role")
      Rails.cache.delete("#{cache_key_with_version}/permissions_by_resource")

      touch
    end
  end
end
