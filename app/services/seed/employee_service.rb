class Seed::EmployeeService
  def self.create(
    company:,
    branch: nil,
    departments: [],
    roles: [],
    user: nil,
    email: "employee_#{SecureRandom.hex}@gmail.com",
    name: Faker::Name.name,
    description: "#{Faker::Job.title} in #{Faker::Commerce.department}",
    business_type: Employee.business_types.keys.sample,
    discarded_at: nil
  )
    employee = Employee.create!(
      user: user,
      company: company,
      branch: branch,
      departments: departments,
      roles: roles,
      email: email,
      name: name,
      description: description,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
