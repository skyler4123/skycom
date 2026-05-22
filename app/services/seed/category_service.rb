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

    if properties.present?
      PropertyMapping.create!(
        company: company,
        category: category,
        resource_name: resource_name,
        name: "#{name} mappings",
        **properties
      )
    end

    category
  end
end
