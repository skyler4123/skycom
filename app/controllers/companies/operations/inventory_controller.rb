# frozen_string_literal: true

# Companies::Operations::InventoryController — the Inventory operation. Hydrates
# the warehouse stock ledger, four KPI cards, inbound/outbound records and the
# cycle-count state; every write finishes inside the console (receive, transfer
# out, export, adjust, reorder, count) through the Inventory services.
#
# Serves Stimulus: Companies_Operations_Inventory_ShowController
# Endpoints:
#   GET    /companies/:company_id/operations/inventory/:operation_id
#   GET    /companies/:company_id/operations/inventory/:operation_id/ledger
#   GET    /companies/:company_id/operations/inventory/:operation_id/export
#   POST   /companies/:company_id/operations/inventory/:operation_id/receipts
#   POST   /companies/:company_id/operations/inventory/:operation_id/receipts/:receipt_id/post
#   POST   /companies/:company_id/operations/inventory/:operation_id/transfers
#   POST   /companies/:company_id/operations/inventory/:operation_id/transfers/:transfer_id/receive
#   POST   /companies/:company_id/operations/inventory/:operation_id/exports
#   POST   /companies/:company_id/operations/inventory/:operation_id/adjustments
#   POST   /companies/:company_id/operations/inventory/:operation_id/reorder
#   POST   /companies/:company_id/operations/inventory/:operation_id/counts
#   GET    /companies/:company_id/operations/inventory/:operation_id/counts/:count_id
#   PATCH  /companies/:company_id/operations/inventory/:operation_id/counts/:count_id
#   POST   /companies/:company_id/operations/inventory/:operation_id/counts/:count_id/submit
# Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/business_analysis/05-inventory.md
class Companies::Operations::InventoryController < Companies::Operations::BaseController
  before_action :set_warehouse

  rescue_from Inventory::Error, StockMovementService::Error, ActiveRecord::RecordInvalid,
    ActiveRecord::RecordNotFound do |error|
    render json: { errors: [ error.message ] }, status: :unprocessable_content
  end

  def ledger
    render json: Inventory::LedgerQueryService.call(
      company: current_company,
      warehouse: @warehouse,
      q: params[:q],
      filter: params[:filter],
      page: params[:page],
      per_page: params[:per_page]
    )
  end

  def export
    service = Inventory::LedgerCsvService.new(
      company: current_company,
      warehouse: @warehouse,
      q: params[:q],
      filter: params[:filter]
    )
    csv = service.call

    send_data csv,
      filename: service.filename,
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
  end

  def create_receipt
    render json: {
      status: "ok",
      **Inventory::ReceiveService.post(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        stock_id: receipt_params[:stock_id],
        quantity: receipt_params[:quantity],
        supplier_id: receipt_params[:supplier_id],
        location: receipt_params[:location],
        note: receipt_params[:note]
      )
    }
  end

  def post_receipt
    render json: {
      status: "ok",
      **Inventory::ReceiveService.post_import(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        import_id: params[:receipt_id],
        stock_id: receipt_params[:stock_id],
        quantity: receipt_params[:quantity],
        location: receipt_params[:location]
      )
    }
  end

  def create_transfer
    render json: {
      status: "ok",
      **Inventory::TransferService.transfer(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        stock_id: transfer_params[:stock_id],
        quantity: transfer_params[:quantity],
        destination_warehouse_id: transfer_params[:destination_warehouse_id],
        note: transfer_params[:note]
      )
    }
  end

  def receive_transfer
    render json: {
      status: "ok",
      **Inventory::TransferService.receive(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        transfer_id: params[:transfer_id]
      )
    }
  end

  def create_export
    render json: {
      status: "ok",
      **Inventory::ExportService.export(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        stock_id: export_params[:stock_id],
        quantity: export_params[:quantity],
        reference: export_params[:reference],
        note: export_params[:note]
      )
    }
  end

  def create_adjustment
    render json: {
      status: "ok",
      **Inventory::AdjustmentService.adjust(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        stock_id: adjustment_params[:stock_id],
        new_on_hand: adjustment_params[:new_on_hand],
        reason: adjustment_params[:reason],
        note: adjustment_params[:note]
      )
    }
  end

  def create_reorder
    render json: {
      status: "ok",
      **Inventory::ReorderService.create(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        stock_id: reorder_params[:stock_id],
        supplier_id: reorder_params[:supplier_id],
        quantity: reorder_params[:quantity]
      )
    }
  end

  def start_count
    render json: {
      status: "ok",
      **Inventory::CountService.start(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        notes: count_params[:notes]
      )
    }
  end

  def show_count
    render json: Inventory::CountService.show(
      company: current_company,
      warehouse: @warehouse,
      count_id: params[:count_id]
    )
  end

  def update_count
    render json: {
      status: "ok",
      **Inventory::CountService.save_progress(
        company: current_company,
        warehouse: @warehouse,
        count_id: params[:count_id],
        lines: count_lines,
        employee: current_employee
      )
    }
  end

  def submit_count
    render json: {
      status: "ok",
      **Inventory::CountService.submit(
        company: current_company,
        warehouse: @warehouse,
        employee: current_employee,
        count_id: params[:count_id],
        lines: count_lines
      )
    }
  end

  private

  def expected_operation_type
    :inventory
  end

  def operation_payload
    {
      coming_soon: false,
      inventory: Inventory::ConsoleService.call(company: current_company, appointment: @appointment)
    }
  end

  def set_warehouse
    @warehouse = @appointment&.warehouse
    return if @warehouse.present?

    respond_to do |format|
      format.html do
        redirect_to company_operations_path(current_company),
          alert: "Inventory requires a warehouse."
      end
      format.json do
        render json: { errors: [ "Inventory requires a warehouse." ] }, status: :unprocessable_content
      end
    end
  end

  def receipt_params
    params.fetch(:receipt, ActionController::Parameters.new).permit(:stock_id, :quantity, :supplier_id, :location, :note)
  end

  def transfer_params
    params.fetch(:transfer, ActionController::Parameters.new).permit(:stock_id, :quantity, :destination_warehouse_id, :note)
  end

  def export_params
    params.fetch(:stock_export, ActionController::Parameters.new).permit(:stock_id, :quantity, :reference, :note)
  end

  def adjustment_params
    params.fetch(:adjustment, ActionController::Parameters.new).permit(:stock_id, :new_on_hand, :reason, :note)
  end

  def reorder_params
    params.fetch(:reorder, ActionController::Parameters.new).permit(:stock_id, :supplier_id, :quantity)
  end

  def count_params
    params.fetch(:count, ActionController::Parameters.new).permit(:notes)
  end

  def count_lines
    permitted = params.fetch(:count, ActionController::Parameters.new).permit(lines: [ :id, :counted_quantity ])
    permitted[:lines] || []
  end
end
