# frozen_string_literal: true

class Companies::OrderProcessing::V1Controller < Companies::ApplicationController
  def checkout
    result = OrderProcessingV1::CheckAvailabilityService.call(items: checkout_params[:items])

    unless result[:available]
      render json: { errors: [ "Insufficient stock" ], failed_item: result[:failed_item] }, status: :unprocessable_entity
      return
    end

    order_result = OrderProcessingV1::CreateOrderService.call(
      company: current_company,
      branch: current_company.branches.find(checkout_params[:branch_id]),
      items: checkout_params[:items],
      customer: checkout_params[:customer_id] ? current_company.customers.find_by(id: checkout_params[:customer_id]) : nil
    )

    render json: order_result.merge(message: "Order created"), status: :created
  end

  def pay
    order = current_company.orders.find(params[:order_id])
    appointment = PaymentMethodAppointment.branch_level
      .find_by!(id: params[:payment_method_appointment_id], company_id: current_company.id)

    result = OrderProcessingV1::InitiatePaymentService.call(order: order, appointment: appointment)

    payload = { status: result.status, order_id: result.order_id }
    payload[:transaction_id] = result.transaction_id if result.transaction_id
    payload[:transaction_token] = result.transaction_token if result.transaction_token
    payload[:qr_string] = result.qr_string if result.qr_string
    payload[:message] = result.status == "paid" ? "Payment completed" : "Awaiting QR payment"

    render json: payload
  rescue OrderProcessingV1::InsufficientStockError
    render json: { errors: [ "Insufficient stock for payment" ] }, status: :unprocessable_entity
  rescue OrderProcessingV1::InvalidPaymentMethodError => e
    render json: { errors: [ e.message ] }, status: :unprocessable_entity
  end

  def pay_cancel
    cancelled = OrderProcessingV1::CancelPaymentService.call(
      transaction_token: params[:transaction_token],
      company: current_company
    )
    render json: { status: cancelled ? "cancelled" : "not_pending", message: "Payment cancelled" }
  end

  private

  def checkout_params
    params.permit(:branch_id, :customer_id, items: [ :stock_id, :product_id, :quantity, :unit_price ])
  end
end
