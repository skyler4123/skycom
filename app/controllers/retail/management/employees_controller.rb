class Retail::Management::EmployeesController < Retail::Management::ApplicationController
  # GET /companies or /companies.json
  def index
    # render html: "", layout: true
    @stores = @retail.stores
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { retail: @retail, stores: @stores } }
    end
  end
end
