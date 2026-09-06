class TableConfig < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  # Valid values for column alignment.
  ALLOWED_ALIGNS = %w[left center right].freeze
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
end
