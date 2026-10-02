# app/controllers/companies/stock_pendings_controller.rb
#
# StockPendings dashboard API (Shell-First). Static table (no TableConfig or
# Meilisearch — StockPending is a lean ledger-style record): index filters by
# warehouse_id / workflow_status. Holds are created through
# StockPendings::HoldService (pending moves only via hold/release ledger rows);
# quantity/stock/warehouse are immutable after creation (422 on change).
# Serves Stimulus: Companies_StockPendings_IndexController (index JSON),
#                  Companies_StockPendings_NewController (new.json reference data + create),
#                  Companies_StockPendings_ShowController (show.json + release/cancel),
#                  Companies_StockPendings_EditController (edit.json + update name/reason)
# Endpoints:
#   GET   /companies/:company_id/stock_pendings(.json)          — index dashboard
#   GET   /companies/:company_id/stock_pendings/new(.json)      — new form reference data
#   GET   /companies/:company_id/stock_pendings/:id(.json)      — show with ledger
#   GET   /companies/:company_id/stock_pendings/:id/edit(.json) — edit form
#   POST  /companies/:company_id/stock_pendings(.json) { stock_pending: {...} }
#         — hold stock (422 + persist-nothing on insufficient stock)
#   PATCH /companies/:company_id/stock_pendings/:id(.json) { stock_pending: { name, reason } }
#   POST  /companies/:company_id/stock_pendings/:id/release     — release the hold
#   POST  /companies/:company_id/stock_pendings/:id/cancel      — cancel the hold
# Docs: docs/superpowers/specs/2026-10-02-stock-pending-design.md
class Companies::StockPendingsController < Companies::ApplicationController
  before_action :find_pending, only: [ :show, :edit, :update, :release, :cancel ]

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.stock_pendings.includes(:stock, :warehouse, :product)
        scope = scope.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?

        @pagy, @pendings_results = pagy(:offset, scope.order(created_at: :desc), jsonapi: true)

        render json: {
          stock_pendings: format_stock_pendings(@pendings_results),
          warehouses: current_company.warehouses.order(:name).map { |w| w.as_json(only: [ :id, :name ]) },
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { stock_pending: format_stock_pending(@pending, with_ledger: true) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: form_reference_data }
    end
  end

  def edit
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          stock_pending: format_stock_pending(@pending),
          **form_reference_data
        }
      end
    end
  end

  def create
    stock = current_company.stocks.find(pending_params[:stock_id])
    result = StockPendings::HoldService.call(
      company: current_company, warehouse: stock.warehouse, stock: stock,
      quantity: pending_params[:quantity],
      business_type: pending_params[:business_type] || :manual,
      name: pending_params[:name], reason: pending_params[:reason]
    )

    if result[:success]
      render json: { stock_pending: format_stock_pending(result[:stock_pending]), status: "ok" }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: [ e.message ] }, status: :not_found
  end

  def update
    unless @pending.holding? || @pending.workflow_status_draft?
      return render json: { errors: [ "Pending is already #{@pending.workflow_status}, only draft/holding pendings can be edited" ] },
        status: :unprocessable_content
    end

    if (pending_params.keys.map(&:to_s) & %w[quantity stock_id warehouse_id product_id business_type]).any?
      return render json: { errors: [ "Quantity, stock and business type are immutable once held" ] },
        status: :unprocessable_content
    end

    if @pending.update(pending_params.slice(:name, :reason))
      render json: { stock_pending: format_stock_pending(@pending.reload), status: "ok" }
    else
      render json: { errors: @pending.errors.full_messages }, status: :unprocessable_content
    end
  end

  def release
    run_transition(target: :release)
  end

  def cancel
    run_transition(target: :cancel)
  end

  private

  def find_pending
    @pending = current_company.stock_pendings.find(params[:id])
  end

  def pending_params
    params.require(:stock_pending).permit(
      :stock_id, :quantity, :business_type, :name, :reason
    )
  end

  # One transition = one release ledger row + status stamps; failures roll
  # back everything and render 422 (docs/API_ERROR_FORMAT.md).
  def run_transition(target:)
    result = StockPendings::ReleaseService.call(stock_pending: @pending, target: target)
    if result[:success]
      render json: { stock_pending: format_stock_pending(@pending.reload), status: "ok" }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  def format_stock_pending(pending, with_ledger: false)
    payload = pending.as_json(only: [
      :id, :name, :reason, :code, :quantity, :warehouse_id, :stock_id, :product_id,
      :status_changed_at, :released_at,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at
    ]).merge(
      product_name: pending.product&.name,
      warehouse_name: pending.warehouse&.name,
      stock_code: pending.stock&.code
    )
    return payload unless with_ledger

    payload.merge(
      ledger: pending.stock_transactions.order(:created_at).map { |t|
        t.as_json(only: [ :id, :direction, :transaction_type, :quantity, :warehouse_id, :product_id, :created_at ])
      }
    )
  end

  def format_stock_pendings(pendings)
    pendings.map { |p| format_stock_pending(p) }
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
end
