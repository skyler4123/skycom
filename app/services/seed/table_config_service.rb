class Seed::TableConfigService
  # Builds one columns_metadata entry with every applicable search/filter option turned ON
  # (owner disables per column in the TableConfig editor — docs/DYNAMIC_TABLE.md §2.5).
  # String-capable columns get `search: true`; integer/decimal get half-open range buckets,
  # boolean gets true/false options, datetime gets year buckets around the current year.
  # `active: true` is required in every filter hash (TableConfig validation).
  def self.field_hash(key, name = nil)
    col = { "key" => key.to_s, "name" => name.presence || key.to_s.humanize,
            "visible" => true, "align" => "left", "width" => nil }

    case key.to_s
    when "name", "description", "code", /\Aproperty_string_/
      col["search"] = true
    when /\Aproperty_integer_/
      col["filter"] = { "type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, nil ] ] }
    when /\Aproperty_decimal_/
      col["filter"] = { "type" => "range", "active" => true, "buckets" => [ [ nil, 10.0 ], [ 10.0, nil ] ] }
    when /\Aproperty_boolean_/
      col["filter"] = { "type" => "boolean", "active" => true }
    when /\Aproperty_datetime_/
      year = Time.current.year
      col["filter"] = { "type" => "date", "active" => true,
        "buckets" => [ [ nil, year - 1 ], [ year - 1, year ], [ year, nil ] ] }
    end

    col
  end

  def self.new(
    company:,
    resource_name:,
    category:,
    property_mapping: nil,
    columns_metadata: [],
    name: nil
  )
    TableConfig.new(
      company: company,
      resource_name: resource_name,
      category: category,
      property_mapping: property_mapping,
      name: name || "#{category&.name || resource_name} table config",
      metadata: { "columns" => columns_metadata }
    )
  end

  def self.create(
    company:,
    resource_name:,
    category:,
    property_mapping: nil,
    columns_metadata: [],
    name: nil
  )
    pm = property_mapping || category.default_property_mapping
    name ||= "#{category&.name || resource_name} table config"

    existing = pm.table_configs.first
    if existing
      existing.update!(metadata: { "columns" => columns_metadata }, name: name)
      existing
    else
      record = new(
        company: company,
        resource_name: resource_name,
        category: category,
        property_mapping: pm,
        columns_metadata: columns_metadata,
        name: name
      )
      record.save!
      record
    end
  end
end
