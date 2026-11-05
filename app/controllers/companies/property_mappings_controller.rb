class Companies::PropertyMappingsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.property_mappings.includes(:category)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @mappings = pagy(:offset, scope, jsonapi: true)

        render json: {
          property_mappings: format_mappings(@mappings),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    mapping = current_company.property_mappings.includes(:category).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { property_mapping: format_mapping(mapping) } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { status: "error", message: "Property mapping not found" }, status: :not_found }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    mapping = current_company.property_mappings.includes(:category).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { property_mapping: format_mapping(mapping) } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { status: "error", message: "Property mapping not found" }, status: :not_found }
    end
  end

  def create
    mapping = current_company.property_mappings.new(property_mapping_params)

    if mapping.save
      redirect_to company_property_mapping_path(current_company, mapping), notice: "Property mapping created successfully."
    else
      redirect_to new_company_property_mapping_path(current_company),
        alert: mapping.errors.full_messages.to_sentence
    end
  end

  def update
    mapping = current_company.property_mappings.find(params[:id])

    p_params = normalize_metadata(mapping, property_mapping_params)

    if mapping.update(p_params)
      redirect_to company_property_mapping_path(current_company, mapping), notice: "Property mapping updated successfully."
    else
      redirect_to edit_company_property_mapping_path(current_company, mapping),
        alert: mapping.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to company_property_mappings_path(current_company), alert: "Property mapping not found."
  end

  def destroy
    mapping = current_company.property_mappings.find(params[:id])
    mapping.destroy!
    redirect_to company_property_mappings_path(current_company), notice: "Property mapping deleted."
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Property mapping not found" }, status: :not_found
  end

  private

  # The edit form owns key/name (and type for extra columns). Merge submitted
  # entries with the existing metadata so settings the form does not render
  # (input_type, options, placeholder, min, max, ...) survive a save.
  def normalize_metadata(mapping, p_params)
    return p_params unless p_params[:metadata].is_a?(ActionController::Parameters)

    meta = p_params[:metadata].to_unsafe_h

    if meta["properties"].is_a?(Hash)
      meta["properties"] = merge_entries(
        mapping.properties, meta["properties"].values, derive_type: true
      )
    end

    if meta["extra_columns"].is_a?(Hash)
      meta["extra_columns"] = merge_entries(
        mapping.metadata&.dig("extra_columns"), meta["extra_columns"].values, derive_type: false
      )
    end

    p_params[:metadata] = meta
    p_params
  end

  def merge_entries(existing_entries, submitted_entries, derive_type:)
    existing_by_key = Array(existing_entries).index_by { |entry| entry["key"] }

    submitted_entries.map do |entry|
      if !derive_type && entry["key"].blank?
        entry["key"] = "extra_#{SecureRandom.hex(4)}"
      end

      merged = existing_by_key[entry["key"]] ? existing_by_key[entry["key"]].merge(entry) : entry.dup
      merged.delete("validates")
      merged["type"] ||= derive_type ? type_from_key(entry["key"]) : "string"
      merged
    end
  end

  def type_from_key(key)
    key.to_s.split("_")[1].presence || "string"
  end

  def property_mapping_params
    params.require(:property_mapping).permit(:category_id, :name, :description, metadata: {})
  end

  def format_mapping(mapping)
    mapping.as_json(only: [ :id, :category_id, :name, :description, :metadata, :resource_name, :created_at, :updated_at ]).merge(
      category: mapping.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_mappings(mappings)
    mappings.map { |m| format_mapping(m) }
  end
end
