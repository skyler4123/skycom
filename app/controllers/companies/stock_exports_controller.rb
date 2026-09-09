# app/controllers/companies/stock_exports_controller.rb
#
# StockExports dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Products (?q= / ?filters[key]= → Meilisearch via
# StockExports::SearchQueryService; plain DB path otherwise). quantity is a
# filterable metric (StockExport.ms_extra_filterable_columns).
# Serves Stimulus: Companies_StockExports_IndexController (index JSON incl. q/filters passthrough)
# Endpoints: GET /companies/:company_id/stock_exports(.json) — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md
class Companies::StockExportsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stock_exports.includes(:product, :branch, :category, :warehouse)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

        search = StockExports::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @exports_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          stock_exports: format_stock_exports(@exports_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  private

  def format_stock_export(export)
    export.as_json(only: [
      :id, :name, :code, :category_id, :quantity,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ] + property_columns).merge(
      product_name: export.product&.name,
      warehouse_name: export.warehouse&.name,
      branch_name: export.branch&.name,
      category_name: export.category&.name,
      from_name: format_polymorphic_name(export.appoint_from),
      to_name: format_polymorphic_name(export.appoint_to)
    )
  end

  def format_stock_exports(exports)
    exports.map { |e| format_stock_export(e) }
  end

  def format_polymorphic_name(obj)
    return nil unless obj
    obj.try(:name) || obj.try(:title) || "#{obj.class.name}##{obj.id}"
  end

  def property_columns
    @property_columns ||= DynamicSearchConcern::PROPERTY_COLUMNS
  end
end
