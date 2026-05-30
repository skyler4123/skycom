# == Property Slot Count Rationale (10-5-20-10-10-10)
#
# The property_* columns on this table store jsonb *display configuration*
# (label, input_type, options, format hints) — NOT the actual data.
# Actual typed data lives in the corresponding resource table columns.
#
#   property_mappings.property_integer_1 = { "label": "Volume", "input_type": "number", "suffix": "ml" }
#   products.property_integer_1          = 150  (the actual value)
#
# WHY THESE COUNTS:
#   string (10)  — Reduced from 20: free-text inputs can often be replaced by
#                  integer-backed select dropdowns. Covers color codes, short IDs,
#                  phone masks, badge labels.
#   text    (5)  — Long-form only: descriptions, notes, terms. Rarely need >5.
#   integer (20) — Most versatile. Can serve as select dropdowns (store enum IDs,
#                  display labels in UI), counts, thresholds, ranks, progress bars,
#                  sliders. 20 slots handle rich categorical + numeric needs.
#   decimal (10) — Monetary values, weights, percentages, dimensions. Sufficient
#                  for financial/measurement fields per category.
#   boolean (10) — Toggle flags, binary decisions, radio cards. Covers typical
#                  yes/no attributes per category.
#   datetime(10) — Dates, timestamps for scheduling, expiry, milestones, audits.

# === Supported Keys Per Type ===
#
# These are the only keys recognized per column type. Any key outside this
# list will fail validation.
#
# STRING (property_string_1..10)
#   Keys:      label, input_type, placeholder, suffix, prefix, default
#   Example:   { "label":"Variant Color", "input_type":"text", "placeholder":"#FF5733" }
#
# TEXT (property_text_1..5)
#   Keys:      label, input_type, placeholder, default
#   Example:   { "label":"Full Description", "input_type":"textarea" }
#
# INTEGER (property_integer_1..20)
#   Keys:      label, input_type, min, max, placeholder, suffix, prefix, default, options
#   input_type: select, progress_bar, slider, star
#   Example:   { "label":"Skin Type", "input_type":"select",
#                "options":[{"value":1,"label":"Oily"},{"value":2,"label":"Dry"}] }
#
# DECIMAL (property_decimal_1..10)
#   Keys:      label, input_type, precision, suffix, prefix, placeholder, default, currency
#   input_type: currency, number, percentage
#   Example:   { "label":"Price", "input_type":"currency", "currency":"VND", "precision":0 }
#
# BOOLEAN (property_boolean_1..10)
#   Keys:      label, input_type, suffix, prefix, placeholder, default, true_label, false_label
#   Example:   { "label":"Active", "input_type":"toggle" }
#
# DATETIME (property_datetime_1..10)
#   Keys:      label, input_type, suffix, prefix, placeholder, default, format, timezone
#   Example:   { "label":"Hire Date", "input_type":"date_only", "format":"YYYY-MM-DD" }

class PropertyMapping < ApplicationRecord
  include CategoryConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :category

  before_validation :normalize_string_values

  SUPPORTED_KEYS = {
    property_string:  %w[label input_type placeholder suffix prefix default].freeze,
    property_text:    %w[label input_type placeholder default].freeze,
    property_integer: %w[label input_type placeholder suffix prefix default min max options].freeze,
    property_decimal: %w[label input_type placeholder suffix prefix default currency precision].freeze,
    property_boolean: %w[label input_type placeholder suffix prefix default true_label false_label].freeze,
    property_datetime: %w[label input_type placeholder suffix prefix default format timezone].freeze
  }.freeze

  VALID_INPUT_TYPES = {
    property_string:  %w[text].freeze,
    property_text:    %w[textarea].freeze,
    property_integer: %w[select progress_bar slider star].freeze,
    property_decimal: %w[currency number percentage].freeze,
    property_boolean: %w[toggle].freeze,
    property_datetime: nil
  }.freeze

  validate :validate_property_configs

  private

  def validate_property_configs
    property_columns = self.class.attribute_names.select { |a| a.start_with?("property_") }

    property_columns.each do |column|
      value = send(column)
      next if value.nil? || value == {} || value == []

      unless value.is_a?(Hash)
        errors.add(column, "must be a JSON object (Hash)")
        next
      end

      prefix = column.to_s.sub(/_\d+\z/, "").to_sym
      supported = SUPPORTED_KEYS[prefix]

      if supported
        unexpected = value.keys.map(&:to_s) - supported
        if unexpected.any?
          errors.add(column, "unsupported keys: #{unexpected.join(", ")}. Supported keys: #{supported.join(", ")}")
        end
      end

      if value["label"].blank?
        errors.add(column, "must include a non-blank \"label\" key")
      end

      input_type = value["input_type"]
      next if input_type.blank?

      valid_types = VALID_INPUT_TYPES[prefix]
      if valid_types && !valid_types.include?(input_type)
        errors.add(column, "\"input_type\" must be one of: #{valid_types.join(", ")}")
        next
      end

      if input_type == "select"
        options = value["options"]
        unless options.is_a?(Array) && options.all? { |o| o.is_a?(Hash) && o.key?("value") && o.key?("label") }
          errors.add(column, "\"options\" must be an array of objects with \"value\" and \"label\" keys")
        end
      end
    end
  end

  def normalize_string_values
    property_columns = self.class.attribute_names.select { |a| a.start_with?("property_") }

    property_columns.each do |column|
      value = send(column)
      next unless value.is_a?(String)
      send(:"#{column}=", { "label" => value })
    end
  end
end
