class Seed::EmployeeGroupService
  def self.create(
    company:,
    branch: nil,
    email: "employee_group_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    employee_group = EmployeeGroup.create!(
      company: company,
      branch: branch,
      email: email,
      name: name,
      description: description
    )
  end
end
