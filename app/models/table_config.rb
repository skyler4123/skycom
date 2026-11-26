# frozen_string_literal: true

# TableConfig — Atomic purpose: per-company/category table layout definition for
# an index page (columns, visibility, and optional filters).
#
# Why it exists: lets each tenant shape its grid view for a resource without code
# changes; the layout is data (metadata.columns) validated against the category's
# property mapping (see docs/DYNAMIC_TABLE.md and docs/COMPUTED_COLUMNS.md).
# How it works: `columns` is a store_accessor on metadata; after_initialize seeds
# defaults, before_validation resolves each column's source (real DB column,
# computed model method, property, or extra), and the validation enforces the
# documented shape (key/name/visible/search/filter). A real DB column always
# wins over a computed declaration with the same key.
# Main associations: belongs_to :company (touch), :category, :property_mapping;
# has_many :table_config_logs (dependent: :nullify).
class TableConfig < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  # Standard columns eligible for keyword search (property_string_* are also searchable).
  SEARCHABLE_STANDARD_KEYS = %w[name description code title].freeze
  # Standard (non-property) numeric metric columns eligible for range filters.
  # Must mirror an `ms_extra_filterable_columns` declaration on the indexed model
  # to actually filter (docs/MEILISEARCH.md §2).
  NUMERIC_STANDARD_KEYS = %w[quantity pending].freeze
  # Valid strategy types for a column's "filter" setting.
  FILTER_TYPES = %w[range enum boolean date].freeze
  # Allowed keys inside a column "filter" hash (strict shape).
  FILTER_ALLOWED_KEYS = %w[type active buckets].freeze
  # Fixed display labels for standard (non-property) columns. Names are owned
  # by this table, never by the Table Config editor.
  STANDARD_COLUMN_NAMES = {
    "name" => "Name",
    "description" => "Description",
    "code" => "Code",
    "title" => "Title",
    "quantity" => "Quantity",
    "pending" => "Pending"
  }.freeze
  # Data types for the fixed standard labels above.
  STANDARD_COLUMN_TYPES = {
    "name" => "string",
    "description" => "string",
    "code" => "string",
    "title" => "string",
    "quantity" => "integer",
    "pending" => "integer"
  }.freeze
  store_accessor :metadata, :columns
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company, touch: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :table_config_logs, dependent: :nullify

  # TableConfig layout configuration for the Cashier/Accountant Grid View
  # [
  #   {
  #     "key" => "code",
  #     "name" => "Invoice No.",
  #     "visible" => true
  #   },
  #   {
  #     "key" => "property_string_1",
  #     "name" => "Payment Type",
  #     "visible" => true,
  #     "search" => true
  #   },
  #   {
  #     "key" => "quantity",
  #     "name" => "Quantity",
  #     "visible" => true,
  #     "type" => "integer"
  #   },
  #   {
  #     "key" => "property_integer_1",
  #     "name" => "Qty Items",
  #     "visible" => true,
  #     "filter" => { "type" => "range", "active" => true, "buckets" => [[nil, 100], [100, nil]] }
  #   }
  # ]
  # ---------------------------------------------------------------------------
  # PATTERN — each element must follow this shape:
  #   {
  #     key:     String   # Column identifier (e.g. "name", "property_integer_1")
  #     name:    String   # Display name in the table header
  #     visible: Boolean  # true = shown, false = hidden (preserves config)
  #     type:    String   # Optional. Derived for computed columns (e.g. "integer")
  #     search:  Boolean  # Optional. Keyword-searchable column (string columns only)
  #     filter:  Hash     # Optional. Dropdown filter config, shape depends on column type.
  #                       # "active" (boolean, REQUIRED) gates the filter — it only applies
  #                       # on index pages while active: true.
  #                       #   integer/decimal: { "type" => "range", "active" => bool, "buckets" => [[from, to], ...] }
  #                       #                    half-open [from, to); null = open side
  #                       #   integer (PM input_type=select): { "type" => "enum", "active" => bool }
  #                       #   boolean: { "type" => "boolean", "active" => bool }
  #                       #   datetime: { "type" => "date", "active" => bool, "buckets" => [[from_year, to_year], ...] }
  #   }
  # Computed columns never accept "search" or "filter" — their values are
  # calculated by the model (docs/COMPUTED_COLUMNS.md).
  # ---------------------------------------------------------------------------

  validate :columns_metadata_must_conform_to_schema
  before_validation :normalize_columns
  after_initialize :set_default_columns, if: :new_record?

  # Real DB columns for this resource, filtered from the curated standard list.
  # Used by the Table Config editor so it never offers a column the model lacks.
  def self.standard_columns_for(resource_name)
    model = ComputedColumns.model_for(resource_name)
    keys = model ? (STANDARD_COLUMN_NAMES.keys & model.column_names) : STANDARD_COLUMN_NAMES.keys

    keys.map do |key|
      {
        "key" => key,
        "name" => STANDARD_COLUMN_NAMES[key],
        "type" => STANDARD_COLUMN_TYPES[key]
      }
    end
  end

  # Computed method columns declared by the resource model (nil when unsupported).
  def self.computed_columns_for(resource_name)
    ComputedColumns.for(resource_name)
  end

  def effective_resource_name
    resource_name.presence || category&.resource_name
  end

  private

  # Resolves each column to the source that owns it. A real DB column wins over a
  # computed method with the same key; a standard key that is neither real nor
  # computed is a ghost and is dropped (e.g. Product "title", or "quantity" on a
  # model that neither stores nor declares it).
  def normalize_columns
    return unless columns.is_a?(Array)

    properties_by_key = (property_mapping&.properties || []).index_by { |entry| entry["key"] }
    extra_columns = property_mapping&.metadata&.dig("extra_columns")
    extras_by_key = (extra_columns.is_a?(Array) ? extra_columns : []).index_by { |entry| entry["key"] }
    changed = false

    normalized = columns.filter_map do |column|
      next column unless column.is_a?(Hash)

      key = column["key"].to_s

      if standard_key?(key)
        normalized_column = column.except("type")
        canonical_name = STANDARD_COLUMN_NAMES[key]
        if canonical_name.present? && canonical_name != normalized_column["name"]
          normalized_column = normalized_column.merge("name" => canonical_name)
        end
      elsif (entry = computed_entry_for(key))
        normalized_column = column.except("search", "filter").merge(
          "name" => entry["name"],
          "type" => entry["type"]
        )
      elsif STANDARD_COLUMN_NAMES.key?(key) && resource_model
        changed = true
        next nil
      elsif key.start_with?("property_")
        normalized_column = column
        canonical_name = properties_by_key[key]&.[]("name")
        if canonical_name.present? && canonical_name != column["name"]
          normalized_column = column.merge("name" => canonical_name)
        end
      elsif key.start_with?("extra_")
        normalized_column = column
        canonical_name = extras_by_key[key]&.[]("name")
        if canonical_name.present? && canonical_name != column["name"]
          normalized_column = column.merge("name" => canonical_name)
        end
      else
        normalized_column = column
      end

      changed ||= normalized_column != column
      normalized_column
    end

    self.columns = normalized if changed
  end

  def columns_metadata_must_conform_to_schema
    columns = self.columns || []
    unless columns.is_a?(Array)
      errors.add(:metadata, "columns must be an array")
      return
    end

    columns.each_with_index do |field, idx|
      unless field.is_a?(Hash)
        errors.add(:metadata, "columns element #{idx} must be a hash")
        next
      end

      key      = field["key"]
      name_val = field["name"]

      if !key.is_a?(String) || key.blank?
        errors.add(:metadata, "columns element #{idx}: key is required and must be a non-blank string")
      end

      if !name_val.is_a?(String) || name_val.blank?
        errors.add(:metadata, "columns element #{idx}: name is required and must be a non-blank string")
      end

      errors.add(:metadata, "columns element #{idx}: visible must be a boolean") if field.key?("visible") && ![ true, false ].include?(field["visible"])

      validate_search_and_filter(field, idx)

      if key.to_s.start_with?("property_") && name_val.present? && property_mapping.present?
        pm_entry = (property_mapping.properties || []).find { |pm| pm["key"] == key }
        if pm_entry && pm_entry["name"] != name_val
          errors.add(:metadata, "columns element #{idx}: name '#{name_val}' must match PropertyMapping value '#{pm_entry['name']}'. Edit the PropertyMapping to change this name.")
        end
      end
    end
  end

  def set_default_columns
    self.metadata ||= {}
    self.columns ||= [
      { "key" => "name", "name" => "Name", "visible" => true }
    ]
  end

  def validate_search_and_filter(field, idx)
    key = field["key"].to_s
    source = column_source(key)

    if field.key?("search")
      if ![ true, false ].include?(field["search"])
        errors.add(:metadata, "columns element #{idx}: search must be a boolean")
      elsif source == "computed" && field["search"]
        errors.add(:metadata, "columns element #{idx}: search is not allowed on computed columns")
      elsif field["search"] && !string_searchable?(key)
        errors.add(:metadata, "columns element #{idx}: search is only allowed on string columns")
      end
    end

    return if !field.key?("filter") || field["filter"].blank?

    if source == "computed"
      errors.add(:metadata, "columns element #{idx}: filter is not allowed on computed columns")
      return
    end

    validate_filter(field["filter"], idx, key)
  end

  def validate_filter(filter, idx, key)
    unless filter.is_a?(Hash)
      errors.add(:metadata, "columns element #{idx}: filter must be a hash (invalid JSON?)")
      return
    end

    unknown = filter.keys - FILTER_ALLOWED_KEYS
    errors.add(:metadata, "columns element #{idx}: filter has unknown keys: #{unknown.join(", ")}") if unknown.any?

    type = filter["type"]
    unless FILTER_TYPES.include?(type)
      errors.add(:metadata, "columns element #{idx}: filter type must be one of #{FILTER_TYPES.join(", ")}")
      return
    end

    unless filter.key?("active") && [ true, false ].include?(filter["active"])
      errors.add(:metadata, "columns element #{idx}: filter requires \"active\" true or false")
    end

    column_type = infer_column_type(key)

    case type
    when "range"
      errors.add(:metadata, "columns element #{idx}: range filter is only allowed on integer/decimal columns") unless %w[integer decimal].include?(column_type)
      validate_buckets(filter["buckets"], idx)
    when "date"
      errors.add(:metadata, "columns element #{idx}: date filter is only allowed on datetime columns") unless column_type == "datetime"
      validate_buckets(filter["buckets"], idx)
    when "enum"
      unless column_type == "integer" && pm_entry_for(key)&.[]("input_type") == "select"
        errors.add(:metadata, "columns element #{idx}: enum filter requires an integer column with PropertyMapping input_type=select")
      end
    when "boolean"
      errors.add(:metadata, "columns element #{idx}: boolean filter is only allowed on boolean columns") unless column_type == "boolean"
    end
  end

  def validate_buckets(buckets, idx)
    unless buckets.is_a?(Array) && buckets.any?
      errors.add(:metadata, "columns element #{idx}: filter requires a non-empty buckets array")
      return
    end

    buckets.each do |b|
      unless b.is_a?(Array) && b.size == 2 && b.all? { |v| v.nil? || v.is_a?(Numeric) }
        errors.add(:metadata, "columns element #{idx}: each bucket must be [from, to] with numbers or null")
        next
      end
      from, to = b
      errors.add(:metadata, "columns element #{idx}: bucket #{b.inspect} has both sides open") if from.nil? && to.nil?
      errors.add(:metadata, "columns element #{idx}: bucket #{b.inspect} must satisfy from < to") if from && to && from >= to
    end
  end

  def string_searchable?(key)
    return false if column_source(key) == "computed"
    return true if key.start_with?("property_string_")

    standard_key?(key) && SEARCHABLE_STANDARD_KEYS.include?(key)
  end

  # Real DB column for this resource -> standard. Otherwise a declared computed
  # method -> computed. Otherwise property/extra/other.
  def column_source(key)
    key = key.to_s
    return "standard" if standard_key?(key)
    return "computed" if computed_entry_for(key)
    return "property" if key.start_with?("property_")
    return "extra" if key.start_with?("extra_")

    "other"
  end

  def standard_key?(key)
    key = key.to_s
    return false unless STANDARD_COLUMN_NAMES.key?(key)
    return true if resource_model.nil?

    resource_model.column_names.include?(key)
  end

  def resource_model
    return @resource_model if defined?(@resource_model)

    @resource_model = ComputedColumns.model_for(effective_resource_name)
  end

  def computed_columns
    @computed_columns ||= self.class.computed_columns_for(effective_resource_name) || []
  end

  def computed_entry_for(key)
    computed_columns.find { |column| column["key"] == key.to_s }
  end

  def pm_entry_for(key)
    return nil if property_mapping.blank?
    (property_mapping.properties || []).find { |p| p["key"] == key }
  end

  # Column data type: computed method wins, then real standard column, then
  # PropertyMapping "type", then the key prefix fallback.
  def infer_column_type(key)
    key = key.to_s
    computed_type = computed_entry_for(key)&.[]("type")
    return computed_type if computed_type.present?
    return STANDARD_COLUMN_TYPES[key] if standard_key?(key)

    type = pm_entry_for(key)&.[]("type")
    return type if type.present?

    case key
    when /\Aproperty_string_/      then "string"
    when /\Aproperty_integer_/     then "integer"
    when /\Aproperty_decimal_/     then "decimal"
    when /\Aproperty_boolean_/     then "boolean"
    when /\Aproperty_datetime_/    then "datetime"
    end
  end
end
