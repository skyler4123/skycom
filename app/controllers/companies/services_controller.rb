# app/controllers/companies/services_controller.rb

class Companies::ServicesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.services
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @services_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          services: format_services(@services_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        service = current_company.services.new(service_params)
        if service.save
          render json: { service: format_service(service) }, status: :created
        else
          render json: { errors: service.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    service = current_company.services.find(params[:id])

    respond_to do |format|
      format.json do
        if service.update(service_params)
          render json: { service: format_service(service) }, status: :created
        else
          render json: { errors: service.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Service not found" }, status: :not_found
  end

  private

  def service_params
    params.require(:service).permit(
      :name,
      :description,
      :business_type,
      :workflow_status,
      :code
    )
  end

  def format_service(service)
    service.as_json(only: [
      :id, :name, :description, :code,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at
    ]).merge(
      category: service.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_services(services)
    services.map { |service| format_service(service) }
  end
end
