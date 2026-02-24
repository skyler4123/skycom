class Retail::Management::CustomersController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @customers = @retail.cached_customers
        render json: { customers: @customers }
      end
    end
  end
end
