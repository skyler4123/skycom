class Seed::EmployeeService
  def self.create(
    company:,
    branch: nil,
    user: nil,
    name: Faker::Name.name,
    description: "#{Faker::Job.title} in #{Faker::Commerce.department}",
    business_type: Employee.business_types.keys.sample,
    discarded_at: nil
  )
    employee = Employee.create!(
      user: user,
      company: company,
      branch: branch,
      name: name,
      description: description,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
