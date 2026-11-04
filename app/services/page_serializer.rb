# frozen_string_literal: true

# Shared JSON shapes for Pages and their location appointments. Kept in one
# place so the Pages index, Page Configs, launch and operation controllers all
# describe the same Page/appointment contract.
class PageSerializer
  PAGE_ATTRIBUTES = %i[
    id name description code page_type resolution metadata
    lifecycle_status workflow_status permission_resource_name
  ].freeze

  class << self
    def page(page)
      page.as_json(only: PAGE_ATTRIBUTES)
    end

    def appointment(appointment, employee:, launch_path: nil)
      record = appointment.page
      payload = {
        id: appointment.id,
        kind: appointment.is_a?(BranchPageAppointment) ? "branch" : "warehouse",
        page: page(record),
        location: location(appointment),
        metadata: appointment.metadata,
        effective_config: record.config_for(appointment),
        workflow_status: appointment.workflow_status,
        lifecycle_status: appointment.lifecycle_status,
        accessible: record.accessible_by?(employee),
        launch_path: launch_path
      }

      if appointment.is_a?(BranchPageAppointment)
        payload[:branch] = { id: appointment.branch_id, name: appointment.branch.name }
      else
        payload[:warehouse] = { id: appointment.warehouse_id, name: appointment.warehouse.name }
      end

      payload
    end

    def location(appointment)
      if appointment.is_a?(BranchPageAppointment)
        { id: appointment.branch_id, name: appointment.branch.name }
      else
        { id: appointment.warehouse_id, name: appointment.warehouse.name }
      end
    end
  end
end
