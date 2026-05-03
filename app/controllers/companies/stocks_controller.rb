# app/controllers/companies/stocks_controller.rb

class Companies::StocksController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stocks.includes(:product, :warehouse, :branch)
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?

        if params[:search].present?
          scope = scope.where("sku ILIKE ? OR barcode ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
        end

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
      :id, :name, :quantity, :reorder, :sku, :barcode,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ]).merge(
      product_name: stock.product&.name,
      warehouse_name: stock.warehouse&.name,
      branch_name: stock.branch&.name
    )
  end

  def format_stocks(stocks)
    stocks.map { |stock| format_stock(stock) }
  end
end
