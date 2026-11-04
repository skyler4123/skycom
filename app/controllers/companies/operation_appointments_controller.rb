# frozen_string_literal: true

# Companies::OperationAppointmentsController — shared show/edit/update flow for
# branch and warehouse operation appointments. Subclasses define the scoped
# relation, strong-param key, and member paths. Not routed directly.
# Serves Stimulus: Companies_BranchOperationAppointments_ShowController|EditController,
#                  Companies_OperationWarehouseAppointments_ShowController|EditController
# Docs: docs/OPERATIONS.md
class Companies::OperationAppointmentsController < Companies::ApplicationController
  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { appointment: appointment_payload } }
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
    end
  end

  def update
    return render_invalid_status unless valid_workflow_status?

    if appointment.update(appointment_params)
      respond_to do |format|
        format.html { redirect_to appointment_path, notice: "Operation appointment updated." }
        format.json do
          render json: {
            appointment: appointment_payload,
            message: "Operation appointment updated."
          }
        end
      end
    else
      render_errors(appointment.errors.full_messages)
    end
  end

  private

  def appointment
    @appointment ||= appointment_scope.find(params[:id])
  end

  def appointment_scope
    raise NotImplementedError, "#{self.class} must define #appointment_scope"
  end

  def appointment_param_key
    raise NotImplementedError, "#{self.class} must define #appointment_param_key"
  end

  def appointment_path
    raise NotImplementedError, "#{self.class} must define #appointment_path"
  end

  def edit_appointment_path
    raise NotImplementedError, "#{self.class} must define #edit_appointment_path"
  end

  def appointment_params
    params.require(appointment_param_key).permit(:workflow_status, metadata: {})
  end

  def valid_workflow_status?
    raw = params.require(appointment_param_key)
    return true unless raw.key?(:workflow_status)

    raw[:workflow_status].to_s.in?(appointment.class.workflow_statuses.keys)
  end

  def appointment_payload
    OperationSerializer.appointment(
      appointment,
      employee: current_employee,
      launch_path: launch_path_for(appointment)
    )
  end

  def launch_path_for(record)
    OperationLaunchService.call(
      company: current_company,
      operation: record.operation,
      appointment: record
    )
  end

  def render_invalid_status
    render_errors([ "Invalid workflow status" ])
  end

  def render_errors(errors)
    respond_to do |format|
      format.html { redirect_to edit_appointment_path, alert: errors.to_sentence }
      format.json { render json: { errors: errors }, status: :unprocessable_content }
    end
  end
end
