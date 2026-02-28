class Seed::CategoryService
  def self.create(
    company:,
    name: Faker::Commerce.department
  )
    Category.first_or_create!(
      company: company,
      name: name
    )
  end
end
