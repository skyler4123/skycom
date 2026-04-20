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

      # 1. Find all policies for this resource + action across all roles (active only)
      matching_policies = []
      permissions_by_role.each_value do |role_data|
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

    # 3. Returns all roles with ALL company policies
    # Each policy includes policy_appointment (if exists) with workflow_status
    # Used for Permissions UI page
    def permissions
      cache_key = "#{cache_key_with_version}/permissions"
      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        load_permissions_from_db
      end
    end

    # 4. Database Logic - All roles with all policies and their policy_appointment
    def load_permissions_from_db
      all_policies = company.policies.to_a

      roles.map do |role|
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

    # 5. Only active PolicyAppointments - used for can? checks
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
                tag_conditions: appointment.policy.tag_conditions || {},
                business_type: appointment.policy.business_type
              }
            end
          }
        end
      end
    end

    def clear_permissions_cache
      Rails.cache.delete("#{cache_key_with_version}/permissions")
      Rails.cache.delete("#{cache_key_with_version}/permissions_by_role")
      touch
    end
  end
end
