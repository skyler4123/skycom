class TableConfig < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :columns_metadata, :jsonb, default: -> {
    [ { "key" => "name", "name" => "Name", "visible" => true, "sortable" => true,
       "align" => "left", "pinned" => nil, "width" => nil, "roles" => [],
       "is_virtual" => false, "render_config" => {} } ]
  }
  attribute :metadata, :jsonb, default: {}

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
  #     "align" => "left",
  #     "pinned" => "left",
  #     "roles" => []
  #   },
  #   {
  #     "key" => "property_string_1",
  #     "name" => "Payment Type",
  #     "visible" => true,
  #     "width" => 130,
  #     "align" => "center",
  #     "pinned" => nil,
  #     "roles" => []
  #   },
  #   {
  #     "key" => "property_integer_1",
  #     "name" => "Qty Items",
  #     "visible" => true,
  #     "width" => 100,
  #     "align" => "right",
  #     "pinned" => nil,
  #     "roles" => []
  #   },
  #   {
  #     "key" => "property_decimal_1",
  #     "name" => "VAT Tax Amount",
  #     "visible" => true,
  #     "width" => 160,
  #     "align" => "right",
  #     "pinned" => nil,
  #     "roles" => ["admin", "accountant"],
  #     "render_config" => {
  #       "format" => "currency",
  #       "currency_symbol" => "₫"
  #     }
  #   },
  #   {
  #     "key" => "property_boolean_1",
  #     "name" => "E-Receipt Sent",
  #     "visible" => true,
  #     "width" => 120,
  #     "align" => "center",
  #     "pinned" => nil,
  #     "roles" => [],
  #     "render_config" => {
  #       "format" => "badge",
  #       "truthy_color" => "green",
  #       "falsy_color" => "gray"
  #     }
  #   }
  # ]
  # ---------------------------------------------------------------------------
  # PATTERN — each element must follow this shape:
  #   {
  #     key:           String   # Column identifier (e.g. "name", "property_integer_1")
  #     name:          String   # Display name in the table header
  #     is_virtual:    Boolean  # false = real DB column, true = computed client-side
  #     visible:       Boolean  # true = shown, false = hidden (preserves config)
  #     width:         Integer  # Column width in pixels (null = auto)
  #     align:         String   # "left" | "center" | "right"
  #     pinned:        String   # "left" | "right" | null (sticky column)
  #     sortable:      Boolean  # Whether this column supports sorting
  #     roles:         String[] # Role keys allowed to see this column ([] = all)
  #     render_config: Hash     # Formatting options (e.g. { "format" => "currency" })
  #   }
  # ---------------------------------------------------------------------------

  ALLOWED_ALIGNS  = ALLOWED_TABLE_ALIGNS
  ALLOWED_PINNEDS = ALLOWED_TABLE_PINNEDS

  validate :columns_metadata_must_conform_to_schema

  private

  def columns_metadata_must_conform_to_schema
    unless columns_metadata.is_a?(Array)
      errors.add(:columns_metadata, "must be an array")
      return
    end

    columns_metadata.each_with_index do |field, idx|
      unless field.is_a?(Hash)
        errors.add(:columns_metadata, "element #{idx} must be a hash")
        next
      end

      key      = field["key"]
      name_val = field["name"]

      if !key.is_a?(String) || key.blank?
        errors.add(:columns_metadata, "element #{idx}: key is required and must be a non-blank string")
      end

      if !name_val.is_a?(String) || name_val.blank?
        errors.add(:columns_metadata, "element #{idx}: name is required and must be a non-blank string")
      end

      errors.add(:columns_metadata, "element #{idx}: visible must be a boolean")       if field.key?("visible")   && ![ true, false ].include?(field["visible"])
      errors.add(:columns_metadata, "element #{idx}: sortable must be a boolean")      if field.key?("sortable")  && ![ true, false ].include?(field["sortable"])
      errors.add(:columns_metadata, "element #{idx}: is_virtual must be a boolean")    if field.key?("is_virtual") && ![ true, false ].include?(field["is_virtual"])
      errors.add(:columns_metadata, "element #{idx}: align must be one of #{ALLOWED_ALIGNS}")  if field.key?("align") && field["align"].present? && ALLOWED_ALIGNS.exclude?(field["align"])
      errors.add(:columns_metadata, "element #{idx}: pinned must be one of #{ALLOWED_PINNEDS}") if field.key?("pinned") && field["pinned"].present? && ALLOWED_PINNEDS.exclude?(field["pinned"])
      errors.add(:columns_metadata, "element #{idx}: width must be an integer or null") if field.key?("width") && !field["width"].nil? && !field["width"].is_a?(Integer)
      errors.add(:columns_metadata, "element #{idx}: roles must be an array of strings") if field.key?("roles") && !field["roles"].nil? && !(field["roles"].is_a?(Array) && field["roles"].all? { |r| r.is_a?(String) })
      errors.add(:columns_metadata, "element #{idx}: render_config must be a hash")   if field.key?("render_config") && !field["render_config"].nil? && !field["render_config"].is_a?(Hash)

      if key.to_s.start_with?("property_") && name_val.present? && property_mapping.present?
        pm_entry = property_mapping.property_metadata.find { |pm| pm["key"] == key }
        if pm_entry && pm_entry["name"] != name_val
          errors.add(:columns_metadata, "element #{idx}: name '#{name_val}' must match PropertyMapping value '#{pm_entry['name']}'. Edit the PropertyMapping to change this name.")
        end
      end
    end
  end
end
