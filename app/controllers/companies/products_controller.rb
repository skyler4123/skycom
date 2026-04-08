# app/controllers/companies/products_controller.rb

class Companies::ProductsController < Companies::ApplicationController
  def index
    # debugger
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @products = @company.products
        render json: { products: @products }
      end
    end
  end
end
