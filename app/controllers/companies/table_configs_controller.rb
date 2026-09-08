# app/controllers/companies/table_configs_controller.rb
#
# TableConfig dashboard API + editor form handling.
# update: metadata[columns] accepts per-column `search` (boolean, string columns) and
#         `filter` (range/enum/boolean/date hash; submitted as raw JSON text, parsed in
#         normalize_column_types, shape-validated in TableConfig).
# Serves Stimulus: Companies_TableConfigs_IndexController|ShowController|NewController|EditController
# Endpoints: GET/POST/PATCH /companies/:company_id/table_configs... — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md (column pattern), docs/MEILISEARCH.md (consumers of search/filter config)
class Companies::TableConfigsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.table_configs.includes(:category, :property_mapping)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @configs = pagy(:offset, scope, jsonapi: true)

        render json: {
          table_configs: format_configs(@configs),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    config = current_company.table_configs.includes(:category, :property_mapping).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { table_config: format_config(config) } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { status: "error", message: "Table config not found" }, status: :not_found }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    config = current_company.table_configs.includes(:category, :property_mapping).find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { table_config: format_config(config) } }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { status: "error", message: "Table config not found" }, status: :not_found }
    end
  end

  def create
    config = current_company.table_configs.new(normalize_metadata(table_config_params))

    if config.save
      redirect_to company_table_config_path(current_company, config), notice: "Table config created successfully."
    else
      redirect_to new_company_table_config_path(current_company),
        alert: config.errors.full_messages.to_sentence
    end
  end

  def update
    config = current_company.table_configs.find(params[:id])

    p_params = normalize_metadata(table_config_params)

    if config.update(p_params)
      redirect_to company_table_config_path(current_company, config), notice: "Table config updated successfully."
    else
      redirect_to edit_company_table_config_path(current_company, config),
        alert: config.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to company_table_configs_path(current_company), alert: "Table config not found."
  end

  private

  # Shared by create/update: converts the metadata[columns] hash-of-indexes form payload
  # into an array and type-normalizes each column (see normalize_column_types).
  def normalize_metadata(p_params)
    return p_params unless p_params[:metadata].is_a?(ActionController::Parameters)

    meta = p_params[:metadata].to_unsafe_h
    meta["columns"] = normalize_column_types(meta["columns"].values.to_a) if meta["columns"].is_a?(Hash)
    p_params[:metadata] = meta
    p_params
  end

  def normalize_column_types(columns)
    columns.map do |col|
      h = col.to_h
      h["visible"] = to_boolean(h["visible"]) if h.key?("visible")
      h["search"] = to_boolean(h["search"]) if h.key?("search")
      h["filter"] = parse_filter_config(h["filter"]) if h.key?("filter")
      merge_filter_active(h)
      h.delete("filter") if h["filter"].blank?
      h["width"] = h["width"].present? ? h["width"].to_i : nil
      h["name"] = h["key"].humanize if h["name"].blank?
      h
    end
  end

  # The Filter cell pairs a JSON textarea with an "active" checkbox (temp key filter_active).
  # The checkbox always wins when present; configs submitted without it (legacy/API) keep
  # an explicit active and default to enabled when missing.
  def merge_filter_active(h)
    h.delete("filter_active").then do |submitted|
      next unless h["filter"].is_a?(Hash)

      h["filter"]["active"] = if submitted.nil?
        h["filter"].fetch("active", true)
      else
        to_boolean(submitted)
      end
    end
  end

  # The filter cell submits raw JSON text. Parse it back into a hash; invalid JSON stays a
  # string so the TableConfig model validation rejects the save with a useful error.
  def parse_filter_config(value)
    return value if value.is_a?(Hash)
    return nil if value.blank?
    JSON.parse(value)
  rescue JSON::ParserError
    value
  end

  def to_boolean(value)
    return value if [ true, false ].include?(value)
    return true if value == "true" || value == "1"
    return false if value == "false" || value == "0"
    false
  end

  def table_config_params
    params.require(:table_config).permit(:category_id, :property_mapping_id, :name, :description, metadata: {})
  end

  def format_config(config)
    config.as_json(only: [ :id, :category_id, :property_mapping_id, :name, :description, :metadata, :resource_name, :created_at, :updated_at ]).merge(
      category: config.category&.as_json(only: [ :id, :name ]),
      property_mapping: config.property_mapping&.as_json(only: [ :id, :name ])
    )
  end

  def format_configs(configs)
    configs.map { |c| format_config(c) }
  end
end
