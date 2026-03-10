# app/controllers/companies/employees_controller.rb

class Companies::EmployeesController < Companies::ApplicationController

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # Eager load departments through the appointment table
        @employees = current_company.employees.includes(:user, :roles, :departments).map do |employee|
          employee.as_json(include: { user: { only: :email } }).merge(
            roles: employee.roles.map { |r| { id: r.id, name: r.name } },
            # Map departments to a flat array of names or objects
            departments: employee.departments.map { |d| { id: d.id, name: d.name } }
          )
        end

        @pagy, @employees = pagy(:offset, @employees, jsonapi: true)
        render json: { employees: @employees, pagination: @pagy.data_hash }
      end
    end
  end
end
