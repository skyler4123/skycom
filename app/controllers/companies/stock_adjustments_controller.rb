# app/controllers/companies/stock_adjustments_controller.rb
#
# StockAdjustments dashboard API (Shell-First). Stock-take corrections as a
# dedicated document: direction (increase/decrease) + reason, line items via
# StockItemAppointment. create runs the movement through
# StockMovementService::Adjustments::CreateService — one transaction for
# document + lines + ledger rows + quantity (remove side is hold-aware floored).
# Serves Stimulus: (future) Companies_StockAdjustments_IndexController
# Endpoints:
#   GET  /companies/:company_id/stock_adjustments(.json) — index dashboard
#   POST /companies/:company_id/stock_adjustments(.json) { stock_adjustment: {...}, stock_items: [...] }
# Docs: docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md
class Companies::StockAdjustmentsController < Companies::ApplicationController
  include Companies::StockMovementConcern

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

  def format_stock_adjustment(adjustment)
    adjustment.as_json(only: [
      :id, :name, :code, :category_id, :quantity, :direction, :reason,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ] + property_columns).merge(
      warehouse_name: adjustment.warehouse&.name,
      branch_name: adjustment.branch&.name,
      category_name: adjustment.category&.name,
      by_name: format_polymorphic_name(adjustment.appoint_by)
    )
  end

  def format_polymorphic_name(obj)
    return nil unless obj

    obj.try(:name) || "#{obj.class.name}##{obj.id}"
  end

  def property_columns
    @property_columns ||= DynamicSearchConcern::PROPERTY_COLUMNS
  end
end
