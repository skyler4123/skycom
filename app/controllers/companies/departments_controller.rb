# app/controllers/companies/departments_controller.rb

class Companies::DepartmentsController < Companies::ApplicationController

  def index
    # debugger
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @departments = @company.departments
        render json: { departments: @departments }
      end
    end
  end
end
