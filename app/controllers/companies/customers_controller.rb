# app/controllers/companies/customers_controller.rb

class Companies::CustomersController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.customers
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?

        @pagy, @customers_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          customers: format_customers(@customers_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        customer = current_company.customers.new(customer_params)
        if customer.save
          render json: { customer: format_customer(customer) }, status: :created
        else
          render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    customer = current_company.customers.find(params[:id])

    respond_to do |format|
      format.json do
        if customer.update(customer_params)
          render json: { customer: format_customer(customer) }, status: :created
        else
          render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Customer not found" }, status: :not_found
  end

  private

  def customer_params
    params.require(:customer).permit(
      :name,
      :email,
      :description,
      :business_type,
      :workflow_status
    )
  end

  def format_customer(customer)
    customer.as_json(only: [
      :id, :name, :email, :description, :code,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at
    ])
  end

  def format_customers(customers)
    customers.map { |customer| format_customer(customer) }
  end
end
