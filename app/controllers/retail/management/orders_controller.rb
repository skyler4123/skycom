class Retail::Management::OrdersController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @orders = @retail.cached_orders
        render json: { orders: @orders }
      end
    end
  end
end
