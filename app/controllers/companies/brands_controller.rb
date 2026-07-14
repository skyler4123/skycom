class Companies::BrandsController < Companies::ApplicationController
  feature_key :inventory_basic

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.brands
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @brands_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          brands: format_brands(@brands_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    brand = current_company.brands.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { brand: format_brand(brand) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    brand = current_company.brands.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { brand: format_brand(brand) } }
    end
  end

  def create
    brand = current_company.brands.new(brand_params)
    brand.code ||= "BR-#{SecureRandom.hex(4).upcase}"
    if brand.save
      redirect_to company_brand_path(current_company, brand), notice: "Brand created successfully"
    else
      redirect_to new_company_brand_path(current_company),
        alert: brand.errors.full_messages.to_sentence
    end
  end

  def update
    brand = current_company.brands.find(params[:id])

    respond_to do |format|
      format.html do
        if brand.update(brand_params)
          redirect_to company_brand_path(current_company, brand), notice: "Brand updated successfully."
        else
          redirect_to edit_company_brand_path(current_company, brand),
            alert: brand.errors.full_messages.to_sentence
        end
      end
      format.json do
        if brand.update(brand_params)
          render json: { brand: format_brand(brand), message: "Brand updated successfully" }, status: :ok
        else
          render json: { errors: brand.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Brand not found" }, status: :not_found
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

  def brand_params
    params.require(:brand).permit(
      :name,
      :description,
      :code,
      :business_type,
      :workflow_status,
      :category_id,
      :phone_number,
      :email,
      *property_keys
    )
  end

  def format_brand(brand)
    brand.as_json(only: [
      :id, :name, :description, :code, :category_id,
      :business_type, :lifecycle_status, :workflow_status,
      :phone_number, :email,
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
      category: brand.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_brands(brands)
    brands.map { |brand| format_brand(brand) }
  end
end
