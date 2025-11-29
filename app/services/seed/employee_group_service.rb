class Seed::EmployeeGroupService
  def self.create(
    company_group:,
    company: nil,
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    employee_group = EmployeeGroup.create!(
      company_group: company_group,
      company: company,
      name: name,
      description: description
    )
  end
end
