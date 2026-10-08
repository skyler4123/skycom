# app/controllers/companies/permission_logs_controller.rb
#
# Permission audit trail (read-only, Shell-First). Rows are written explicitly
# by Companies::PermissionsController via PermissionLogs::WriteService — no writes here.
# Serves Stimulus: Companies_PermissionLogs_IndexController|ShowController
# Endpoints: GET /companies/:company_id/permission_logs(.json) — see config/routes.rb
# Docs: docs/ABAC.md
class Companies::PermissionLogsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.permission_logs
          .includes(:employee, :role, :policy, :policy_role_appointment)
          .order(created_at: :desc)
        scope = scope.where(role_id: params[:role_id]) if params[:role_id].present?
        scope = scope.where(policy_id: params[:policy_id]) if params[:policy_id].present?
        scope = scope.where(resource_name: params[:resource_name]) if params[:resource_name].present?
        scope = scope.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        scope = scope.where(action: params[:log_action]) if params[:log_action].present?
        scope = scope.where("permission_logs.created_at >= ?", params[:from]) if params[:from].present?
        scope = scope.where("permission_logs.created_at <= ?", params[:to]) if params[:to].present?

        @pagy, @results = pagy(:offset, scope, jsonapi: true)

        render json: {
          permission_logs: @results.map { |l| format_log(l) },
          pagination: @pagy.data_hash,
          filters: filter_options
        }
      end
    end
  end

  def show
    log = current_company.permission_logs
      .includes(:employee, :role, :policy, :policy_role_appointment).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { permission_log: format_log(log) } }
    end
  end

  private

  def filter_options
    {
      roles: current_company.roles.map { |r| { id: r.id, name: r.name } },
      policies: current_company.policies.map { |p|
        { id: p.id, name: p.name.presence || "#{p.resource}##{p.action}" }
      },
      resource_names: current_company.permission_logs.distinct.pluck(:resource_name).compact,
      actions: PermissionLog.actions.keys
    }
  end

  def format_log(l)
    l.as_json(only: %i[id policy_id role_id policy_role_appointment_id employee_id action
      employee_name role_name policy_name resource_name policy_action
      from_workflow_status to_workflow_status metadata
      lifecycle_status workflow_status business_type expiration_date discarded_at created_at]).merge(
      role: l.role&.as_json(only: %i[id name]) || { id: l.role_id, name: l.role_name },
      policy: l.policy&.as_json(only: %i[id name resource action]) ||
        { id: l.policy_id, name: l.policy_name, resource: l.resource_name, action: l.policy_action },
      employee: { id: l.employee_id, name: l.employee_name || l.employee&.name }
    )
  end
end
