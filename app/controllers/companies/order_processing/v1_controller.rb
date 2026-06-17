# frozen_string_literal: true

class Companies::OrderProcessing::V1Controller < Companies::ApplicationController
  def checkout
    result = OrderProcessingV1::CheckAvailabilityService.call(items: checkout_params[:items])

    unless result[:available]
      render json: { error: "Insufficient stock", failed_item: result[:failed_item] }, status: :unprocessable_entity
      return
    end

    order_result = OrderProcessingV1::CreateOrderService.call(
      company: current_company,
      branch: current_company.branches.find(checkout_params[:branch_id]),
      items: checkout_params[:items],
      customer: checkout_params[:customer_id] ? current_company.customers.find_by(id: checkout_params[:customer_id]) : nil
    )

    render json: order_result, status: :created
  end

  def pay
    order = current_company.orders.find(params[:order_id])

    items = order.order_appointments.map do |oa|
      product = oa.appoint_to
      stock = current_company.stocks.find_by!(product_id: product.id)
      { stock_id: stock.id, quantity: oa.quantity }
    end

    OrderProcessingV1::ReserveStockService.call(items: items)

    payment_result = OrderProcessingV1::ProcessPaymentService.call(order: order)

    OrderProcessingV1::FinalizeJob.perform_later(order.id)

    render json: {
      status: "paid",
      order_id: order.id,
      payment_id: payment_result[:payment_id]
    }
  rescue OrderProcessingV1::InsufficientStockError
    render json: { error: "Insufficient stock for payment" }, status: :unprocessable_entity
  end

  private

  def checkout_params
    params.permit(:branch_id, :customer_id, items: [ :stock_id, :product_id, :quantity, :unit_price ])
  end
end
