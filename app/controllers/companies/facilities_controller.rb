class Companies::FacilitiesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.facilities
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @facilities_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          facilities: format_facilities(@facilities_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        facility = current_company.facilities.new(facility_params)
        if facility.save
          render json: { facility: format_facility(facility) }, status: :created
        else
          render json: { errors: facility.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    facility = current_company.facilities.find(params[:id])

    respond_to do |format|
      format.json do
        if facility.update(facility_params)
          render json: { facility: format_facility(facility) }, status: :created
        else
          render json: { errors: facility.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Facility not found" }, status: :not_found
  end

  private

  def facility_params
    params.require(:facility).permit(
      :name,
      :description,
      :code,
      :branch_id,
      :business_type,
      :workflow_status,
      :category_id,
      :phone_number,
      :email
    )
  end

  def format_facility(facility)
    result = {
      id: facility.id,
      name: facility.name,
      description: facility.description,
      code: facility.code,
      branch_id: facility.branch_id,
      business_type: facility.business_type,
      lifecycle_status: facility.lifecycle_status,
      workflow_status: facility.workflow_status,
      phone_number: facility.phone_number,
      email: facility.email,
      created_at: facility.created_at,
      updated_at: facility.updated_at
    }
    result[:category] = facility.category&.as_json(only: [ :id, :name ])
    result[:branch] = facility.branch&.as_json(only: [ :id, :name ])
    result
  end

  def format_facilities(facilities)
    facilities.map { |facility| format_facility(facility) }
  end
end
