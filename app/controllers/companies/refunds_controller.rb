# app/controllers/companies/refunds_controller.rb
#
# Refunds dashboard API (Shell-First). Refund requests follow a company's
# `refund_process` workflow (category is the bridge); advance is the single
# workflow-transition entry point.
# Serves Stimulus: Companies_Refunds_IndexController,
#                  Companies_Refunds_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/refunds(.json) + nested CRUD,
#            POST /companies/:company_id/refunds/:id/advance
class Companies::RefundsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.refunds.includes(:workflow_step, :customer, :branch, :category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        search = Refunds::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @refunds_results = pagy(:offset, scope, jsonapi: true)
        render json: { refunds: format_refunds(@refunds_results), pagination: @pagy.data_hash }
      end
    end
  end

  def show
    refund = current_company.refunds.includes(:customer, :branch, :category, :order, :invoice, :source_transaction, :product, :payment_method, { workflow_step: { workflow: :workflow_steps } }).find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { refund: format_refund(refund, with_workflow_detail: true) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: form_reference_data }
    end
  end

  def edit
    refund = current_company.refunds.includes({ workflow_step: { workflow: :workflow_steps } }).find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: { refund: format_refund(refund, with_workflow_detail: true), **form_reference_data }
      end
    end
  end

  def create
    refund = current_company.refunds.new(refund_params)
    refund.code ||= "REF-#{SecureRandom.hex(4).upcase}"
    refund.created_by_employee = current_employee

    if refund.save
      redirect_to company_refund_path(current_company, refund), notice: "Refund created successfully"
    else
      redirect_to new_company_refund_path(current_company), alert: refund.errors.full_messages.to_sentence
    end
  end

  def update
    refund = current_company.refunds.find(params[:id])
    refund.assign_attributes(refund_params)

    if refund.save
      redirect_to company_refund_path(current_company, refund), notice: "Refund updated successfully."
    else
      redirect_to edit_company_refund_path(current_company, refund), alert: refund.errors.full_messages.to_sentence
    end
  end

  def advance
    refund = current_company.refunds.find(params[:id])
    target_step = if params[:target_step_id].present?
      WorkflowStep.where(company: current_company).find_by(id: params[:target_step_id])
    end

    result = Workflows::AdvanceService.call(
      subject: refund,
      employee: current_employee,
      outcome: params[:outcome],
      note: params[:note],
      target_step: target_step
    )

    if result[:success]
      render json: { message: "Refund #{params[:outcome]}", refund: format_refund(refund.reload) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_content
    end
  end

  private

  def form_reference_data
    {
      customers: current_company.customers.order(:name).map { |c| c.as_json(only: [ :id, :name ]) },
      orders: current_company.orders.order(:created_at).limit(50).map { |o| o.as_json(only: [ :id, :name, :code ]) },
      invoices: current_company.invoices.order(:created_at).limit(50).map { |i| i.as_json(only: [ :id, :name, :code ]) },
      products: current_company.products.order(:name).map { |p| p.as_json(only: [ :id, :name ]) },
      payment_methods: current_company.payment_methods.order(:name).map { |m| m.as_json(only: [ :id, :name ]) }
    }
  end

  def property_keys
    (1..5).map { |i| "property_string_#{i}" } +
      (1..10).map { |i| "property_integer_#{i}" } +
      (1..5).map { |i| "property_decimal_#{i}" } +
      (1..5).map { |i| "property_boolean_#{i}" } +
      (1..5).map { |i| "property_datetime_#{i}" }
  end

  def refund_params
    params.require(:refund).permit(
      :name, :description, :refund_type, :reason, :money_amount_cents, :currency,
      :quantity, :customer_id, :order_id, :invoice_id, :transaction_id,
      :payment_method_id, :product_id, :category_id, :branch_id,
      *property_keys
    )
  end

  def format_refunds(refunds)
    refunds.map { |r| format_refund(r) }
  end

  def format_refund(refund, with_workflow_detail: false)
    workflow = refund.workflow_step&.workflow
    payload = refund.as_json(only: [
      :id, :name, :description, :code, :refund_type, :reason, :money_amount_cents,
      :currency, :quantity, :customer_id, :order_id, :invoice_id, :transaction_id,
      :payment_method_id, :product_id, :category_id, :branch_id,
      :workflow_step_id, :lifecycle_status, :workflow_status,
      :created_at, :updated_at, *property_keys
    ]).merge(
      workflow: workflow&.as_json(only: [ :id, :name ]),
      current_workflow_step: refund.workflow_step&.as_json(only: [ :id, :name, :position, :text_color, :background_color ]),
      customer: refund.customer&.as_json(only: [ :id, :name ]),
      branch: refund.branch&.as_json(only: [ :id, :name ]),
      category: refund.category&.as_json(only: [ :id, :name ]),
      product: refund.product&.as_json(only: [ :id, :name ]),
      payment_method: refund.payment_method&.as_json(only: [ :id, :name ]),
      transaction: refund.source_transaction&.as_json(only: [ :id, :code, :gateway_reference ])
    )

    return payload unless with_workflow_detail

    payload.merge(
      workflow_steps: workflow&.workflow_steps&.sort_by(&:position)&.map { |s| s.as_json(only: [ :id, :name, :position, :text_color, :background_color ]) },
      workflow_step_logs: refund.workflow_step_logs.order(:created_at).map { |log|
        log.as_json(only: [ :id, :outcome, :note, :created_at ])
          .merge(step_name: log.workflow_step&.name, employee_name: log.employee&.name)
      }
    )
  end
end
