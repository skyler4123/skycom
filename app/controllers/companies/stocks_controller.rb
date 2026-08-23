# app/controllers/companies/stocks_controller.rb

class Companies::StocksController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stocks.includes(:product, :warehouse, :branch, :category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @stocks_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          stocks: format_stocks(@stocks_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  private

  def format_stock(stock)
    stock.as_json(only: [
      :id, :name, :quantity, :reorder,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ]).merge(
      product_name: stock.product&.name,
      warehouse_name: stock.warehouse&.name,
      branch_name: stock.branch&.name,
      category_name: stock.category&.name
    )
  end

  def format_stocks(stocks)
    stocks.map { |stock| format_stock(stock) }
  end
end
