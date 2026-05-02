# app/controllers/companies/orders_controller.rb

class Companies::OrdersController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.orders
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?
        scope = scope.where(currency_code: params[:currency_code]) if params[:currency_code].present?

        @pagy, @orders_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          orders: format_orders(@orders_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        order = current_company.orders.new(order_params)
        if order.save
          render json: { order: format_order(order) }, status: :created
        else
          render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    order = current_company.orders.find(params[:id])

    respond_to do |format|
      format.json do
        if order.update(order_params)
          render json: { order: format_order(order) }, status: :created
        else
          render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Order not found" }, status: :not_found
  end

  private

  def order_params
    params.require(:order).permit(
      :name,
      :description,
      :business_type,
      :workflow_status,
      :currency_code,
      :customer_id
    )
  end

  def format_order(order)
    order.as_json(only: [
      :id, :name, :description, :code,
      :lifecycle_status, :workflow_status, :business_type,
      :currency_code, :customer_id,
      :created_at, :updated_at
    ])
  end

  def format_orders(orders)
    orders.map { |order| format_order(order) }
  end
end
