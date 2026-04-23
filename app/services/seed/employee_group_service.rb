class Seed::EmployeeGroupService
  def self.new(
    company:,
    branch: nil,
    email: "employee_group_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    EmployeeGroup.new(
      company: company,
      branch: branch,
      email: email,
      name: name,
      description: description
    )
  end

  def self.create(...)
    employee_group = new(...)
    employee_group.save!
    employee_group
  end
end
