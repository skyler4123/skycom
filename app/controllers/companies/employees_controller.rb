# app/controllers/companies/employees_controller.rb

class Companies::EmployeesController < Companies::ApplicationController

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @employees = @company.employees
        render json: { employees: @employees }
      end
    end
  end
end
