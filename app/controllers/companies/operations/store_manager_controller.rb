# frozen_string_literal: true

# Companies::Operations::StoreManagerController — the Store Manager operation.
# Hydrates the resolved BranchOperationAppointment and exposes the live retail
# command payload: sales KPIs (invoice totals), the whole-day fulfilment queue,
# shelf replenishment with real transfer/purchase documents, cashier totals,
# branch-clock order volume, the real on-duty roster and the shift close sheet.
#
# Serves Stimulus: Companies_Operations_StoreManager_ShowController
# Endpoints:
#   GET  /companies/:company_id/operations/store_manager/:operation_id
#   GET  /companies/:company_id/operations/store_manager/:operation_id/queue
#   POST /companies/:company_id/operations/store_manager/:operation_id/orders/:order_id/mark_ready
#   POST /companies/:company_id/operations/store_manager/:operation_id/orders/:order_id/hand_over
#   POST /companies/:company_id/operations/store_manager/:operation_id/replenishments
#   POST /companies/:company_id/operations/store_manager/:operation_id/shift_close
# Docs: docs/OPERATIONS.md, docs/STOCK.md, docs/business_analysis/06-store-manager.md
class Companies::Operations::StoreManagerController < Companies::Operations::BaseController
  rescue_from StoreManager::Error, Inventory::Error, StockMovementService::Error,
    ActiveRecord::RecordInvalid do |error|
    render json: { errors: [ error.message ] }, status: :unprocessable_content
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: { errors: [ "Record not found." ] }, status: :not_found
  end

  def show
    payload = base_payload.merge(
      store_manager: StoreManager::ConsoleService.call(
        company: current_company,
        appointment: @appointment,
        now: Time.current,
        date: requested_date,
        tab: params[:tab],
        q: params[:q],
        page: params[:page]
      )
    )

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: payload }
    end
  end

  def queue
    render json: StoreManager::QueueQueryService.call(
      company: current_company,
      branch: branch,
      date: requested_date || LocalTime.today(branch, at: Time.current),
      now: Time.current,
      tab: params[:tab],
      q: params[:q],
      page: params[:page],
      read_only: !requested_date.nil? && requested_date != LocalTime.today(branch, at: Time.current)
    )
  end

  def mark_ready
    result = StoreManager::OrderFulfillmentService.mark_ready(company: current_company, order: scoped_order)
    render json: { message: result[:message], order: order_payload(result[:order]) }
  end

  def hand_over
    result = StoreManager::OrderFulfillmentService.hand_over(company: current_company, order: scoped_order)
    render json: { message: result[:message], order: order_payload(result[:order]) }
  end

  def create_replenishment
    render json: StoreManager::ReplenishmentService.call(
      company: current_company,
      branch: branch,
      employee: current_employee,
      stock_id: replenishment_params[:stock_id],
      quantity: replenishment_params[:quantity],
      supplier_id: replenishment_params[:supplier_id]
    )
  end

  def save_shift_close
    date = requested_date || LocalTime.today(branch, at: Time.current)
    render json: StoreManager::ShiftCloseService.save(
      company: current_company,
      branch: branch,
      employee: current_employee,
      date: date,
      opening_float_cents: shift_close_params[:opening_float_cents],
      counted_cash_cents: shift_close_params[:counted_cash_cents],
      note: shift_close_params[:note]
    )
  end

  private

  def expected_operation_type
    :store_manager
  end

  def operation_payload
    { coming_soon: false }
  end

  def base_payload
    {
      coming_soon: false,
      operation: OperationSerializer.operation(@operation),
      appointment: OperationSerializer.appointment(@appointment, employee: current_employee),
      config: effective_config
    }
  end

  def branch
    @appointment.branch
  end

  def requested_date
    return @requested_date if defined?(@requested_date)

    @requested_date = begin
      value = params[:date].presence
      if value.blank?
        nil
      else
        date = Date.iso8601(value)
        if date > LocalTime.today(branch, at: Time.current)
          raise StoreManager::Error, "Future dates are not available."
        end
        date
      end
    rescue Date::Error
      raise StoreManager::Error, "Choose a valid date."
    end
  end

  def scoped_order
    @scoped_order ||= current_company.orders
      .where(branch_id: branch.id, discarded_at: nil)
      .find(params[:order_id])
  end

  def order_payload(order)
    {
      id: order.id,
      code: order.code,
      fulfillment_status: order.fulfillment_status,
      fulfillment_label: order.fulfillment_status.humanize,
      handed_over_at: LocalTime.utc_iso(order.handed_over_at)
    }
  end

  def replenishment_params
    params.fetch(:replenishment, ActionController::Parameters.new)
      .permit(:stock_id, :quantity, :supplier_id)
  end

  def shift_close_params
    params.fetch(:shift_close, ActionController::Parameters.new)
      .permit(:opening_float_cents, :counted_cash_cents, :note)
  end
end
