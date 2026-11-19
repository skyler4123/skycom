# app/controllers/companies/orders_controller.rb
# Companies::OrdersController — CRUD for sales Orders plus POS receipt.
# Shell-First for index/show/new/edit (format.html empty + format.json hydrated).
# create/update are HTML redirects; receipt is JSON-only for the retail-cashier panel.
# index additionally supports the TableConfig-driven dynamic search/filter
# (?q= / ?filters[key]= → Meilisearch via Orders::SearchQueryService; plain DB path otherwise).
# Serves Stimulus: Companies_Operations_Pos_ShowController#showReceipt (GET receipt),
#                  Companies_Orders_IndexController (index/show; index JSON incl. q/filters passthrough)
# Endpoint: GET receipt — see config/routes.rb:36 + Helpers.receipt_company_order_path
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md
class Companies::OrdersController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.orders.includes(:category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

        search = Orders::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

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
  # Tenant-scoped receipt for the POS post-payment panel. Totals come from the
  # order/invoice snapshots written at sale time — never from a hardcoded rate.
  # Requires OrdersPolicy#receipt?.
  def receipt
    order = current_company.orders.includes(
      { order_product_appointments: :product },
      { order_service_appointments: :service },
      { order_product_group_appointments: :product_group },
      { order_service_group_appointments: :service_group },
      { order_subscription_plan_appointments: :subscription_plan },
      :branch, :employee
    ).find(params[:id])
    invoice = order.invoices.order(:created_at).last
    transaction = invoice&.transactions&.order(:created_at)&.last
    used_discounts = invoice ? invoice.discounts.where(status: :used) : Discount.none

    subtotal_cents = money_to_cents(order.line_total, order.currency)
    discount_cents = used_discounts.sum(:amount_cents)
    tax_cents = invoice ? invoice.tax_cents.to_i : order_tax_cents(order, subtotal_cents, discount_cents)
    total_cents = invoice_total_cents(invoice, subtotal_cents, discount_cents, tax_cents)
    tax_rate_bp = invoice&.pos_tax_rate_bp || order.pos_tax_rate_bp
    tax_name = invoice&.pos_tax_name.presence || order.pos_tax_name.presence

    render json: {
      receipt: {
        invoice_code: invoice&.code,
        issued_at: invoice&.created_at || order.created_at,
        payment_status: invoice&.payment_status,
        currency: order.currency,
        branch_name: order.branch&.name,
        cashier_name: order.employee&.name,
        items: receipt_items(order),
        subtotal_cents: subtotal_cents,
        discount_cents: discount_cents,
        discount_code: used_discounts.order(:created_at).last&.code,
        tax_cents: tax_cents,
        tax_rate_bp: tax_rate_bp,
        tax_name: tax_name,
        total_cents: total_cents,
        payment_method_name: transaction&.payment_method&.name,
        cash_received_cents: transaction&.cash_received_cents,
        change_cents: transaction&.change_cents
      }
    }
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { employees: employee_options } }
    end
  end

  def edit
    order = current_company.orders.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { order: format_order(order), employees: employee_options } }
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
    (1..5).map { |i| "property_string_#{i}" } +
      (1..10).map { |i| "property_integer_#{i}" } +
      (1..5).map { |i| "property_decimal_#{i}" } +
      (1..5).map { |i| "property_boolean_#{i}" } +
      (1..5).map { |i| "property_datetime_#{i}" }
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
      :employee_id,
      *property_keys
    )
  end

  def employee_options
    current_company.employees.where(discarded_at: nil).order(:name).map do |employee|
      { id: employee.id, name: employee.name }
    end
  end

  def format_order(order)
    order.as_json(only: [
      :id, :name, :description, :code,
      :lifecycle_status, :workflow_status, :business_type,
      :currency, :category_id, :customer_id, :employee_id,
      :created_at, :updated_at,
      *property_keys
    ]).merge(
      category: order.category&.as_json(only: [ :id, :name ]),
      employee: order.employee&.as_json(only: [ :id, :name ])
    )
  end

  def format_orders(orders)
    orders.map { |order| format_order(order) }
  end

  def receipt_items(order)
    order.line_items.map do |oa|
      {
        name: oa.name.presence || line_item_name(oa) || "Item",
        quantity: oa.quantity,
        unit_price_cents: money_to_cents(oa.unit_price, order.currency),
        total_cents: money_to_cents(oa.total_price, order.currency),
        kind: line_item_kind(oa)
      }
    end
  end

  def line_item_kind(line_item)
    case line_item
    when OrderProductAppointment then "product"
    when OrderServiceAppointment then "service"
    when OrderProductGroupAppointment then "product_group"
    when OrderServiceGroupAppointment then "service_group"
    when OrderSubscriptionPlanAppointment then "subscription_plan"
    else "item"
    end
  end

  def money_to_cents(value, currency)
    return 0 if value.nil?

    Money.from_amount(value, currency).cents
  end

  def order_tax_cents(order, subtotal_cents, discount_cents)
    rate_bp = order.pos_tax_rate_bp.to_i
    return 0 if rate_bp.zero?

    taxable = [ subtotal_cents - discount_cents, 0 ].max
    (taxable * rate_bp / 10_000.0).round
  end

  def invoice_total_cents(invoice, subtotal_cents, discount_cents, tax_cents)
    if invoice
      total = invoice.total_cents.to_i
      total.positive? ? total : invoice.price_cents.to_i
    else
      subtotal_cents - discount_cents + tax_cents
    end
  end

  def line_item_name(line_item)
    %i[product service product_group service_group subscription_plan].each do |assoc|
      next unless line_item.respond_to?(assoc)

      record = line_item.public_send(assoc)
      return record.name if record.respond_to?(:name)
    end
    nil
  rescue StandardError
    nil
  end
end
