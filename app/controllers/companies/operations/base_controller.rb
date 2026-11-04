# frozen_string_literal: true

# Companies::Operations::BaseController — shared shell for purpose-specific
# operation screens. Resolves the company Operation, its active location appointment, and the
# access gate before the subclass renders its payload.
# Serves Stimulus: Companies_Operations_<Type>_ShowController (via subclasses)
# Docs: docs/OPERATIONS.md
class Companies::Operations::BaseController < Companies::ApplicationController
  before_action :set_operation
  before_action :set_appointment
  before_action :authorize_operation_roles!

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          operation: OperationSerializer.operation(@operation),
          appointment: OperationSerializer.appointment(@appointment, employee: current_employee),
          config: effective_config
        }.merge(operation_payload)
      end
    end
  end

  private

  def expected_operation_type
    raise NotImplementedError, "#{self.class} must define #expected_operation_type"
  end

  def set_operation
    @operation = current_company.operations.find_by!(id: params[:operation_id], operation_type: expected_operation_type)
  end

  def set_appointment
    @appointment = Operations::AppointmentResolver.call(
      company: current_company,
      operation: @operation,
      employee: current_employee,
      branch_id: params[:branch_id],
      warehouse_id: params[:warehouse_id]
    )

    return render_operation_error("No active operation appointment found for this location.") unless @appointment
    render_operation_error("This operation appointment is inactive.") unless @appointment.workflow_status_active?
  end

  def authorize_operation_roles!
    return if @operation.accessible_by?(current_employee)

    render_operation_error("You do not have access to this operation.", status: :forbidden)
  end

  def effective_config
    @effective_config ||= @operation.config_for(@appointment)
  end

  def operation_payload
    { coming_soon: true }
  end

  def render_operation_error(message, status: :unprocessable_content)
    respond_to do |format|
      format.html { redirect_to company_operations_path(current_company), alert: message }
      format.json { render json: { errors: [ message ] }, status: status }
    end
  end
end
