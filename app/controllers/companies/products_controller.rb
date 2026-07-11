# app/controllers/companies/products_controller.rb

class Companies::ProductsController < Companies::ApplicationController
  feature_key :inventory_basic

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

  def show
    product = current_company.products.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { product: format_product(product) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    product = current_company.products.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { product: format_product(product) } }
    end
  end

  def create
    product = current_company.products.new(product_params)
    if product.save
      redirect_to company_product_path(current_company, product), notice: "Product created successfully"
    else
      redirect_to new_company_product_path(current_company),
        alert: product.errors.full_messages.to_sentence
    end
  end

  def update
    product = current_company.products.find(params[:id])

    respond_to do |format|
      format.html do
        if product.update(product_params)
          redirect_to company_product_path(current_company, product), notice: "Product updated successfully."
        else
          redirect_to edit_company_product_path(current_company, product),
            alert: product.errors.full_messages.to_sentence
        end
      end
      format.json do
        if product.update(product_params)
          render json: { product: format_product(product) }, status: :ok
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
    property_keys = (1..10).map { |i| "property_string_#{i}" } +
                    (1..5).map { |i| "property_text_#{i}" } +
                    (1..20).map { |i| "property_integer_#{i}" } +
                    (1..10).map { |i| "property_decimal_#{i}" } +
                    (1..10).map { |i| "property_boolean_#{i}" } +
                    (1..10).map { |i| "property_datetime_#{i}" }

    params.require(:product).permit(
      :name, :description, :business_type, :workflow_status, :category_id,
      *property_keys
    )
  end

  def format_product(product)
    product.as_json(only: [
      :id, :name, :description, :code, :category_id,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at,
      :property_string_1, :property_string_2, :property_string_3, :property_string_4, :property_string_5,
      :property_string_6, :property_string_7, :property_string_8, :property_string_9, :property_string_10,
      :property_text_1, :property_text_2, :property_text_3, :property_text_4, :property_text_5,
      :property_integer_1, :property_integer_2, :property_integer_3, :property_integer_4, :property_integer_5,
      :property_integer_6, :property_integer_7, :property_integer_8, :property_integer_9, :property_integer_10,
      :property_integer_11, :property_integer_12, :property_integer_13, :property_integer_14, :property_integer_15,
      :property_integer_16, :property_integer_17, :property_integer_18, :property_integer_19, :property_integer_20,
      :property_decimal_1, :property_decimal_2, :property_decimal_3, :property_decimal_4, :property_decimal_5,
      :property_decimal_6, :property_decimal_7, :property_decimal_8, :property_decimal_9, :property_decimal_10,
      :property_boolean_1, :property_boolean_2, :property_boolean_3, :property_boolean_4, :property_boolean_5,
      :property_boolean_6, :property_boolean_7, :property_boolean_8, :property_boolean_9, :property_boolean_10,
      :property_datetime_1, :property_datetime_2, :property_datetime_3, :property_datetime_4, :property_datetime_5,
      :property_datetime_6, :property_datetime_7, :property_datetime_8, :property_datetime_9, :property_datetime_10
    ]).merge(
      category: product.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_products(products)
    products.map { |product| format_product(product) }
  end
end
