# app/controllers/companies/stock_transfers_controller.rb
#
# StockTransfers dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Products (?q= / ?filters[key]= → Meilisearch via
# StockTransfers::SearchQueryService; plain DB path otherwise). quantity is a
# filterable metric (StockTransfer.ms_extra_filterable_columns).
# Movement endpoints run the two-phase flow through StockMovementService::Transfers::* —
# all quantity writes go through StockTransaction's hardened callback (one DB
# transaction; failures roll back everything and render 422 { errors: [...] }).
# Serves Stimulus: Companies_StockTransfers_IndexController (index JSON incl. q/filters passthrough)
# Endpoints:
#   GET   /companies/:company_id/stock_transfers(.json)            — index dashboard
#   POST  /companies/:company_id/stock_transfers(.json) { stock_transfer: {...}, stock_items: [...] }
#         — builds the document + source-stock lines (pending; no movement yet)
#   POST  /companies/:company_id/stock_transfers/:id/initiate      — phase 1: hold source units
#   POST  /companies/:company_id/stock_transfers/:id/receive       — phase 2: move quantities + ledger rows
#   POST  /companies/:company_id/stock_transfers/:id/cancel        — release holds
# Docs: docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md, docs/DYNAMIC_TABLE.md §2.5
class Companies::StockTransfersController < Companies::ApplicationController
  include Companies::StockMovementConcern

  before_action :find_transfer, only: [ :initiate, :receive, :cancel ]

  def create
    transfer = StockTransfer.new(transfer_params)
    transfer.code = "#{StockTransfer::CODE_PREFIX}-#{SecureRandom.hex(4).upcase}" if transfer.code.blank?
    transfer.workflow_status = :pending # movement starts at initiate

    stock_items_params.each do |item|
      transfer.stock_item_appointments.build(
        company: current_company,
        stock: current_company.stocks.find(item[:stock_id]),
        quantity: item[:quantity]
      )
    end
    transfer.product_id ||= transfer.stock_item_appointments.first&.stock&.product_id
    transfer.quantity = transfer.stock_item_appointments.sum(&:quantity)
    transfer.branch ||= transfer.stock_item_appointments.first&.stock&.branch

    ActiveRecord::Base.transaction do
      transfer.save!
    end

    render json: { stock_transfer: format_stock_transfer(transfer), status: "ok" }
  rescue StockMovementService::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  def initiate
    run_movement do
      StockMovementService::Transfers::InitiateService.call(transfer: @transfer, employee: current_employee)
    end
  end

  def receive
    run_movement do
      StockMovementService::Transfers::ReceiveService.call(transfer: @transfer, employee: current_employee)
    end
  end

  def cancel
    run_movement do
      StockMovementService::Transfers::CancelService.call(transfer: @transfer, employee: current_employee)
    end
  end

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

  def find_transfer
    @transfer = current_company.stock_transfers.find(params[:id])
  end

  def transfer_params
    params.require(:stock_transfer).permit(:warehouse_id, :destination_warehouse_id, :branch_id, :name, :description, :business_type).tap do |h|
      h[:company] = current_company
    end
  end

  # One movement = one DB transaction. Service errors roll back the whole
  # movement; the rescue renders 422 (docs/API_ERROR_FORMAT.md).
  def run_movement
    ActiveRecord::Base.transaction do
      result = yield
      render json: { status: "ok", **result }
    end
  rescue StockMovementService::Error => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

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
