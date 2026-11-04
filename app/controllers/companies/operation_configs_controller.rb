# frozen_string_literal: true

# Companies::OperationConfigsController — company-wide Operation configuration.
# Operations are seeded, never created here. Update permits metadata only; the Operation
# metadata wins over every appointment's metadata when effective config is built.
# Serves Stimulus: Companies_OperationConfigs_IndexController (index, update modal)
# Endpoints: GET /companies/:company_id/operation_configs, PATCH /companies/:company_id/operation_configs/:id
# Docs: docs/OPERATIONS.md
class Companies::OperationConfigsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        operations = current_company.operations
          .includes(:branch_operation_appointments, :operation_warehouse_appointments)
          .order(:operation_type)

        render json: {
          operation_configs: operations.map { |operation| format_operation_config(operation) },
          roles: current_company.roles.order(:name).map { |role| { id: role.id, name: role.name } }
        }
      end
    end
  end

  def update
    operation = current_company.operations.find(params[:id])

    if operation.update(operation_config_params)
      respond_to do |format|
        format.html { redirect_to company_operation_configs_path(current_company), notice: "Operation config updated." }
        format.json do
          render json: {
            operation: OperationSerializer.operation(operation),
            message: "Operation config updated."
          }
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to company_operation_configs_path(current_company),
            alert: operation.errors.full_messages.to_sentence
        end
        format.json { render json: { errors: operation.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def operation_config_params
    params.require(:operation).permit(metadata: {})
  end

  def format_operation_config(operation)
    OperationSerializer.operation(operation).merge(
      branch_appointment_count: operation.branch_operation_appointments.size,
      operation_warehouse_appointment_count: operation.operation_warehouse_appointments.size
    )
  end
end
