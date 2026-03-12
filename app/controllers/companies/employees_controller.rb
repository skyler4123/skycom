# app/controllers/companies/employees_controller.rb

class Companies::EmployeesController < Companies::ApplicationController

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # 1. Apply Filtering Logic
        scope = current_company.employees.includes(:user, :roles, :departments)
        scope = scope.where(departments: { id: params[:department_id] }) if params[:department_id].present?
        scope = scope.joins(:roles).where(roles: { id: params[:role_id] }) if params[:role_id].present?
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(lifecycle_status: params[:status]) if params[:status].present?

        @pagy, @employees_results = pagy(:offset, scope, jsonapi: true)

        # 2. Always provide filter options so the form stays populated
        filter_options = {
          departments: current_company.departments.map { |d| { name: d.name, value: d.id} },
          roles: current_company.roles.map { |r| { name: r.name, value: r.id } },
          statuses: Employee.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
          types: Employee.business_types.keys.map { |t| { name: t.humanize, value: t } }
        }

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
