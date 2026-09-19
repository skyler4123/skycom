# app/controllers/companies/purchases_controller.rb
#
# Purchases dashboard API (Shell-First). Jira-style requisition tickets:
# index supports TableConfig-driven dynamic search/filter (?q= / ?filters[key]=
# → Meilisearch via Purchases::SearchQueryService; plain DB path otherwise).
# advance is the single workflow-transition entry point (Workflows::AdvanceService
# — ABAC can?(:update, subject) enforced there, WorkflowStepLog is the audit).
# Purchase.workflow_id / current_workflow_step / workflow_status are NEVER
# permitted through create/update — only the advance endpoint moves them.
# Serves Stimulus: Companies_Purchases_IndexController (index JSON incl. q/filters passthrough),
#                  Companies_Purchases_NewController|ShowController|EditController,
#                  advance endpoint serves the show-page Approve/Reject/Rework buttons
# Endpoints: GET /companies/:company_id/purchases(.json) + nested CRUD,
#            POST /companies/:company_id/purchases/:id/advance
# Docs: docs/PURCHASE_WORKFLOW.md, docs/DYNAMIC_TABLE.md §2.5

class Companies::PurchasesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.purchases.includes(
          :purchase_item_appointments, :purchase_items,
          :workflow, :current_workflow_step, :supplier, :branch
        )
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        search = Purchases::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @purchases_results = pagy(:offset, scope, jsonapi: true)
        render json: { purchases: format_purchases(@purchases_results), pagination: @pagy.data_hash }
      end
    end
  end

  def show
    purchase = current_company.purchases.includes(
      :purchase_item_appointments, :purchase_items, :supplier, :branch, :category,
      { workflow: :workflow_steps }
    ).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { purchase: format_purchase(purchase, with_workflow_detail: true) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: form_reference_data }
    end
  end

  def edit
    purchase = current_company.purchases.includes(
      :purchase_item_appointments, :purchase_items, { workflow: :workflow_steps }
    ).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          purchase: format_purchase(purchase, with_workflow_detail: true),
          **form_reference_data
        }
      end
    end
  end

  def create
    purchase = current_company.purchases.new(purchase_params)
    purchase.code ||= "PUR-#{SecureRandom.hex(4).upcase}"
    purchase.created_by_employee = current_employee

    if save_purchase(purchase)
      redirect_to company_purchase_path(current_company, purchase), notice: "Purchase created successfully"
    else
      redirect_to new_company_purchase_path(current_company), alert: purchase.errors.full_messages.to_sentence
    end
  end

  def update
    purchase = current_company.purchases.find(params[:id])
    purchase.assign_attributes(purchase_params)

    if save_purchase(purchase)
      redirect_to company_purchase_path(current_company, purchase), notice: "Purchase updated successfully."
    else
      redirect_to edit_company_purchase_path(current_company, purchase), alert: purchase.errors.full_messages.to_sentence
    end
  end

  def advance
    purchase = current_company.purchases.find(params[:id])
    target_step = if params[:target_step_id].present?
      WorkflowStep.where(company: current_company).find_by(id: params[:target_step_id])
    end

    result = Workflows::AdvanceService.call(
      subject: purchase,
      employee: current_employee,
      outcome: params[:outcome],
      note: params[:note],
      target_step: target_step
    )

    if result[:success]
      render json: { message: "Purchase #{params[:outcome]}", purchase: format_purchase(purchase.reload) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  private

  def save_purchase(purchase)
    purchase.purchase_item_appointments.each { |appointment| appointment.appoint_to = purchase if appointment.appoint_to.nil? }
    normalize_appointment_totals(purchase.purchase_item_appointments)
    purchase.save
  end

  # PurchaseItemAppointment#total_price is a stored column — derive it from the
  # submitted quantity × unit_price so FE-created line items stay consistent.
  def normalize_appointment_totals(appointments)
    appointments.each do |appointment|
      next if appointment.marked_for_destruction?
      next unless appointment.quantity.present? && appointment.unit_price.present?

      appointment.total_price = appointment.quantity * appointment.unit_price
    end
  end

  def form_reference_data
    {
      purchase_items: current_company.purchase_items.order(:name)
        .map { |item| item.as_json(only: [ :id, :name, :unit, :estimated_unit_price ]) },
      suppliers: current_company.suppliers.order(:name)
        .map { |s| s.as_json(only: [ :id, :name ]) }
    }
  end

  def property_keys
    (1..10).map { |i| "property_string_#{i}" } +
      (1..20).map { |i| "property_integer_#{i}" } +
      (1..10).map { |i| "property_decimal_#{i}" } +
      (1..10).map { |i| "property_boolean_#{i}" } +
      (1..10).map { |i| "property_datetime_#{i}" }
  end

  # workflow_id / current_workflow_step_id / workflow_status deliberately NOT
  # permitted — the workflow pointer is owned by Workflows::AdvanceService.
  def purchase_params
    params.require(:purchase).permit(
      :name, :description, :needed_by, :currency, :business_type,
      :category_id, :branch_id, :supplier_id,
      *property_keys,
      purchase_item_appointments_attributes: [
        :id, :purchase_item_id, :quantity, :unit_price, :name, :description, :_destroy
      ]
    )
  end

  def format_purchases(purchases)
    purchases.map { |purchase| format_purchase(purchase) }
  end

  def format_purchase(purchase, with_workflow_detail: false)
    appointments = purchase.purchase_item_appointments

    payload = purchase.as_json(only: [
      :id, :name, :description, :code, :needed_by, :currency, :country,
      :category_id, :branch_id, :supplier_id,
      :workflow_id, :current_workflow_step_id,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at,
      *property_keys
    ]).merge(
      total_price: appointments.sum { |a| a.total_price.to_f },
      workflow: purchase.workflow&.as_json(only: [ :id, :name ]),
      current_workflow_step: purchase.current_workflow_step&.as_json(only: [ :id, :name, :position ]),
      supplier: purchase.supplier&.as_json(only: [ :id, :name ]),
      branch: purchase.branch&.as_json(only: [ :id, :name ]),
      category: purchase.category&.as_json(only: [ :id, :name ]),
      purchase_item_appointments: appointments.map { |a|
        a.as_json(only: [ :id, :purchase_item_id, :quantity, :unit_price, :total_price ])
          .merge(item_name: a.purchase_item&.name)
      }
    )

    return payload unless with_workflow_detail

    payload.merge(
      workflow_steps: purchase.workflow&.workflow_steps&.sort_by(&:position)&.map { |s| s.as_json(only: [ :id, :name, :position ]) },
      workflow_step_logs: purchase.workflow_step_logs.order(:created_at).map { |log|
        log.as_json(only: [ :id, :outcome, :note, :created_at ])
          .merge(step_name: log.workflow_step&.name, employee_name: log.employee&.name)
      }
    )
  end
end
