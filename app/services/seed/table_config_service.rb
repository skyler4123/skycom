class Seed::TableConfigService
  def self.new(
    company:,
    resource_name:,
    category:,
    property_mapping: nil,
    fields: [],
    name: nil
  )
    TableConfig.new(
      company: company,
      resource_name: resource_name,
      category: category,
      property_mapping: property_mapping,
      name: name || "#{category&.name || resource_name} table config",
      fields: fields
    )
  end

  def self.create(
    company:,
    resource_name:,
    category:,
    property_mapping: nil,
    fields: [],
    name: nil
  )
    record = new(
      company: company,
      resource_name: resource_name,
      category: category,
      property_mapping: property_mapping,
      fields: fields,
      name: name
    )
    record.save!
    record
  end
end
