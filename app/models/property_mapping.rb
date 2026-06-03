# PropertyMapping configuration for the "invoices" resource (e.g., Category: "B2C Retail Invoice")
# [
#   {
#     "key" => "property_string_1",
#     "name" => "payment_method",
#     "type" => "string",
#     "validates" => {
#       "presence" => true,
#       "inclusion" => { "in" => ["Cash", "Credit Card", "E-Wallet"] }
#     }
#   },
#   {
#     "key" => "property_integer_1",
#     "name" => "total_items_quantity",
#     "type" => "integer",
#     "validates" => {
#       "numericality" => { "only_integer" => true, "greater_than" => 0 }
#     }
#   },
#   {
#     "key" => "property_decimal_1",
#     "name" => "vat_amount_vnd",
#     "type" => "decimal",
#     "validates" => {
#       "numericality" => { "greater_than_or_equal_to" => 0 }
#     }
#   },
#   {
#     "key" => "property_boolean_1",
#     "name" => "is_e_invoice_sent",
#     "type" => "boolean",
#     "validates" => {
#       "inclusion" => { "in" => [true, false] }
#     }
#   }
# ]
#
# === Per-Config Object Schema
#
# Each element in the array must be a Hash with these keys:
#
#   key:        String  — The resource column this config describes
#                        (e.g. "property_string_1"). Required.
#   name:       String  — System identifier (underscored, e.g. "skin_type").
#   type:       String  — One of: string, text, integer, decimal, boolean,
#                        datetime. Derivable from the key prefix.
#   label:      String  — Human-readable display name. Required.
#   validates:  Hash    — Validation rules (future use, currently {}).

class PropertyMapping < ApplicationRecord
  include CategoryConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :category

  has_many :table_configs, dependent: :destroy

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

  validate :validate_property_metadata

  private

  def validate_property_metadata
    unless property_metadata.is_a?(Array)
      errors.add(:property_metadata, "must be an array")
      return
    end

    property_metadata.each_with_index do |entry, idx|
      unless entry.is_a?(Hash)
        errors.add(:property_metadata, "element #{idx} must be a hash")
        next
      end

      key = entry["key"]
      if key.blank?
        errors.add(:property_metadata, "element #{idx}: key is required")
        next
      end

      label = entry["label"]
      if label.blank?
        errors.add(:property_metadata, "element #{idx}: label is required")
      end

      prefix = key.to_s.sub(/_\d+\z/, "").to_sym
      supported = SUPPORTED_KEYS[prefix]

      if supported
        unexpected = entry.keys - supported - %w[key name type label validates]
        if unexpected.any?
          errors.add(:property_metadata, "element #{idx}: unsupported keys #{unexpected.join(", ")} for #{key}. Supported: #{supported.join(", ")}")
        end
      end

      input_type = entry["input_type"]
      next if input_type.blank?

      valid_types = VALID_INPUT_TYPES[prefix]
      if valid_types && !valid_types.include?(input_type)
        errors.add(:property_metadata, "element #{idx}: input_type must be one of: #{valid_types.join(", ")}")
        next
      end

      if input_type == "select"
        options = entry["options"]
        unless options.is_a?(Array) && options.all? { |o| o.is_a?(Hash) && o.key?("value") && o.key?("label") }
          errors.add(:property_metadata, "element #{idx}: options must be an array of objects with value and label keys")
        end
      end
    end
  end
end
