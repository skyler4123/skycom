# frozen_string_literal: true

# Shared JSON shapes for Operations and their location appointments. Kept in one
# place so the Operations index, Operation Configs, launch and operation controllers all
# describe the same Operation/appointment contract.
class OperationSerializer
  OPERATION_ATTRIBUTES = %i[
    id name description code operation_type resolution metadata
    lifecycle_status workflow_status permission_resource_name
  ].freeze

  class << self
    def operation(operation)
      operation.as_json(only: OPERATION_ATTRIBUTES)
    end

    def appointment(appointment, employee:, launch_path: nil)
      record = appointment.operation
      payload = {
        id: appointment.id,
        kind: appointment.is_a?(BranchOperationAppointment) ? "branch" : "warehouse",
        operation: operation(record),
        location: location(appointment),
        metadata: appointment.metadata,
        effective_config: record.config_for(appointment),
        workflow_status: appointment.workflow_status,
        lifecycle_status: appointment.lifecycle_status,
        accessible: record.accessible_by?(employee),
        launch_path: launch_path
      }

      if appointment.is_a?(BranchOperationAppointment)
        payload[:branch] = { id: appointment.branch_id, name: appointment.branch.name }
      else
        payload[:warehouse] = { id: appointment.warehouse_id, name: appointment.warehouse.name }
      end

      payload
    end

    def location(appointment)
      if appointment.is_a?(BranchOperationAppointment)
        { id: appointment.branch_id, name: appointment.branch.name }
      else
        { id: appointment.warehouse_id, name: appointment.warehouse.name }
      end
    end
  end
end
