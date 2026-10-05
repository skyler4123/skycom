# app/controllers/companies/event_config_logs_controller.rb
#
# EventConfig audit trail (read-only, Shell-First). Rows are written explicitly
# by Companies::EventConfigsController after create/update — no writes here.
# Serves Stimulus: Companies_EventConfigLogs_IndexController|ShowController
# Endpoints: GET /companies/:company_id/event_config_logs(.json) — see config/routes.rb
class Companies::EventConfigLogsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.event_config_logs
          .includes(:employee, :category, :event_config)
          .order(created_at: :desc)
        scope = scope.where(event_config_id: params[:event_config_id]) if params[:event_config_id].present?
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where(action: params[:log_action]) if params[:log_action].present?
        scope = scope.where("event_config_logs.created_at >= ?", params[:from]) if params[:from].present?
        scope = scope.where("event_config_logs.created_at <= ?", params[:to]) if params[:to].present?

        @pagy, @results = pagy(:offset, scope, jsonapi: true)

        render json: {
          event_config_logs: @results.map { |l| format_log(l) },
          pagination: @pagy.data_hash,
          filters: filter_options
        }
      end
    end
  end

  def show
    log = current_company.event_config_logs.includes(:employee, :category, :event_config).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { event_config_log: format_log(log) } }
    end
  end

  private

  def filter_options
    {
      event_configs: current_company.event_configs.includes(:category).map { |c|
        { id: c.id, name: c.category&.name || c.id }
      },
      categories: current_company.categories.where(resource_name: "events").map { |c| c.as_json(only: [ :id, :name ]) },
      actions: EventConfigLog.actions.keys
    }
  end

  def format_log(l)
    l.as_json(only: %i[id event_config_id category_id employee_id action employee_name category_name
      create_stock_pending strict_stock_hold create_order_on_complete
      warn_on_facility_overlap warn_on_host_overlap
      lifecycle_status workflow_status business_type expiration_date metadata discarded_at created_at]).merge(
      category: l.category&.as_json(only: %i[id name]),
      employee: { id: l.employee_id, name: l.employee_name || l.employee&.name }
    )
  end
end
