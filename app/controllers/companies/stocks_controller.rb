# app/controllers/companies/stocks_controller.rb
#
# Stocks dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Products (?q= / ?filters[key]= → Meilisearch via
# Stocks::SearchQueryService; plain DB path otherwise). quantity/pending are
# filterable metrics (Stock.ms_extra_filterable_columns). show is the stock-row
# screen: one row's quantities, location, price and its recent ledger entries.
# Serves Stimulus: Companies_Stocks_IndexController (index JSON incl. q/filters passthrough),
#                  Companies_Stocks_ShowController (show JSON)
# Endpoints: GET /companies/:company_id/stocks(.json) — see config/routes.rb
#            GET /companies/:company_id/stocks/:id(.json)
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md, docs/STOCK.md
class Companies::StocksController < Companies::ApplicationController
  # Movements shown on one stock-row screen. The row identity is the stock's
  # (company, warehouse, product) triple because StockTransaction has no stock_id.
  STOCK_LEDGER_LIMIT = 20

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

  def show
    stock = current_company.stocks.includes(:product, :warehouse, :branch).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { stock: format_stock_row(stock), ledger: stock_ledger(stock) } }
    end
  end

  private

  def format_stock_row(stock)
    Stocks::RowPresenter.call(stock, company: current_company).merge(
      product_name: stock.product&.name,
      warehouse_name: stock.warehouse&.name,
      warehouse_code: stock.warehouse&.code,
      branch_name: stock.branch&.name,
      updated_at: stock.updated_at.iso8601
    )
  end

  def stock_ledger(stock)
    StockTransaction
      .where(company_id: current_company.id, warehouse_id: stock.warehouse_id, product_id: stock.product_id)
      .order(created_at: :desc, id: :desc)
      .limit(STOCK_LEDGER_LIMIT)
      .includes(:appoint_for)
      .map do |transaction|
        {
          id: transaction.id,
          direction: transaction.direction,
          transaction_type: transaction.transaction_type,
          transaction_type_label: transaction.transaction_type.to_s.humanize,
          quantity: transaction.quantity.to_i,
          document_code: transaction.appoint_for.try(:code),
          occurred_at: transaction.created_at.iso8601
        }
      end
  end

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
