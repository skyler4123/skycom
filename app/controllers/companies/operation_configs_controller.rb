# frozen_string_literal: true

# Companies::OperationConfigsController — company-wide Operation configuration.
# Operations are seeded, never created here. Update permits metadata only; saving
# it copies the metadata to every appointment, whose local metadata otherwise wins
# when effective config is built. Index caches the company-level payload for
# OPERATIONS_CACHE_EXPIRY and filters it by q/operation_type/workflow_status/resolution.
# Serves Stimulus: Companies_OperationConfigs_IndexController (index),
#                  Companies_OperationConfigs_ShowController (show),
#                  Companies_OperationConfigs_EditController (edit, update)
# Endpoints: GET /companies/:company_id/operation_configs(.json?q=&operation_type=&workflow_status=&resolution=),
#            GET /companies/:company_id/operation_configs/:id(.json),
#            GET /companies/:company_id/operation_configs/:id/edit,
#            PATCH /companies/:company_id/operation_configs/:id
# Docs: docs/OPERATIONS.md
class Companies::OperationConfigsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        rows = cached_operation_config_rows

        render json: {
          operation_configs: filter_operation_config_rows(rows),
          filters: operation_config_filter_options(rows)
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

  def cached_operation_config_rows
    Rails.sync_cache.fetch(
      CacheKeyService.company_operation_configs(current_company.id),
      expires_in: OPERATIONS_CACHE_EXPIRY
    ) do
      current_company.operations
        .includes(:branch_operation_appointments, :operation_warehouse_appointments)
        .order(:operation_type)
        .map { |operation| format_operation_config(operation) }
    end
  end

  def filter_operation_config_rows(rows)
    filtered = rows

    if params[:q].present?
      query = params[:q].to_s.downcase
      filtered = filtered.select do |row|
        [ row["name"], row["code"] ].compact.any? { |value| value.to_s.downcase.include?(query) }
      end
    end

    filtered = filtered.select { |row| row["operation_type"] == params[:operation_type] } if params[:operation_type].present?
    filtered = filtered.select { |row| row["workflow_status"] == params[:workflow_status] } if params[:workflow_status].present?
    filtered = filtered.select { |row| row["resolution"] == params[:resolution] } if params[:resolution].present?

    filtered
  end

  def operation_config_filter_options(rows)
    operation_types = rows.map { |row| row["operation_type"] }.compact.uniq

    {
      operation_types: operation_types.map do |operation_type|
        {
          value: operation_type,
          name: OPERATION_TYPES.dig(operation_type.to_sym, :label) || operation_type.humanize
        }
      end,
      statuses: Operation.workflow_statuses.keys.map do |status|
        { value: status, name: status.split("_").map(&:capitalize).join(" ") }
      end,
      resolutions: Operation.resolutions.keys.map do |resolution|
        { value: resolution, name: resolution.humanize }
      end
    }
  end

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
      "branch_appointment_count" => operation.branch_operation_appointments.size,
      "operation_warehouse_appointment_count" => operation.operation_warehouse_appointments.size
    )
  end
end
