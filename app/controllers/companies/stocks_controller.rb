# app/controllers/companies/stocks_controller.rb
#
# Stocks dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Products (?q= / ?filters[key]= → Meilisearch via
# Stocks::SearchQueryService; plain DB path otherwise). quantity/pending are
# filterable metrics (Stock.ms_extra_filterable_columns).
# Serves Stimulus: Companies_Stocks_IndexController (index JSON incl. q/filters passthrough)
# Endpoints: GET /companies/:company_id/stocks(.json) — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md
class Companies::StocksController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stocks.includes(:product, :warehouse, :branch, :category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

        search = Stocks::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

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
      :id, :name, :code, :category_id, :quantity, :pending,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ] + property_columns).merge(
      product_name: stock.product&.name,
      warehouse_name: stock.warehouse&.name,
      branch_name: stock.branch&.name,
      category_name: stock.category&.name
    )
  end

  def format_stocks(stocks)
    stocks.map { |stock| format_stock(stock) }
  end

  def property_columns
    @property_columns ||= DynamicSearchConcern::PROPERTY_COLUMNS
  end
end
