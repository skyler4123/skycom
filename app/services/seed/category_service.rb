class Seed::CategoryService
  def self.new(
    company:,
    name: Faker::Commerce.department,
    resource_name: nil,
    properties: {}
  )
    Category.new(
      company: company,
      name: name,
      resource_name: resource_name
    )
  end

  def self.create(
    company:,
    name: Faker::Commerce.department,
    resource_name: nil,
    properties: {}
  )
    category = new(
      company: company,
      name: name,
      resource_name: resource_name,
      properties: properties
    )
    category.save!

    category.property_mapping.update!(**properties) if properties.present?

    category
  end
end
