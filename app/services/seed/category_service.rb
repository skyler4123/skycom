class Seed::CategoryService
  def self.create(
    company_group:,
    name:
  )
    Category.first_or_create!(
      company_group: company_group,
      name: name
    )
  end
end
