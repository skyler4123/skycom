class Seed::TableConfigService
  def self.new(
    company:,
    resource_name:,
    category:,
    fields: [],
    name: nil
  )
    TableConfig.new(
      company: company,
      resource_name: resource_name,
      category: category,
      name: name || "#{category&.name || resource_name} table config",
      fields: fields
    )
  end

  def self.create(
    company:,
    resource_name:,
    category:,
    fields: [],
    name: nil
  )
    record = new(
      company: company,
      resource_name: resource_name,
      category: category,
      fields: fields,
      name: name
    )
    record.save!
    record
  end
end
