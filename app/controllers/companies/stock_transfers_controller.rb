# app/controllers/companies/stock_transfers_controller.rb
#
# StockTransfers dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Products (?q= / ?filters[key]= → Meilisearch via
# StockTransfers::SearchQueryService; plain DB path otherwise). quantity is a
# filterable metric (StockTransfer.ms_extra_filterable_columns).
# Serves Stimulus: Companies_StockTransfers_IndexController (index JSON incl. q/filters passthrough)
# Endpoints: GET /companies/:company_id/stock_transfers(.json) — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md
class Companies::StockTransfersController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stock_transfers.includes(:product, :branch, :category, :warehouse)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

        search = StockTransfers::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @transfers_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          stock_transfers: format_stock_transfers(@transfers_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  private

  def format_stock_transfer(transfer)
    transfer.as_json(only: [
      :id, :name, :code, :category_id, :quantity,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ] + property_columns).merge(
      product_name: transfer.product&.name,
      warehouse_name: transfer.warehouse&.name,
      branch_name: transfer.branch&.name,
      category_name: transfer.category&.name,
      from_name: format_polymorphic_name(transfer.appoint_from),
      to_name: format_polymorphic_name(transfer.appoint_to)
    )
  end

  def format_stock_transfers(transfers)
    transfers.map { |t| format_stock_transfer(t) }
  end

  def format_polymorphic_name(obj)
    return nil unless obj
    obj.try(:name) || obj.try(:title) || "#{obj.class.name}##{obj.id}"
  end

  def property_columns
    @property_columns ||= DynamicSearchConcern::PROPERTY_COLUMNS
  end
end
