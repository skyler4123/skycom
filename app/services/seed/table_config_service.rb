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
      columns_metadata: columns_metadata
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
    record = new(
      company: company,
      resource_name: resource_name,
      category: category,
      property_mapping: property_mapping,
      columns_metadata: columns_metadata,
      name: name
    )
    record.save!
    record
  end
end
