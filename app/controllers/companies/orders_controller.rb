# app/controllers/companies/orders_controller.rb
# Companies::OrdersController — CRUD for sales Orders plus POS receipt.
# Shell-First for index/show/new/edit (format.html empty + format.json hydrated).
# create/update are HTML redirects; receipt is JSON-only for the retail-cashier panel.
class Companies::OrdersController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.orders.includes(:category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @orders_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          orders: format_orders(@orders_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    order = current_company.orders.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { order: format_order(order) } }
    end
  end

  # GET /companies/:company_id/orders/:id/receipt
  # Tenant-scoped receipt for the POS post-payment panel. Finds the order via
  # current_company (404 if foreign), then the latest invoice + transaction.
  # Totals mirror the cart (subtotal from invoice.price_cents or items sum, 10% tax)
  # so the receipt matches what the cashier displayed. Requires OrdersPolicy#receipt?.
  def receipt
    order = current_company.orders.includes(order_appointments: { appoint_to: {} }).find(params[:id])
    invoice = order.invoices.order(:created_at).last
    transaction = invoice&.transactions&.order(:created_at)&.last

    items = order.order_appointments.map do |oa|
      {
        name: oa.name.presence || oa.appoint_to&.name || "Item",
        quantity: oa.quantity,
        unit_price: oa.unit_price.to_f,
        total_price: oa.total_price.to_f
      }
    end

    subtotal = invoice ? invoice.price_cents / 100.0 : items.sum { |i| i[:total_price] }.round(2)
    tax = (subtotal * 0.10).round(2)

    render json: {
      receipt: {
        invoice_code: invoice&.code,
        issued_at: invoice&.created_at,
        payment_status: invoice&.payment_status,
        currency: order.currency,
        items: items,
        subtotal: subtotal.round(2),
        tax: tax,
        total: (subtotal + tax).round(2),
        payment_method_name: transaction&.payment_method&.name
      }
    }
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    order = current_company.orders.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { order: format_order(order) } }
    end
  end

  def create
    order = current_company.orders.new(order_params)

    if order.save
      redirect_to company_order_path(current_company, order), notice: "Order created successfully"
    else
      redirect_to new_company_order_path(current_company),
        alert: order.errors.full_messages.to_sentence
    end
  end

  def update
    order = current_company.orders.find(params[:id])

    if order.update(order_params)
      redirect_to company_order_path(current_company, order), notice: "Order updated successfully"
    else
      redirect_to edit_company_order_path(current_company, order),
        alert: order.errors.full_messages.to_sentence
    end
  end

  private

  def property_keys
    (1..10).map { |i| "property_string_#{i}" } +
      (1..5).map { |i| "property_text_#{i}" } +
      (1..20).map { |i| "property_integer_#{i}" } +
      (1..10).map { |i| "property_decimal_#{i}" } +
      (1..10).map { |i| "property_boolean_#{i}" } +
      (1..10).map { |i| "property_datetime_#{i}" }
  end

  def order_params
    params.require(:order).permit(
      :name,
      :description,
      :code,
      :business_type,
      :workflow_status,
      :currency,
      :category_id,
      :customer_id,
      *property_keys
    )
  end

  def format_order(order)
    order.as_json(only: [
      :id, :name, :description, :code,
      :lifecycle_status, :workflow_status, :business_type,
      :currency, :category_id, :customer_id,
      :created_at, :updated_at,
      *property_keys
    ]).merge(
      category: order.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_orders(orders)
    orders.map { |order| format_order(order) }
  end
end
