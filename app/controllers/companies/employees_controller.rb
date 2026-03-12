# app/controllers/companies/employees_controller.rb

class Companies::EmployeesController < Companies::ApplicationController

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        #  Apply Filtering Logic
        scope = current_company.employees.includes(:user, :roles, :departments)
        scope = scope.where(departments: { id: params[:department_id] }) if params[:department_id].present?
        scope = scope.joins(:roles).where(roles: { id: params[:role_id] }) if params[:role_id].present?
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(lifecycle_status: params[:status]) if params[:status].present?

        #  Paginate the scoped results
        @pagy, @employees_results = pagy(:offset, scope, jsonapi: true)

        # If you prefer to ALWAYS send them, remove this condition.
        is_initial_load = params[:department_id].blank? && params[:role_id].blank?
        
        filter_options = if is_initial_load
          {
            departments: current_company.departments.map { |d| [d.name, d.id] },
            roles: current_company.roles.map { |r| [r.name, r.id] },
            statuses: Employee.lifecycle_statuses.keys.map { |s| [s.humanize, s] },
            types: Employee.business_types.keys.map { |t| [t.humanize, t] }
          }
        else
          {} # Keep the key, but send empty data to save resources
        end

        render json: { 
          employees: format_employees(@employees_results), 
          pagination: @pagy.data_hash,
          filter_options: filter_options
        }
      end
    end
  end

  private

  def format_employees(employees)
    employees.map do |employee|
      employee.as_json(include: { user: { only: :email } }).merge(
        roles: employee.roles.map { |r| { id: r.id, name: r.name } },
        departments: employee.departments.map { |d| { id: d.id, name: d.name } }
      )
    end
  end
end
