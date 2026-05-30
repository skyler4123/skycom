class TableConfig < ApplicationRecord
  include CategoryConcern
  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :fields, :jsonb, default: -> {
    [ { "key" => "name", "label" => "Name", "visible" => true, "sortable" => true,
       "align" => "left", "pinned" => nil, "width" => nil, "roles" => [],
       "is_virtual" => false, "render_config" => {} } ]
  }

  belongs_to :company
  belongs_to :category

  # ---------------------------------------------------------------------------
  # `fields` JSONB Array — Enterprise Table Configuration
  # ---------------------------------------------------------------------------
  # WHY jsonb array of hashes instead of a plain string array:
  #   A simple string array only supports column ordering. Enterprise grids
  #   need per-column width, alignment, pinning, role-based visibility, and
  #   render formatting (currency, computed composites) — all requiring
  #   structured metadata. A JSONB array of hashes provides a single source
  #   of truth the frontend reads directly to build the table without extra
  #   joins or configuration lookups.
  #
  # PATTERN — each element must follow this shape:
  #   {
  #     key:           String   # Column identifier (e.g. "name", "property_integer_1")
  #     label:         String   # Display name in the table header
  #     is_virtual:    Boolean  # false = real DB column, true = computed client-side
  #     visible:       Boolean  # true = shown, false = hidden (preserves config)
  #     width:         Integer  # Column width in pixels (null = auto)
  #     align:         String   # "left" | "center" | "right"
  #     pinned:        String   # "left" | "right" | null (sticky column)
  #     sortable:      Boolean  # Whether this column supports sorting
  #     roles:         String[] # Role keys allowed to see this column ([] = all)
  #     render_config: Hash     # Formatting options (e.g. { "format" => "currency" })
  #   }
  #
  # EXAMPLE:
  #   [
  #     { "key" => "name", "label" => "Product Name", "visible" => true,
  #       "width" => 250, "align" => "left", "pinned" => "left",
  #       "sortable" => true, "roles" => [], "is_virtual" => false,
  #       "render_config" => {} },
  #     { "key" => "property_integer_1", "label" => "Unit Cost",
  #       "visible" => true, "width" => 120, "align" => "right",
  #       "sortable" => true, "roles" => ["admin", "manager"],
  #       "is_virtual" => false,
  #       "render_config" => { "format" => "currency", "currency_symbol" => "₫" } },
  #     { "key" => "total_weight", "label" => "Gross Weight (g)",
  #       "visible" => true, "width" => 160, "align" => "right",
  #       "sortable" => false, "roles" => [], "is_virtual" => true,
  #       "render_config" => { "type" => "math", "operator" => "+",
  #                            "depends_on" => ["property_integer_2", "property_integer_3"] } }
  #   ]
  # ---------------------------------------------------------------------------

  ALLOWED_ALIGNS  = %w[left center right].freeze
  ALLOWED_PINNEDS = %w[left right].freeze

  validate :fields_must_conform_to_schema

  private

  def fields_must_conform_to_schema
    unless fields.is_a?(Array)
      errors.add(:fields, "must be an array")
      return
    end

    fields.each_with_index do |field, idx|
      unless field.is_a?(Hash)
        errors.add(:fields, "element #{idx} must be a hash")
        next
      end

      key   = field["key"]
      label = field["label"]

      if !key.is_a?(String) || key.blank?
        errors.add(:fields, "element #{idx}: key is required and must be a non-blank string")
      end

      if !label.is_a?(String) || label.blank?
        errors.add(:fields, "element #{idx}: label is required and must be a non-blank string")
      end

      errors.add(:fields, "element #{idx}: visible must be a boolean")       if field.key?("visible")   && ![ true, false ].include?(field["visible"])
      errors.add(:fields, "element #{idx}: sortable must be a boolean")      if field.key?("sortable")  && ![ true, false ].include?(field["sortable"])
      errors.add(:fields, "element #{idx}: is_virtual must be a boolean")    if field.key?("is_virtual") && ![ true, false ].include?(field["is_virtual"])
      errors.add(:fields, "element #{idx}: align must be one of #{ALLOWED_ALIGNS}")  if field.key?("align") && field["align"].present? && ALLOWED_ALIGNS.exclude?(field["align"])
      errors.add(:fields, "element #{idx}: pinned must be one of #{ALLOWED_PINNEDS}") if field.key?("pinned") && field["pinned"].present? && ALLOWED_PINNEDS.exclude?(field["pinned"])
      errors.add(:fields, "element #{idx}: width must be an integer or null") if field.key?("width") && !field["width"].nil? && !field["width"].is_a?(Integer)
      errors.add(:fields, "element #{idx}: roles must be an array of strings") if field.key?("roles") && !field["roles"].nil? && !(field["roles"].is_a?(Array) && field["roles"].all? { |r| r.is_a?(String) })
      errors.add(:fields, "element #{idx}: render_config must be a hash")   if field.key?("render_config") && !field["render_config"].nil? && !field["render_config"].is_a?(Hash)
    end
  end
end
