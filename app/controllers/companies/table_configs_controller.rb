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
    config = current_company.table_configs.new(table_config_params)

    if config.save
      redirect_to company_table_config_path(current_company, config), notice: "Table config created successfully."
    else
      redirect_to new_company_table_config_path(current_company),
        alert: config.errors.full_messages.to_sentence
    end
  end

  def update
    config = current_company.table_configs.find(params[:id])

    p_params = table_config_params
    if p_params[:columns_metadata].is_a?(ActionController::Parameters) && !p_params[:columns_metadata].is_a?(Array)
      p_params[:columns_metadata] = p_params[:columns_metadata].values.to_a
    end

    p_params[:columns_metadata] = normalize_column_types(p_params[:columns_metadata]) if p_params[:columns_metadata].is_a?(Array)

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

  def normalize_column_types(columns)
    columns.map do |col|
      h = col.to_h
      h["visible"] = to_boolean(h["visible"]) if h.key?("visible")
      h["sortable"] = to_boolean(h["sortable"]) if h.key?("sortable")
      h["is_virtual"] = to_boolean(h["is_virtual"]) if h.key?("is_virtual")
      h["width"] = h["width"].present? ? h["width"].to_i : nil
      h["roles"] = h["roles"].present? ? h["roles"].split(",").map(&:strip) : []
      h["pinned"] = nil if h["pinned"].blank?
    h["name"] = h["key"].humanize if h["name"].blank?
      h
    end
  end

  def to_boolean(value)
    return value if [ true, false ].include?(value)
    return true if value == "true" || value == "1"
    return false if value == "false" || value == "0"
    false
  end

  def table_config_params
    params.require(:table_config).permit(:category_id, :property_mapping_id, :name, :description, columns_metadata: {})
  end

  def format_config(config)
    config.as_json(only: [ :id, :category_id, :property_mapping_id, :name, :description, :columns_metadata, :resource_name, :created_at, :updated_at ]).merge(
      category: config.category&.as_json(only: [ :id, :name ]),
      property_mapping: config.property_mapping&.as_json(only: [ :id, :name ])
    )
  end

  def format_configs(configs)
    configs.map { |c| format_config(c) }
  end
end
