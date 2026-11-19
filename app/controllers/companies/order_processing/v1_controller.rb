# frozen_string_literal: true

# Companies::OrderProcessing::V1Controller — POS checkout → pay JSON API.
# Shell: docs/ORDER_PROCESSING_V1.md
# - checkout: CreateOrderService re-prices server-side, resolves the selling
#   stock row, writes product + service lines, and snapshots POS tax.
# - apply_discount/remove_discount: reserve/release a code on the pending order
#   and return authoritative totals.
# - pay: InitiatePaymentService writes the invoice total including tax.
#        Cash completes synchronously; QR waits for the webhook.
# - cancel: CancelOrderService voids a pending order and releases reservations.
# - pay_cancel: CancelPaymentService for an abandoned QR transaction.
# - All money actions return 423 while the POS terminal is locked.
# Serves Stimulus: Companies_Operations_Pos_ShowController
#                  Companies_TopUps_NewController (shares MockQrGateway path)
# Endpoints: POST checkout, pay, pay_cancel, apply_discount, remove_discount, cancel
# Docs: docs/ORDER_PROCESSING_V1.md, docs/DISCOUNTS.md
class Companies::OrderProcessing::V1Controller < Companies::ApplicationController
  before_action :reject_locked_terminal!, only: %i[checkout pay pay_cancel apply_discount remove_discount cancel]

  # Creates a pending Order from server prices. Does not touch stock/invoices.
  def checkout
    order_result = OrderProcessingV1::CreateOrderService.call(
      company: current_company,
      branch: current_company.branches.find(checkout_params[:branch_id]),
      items: checkout_params[:items],
      customer: checkout_params[:customer_id] ? current_company.customers.find_by(id: checkout_params[:customer_id]) : nil,
      employee: current_employee
    )

    render json: order_result.merge(message: "Order created"), status: :created
  rescue OrderProcessingV1::InvalidOrderItemError,
         OrderProcessingV1::InsufficientStockError => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  # Pays a pending Order via a branch-appointed payment method.
  # - Validates appointment is branch_level, belongs to order.branch and is active.
  # - Uses the order's pending discount (or reserves discount_code), computes the
  #   invoice total including tax, and creates the invoice/tax snapshots.
  # - Cash completes synchronously; QR leaves the transaction pending for the webhook.
  # - Rescues stock, payment-method, discount, amount, and order-state errors → 422.
  def pay
    order = current_company.orders.find(params[:order_id])
    appointment = BranchPaymentMethodAppointment
      .find_by!(id: params[:payment_method_appointment_id], company_id: current_company.id)

    result = OrderProcessingV1::InitiatePaymentService.call(
      order: order,
      appointment: appointment,
      discount_code: params[:discount_code].presence,
      employee: current_employee,
      cash_received_cents: params[:cash_received_cents]
    )

    # TODO: transaction_token (API) vs gateway_reference (DB) naming mismatch — unify later.
    payload = {
      status: result.status,
      order_id: result.order_id,
      subtotal_cents: result.subtotal_cents,
      discount_cents: result.discount_cents,
      tax_cents: result.tax_cents,
      total_cents: result.total_cents,
      currency: result.currency,
      cash_received_cents: result.cash_received_cents,
      change_cents: result.change_cents
    }
    payload[:transaction_id] = result.transaction_id if result.transaction_id
    payload[:transaction_token] = result.transaction_token if result.transaction_token
    payload[:qr_string] = result.qr_string if result.qr_string
    payload[:discount_amount_cents] = result.discount.amount_cents if result.discount
    payload[:message] = result.status == "paid" ? "Payment completed" : "Awaiting QR payment"

    render json: payload
  rescue OrderProcessingV1::InsufficientStockError
    render json: { errors: [ "Insufficient stock for payment" ] }, status: :unprocessable_content
  rescue OrderProcessingV1::InvalidPaymentMethodError,
         OrderProcessingV1::InvalidDiscountError,
         OrderProcessingV1::InvalidPaymentAmountError,
         OrderProcessingV1::InvalidOrderStateError => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  # Cancels an abandoned QR payment. Only a pending Transaction can be cancelled:
  # releases reserved stock (ReleaseReservedStockService) and marks txn failed.
  # Returns cancelled / not_pending — never raises for already completed/cancelled txns.
  # TODO: param transaction_token vs column gateway_reference naming — unify later.
  def pay_cancel
    cancelled = OrderProcessingV1::CancelPaymentService.call(
      transaction_token: params[:transaction_token],
      company: current_company
    )
    render json: { status: cancelled ? "cancelled" : "not_pending", message: "Payment cancelled" }
  end

  # Reserves a single-use code on the created order and returns the new totals.
  def apply_discount
    order = current_company.orders.find(params[:order_id])
    raise OrderProcessingV1::InvalidOrderStateError, "Order is not payable" unless order.workflow_status_pending?

    code = params[:discount_code].to_s.strip
    existing = order.discounts.status_pending.first
    return render json: discount_payload(order, existing, "Discount applied") if existing && existing.code == code.upcase

    result = Discounts::ApplyService.call(
      company: current_company, order: order, code: code, employee: current_employee
    )
    unless result[:success]
      render json: { errors: result[:errors] }, status: :unprocessable_content
      return
    end

    existing&.release! if existing
    render json: discount_payload(order, result[:discount], "Discount applied")
  rescue OrderProcessingV1::InvalidOrderStateError => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  def remove_discount
    order = current_company.orders.find(params[:order_id])
    raise OrderProcessingV1::InvalidOrderStateError, "Order is not payable" unless order.workflow_status_pending?

    Discounts::ReleaseService.call(order: order)
    render json: discount_payload(order, nil, "Discount removed")
  rescue OrderProcessingV1::InvalidOrderStateError => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  def cancel
    order = current_company.orders.find(params[:order_id])
    result = OrderProcessingV1::CancelOrderService.call(order: order, company: current_company)
    if result[:success]
      render json: { message: result[:message] }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def discount_payload(order, discount, message)
    totals = OrderProcessingV1::OrderTotalsService.call(
      order: order, discount_cents: discount&.amount_cents.to_i
    )
    {
      discount: discount ? { code: discount.code, amount_cents: discount.amount_cents } : nil,
      subtotal_cents: totals.subtotal_cents,
      discount_cents: totals.discount_cents,
      tax_cents: totals.tax_cents,
      total_cents: totals.total_cents,
      currency: totals.currency,
      message: message
    }
  end

  # The POS lock is a real server state, not only a CSS overlay. Money actions
  # reject while the current session has the company's terminal locked.
  def reject_locked_terminal!
    return unless session[:pos_locked_company_id] == current_company.id

    render json: { errors: [ "Terminal is locked" ] }, status: :locked
  end

  def checkout_params
    params.permit(:branch_id, :customer_id, items: [ :product_id, :service_id, :quantity ])
  end
end
