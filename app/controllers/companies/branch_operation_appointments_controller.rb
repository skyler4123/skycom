# frozen_string_literal: true

# Companies::BranchOperationAppointmentsController — branch-level operation toggles and
# metadata. Operation config overrides this row's metadata when effective config is
# built. Only update is routed.
# Serves Stimulus: Companies_Operations_IndexController (edit config modal)
# Endpoints: PATCH /companies/:company_id/branch_operation_appointments/:id
# Docs: docs/OPERATIONS.md
class Companies::BranchOperationAppointmentsController < Companies::ApplicationController
  def update
    appointment = current_company.branch_operation_appointments
      .includes(:operation, :branch)
      .find(params[:id])

    return render_invalid_status unless valid_workflow_status?

    if appointment.update(appointment_params)
      respond_to do |format|
        format.html { redirect_to company_operations_path(current_company), notice: "Operation appointment updated." }
        format.json do
          render json: {
            appointment: OperationSerializer.appointment(
              appointment,
              employee: current_employee,
              launch_path: launch_path_for(appointment)
            ),
            message: "Operation appointment updated."
          }
        end
      end
    else
      render_errors(appointment.errors.full_messages)
    end
  end

  private

  def appointment_params
    params.require(:branch_operation_appointment).permit(:workflow_status, metadata: {})
  end

  def valid_workflow_status?
    raw = params.require(:branch_operation_appointment)
    return true unless raw.key?(:workflow_status)

    BranchOperationAppointment.workflow_statuses.key?(raw[:workflow_status].to_s)
  end

  def launch_path_for(appointment)
    OperationLaunchService.call(
      company: current_company,
      operation: appointment.operation,
      appointment: appointment
    )
  end

  def render_invalid_status
    render_errors([ "Invalid workflow status" ])
  end

  def render_errors(errors)
    respond_to do |format|
      format.html { redirect_to company_operations_path(current_company), alert: errors.to_sentence }
      format.json { render json: { errors: errors }, status: :unprocessable_content }
    end
  end
end
