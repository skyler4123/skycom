# app/controllers/companies/stock_adjustments_controller.rb
#
# StockAdjustments dashboard API (Shell-First). Stock-take corrections as a
# dedicated document: direction (increase/decrease) + reason, line items via
# StockAdjustmentStockAppointment. create runs the movement through
# StockMovementService::Adjustments::CreateService — one transaction for
# document + lines + ledger rows + quantity (remove side is hold-aware floored).
# Serves Stimulus: Companies_StockAdjustments_IndexController (index JSON),
#                  Companies_StockAdjustments_NewController (new.json reference data),
#                  Companies_StockAdjustments_ShowController (show.json lines + ledger)
# Endpoints:
#   GET  /companies/:company_id/stock_adjustments(.json) — index dashboard
#   GET  /companies/:company_id/stock_adjustments/new(.json) — new form reference data
#   GET  /companies/:company_id/stock_adjustments/:id(.json) — show with lines + ledger
#   POST /companies/:company_id/stock_adjustments(.json) { stock_adjustment: {...}, stock_items: [...] }
# Docs: docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md
class Companies::StockAdjustmentsController < Companies::ApplicationController
  include Companies::StockMovementConcern

  def show
    adjustment = current_company.stock_adjustments
      .includes(stock_adjustment_stock_appointments: { stock: :product })
      .find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { stock_adjustment: format_stock_adjustment(adjustment, with_lines: true) } }
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
        scope = current_company.stock_adjustments.includes(:category, :warehouse, :branch)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @adjustments_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          stock_adjustments: @adjustments_results.map { |a| format_stock_adjustment(a) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    create_movement_document(StockAdjustment, StockMovementService::Adjustments::CreateService)
  end

  private

  def format_stock_adjustment(adjustment, with_lines: false)
    # NOTE: stock_adjustments has no quantity column — lines are the only
    # quantity truth, so the total is computed for the show payload.
    payload = adjustment.as_json(only: [
      :id, :name, :code, :category_id, :direction, :reason,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ] + property_columns).merge(
      warehouse_name: adjustment.warehouse&.name,
      branch_name: adjustment.branch&.name,
      category_name: adjustment.category&.name,
      by_name: format_polymorphic_name(adjustment.appoint_by)
    )
    return payload unless with_lines

    line_rows = adjustment.stock_adjustment_stock_appointments.map { |l|
      l.as_json(only: [ :id, :stock_id, :quantity ]).merge(
        product_name: l.stock.product&.name,
        warehouse_name: l.stock.warehouse&.name
      )
    }
    payload.merge(
      quantity: line_rows.sum { |l| l["quantity"].to_i },
      lines: line_rows,
      ledger: adjustment.stock_transactions.order(:created_at).map { |t|
        t.as_json(only: [ :id, :direction, :transaction_type, :quantity, :warehouse_id, :product_id, :created_at ])
      }
    )
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

    obj.try(:name) || "#{obj.class.name}##{obj.id}"
  end

  def property_columns
    @property_columns ||= DynamicSearchConcern::PROPERTY_COLUMNS
  end
end
