class Seed::TableConfigService
  def self.new(
    company:,
    resource_name:,
    category:,
    visible_fields: [],
    name: nil
  )
    TableConfig.new(
      company: company,
      resource_name: resource_name,
      category: category,
      name: name || "#{category&.name || resource_name} table config",
      visible_fields: visible_fields
    )
  end

  def self.create(
    company:,
    resource_name:,
    category:,
    visible_fields: [],
    name: nil
  )
    record = new(
      company: company,
      resource_name: resource_name,
      category: category,
      visible_fields: visible_fields,
      name: name
    )
    record.save!
    record
  end
end
