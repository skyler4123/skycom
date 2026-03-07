# app/controllers/companies/employees_controller.rb

class Companies::EmployeesController < Companies::ApplicationController

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @employees = @company.employees.includes(:user) # Use includes to avoid N+1 queries
        render json: { 
          employees: @employees.as_json(include: { user: { only: :email } }) 
        }
      end
    end
  end
end
