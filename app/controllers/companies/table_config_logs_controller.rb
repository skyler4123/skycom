# app/controllers/companies/table_config_logs_controller.rb
#
# TableConfig audit trail (read-only, Shell-First). Rows are written explicitly
# by Companies::TableConfigsController after create/update — no writes here.
# Serves Stimulus: Companies_TableConfigLogs_IndexController|ShowController
# Endpoints: GET /companies/:company_id/table_config_logs(.json) — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md
class Companies::TableConfigLogsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.table_config_logs
          .includes(:employee, :category, :property_mapping, :table_config)
          .order(created_at: :desc)
        scope = scope.where(table_config_id: params[:table_config_id]) if params[:table_config_id].present?
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(property_mapping_id: params[:property_mapping_id]) if params[:property_mapping_id].present?
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where(action: params[:log_action]) if params[:log_action].present?
        scope = scope.where("table_config_logs.created_at >= ?", params[:from]) if params[:from].present?
        scope = scope.where("table_config_logs.created_at <= ?", params[:to]) if params[:to].present?

        @pagy, @results = pagy(:offset, scope, jsonapi: true)

        render json: {
          table_config_logs: @results.map { |l| format_log(l) },
          pagination: @pagy.data_hash,
          filters: filter_options
        }
      end
    end
  end

  def show
    log = current_company.table_config_logs.includes(:employee, :category, :property_mapping, :table_config).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { table_config_log: format_log(log) } }
    end
  end

  private

  def filter_options
    {
      table_configs: current_company.table_configs.map { |c|
        { id: c.id, name: c.name.presence || c.resource_name || c.id }
      },
      categories: current_company.categories.map { |c| c.as_json(only: [ :id, :name ]) },
      actions: TableConfigLog.actions.keys
    }
  end

  def format_log(l)
    l.as_json(only: %i[id table_config_id category_id property_mapping_id employee_id action
      employee_name category_name property_mapping_name
      name description resource_name metadata
      lifecycle_status workflow_status business_type expiration_date discarded_at created_at]).merge(
      category: l.category&.as_json(only: %i[id name]) || { id: l.category_id, name: l.category_name },
      employee: { id: l.employee_id, name: l.employee_name || l.employee&.name }
    )
  end
end
