# frozen_string_literal: true

# Company::PermissionConcern — Atomic purpose: company-level RBAC view helpers
# that expose roles with their policies and cached permission maps.
#
# Why it exists: the Permissions UI and authorization checks need the same
# role-to-policy projections; caching them on the company avoids N+1 queries and
# repeated assembly.
# How it works: #permissions, #permissions_by_role, and #permissions_by_resource
# read through Rails.sync_cache (PERMISSIONS_CACHE_EXPIRY) and are cleared by
# #clear_permissions_cache, which also touches the company.
# Main associations: none directly; reads Company#roles and Company#policies,
# and uses PolicyRoleAppointment.
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

      Rails.sync_cache.fetch(cache_key, expires_in: PERMISSIONS_CACHE_EXPIRY) do
        all_policies = policies.where.not(business_type: :owner).to_a

        roles.where.not(business_type: :owner).map do |role|
          role_policies = role.policy_role_appointments.includes(:policy).to_a

          {
            id: role.id,
            name: role.name,
            description: role.description,
            policies: all_policies.select { |policy| role_policies.find { |a| a.policy_id == policy.id } }.map do |policy|
              appointment = role_policies.find { |a| a.policy_id == policy.id }

              {
                id: policy.id,
                name: policy.name,
                description: policy.description,
                code: policy.code,
                resource: policy.resource,
                action: policy.action,
                business_type: policy.business_type,
                tag_conditions: policy.tag_conditions || {},
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

    # Only active PolicyRoleAppointments - used for actual permission checks (can?)
    def permissions_by_role
      cache_key = "#{cache_key_with_version}/permissions_by_role"

      Rails.sync_cache.fetch(cache_key, expires_in: PERMISSIONS_CACHE_EXPIRY) do
        roles.includes(:policy_role_appointments).each_with_object({}) do |role, hash|
          active_appointments = role.policy_role_appointments.active.includes(:policy)

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

      Rails.sync_cache.fetch(cache_key, expires_in: PERMISSIONS_CACHE_EXPIRY) do
        roles.includes(:policy_role_appointments).each_with_object({}) do |role, hash|
          active_appointments = role.policy_role_appointments.active.includes(:policy)
          role_permissions = active_appointments.group_by { |a| a.policy.resource }.transform_values do |appointments|
            appointments.map { |a| a.policy.action }
          end

          hash[role.name] = role_permissions
        end
      end
    end

    def clear_permissions_cache
      Rails.sync_cache.delete("#{cache_key_with_version}/permissions")
      Rails.sync_cache.delete("#{cache_key_with_version}/permissions_by_role")
      Rails.sync_cache.delete("#{cache_key_with_version}/permissions_by_resource")

      touch
    end
  end
end
