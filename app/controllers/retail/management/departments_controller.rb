class Retail::Management::DepartmentsController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
    end
  end
end
