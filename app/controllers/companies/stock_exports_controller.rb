# app/controllers/companies/stock_exports_controller.rb
#
# StockExports dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Products (?q= / ?filters[key]= → Meilisearch via
# StockExports::SearchQueryService; plain DB path otherwise). quantity is a
# filterable metric (StockExport.ms_extra_filterable_columns).
# create runs the movement through StockMovementService::Exports::CreateService —
# hold-aware floor enforced; nothing persisted when any line exceeds availability.
# Serves Stimulus: Companies_StockExports_IndexController (index JSON incl. q/filters passthrough),
#                  Companies_StockExports_NewController (new.json reference data),
#                  Companies_StockExports_ShowController (show.json lines + ledger)
# Endpoints:
#   GET  /companies/:company_id/stock_exports(.json)                          — index dashboard
#   GET  /companies/:company_id/stock_exports/new(.json)                      — new form reference data
#   GET  /companies/:company_id/stock_exports/:id(.json)                      — show with lines + ledger
#   POST /companies/:company_id/stock_exports(.json) { stock_export: {...}, stock_items: [...] }
# Docs: docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md, docs/DYNAMIC_TABLE.md §2.5
class Companies::StockExportsController < Companies::ApplicationController
  include Companies::StockMovementConcern

  def create
    create_movement_document(StockExport, StockMovementService::Exports::CreateService)
  end

  def show
    export = current_company.stock_exports
      .includes(stock_export_stock_appointments: { stock: :product })
      .find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { stock_export: format_stock_export(export, with_lines: true) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: form_reference_data }
    end
  end

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

  def format_stock_export(export, with_lines: false)
    payload = export.as_json(only: [
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
    return payload unless with_lines

    payload.merge(
      lines: export.stock_export_stock_appointments.map { |l|
        l.as_json(only: [ :id, :stock_id, :quantity ]).merge(
          product_name: l.stock.product&.name,
          warehouse_name: l.stock.warehouse&.name
        )
      },
      ledger: export.stock_transactions.order(:created_at).map { |t|
        t.as_json(only: [ :id, :direction, :transaction_type, :quantity, :warehouse_id, :product_id, :created_at ])
      }
    )
  end

  def format_stock_exports(exports)
    exports.map { |e| format_stock_export(e) }
  end

  def form_reference_data
    {
      warehouses: current_company.warehouses.order(:name).map { |w| w.as_json(only: [ :id, :name ]) },
      stocks: current_company.stocks.includes(:product, :warehouse).map { |s|
        s.as_json(only: [ :id, :product_id, :warehouse_id, :quantity, :pending ]).merge(
          product_name: s.product&.name,
          warehouse_name: s.warehouse&.name,
          available: s.quantity - s.pending
        )
      }
    }
  end

  def format_polymorphic_name(obj)
    return nil unless obj
    obj.try(:name) || obj.try(:title) || "#{obj.class.name}##{obj.id}"
  end

  def property_columns
    @property_columns ||= DynamicSearchConcern::PROPERTY_COLUMNS
  end
end
