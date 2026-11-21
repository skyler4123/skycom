# frozen_string_literal: true

# Companies::Operations::PosController — the POS operation. Hydrates the
# branch-scoped product/service catalog (server cents, company currency, POS
# tax, selling-warehouse stock), the branch payment methods, customer lookup,
# search, and the server-enforced terminal lock.
# Serves Stimulus: Companies_Operations_Pos_ShowController
# Endpoints: GET  /companies/:company_id/operations/pos/:operation_id
#            GET  /companies/:company_id/operations/pos/:operation_id/catalog?q=
#            GET  /companies/:company_id/operations/pos/:operation_id/customer_lookup?q=
#            POST /companies/:company_id/operations/pos/:operation_id/lock
#            POST /companies/:company_id/operations/pos/:operation_id/unlock
# Docs: docs/OPERATIONS.md, docs/ORDER_PROCESSING_V1.md
class Companies::Operations::PosController < Companies::Operations::BaseController
  # Lightweight POS customer lookup (id/code/name/email/phone_number/property slots).
  # IDs are exact DB lookups; every text query goes through Meilisearch — never SQL LIKE.
  # POS operators do not need the Customers dashboard permission to serve a customer.
  def customer_lookup
    query = params[:q].to_s.strip
    return render json: { customer: nil } if query.blank?

    customer = find_customer(query)
    render json: { customer: customer ? customer_lookup_payload(customer) : nil }
  end

  # Catalog-only refresh for search-as-you-type. The operation/appointment
  # gates still run; the payload is the same shape the initial show uses.
  def catalog
    render json: Pos::CatalogService.call(
      company: current_company,
      branch: @appointment.branch,
      query: params[:q]
    )
  end

  # Server-enforced terminal lock. The client overlay is only the visual half;
  # checkout/pay reject with 423 while this session flag is set.
  def lock
    session[:pos_locked_company_id] = current_company.id
    render json: { locked: true, message: "Terminal locked" }
  end

  def unlock
    unless current_user.authenticate(params[:password].to_s)
      render json: { errors: [ "Incorrect password" ] }, status: :unprocessable_content
      return
    end

    session.delete(:pos_locked_company_id)
    render json: { locked: false, message: "Terminal unlocked" }
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
    Pos::CatalogService.call(
      company: current_company,
      branch: @appointment.branch,
      query: params[:q]
    ).merge(
      coming_soon: false,
      payment_methods: payment_methods,
      locked: pos_locked?
    )
  end

  def payment_methods
    @appointment.branch.branch_payment_method_appointments
      .includes(:payment_method)
      .where(lifecycle_status: LIFECYCLE_STATUS.fetch(:active))
      .reject { |appointment| appointment.payment_method.redirect? }
      .map do |appointment|
        { id: appointment.id }.merge(
          appointment.payment_method.slice(:name, :code, :payment_mode, :strategy)
        )
      end
  end

  def pos_locked?
    session[:pos_locked_company_id] == current_company.id
  end
end
