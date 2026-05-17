class Seed::CategoryService
  def self.new(
    company:,
    name: Faker::Commerce.department,
    resource_name: nil,
    properties: {}
  )
    category = Category.new(
      company: company,
      name: name,
      resource_name: resource_name
    )
    properties.each { |key, value| category[key] = value }
    category
  end

  def self.create(...)
    category = new(...)
    category.save!
    category
  end
end
