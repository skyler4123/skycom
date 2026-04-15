class ClientCacheController < ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        debugger
        render json: {
          user: current_user.as_json,
          companies: current_user.accessible_companies.as_json(include: [ :branches, :departments, :roles ]),
          enums: {
            employee: {
              lifecycle_statuses: Employee.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
              workflow_statuses: Employee.workflow_statuses.keys.map { |s| { name: s.humanize, value: s } },
              business_types: Employee.business_types.keys.map { |t| { name: t.humanize, value: t } }
            }
          },
          company_permissions: current_user.accessible_companies.map(&:permissions),
          user_permissions: current_user.permissions
          # Future expansions:
          # settings: current_user.settings,
          # permissions: current_user.all_permissions
        }
      end
    end
  end
end
