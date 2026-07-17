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
#   name:       String  — Human-readable display name. Required.
#   type:       String  — One of: string, text, integer, decimal, boolean,
#                        datetime. Derivable from the key prefix.
#   validates:  Hash    — Validation rules (future use, currently {}).

class PropertyMapping < ApplicationRecord
  include CategoryConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company, touch: true
  belongs_to :category

  has_many :table_configs, dependent: :destroy
  after_create :create_default_table_config

  def default_table_config
    table_configs.first
  end

  has_many :answers, dependent: :restrict_with_error
  has_many :articles, dependent: :restrict_with_error
  has_many :article_groups, dependent: :restrict_with_error
  has_many :brands, dependent: :restrict_with_error
  has_many :branches, dependent: :restrict_with_error
  has_many :carts, dependent: :restrict_with_error
  has_many :cart_groups, dependent: :restrict_with_error
  has_many :customers, dependent: :restrict_with_error
  has_many :customer_groups, dependent: :restrict_with_error
  has_many :departments, dependent: :restrict_with_error
  has_many :documents, dependent: :restrict_with_error
  has_many :document_groups, dependent: :restrict_with_error
  has_many :employees, dependent: :restrict_with_error
  has_many :employee_groups, dependent: :restrict_with_error
  has_many :events, dependent: :restrict_with_error
  has_many :event_groups, dependent: :restrict_with_error
  has_many :exams, dependent: :restrict_with_error
  has_many :exam_groups, dependent: :restrict_with_error
  has_many :facilities, dependent: :restrict_with_error
  has_many :facility_groups, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error
  has_many :memberships, dependent: :restrict_with_error
  has_many :notifications, dependent: :restrict_with_error
  has_many :notification_groups, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :order_groups, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error
  has_many :product_groups, dependent: :restrict_with_error
  has_many :projects, dependent: :restrict_with_error
  has_many :project_groups, dependent: :restrict_with_error
  has_many :purchases, dependent: :restrict_with_error
  has_many :purchase_items, dependent: :restrict_with_error
  has_many :questions, dependent: :restrict_with_error
  has_many :reservations, dependent: :restrict_with_error
  has_many :services, dependent: :restrict_with_error
  has_many :service_groups, dependent: :restrict_with_error
  has_many :settings, dependent: :restrict_with_error
  has_many :setting_groups, dependent: :restrict_with_error
  has_many :stocks, dependent: :restrict_with_error
  has_many :stock_exports, dependent: :restrict_with_error
  has_many :stock_imports, dependent: :restrict_with_error
  has_many :stock_transfers, dependent: :restrict_with_error
  has_many :tasks, dependent: :restrict_with_error
  has_many :task_groups, dependent: :restrict_with_error
  has_many :warehouses, dependent: :restrict_with_error

  SUPPORTED_KEYS = PROPERTY_MAPPING_SUPPORTED_KEYS
  VALID_INPUT_TYPES = PROPERTY_MAPPING_VALID_INPUT_TYPES

  validate :validate_property_metadata
  validate :must_have_table_config
  after_update :sync_table_configs, if: :saved_change_to_metadata?

  def sync_table_configs
    props = (metadata || {})["properties"] || []
    pm_property_keys = props.select { |pm| pm["key"].to_s.start_with?("property_") }
    pm_keys = pm_property_keys.map { |pm| pm["key"] }

    table_configs.reset.each do |tc|
      tc_meta = tc.metadata || {}
      columns = (tc_meta["columns"] || []).dup
      changed = false

      original_size = columns.size
      columns.reject! { |col| col["key"].to_s.start_with?("property_") && !pm_keys.include?(col["key"]) }
      changed ||= columns.size != original_size

      columns.each do |col|
        next unless col["key"].to_s.start_with?("property_")
        pm_entry = pm_property_keys.find { |pm| pm["key"] == col["key"] }
        next unless pm_entry
        next if pm_entry["name"] == col["name"]

        col["name"] = pm_entry["name"]
        changed = true
      end

      pm_keys.each do |key|
        next if columns.any? { |c| c["key"] == key }
        pm_entry = pm_property_keys.find { |pm| pm["key"] == key }
        columns << {
          "key" => key,
          "name" => pm_entry["name"],
          "visible" => true,
          "sortable" => true,
          "align" => "left",
          "pinned" => nil,
          "width" => nil,
          "roles" => [],
          "is_virtual" => false,
          "render_config" => {}
        }
        changed = true
      end

      if changed
        tc_meta["columns"] = columns
        tc.update_columns(metadata: tc_meta)
      end
    end
  end

  private

  def create_default_table_config
    table_configs.create!(company: company, category: category)
  end

  def must_have_table_config
    return unless persisted?
    return if table_configs.any?

    errors.add(:base, "must have at least one table config")
  end

  def validate_property_metadata
    props = (metadata || {})["properties"] || []
    unless props.is_a?(Array)
      errors.add(:metadata, "properties must be an array")
      return
    end

    props.each_with_index do |entry, idx|
      unless entry.is_a?(Hash)
        errors.add(:metadata, "properties element #{idx} must be a hash")
        next
      end

      key = entry["key"]
      if key.blank?
        errors.add(:metadata, "properties element #{idx}: key is required")
        next
      end

      name = entry["name"]
      if name.blank?
        errors.add(:metadata, "properties element #{idx}: name is required")
      end

      prefix = key.to_s.sub(/_\d+\z/, "").to_sym
      supported = SUPPORTED_KEYS[prefix]

      if supported
        unexpected = entry.keys - supported - %w[key type name validates]
        if unexpected.any?
          errors.add(:metadata, "properties element #{idx}: unsupported keys #{unexpected.join(", ")} for #{key}. Supported: #{supported.join(", ")}")
        end
      end

      input_type = entry["input_type"]
      next if input_type.blank?

      valid_types = VALID_INPUT_TYPES[prefix]
      if valid_types && !valid_types.include?(input_type)
        errors.add(:metadata, "properties element #{idx}: input_type must be one of: #{valid_types.join(", ")}")
        next
      end

      if input_type == "select"
        options = entry["options"]
        unless options.is_a?(Array) && options.all? { |o| o.is_a?(Hash) && o.key?("value") && o.key?("label") }
          errors.add(:metadata, "properties element #{idx}: options must be an array of objects with value and label keys")
        end
      end
    end
  end
end
