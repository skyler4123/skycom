class Seed::TableConfigService
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
