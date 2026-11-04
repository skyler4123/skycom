# frozen_string_literal: true

# Companies::OperationsController — operation appointments (Shell-First).
# Index lists every branch and warehouse appointment for the company; launch
# resolves the appointment and redirects to the purpose-specific operation.
# Serves Stimulus: Companies_Operations_IndexController (index, launch)
# Endpoints: GET /companies/:company_id/operations, GET /companies/:company_id/operations/:id/launch
# Docs: docs/OPERATIONS.md
class Companies::OperationsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          operation_appointments: format_appointments(operation_appointments),
          roles: current_company.roles.order(:name).map { |role| { id: role.id, name: role.name } }
        }
      end
    end
  end

  def launch
    operation = current_company.operations.find(params[:id])
    appointment = Operations::AppointmentResolver.call(
      company: current_company,
      operation: operation,
      employee: current_employee,
      branch_id: params[:branch_id],
      warehouse_id: params[:warehouse_id]
    )

    return render_launch_error("No active operation appointment found for this location.") unless appointment
    return render_launch_error("This operation appointment is inactive.") unless appointment.workflow_status_active?
    return render_launch_error("You do not have access to this operation.", status: :forbidden) unless operation.accessible_by?(current_employee)

    launch_path = OperationLaunchService.call(
      company: current_company,
      operation: operation,
      appointment: appointment
    )

    respond_to do |format|
      format.html { redirect_to launch_path }
      format.json { render json: { launch_path: launch_path } }
    end
  end

  private

  def operation_appointments
    branch_appointments = current_company.branch_operation_appointments.includes(:operation, :branch).to_a
    warehouse_appointments = current_company.operation_warehouse_appointments.includes(:operation, :warehouse).to_a

    (branch_appointments + warehouse_appointments).sort_by do |appointment|
      [
        appointment.operation.name.to_s.downcase,
        appointment.is_a?(BranchOperationAppointment) ? 0 : 1,
        OperationSerializer.location(appointment)[:name].to_s.downcase
      ]
    end
  end

  def format_appointments(appointments)
    appointments.map do |appointment|
      OperationSerializer.appointment(
        appointment,
        employee: current_employee,
        launch_path: launch_path_for(appointment)
      )
    end
  end

  def launch_path_for(appointment)
    if appointment.is_a?(BranchOperationAppointment)
      launch_company_operation_path(current_company, appointment.operation, branch_id: appointment.branch_id)
    else
      launch_company_operation_path(current_company, appointment.operation, warehouse_id: appointment.warehouse_id)
    end
  end

  def render_launch_error(message, status: :unprocessable_content)
    respond_to do |format|
      format.html do
        redirect_to company_operations_path(current_company), alert: message
      end
      format.json { render json: { errors: [ message ] }, status: status }
    end
  end
end
