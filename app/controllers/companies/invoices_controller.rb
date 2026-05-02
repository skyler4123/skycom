# app/controllers/companies/invoices_controller.rb

class Companies::InvoicesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.invoices
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?
        scope = scope.where(currency_code: params[:currency_code]) if params[:currency_code].present?

        @pagy, @invoices_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          invoices: format_invoices(@invoices_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        invoice = current_company.invoices.new(invoice_params)
        if invoice.save
          render json: { invoice: format_invoice(invoice) }, status: :created
        else
          render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    invoice = current_company.invoices.find(params[:id])

    respond_to do |format|
      format.json do
        if invoice.update(invoice_params)
          render json: { invoice: format_invoice(invoice) }, status: :created
        else
          render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Invoice not found" }, status: :not_found
  end

  private

  def invoice_params
    params.require(:invoice).permit(
      :name,
      :description,
      :business_type,
      :workflow_status,
      :currency_code,
      :number,
      :total_price,
      :due_date
    )
  end

  def format_invoice(invoice)
    invoice.as_json(only: [
      :id, :name, :description, :code, :number,
      :lifecycle_status, :workflow_status, :business_type,
      :currency_code, :total_price, :due_date,
      :order_id, :created_at, :updated_at
    ])
  end

  def format_invoices(invoices)
    invoices.map { |invoice| format_invoice(invoice) }
  end
end
