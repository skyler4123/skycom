class Seed::CategoryService
  def self.new(
    company:,
    name: Faker::Commerce.department,
    resource_name: nil
  )
    Category.new(
      company: company,
      name: name,
      resource_name: resource_name
    )
  end

  def self.create(...)
    category = new(...)
    category.save!
    category
  end
end
