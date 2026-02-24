class Retail::Management::ProductsController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @products = @retail.cached_products
        render json: { products: @products }
      end
    end
  end
end
