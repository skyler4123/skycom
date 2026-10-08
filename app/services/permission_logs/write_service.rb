# frozen_string_literal: true

# PermissionLogs::WriteService — single write path for every permission audit row.
#
# Why it exists: permission mutations happen in Companies::PermissionsController
# (appointment toggle, tag_conditions edit, bulk resource setup) and will happen
# in Companies::PoliciesController when CRUD lands. All callers funnel here so
# the snapshot shape stays identical.
# How to use: call AFTER the mutation succeeds; never blocks the caller —
# controllers rescue and log to Rails.logger like TableConfigLog writes.
module PermissionLogs
  class WriteService
    def self.call(company:, action:, actor: nil, role: nil, policy: nil, appointment: nil,
      from_workflow_status: nil, to_workflow_status: nil,
      tag_conditions_before: nil, tag_conditions_after: nil)
      company.permission_logs.create!(
        action: action,
        employee: actor,
        employee_name: actor&.name,
        role: role,
        role_name: role&.name,
        policy: policy,
        policy_name: policy&.name,
        resource_name: policy&.resource,
        policy_action: policy&.action,
        policy_role_appointment: appointment,
        from_workflow_status: normalize_status(from_workflow_status),
        to_workflow_status: normalize_status(to_workflow_status),
        metadata: {
          "tag_conditions_before" => tag_conditions_before,
          "tag_conditions_after" => tag_conditions_after
        }.compact
      )
    end

    def self.normalize_status(value)
      return nil if value.nil?
      return value if value.is_a?(Integer)

      PolicyRoleAppointment.workflow_statuses[value.to_s]
    end
    private_class_method :normalize_status
  end
end
