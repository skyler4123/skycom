class Seed::EmployeeGroupService
  def self.create(
    company:,
    branch: nil,
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    employee_group = EmployeeGroup.create!(
      company: company,
      branch: branch,
      name: name,
      description: description
    )
  end
end
