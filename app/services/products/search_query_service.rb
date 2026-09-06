# frozen_string_literal: true

# app/services/products/search_query_service.rb

# Translates TableConfig-driven search/filter form params into a Meilisearch query
# on Product and returns matching record ids in relevance order.
#
# Contract:
#   service = Products::SearchQueryService.new(company:, params:)
#   service.active?      # => boolean — q/filters present AND enabled by the TableConfig
#   service.record_ids   # => Array<String> | nil (nil when !active?)
#
# Wire format (traditional GET form): ?q=red&filters[property_string_1]=red&filters[...] = min:max
# Filter keys are whitelisted against the active TableConfig's columns_metadata; unknown or
# malformed params are ignored. Raises Meilisearch::Error to the caller when the search
# backend fails (the controller turns that into a 503 — never silent unfiltered results).
class Products::SearchQueryService
  # Safety cap on ids returned when a search is active. Single-file constant
  # (docs/CONSTANTS.md) — promote to constants.rb if a second caller appears.
  MS_SEARCH_MAX_IDS = 1000

  attr_reader :company, :params

  def initialize(company:, params:)
    @company = company
    @params = params
  end

  def active?
    return false if table_config.blank?

    search_enabled? || filter_expressions.any?
  end

  def record_ids
    return nil unless active?

    Product.ms_raw_search(query, **search_options).fetch("hits", []).map { |hit| hit["id"] }
  end

  # Public for specs: the Meilisearch search payload (without `q`).
  def search_options
    options = { filter: filter_string, hits_per_page: MS_SEARCH_MAX_IDS }
    options[:attributes_to_search_on] = search_attribute_keys if search_enabled?
    options
  end

  # Public for specs: the full Meilisearch filter expression.
  def filter_string
    parts = [ %(company_id = "#{company.id}") ]
    parts << %(category_id = "#{params[:category_id]}") if params[:category_id].present?
    parts << %(branch_id = "#{params[:branch_id]}") if params[:branch_id].present?
    parts.concat(filter_expressions)
    parts.join(" AND ")
  end

  private

  def query
    params[:q].to_s.strip
  end

  def table_config
    @table_config ||= if params[:category_id].present?
      company.table_configs.find_by(category_id: params[:category_id])
    else
      # Fallback: no category selected — use a products-scope config if one exists.
      company.table_configs.find_by(resource_name: "products")
    end
  end

  def columns
    @columns ||= table_config&.columns || []
  end

  def search_enabled?
    query.present? && columns.any? { |c| c["search"] == true }
  end

  def search_attribute_keys
    columns.select { |c| c["search"] == true }.map { |c| c["key"] }.presence
  end

  # Handles both ActionController::Parameters (form requests) and plain Hashes (JSON APIs/specs).
  # Read-only: keys are whitelisted against the TableConfig and values are parsed with strict
  # regexes before reaching Meilisearch — no model assignment, so to_unsafe_h is safe here.
  def requested_filters
    return @requested_filters if defined?(@requested_filters)

    raw = params[:filters]
    @requested_filters = if raw.blank?
      {}
    elsif raw.respond_to?(:to_unsafe_h)
      raw.to_unsafe_h
    else
      raw.to_h
    end
  end

  def column_with_filter(key)
    columns.find { |c| c["key"] == key.to_s && c["filter"].is_a?(Hash) && c["filter"]["type"].present? }
  end

  def filter_expressions
    requested_filters.filter_map do |key, value|
      col = column_with_filter(key)
      next if col.blank? || value.blank?

      expression_for(col["filter"], col["key"], value.to_s)
    end
  end

  def expression_for(filter, key, value)
    case filter["type"]
    when "boolean" then boolean_expression(key, value)
    when "enum"    then enum_expression(key, value)
    when "range"   then range_expression(key, value)
    when "date"    then date_expression(key, value)
    end
  end

  def boolean_expression(key, value)
    return nil unless %w[true false].include?(value)
    "#{key} = #{value}"
  end

  def enum_expression(key, value)
    return nil unless value.match?(/\A-?\d+\z/)
    "#{key} = #{value}"
  end

  # "min:max" (either side may be empty) -> key >= min AND key < max (half-open)
  def range_expression(key, value)
    return nil unless value.include?(":")

    from, to = value.split(":", 2)
    return nil unless numeric?(from) && numeric?(to)
    return nil if from.empty? && to.empty?

    bounds = []
    bounds << "#{key} >= #{from}" if from.present?
    bounds << "#{key} < #{to}" if to.present?
    bounds.join(" AND ")
  end

  # Half-open year buckets "from:to" -> [from)-01-01 .. [to)-01-01 (UTC)
  def date_expression(key, value)
    return nil unless value.include?(":")

    from, to = value.split(":", 2)
    return nil unless year?(from) && year?(to)
    return nil if from.empty? && to.empty?

    bounds = []
    bounds << "#{key} >= #{from}-01-01T00:00:00Z" if from.present?
    bounds << "#{key} < #{to}-01-01T00:00:00Z" if to.present?
    bounds.join(" AND ")
  end

  def numeric?(str)
    str.empty? || str.match?(/\A-?\d+(\.\d+)?\z/)
  end

  def year?(str)
    str.empty? || str.match?(/\A\d{1,4}\z/)
  end
end
