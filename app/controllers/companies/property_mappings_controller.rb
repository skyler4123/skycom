# app/controllers/companies/property_mappings_controller.rb

class Companies::PropertyMappingsController < Companies::ApplicationController
  def show
    mapping = current_company.property_mappings.find(params[:id])
    render json: { property_mapping: format_mapping(mapping) }
  end

  def create
    mapping = current_company.property_mappings.new(property_mapping_params)

    if mapping.save
      render json: { property_mapping: format_mapping(mapping) }, status: :created
    else
      render json: { errors: mapping.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    mapping = current_company.property_mappings.find(params[:id])

    if mapping.update(property_mapping_params)
      render json: { property_mapping: format_mapping(mapping) }
    else
      render json: { errors: mapping.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    mapping = current_company.property_mappings.find(params[:id])
    mapping.destroy!
    render json: { status: "deleted" }
  end

  private

  def property_mapping_params
    params.require(:property_mapping).permit(:category_id, :name, property_metadatas: {})
  end

  def format_mapping(mapping)
    mapping.as_json(only: [ :id, :category_id, :name, :property_metadatas ])
  end
end
