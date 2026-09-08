class TableConfig < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  # Valid values for column alignment.
  ALLOWED_ALIGNS = %w[left center right].freeze
  # Standard columns eligible for keyword search (property_string_* are also searchable).
  SEARCHABLE_STANDARD_KEYS = %w[name description code].freeze
  # Valid strategy types for a column's "filter" setting.
  FILTER_TYPES = %w[range enum boolean date].freeze
  # Allowed keys inside a column "filter" hash (strict shape).
  FILTER_ALLOWED_KEYS = %w[type active buckets].freeze
  store_accessor :metadata, :columns
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company, touch: true
  belongs_to :category
  belongs_to :property_mapping

  # TableConfig layout configuration for the Cashier/Accountant Grid View
  # [
  #   {
  #     "key" => "code",
  #     "name" => "Invoice No.",
  #     "visible" => true,
  #     "width" => 150,
  #     "align" => "left"
  #   },
  #   {
  #     "key" => "property_string_1",
  #     "name" => "Payment Type",
  #     "visible" => true,
  #     "width" => 130,
  #     "align" => "center"
  #   },
  #   {
  #     "key" => "property_integer_1",
  #     "name" => "Qty Items",
  #     "visible" => true,
  #     "width" => 100,
  #     "align" => "right"
  #   }
  # ]
  # ---------------------------------------------------------------------------
  # PATTERN — each element must follow this shape:
  #   {
  #     key:     String   # Column identifier (e.g. "name", "property_integer_1")
  #     name:    String   # Display name in the table header
  #     visible: Boolean  # true = shown, false = hidden (preserves config)
  #     width:   Integer  # Column width in pixels (null = auto)
  #     align:   String   # "left" | "center" | "right"
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
  # ---------------------------------------------------------------------------

  validate :columns_metadata_must_conform_to_schema
  after_initialize :set_default_columns, if: :new_record?

  private

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

      errors.add(:metadata, "columns element #{idx}: visible must be a boolean")       if field.key?("visible") && ![ true, false ].include?(field["visible"])
      errors.add(:metadata, "columns element #{idx}: align must be one of #{ALLOWED_ALIGNS}")  if field.key?("align") && field["align"].present? && ALLOWED_ALIGNS.exclude?(field["align"])
      errors.add(:metadata, "columns element #{idx}: width must be an integer or null") if field.key?("width") && !field["width"].nil? && !field["width"].is_a?(Integer)

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
      { "key" => "name", "name" => "Name", "visible" => true,
        "align" => "left", "width" => nil }
    ]
  end

  def validate_search_and_filter(field, idx)
    key = field["key"].to_s

    if field.key?("search")
      if ![ true, false ].include?(field["search"])
        errors.add(:metadata, "columns element #{idx}: search must be a boolean")
      elsif field["search"] && !string_searchable?(key)
        errors.add(:metadata, "columns element #{idx}: search is only allowed on string columns")
      end
    end

    return if !field.key?("filter") || field["filter"].blank?

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
    SEARCHABLE_STANDARD_KEYS.include?(key) || key.start_with?("property_string_")
  end

  def pm_entry_for(key)
    return nil if property_mapping.blank?
    (property_mapping.properties || []).find { |p| p["key"] == key }
  end

  # Column data type: PropertyMapping "type" wins, else derived from the key prefix.
  def infer_column_type(key)
    type = pm_entry_for(key)&.[]("type")
    return type if type.present?

    case key
    when /\Aproperty_string_/      then "string"
    when /\Aproperty_integer_/     then "integer"
    when /\Aproperty_decimal_/     then "decimal"
    when /\Aproperty_boolean_/     then "boolean"
    when /\Aproperty_datetime_/    then "datetime"
    when *SEARCHABLE_STANDARD_KEYS then "string"
    end
  end
end
