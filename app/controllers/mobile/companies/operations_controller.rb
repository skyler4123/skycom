# frozen_string_literal: true

# Mobile::Companies::OperationsController — Shell-First list of the operation
# appointments this employee can open. The page shell hydrates from .json; the
# list itself is never server-rendered.
# Serves Stimulus: Mobile_Companies_Operations_IndexController
# Endpoints: GET /mobile/companies/:company_id/operations(.json)
# Docs: docs/MOBILE.md §2-§3, docs/OPERATIONS.md
class Mobile::Companies::OperationsController < Mobile::Companies::BaseController
  def index
    respond_to do |format|
      format.html do
        @page_title = "Operations"
        render_mobile_shell(json_url: mobile_company_operations_path(@company, format: :json))
      end
      format.json { render json: operations_payload }
    end
  end

  private

  def operations_payload
    branch_appointments = @company.branch_operation_appointments.includes(:operation, :branch).to_a
    warehouse_appointments = @company.operation_warehouse_appointments.includes(:operation, :warehouse).to_a

    appointments = (branch_appointments + warehouse_appointments)
      .select { |appointment| appointment.operation.accessible_by?(@employee, appointment: appointment) }
      .sort_by do |appointment|
        [
          appointment.operation.name.to_s.downcase,
          appointment.is_a?(BranchOperationAppointment) ? 0 : 1
        ]
      end

    {
      company: { id: @company.id, name: @company.name },
      employee: { name: @employee.name },
      appointments: appointments.map { |appointment| appointment_payload(appointment) }
    }
  end

  def appointment_payload(appointment)
    branch_appointment = appointment.is_a?(BranchOperationAppointment)
    location = branch_appointment ? appointment.branch : appointment.warehouse

    {
      id: appointment.id,
      location_type: branch_appointment ? "branch" : "warehouse",
      location: location && { id: location.id, name: location.name },
      operation: {
        id: appointment.operation.id,
        name: appointment.operation.name,
        code: appointment.operation.code,
        operation_type: appointment.operation.operation_type,
        workflow_status: appointment.operation.workflow_status
      },
      appointment_workflow_status: appointment.workflow_status
    }
  end
end
