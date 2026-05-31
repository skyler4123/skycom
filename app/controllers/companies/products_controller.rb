# app/controllers/companies/products_controller.rb

class Companies::ProductsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.products
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @products_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          products: format_products(@products_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        product = current_company.products.new(product_params)
        if product.save
          render json: { product: format_product(product) }, status: :created
        else
          render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    product = current_company.products.find(params[:id])

    respond_to do |format|
      format.json do
        if product.update(product_params)
          render json: { product: format_product(product) }, status: :created
        else
          render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Product not found" }, status: :not_found
  end

  private

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :business_type,
      :workflow_status
    )
  end

  def format_product(product)
    product.as_json(only: [
      :id, :name, :description, :code,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at
    ]).merge(
      category: product.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_products(products)
    products.map { |product| format_product(product) }
  end
end
