class Retail::Management::DepartmentsController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @departments  = @retail.departments
        render json: { departments: @departments }
      end
    end
  end
end
