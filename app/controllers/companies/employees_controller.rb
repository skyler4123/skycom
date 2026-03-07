# app/controllers/companies/employees_controller.rb

class Companies::EmployeesController < Companies::ApplicationController

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # Eager load both user (for email) and roles to prevent N+1 queries
        @employees = current_company.employees.includes(:user, :roles).map do |employee|
          employee.as_json(include: { user: { only: :email } }).merge(
            # Extract only the names of the roles into a flat array
            roles: employee.roles.map { |role| { id: role.id, name: role.name } }
          )
        end

        render json: { employees: @employees }
      end
    end
  end
end
