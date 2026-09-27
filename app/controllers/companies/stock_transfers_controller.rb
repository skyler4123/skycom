# app/controllers/companies/stock_transfers_controller.rb
#
# StockTransfers dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Products (?q= / ?filters[key]= → Meilisearch via
# StockTransfers::SearchQueryService; plain DB path otherwise). quantity is a
# filterable metric (StockTransfer.ms_extra_filterable_columns).
# Movement endpoints run the two-phase flow through StockMovementService::Transfers::* —
# all quantity writes go through StockTransaction's hardened callback (one DB
# transaction; failures roll back everything and render 422 { errors: [...] }).
# Serves Stimulus: Companies_StockTransfers_IndexController (index JSON incl. q/filters passthrough),
#                  Companies_StockTransfers_NewController (new.json reference data),
#                  Companies_StockTransfers_ShowController (show.json lines + ledger + phase buttons),
#                  Companies_StockTransfers_EditController (edit.json + PATCH update while draft/pending)
# Endpoints:
#   GET   /companies/:company_id/stock_transfers(.json)            — index dashboard
#   GET   /companies/:company_id/stock_transfers/new(.json)        — new form reference data
#   GET   /companies/:company_id/stock_transfers/:id(.json)        — show with lines + ledger
#   GET   /companies/:company_id/stock_transfers/:id/edit(.json)   — edit form (document + reference data)
#   PATCH /companies/:company_id/stock_transfers/:id(.json) { stock_transfer: {...}, stock_items: [...] }
#         — update header + lines while draft/pending only
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
      transfer.stock_transfer_stock_appointments.build(
        company: current_company,
        stock: current_company.stocks.find(item[:stock_id]),
        quantity: item[:quantity]
      )
    end
    transfer.product_id ||= transfer.stock_transfer_stock_appointments.first&.stock&.product_id
    transfer.quantity = transfer.stock_transfer_stock_appointments.sum(&:quantity)
    transfer.branch ||= transfer.stock_transfer_stock_appointments.first&.stock&.branch

    if transfer.warehouse_id.present?
      transfer.stock_transfer_stock_appointments.each do |line|
        next if line.stock.warehouse_id == transfer.warehouse_id

        raise StockMovementService::Error,
          "Stock #{line.stock.code} belongs to another warehouse"
      end
    end

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

  def show
    transfer = current_company.stock_transfers
      .includes(stock_transfer_stock_appointments: { stock: :product })
      .find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { stock_transfer: format_stock_transfer(transfer, with_lines: true) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: form_reference_data }
    end
  end

  def edit
    transfer = current_company.stock_transfers
      .includes(stock_transfer_stock_appointments: { stock: :product })
      .find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          stock_transfer: format_stock_transfer(transfer, with_lines: true),
          **form_reference_data
        }
      end
    end
  end

  def update
    transfer = current_company.stock_transfers
      .includes(stock_transfer_stock_appointments: { stock: :product })
      .find(params[:id])

    unless transfer.workflow_status_draft? || transfer.workflow_status_pending?
      return render json: { errors: [ "Transfer is already #{transfer.workflow_status}, only draft/pending transfers can be edited" ] },
        status: :unprocessable_content
    end

    transfer.assign_attributes(transfer_params)
    transfer.stock_transfer_stock_appointments.destroy_all if stock_items_params.any?
    stock_items_params.each do |item|
      transfer.stock_transfer_stock_appointments.build(
        company: current_company,
        stock: current_company.stocks.find(item[:stock_id]),
        quantity: item[:quantity]
      )
    end

    if transfer.warehouse_id.present?
      transfer.stock_transfer_stock_appointments.each do |line|
        next if line.stock.warehouse_id == transfer.warehouse_id

        return render json: { errors: [ "Stock #{line.stock.code} belongs to another warehouse" ] },
          status: :unprocessable_content
      end
    end
    transfer.product_id ||= transfer.stock_transfer_stock_appointments.first&.stock&.product_id
    transfer.quantity = transfer.stock_transfer_stock_appointments.sum(&:quantity)

    if transfer.save
      render json: { stock_transfer: format_stock_transfer(transfer, with_lines: true), status: "ok" }
    else
      render json: { errors: transfer.errors.full_messages }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
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
        scope = current_company.stock_transfers.includes(:product, :branch, :category, :warehouse, :destination_warehouse)
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
  # movement; the rescue renders 422 (docs/API_ERROR_FORMAT.md) — mirroring
  # StockMovementConcern so validation/lookup failures never surface as 500.
  def run_movement
    ActiveRecord::Base.transaction do
      result = yield
      render json: { status: "ok", **result }
    end
  rescue StockMovementService::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  def format_stock_transfer(transfer, with_lines: false)
    payload = transfer.as_json(only: [
      :id, :name, :code, :category_id, :quantity,
      :destination_warehouse_id, :initiated_at, :received_at,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ] + property_columns).merge(
      product_name: transfer.product&.name,
      warehouse_name: transfer.warehouse&.name,
      destination_warehouse_name: transfer.destination_warehouse&.name,
      branch_name: transfer.branch&.name,
      category_name: transfer.category&.name,
      from_name: format_polymorphic_name(transfer.appoint_from),
      to_name: format_polymorphic_name(transfer.appoint_to)
    )
    return payload unless with_lines

    payload.merge(
      lines: transfer.stock_transfer_stock_appointments.map { |l|
        l.as_json(only: [ :id, :stock_id, :quantity ]).merge(
          product_name: l.stock.product&.name,
          warehouse_name: l.stock.warehouse&.name
        )
      },
      ledger: transfer.stock_transactions.order(:created_at).map { |t|
        t.as_json(only: [ :id, :direction, :transaction_type, :quantity, :warehouse_id, :product_id, :created_at ])
      }
    )
  end

  def format_stock_transfers(transfers)
    transfers.map { |t| format_stock_transfer(t) }
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
