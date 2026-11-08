# frozen_string_literal: true

# Companies::Operations::PosController — the POS operation. Hydrates the
# branch-scoped product/service catalog and the branch's non-redirect payment
# methods for the resolved BranchOperationAppointment.
# Serves Stimulus: Companies_Operations_Pos_ShowController (hydrate, customer lookup)
# Endpoints: GET /companies/:company_id/operations/pos/:operation_id
#            GET /companies/:company_id/operations/pos/:operation_id/customer_lookup?q=
# Docs: docs/OPERATIONS.md, docs/ORDER_PROCESSING_V1.md
class Companies::Operations::PosController < Companies::Operations::BaseController
  # Lightweight POS customer lookup (id/code/name/email/phone-like property slots).
  # IDs are exact DB lookups; every text query goes through Meilisearch — never SQL LIKE.
  # POS operators do not need the Customers dashboard permission to serve a customer.
  def customer_lookup
    query = params[:q].to_s.strip
    return render json: { customer: nil } if query.blank?

    customer = find_customer(query)
    render json: { customer: customer ? customer_lookup_payload(customer) : nil }
  end

  private

  def expected_operation_type
    :pos
  end

  def find_customer(query)
    scope = current_company.customers

    # Exact primary-key lookup stays on the DB — this is not text search.
    if query.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
      return scope.find_by(id: query)
    end

    hit = Customer.ms_raw_search(
      query, filter: %(company_id = "#{current_company.id}")
    )["hits"].first
    hit ? scope.find_by(id: hit["id"]) : nil
  end

  def customer_lookup_payload(customer)
    membership = customer.membership_of_type(:loyalty) || customer.membership

    {
      id: customer.id,
      name: customer.name,
      code: customer.code,
      email: customer.email,
      membership: membership&.as_json(only: [ :id, :name, :code ])
    }
  end

  def operation_payload
    branch = @appointment.branch
    warehouse_ids = branch.warehouse_ids

    products = current_company.products.includes(:category).where(branch_id: branch.id).limit(50).map do |product|
      price = product.price
      stock = Stock.find_by(product_id: product.id, warehouse_id: warehouse_ids)
      {
        id: product.id,
        name: product.name,
        code: product.code,
        category_id: product.category_id,
        category_name: product.category&.name,
        stock_id: stock&.id,
        stock_quantity: stock&.available_count || 0,
        price: price&.to_f || 0,
        currency: price&.currency.iso_code || "USD",
        image_url: product.image_attachments.first&.variant(:thumb)&.processed&.url
      }
    end

    services = current_company.services.includes(:category).where(branch_id: branch.id).limit(50).map do |service|
      {
        id: service.id,
        name: service.name,
        code: service.code,
        category_id: service.category_id,
        category_name: service.category&.name,
        price: 0,
        currency: "usd",
        image_url: service.image_attachments.first&.variant(:thumb)&.processed&.url
      }
    end

    payment_methods = branch.branch_payment_method_appointments
      .includes(:payment_method)
      .where(lifecycle_status: LIFECYCLE_STATUS.fetch(:active))
      .reject { |appointment| appointment.payment_method.redirect? }
      .map do |appointment|
        { id: appointment.id }.merge(
          appointment.payment_method.slice(:name, :code, :payment_mode, :strategy)
        )
      end

    {
      coming_soon: false,
      products: products,
      services: services,
      payment_methods: payment_methods
    }
  end
end
