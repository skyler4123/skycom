# Property Mapping configuration for dynamic property slots.
# Serves Stimulus: Companies_PropertyMappings_IndexController,
#                  Companies_PropertyMappings_ShowController,
#                  Companies_PropertyMappings_NewController,
#                  Companies_PropertyMappings_EditController
# Endpoints: GET    /companies/:company_id/property_mappings(.json)
#            GET    /companies/:company_id/property_mappings/:id(.json)
#            POST   /companies/:company_id/property_mappings
#            PATCH  /companies/:company_id/property_mappings/:id
#            DELETE /companies/:company_id/property_mappings/:id
# Docs: docs/CATEGORY_DYNAMIC_SCHEMA.md
class Companies::PropertyMappingsController < Companies::ApplicationController
  # Settings the Property Mapping editor owns per friendly type. Blank values
  # are removed on save so clearing an input really clears the setting.
  FORM_SETTING_KEYS = {
    "string" => %w[placeholder default prefix suffix],
    "integer" => %w[input_type placeholder default min max prefix suffix],
    "decimal" => %w[input_type placeholder default currency precision prefix suffix],
    "boolean" => %w[default true_label false_label],
    "datetime" => %w[default format timezone],
    "enum" => %w[input_type options default]
  }.freeze

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

  # The edit form owns key/name, type-specific settings, and enum options.
  # Merge submitted entries with the existing metadata so settings the form
  # does not render still survive a save. Hidden *_submitted markers let the
  # form clear the last row (Rails submits no nested params for an empty table).
  def normalize_metadata(mapping, p_params)
    return p_params unless p_params[:metadata].is_a?(ActionController::Parameters)

    meta = p_params[:metadata].to_unsafe_h
    properties_submitted = meta.delete("properties_submitted").to_s == "1"
    extra_columns_submitted = meta.delete("extra_columns_submitted").to_s == "1"

    submitted_properties = submitted_entries(meta["properties"], properties_submitted)
    unless submitted_properties.nil?
      meta["properties"] = merge_entries(mapping.properties, submitted_properties, derive_type: true)
      meta["used_property_keys"] = build_used_property_keys(mapping, meta["properties"])
    end

    submitted_extra_columns = submitted_entries(meta["extra_columns"], extra_columns_submitted)
    unless submitted_extra_columns.nil?
      meta["extra_columns"] = merge_entries(
        mapping.metadata&.dig("extra_columns"), submitted_extra_columns, derive_type: false
      )
    end

    p_params[:metadata] = meta
    p_params
  end

  # Hash = form-style indexed inputs; Array = direct JSON API payload.
  # nil = this part of the metadata was not submitted at all.
  def submitted_entries(raw, marker_present)
    case raw
    when Hash  then raw.values
    when Array then raw
    else marker_present ? [] : nil
    end
  end

  def merge_entries(existing_entries, submitted_entries, derive_type:)
    existing_by_key = Array(existing_entries).index_by { |entry| entry["key"] }

    submitted_entries.map do |raw_entry|
      entry = raw_entry.is_a?(Hash) ? raw_entry.dup : {}
      entry["name"] = entry["name"].to_s.strip if entry.key?("name")

      if !derive_type && entry["key"].blank?
        entry["key"] = "extra_#{SecureRandom.hex(4)}"
      end

      entry = normalize_property_entry(entry) if derive_type

      merged = existing_by_key[entry["key"]] ? existing_by_key[entry["key"]].merge(entry) : entry.dup
      merged.delete("validates")
      merged["type"] = derive_type ? type_from_key(entry["key"]) : "string" if merged["type"].blank?
      merged = strip_blank_settings(merged) if derive_type
      merged
    end
  end

  # Enum is stored as an integer slot + input_type=select + options so the
  # existing Table Config enum filter keeps working.
  def normalize_property_entry(entry)
    entry = entry.dup
    entry["key"] = entry["key"].to_s.strip

    if entry["key"].match?(/\Aproperty_(string|integer|decimal|boolean|datetime)_\d+\z/)
      entry["type"] = type_from_key(entry["key"])
    elsif entry["type"].blank?
      entry["type"] = type_from_key(entry["key"])
    end

    if entry["input_type"] == "select"
      entry["type"] = "integer"
      entry["options"] = normalize_options(entry["options"])
    elsif entry.key?("input_type") && entry["input_type"].blank?
      entry.delete("options")
    end

    coerce_setting_values(entry)
    entry
  end

  def coerce_setting_values(entry)
    %w[min max].each do |key|
      next if entry[key].blank?

      value = integer_value(entry[key])
      entry[key] = value if value.is_a?(Integer)
    end

    if entry["precision"].present?
      precision = integer_value(entry["precision"])
      entry["precision"] = precision if precision.is_a?(Integer)
    end

    case entry["type"]
    when "integer"
      value = integer_value(entry["default"])
      entry["default"] = value if entry["default"].present? && value.is_a?(Integer)
    when "decimal"
      value = Float(entry["default"], exception: false) if entry["default"].present?
      entry["default"] = value unless value.nil?
    when "boolean"
      entry["default"] = entry["default"] == "true" if %w[true false].include?(entry["default"].to_s)
    end
  end

  # Rails turns options[0][value] into an indexed hash; turn it back into the
  # array shape PropertyMapping validates and stores.
  def normalize_options(raw)
    list = raw.is_a?(Hash) ? raw.values : Array(raw)

    list.filter_map do |option|
      next unless option.is_a?(Hash)

      value = option["value"]
      label = option["label"].to_s.strip
      next if value.to_s.strip.blank? && label.blank?

      { "value" => integer_value(value), "label" => label }
    end
  end

  def integer_value(value)
    return value if value.is_a?(Integer)
    return value.to_i if value.to_s.strip.match?(/\A[+-]?\d+\z/)

    value
  end

  def strip_blank_settings(merged)
    ui_type = merged["input_type"] == "select" ? "enum" : merged["type"]
    Array(FORM_SETTING_KEYS[ui_type]).each do |key|
      next if key == "options"

      merged.delete(key) if merged[key].nil? || merged[key] == ""
    end
    merged
  end

  # Never reuse a slot after its property was deleted: old values still live in
  # the database column and would otherwise appear under a new field name.
  def build_used_property_keys(mapping, properties)
    existing = Array(mapping.metadata&.dig("used_property_keys"))
    previous = Array(mapping.properties).map { |entry| entry["key"] }
    current = Array(properties).map { |entry| entry["key"] }
    (existing + previous + current).compact_blank.uniq
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
