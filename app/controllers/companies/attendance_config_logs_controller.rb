# app/controllers/companies/attendance_config_logs_controller.rb
#
# AttendanceConfig audit trail (read-only, Shell-First). Rows are written
# explicitly by Companies::AttendanceConfigsController after create/update.
# Serves Stimulus: Companies_AttendanceConfigLogs_IndexController|ShowController
# Endpoints: GET /companies/:company_id/attendance_config_logs(.json) — see config/routes.rb
class Companies::AttendanceConfigLogsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_config_logs
          .includes(:employee, :branch, :attendance_config)
          .order(created_at: :desc)
        scope = scope.where(attendance_config_id: params[:attendance_config_id]) if params[:attendance_config_id].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where(action: params[:log_action]) if params[:log_action].present?
        scope = scope.where("attendance_config_logs.created_at >= ?", params[:from]) if params[:from].present?
        scope = scope.where("attendance_config_logs.created_at <= ?", params[:to]) if params[:to].present?

        @pagy, @results = pagy(:offset, scope, jsonapi: true)

        render json: {
          attendance_config_logs: @results.map { |l| format_log(l) },
          pagination: @pagy.data_hash,
          filters: filter_options
        }
      end
    end
  end

  def show
    log = current_company.attendance_config_logs.includes(:employee, :branch, :attendance_config).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { attendance_config_log: format_log(log) } }
    end
  end

  private

  def filter_options
    {
      attendance_configs: current_company.attendance_configs.includes(:branch).map { |c|
        { id: c.id, name: c.branch&.name || c.id }
      },
      branches: current_company.branches.map { |b| b.as_json(only: [ :id, :name ]) },
      actions: AttendanceConfigLog.actions.keys
    }
  end

  def format_log(l)
    l.as_json(only: %i[id attendance_config_id branch_id employee_id action employee_name branch_name
      latitude longitude allowed_radius_meters allowed_wifi_ssid require_photo resolution_strategy
      lifecycle_status workflow_status business_type expiration_date metadata discarded_at created_at]).merge(
      branch: { id: l.branch_id, name: l.branch_name || l.branch&.name },
      employee: { id: l.employee_id, name: l.employee_name || l.employee&.name }
    )
  end
end
