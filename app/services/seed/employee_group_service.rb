class Seed::EmployeeGroupService
  def self.create(
    company_group:,
    branch: nil,
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    employee_group = EmployeeGroup.create!(
      company_group: company_group,
      branch: branch,
      name: name,
      description: description
    )
  end
end
