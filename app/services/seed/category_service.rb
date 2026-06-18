class Seed::CategoryService
  PROPERTY_SLOT_KEYS = %w[
    property_string_1 property_string_2 property_string_3 property_string_4 property_string_5
    property_string_6 property_string_7 property_string_8 property_string_9 property_string_10
    property_text_1 property_text_2 property_text_3 property_text_4 property_text_5
    property_integer_1 property_integer_2 property_integer_3 property_integer_4 property_integer_5
    property_integer_6 property_integer_7 property_integer_8 property_integer_9 property_integer_10
    property_integer_11 property_integer_12 property_integer_13 property_integer_14 property_integer_15
    property_integer_16 property_integer_17 property_integer_18 property_integer_19 property_integer_20
    property_decimal_1 property_decimal_2 property_decimal_3 property_decimal_4 property_decimal_5
    property_decimal_6 property_decimal_7 property_decimal_8 property_decimal_9 property_decimal_10
    property_boolean_1 property_boolean_2 property_boolean_3 property_boolean_4 property_boolean_5
    property_boolean_6 property_boolean_7 property_boolean_8 property_boolean_9 property_boolean_10
    property_datetime_1 property_datetime_2 property_datetime_3 property_datetime_4 property_datetime_5
    property_datetime_6 property_datetime_7 property_datetime_8 property_datetime_9 property_datetime_10
  ].freeze

  STRING_LABELS = %w[SKU Brand Color Size Material Category Origin Scent Grade Variant Model Type Label]
  TEXT_LABELS = %w[Description Notes Instructions Ingredients Warnings Summary Details Specifications]
  INTEGER_LABELS = [ "Quantity", "Units per Box", "Shelf Number", "Min Stock", "Reorder Point",
                     "Max Capacity", "Lead Time", "Page Count", "Slot Number", "Priority" ]
  DECIMAL_LABELS = [ "Weight (kg)", "Unit Price", "Discount %", "Tax Rate", "Rating",
                     "Length (cm)", "Width (cm)", "Height (cm)", "Volume (L)", "Cost" ]
  BOOLEAN_LABELS = %w[Active Featured Taxable Available Seasonal Fragile Refrigerated Digital Exclusive]
  DATETIME_LABELS = [ "Start Date", "End Date", "Manufactured On", "Best Before",
                      "Last Checked", "Expiry Date", "Renewal Date", "Audit Date",
                      "Published At", "Reviewed At" ]

  # Derives the property type from a slot key like "property_string_1" → "string"
  TYPE_FROM_KEY = PROPERTY_SLOT_KEYS.each_with_object({}) do |key, hash|
    hash[key] = key.split("_")[1]
  end.freeze

  def self.new(
    company:,
    name: Faker::Commerce.department,
    resource_name: nil,
    properties: {}
  )
    Category.new(
      company: company,
      name: name,
      resource_name: resource_name
    )
  end

  def self.create(
    company:,
    name: Faker::Commerce.department,
    resource_name: nil,
    properties: {}
  )
    category = new(
      company: company,
      name: name,
      resource_name: resource_name
    )
    category.save!
    metadatas = build_property_metadata(properties.presence || random_property_labels)
    category.default_property_mapping.update!(property_metadata: metadatas) if metadatas.present?

    category
  end

  # Convert a hash of slot_key → label_string into the JSONB array format
  # stored in property_mappings.property_metadata.
  def self.build_property_metadata(entries)
    entries.map do |key, label|
      type = TYPE_FROM_KEY[key.to_s] || "string"
      name = label.to_s.parameterize.underscore.tr("-", "_")
      {
        "key" => key.to_s,
        "name" => name,
        "type" => type,
        "label" => label.to_s,
        "validates" => {}
      }
    end
  end

  def self.find_or_create_for(company:, resource_name:)
    Category.find_or_create_by!(
      company: company,
      resource_name: resource_name.to_s
    ) { |cat| cat.name = resource_name.to_s.humanize }
  end

  def self.random_for(company:, resource_name:)
    Category.where(company: company, resource_name: resource_name.to_s).sample
  end

  # Returns an array of slot-key → random-label pairs (same shape as
  # the `properties:` hash) so build_property_metadata can consume it.
  def self.random_property_labels
    count = rand(10..25)
    PROPERTY_SLOT_KEYS.sample(count).each_with_object({}) do |column, hash|
      hash[column] = label_for(column)
    end
  end

  def self.label_for(column)
    case column
    when /^property_string_/   then STRING_LABELS.sample
    when /^property_text_/     then TEXT_LABELS.sample
    when /^property_integer_/  then INTEGER_LABELS.sample
    when /^property_decimal_/  then DECIMAL_LABELS.sample
    when /^property_boolean_/  then BOOLEAN_LABELS.sample
    when /^property_datetime_/ then DATETIME_LABELS.sample
    else column.humanize
    end
  end
end
