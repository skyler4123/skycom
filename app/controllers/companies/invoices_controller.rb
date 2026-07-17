# app/controllers/companies/invoices_controller.rb

class Companies::InvoicesController < Companies::ApplicationController
  feature_key :finance_basic

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.invoices.includes(:category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @invoices_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          invoices: format_invoices(@invoices_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    invoice = current_company.invoices.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { invoice: format_invoice(invoice) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    invoice = current_company.invoices.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { invoice: format_invoice(invoice) } }
    end
  end

  def create
    invoice = current_company.invoices.new(invoice_params)

    if invoice.save
      redirect_to company_invoice_path(current_company, invoice), notice: "Invoice created successfully"
    else
      redirect_to new_company_invoice_path(current_company),
        alert: invoice.errors.full_messages.to_sentence
    end
  end

  def update
    invoice = current_company.invoices.find(params[:id])

    if invoice.update(invoice_params)
      redirect_to company_invoice_path(current_company, invoice), notice: "Invoice updated successfully"
    else
      redirect_to edit_company_invoice_path(current_company, invoice),
        alert: invoice.errors.full_messages.to_sentence
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

  def invoice_params
    params.require(:invoice).permit(
      :name,
      :description,
      :code,
      :business_type,
      :workflow_status,
      :currency,
      :price_cents,
      :due_date,
      :category_id,
      :order_id,
      *property_keys
    )
  end

  def format_invoice(invoice)
    invoice.as_json(only: [
      :id, :name, :description, :code,
      :lifecycle_status, :workflow_status, :business_type,
      :currency, :price_cents, :due_date,
      :category_id, :order_id,
      :created_at, :updated_at,
      *property_keys
    ]).merge(
      category: invoice.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_invoices(invoices)
    invoices.map { |invoice| format_invoice(invoice) }
  end
end
