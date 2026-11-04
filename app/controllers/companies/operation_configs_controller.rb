# frozen_string_literal: true

# Companies::OperationConfigsController — company-wide Operation configuration.
# Operations are seeded, never created here. Update permits metadata only; the Operation
# metadata wins over every appointment's metadata when effective config is built.
# Serves Stimulus: Companies_OperationConfigs_IndexController (index),
#                  Companies_OperationConfigs_ShowController (show),
#                  Companies_OperationConfigs_EditController (edit, update)
# Endpoints: GET /companies/:company_id/operation_configs(.json),
#            GET /companies/:company_id/operation_configs/:id(.json),
#            GET /companies/:company_id/operation_configs/:id/edit,
#            PATCH /companies/:company_id/operation_configs/:id
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
          operation_configs: operations.map { |operation| format_operation_config(operation) }
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { operation_config: format_operation_config(find_operation) } }
    end
  end

  def edit
    find_operation

    respond_to do |format|
      format.html { render html: "", layout: true }
    end
  end

  def update
    operation = find_operation

    if operation.update(operation_config_params)
      respond_to do |format|
        format.html do
          redirect_to company_operation_config_path(current_company, operation),
            notice: "Operation config updated."
        end
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
          redirect_to edit_company_operation_config_path(current_company, operation),
            alert: operation.errors.full_messages.to_sentence
        end
        format.json { render json: { errors: operation.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def find_operation
    current_company.operations
      .includes(:branch_operation_appointments, :operation_warehouse_appointments)
      .find(params[:id])
  end

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
