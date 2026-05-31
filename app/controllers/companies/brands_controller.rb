class Companies::BrandsController < Companies::ApplicationController
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

  def create
    respond_to do |format|
      format.json do
        Rails.logger.warn "=== BRAND CREATE ==="
        Rails.logger.warn "current_company: #{current_company&.id}"
        Rails.logger.warn "current_employee: #{current_employee&.id}"
        Rails.logger.warn "params: #{params.inspect}"
        Rails.logger.warn "brand_params: #{brand_params.inspect}"

        brand = current_company.brands.new(brand_params)
        brand.code ||= "BR-#{SecureRandom.hex(4).upcase}"
        Rails.logger.warn "brand valid?: #{brand.valid?}"
        Rails.logger.warn "brand errors: #{brand.errors.full_messages}"
        if brand.save
          render json: { brand: format_brand(brand) }, status: :created
        else
          render json: { errors: brand.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    brand = current_company.brands.find(params[:id])

    respond_to do |format|
      format.json do
        if brand.update(brand_params)
          render json: { brand: format_brand(brand) }, status: :created
        else
          render json: { errors: brand.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Brand not found" }, status: :not_found
  end

  private

  def brand_params
    params.require(:brand).permit(
      :name,
      :description,
      :code,
      :business_type,
      :workflow_status,
      :category_id,
      :phone_number,
      :email
    )
  end

  def format_brand(brand)
    result = {
      id: brand.id,
      name: brand.name,
      description: brand.description,
      code: brand.code,
      business_type: brand.business_type,
      lifecycle_status: brand.lifecycle_status,
      workflow_status: brand.workflow_status,
      phone_number: brand.phone_number,
      email: brand.email,
      created_at: brand.created_at,
      updated_at: brand.updated_at
    }
    result[:category] = brand.category&.as_json(only: [ :id, :name ])
    result
  end

  def format_brands(brands)
    brands.map { |brand| format_brand(brand) }
  end
end
