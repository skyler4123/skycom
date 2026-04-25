class Seed::EmployeeService
  def self.new(
    company:,
    branch: nil,
    departments: [],
    roles: [],
    user: nil,
    email: nil,
    name: nil,
    description: nil,
    workflow_status: nil,
    lifecycle_status: nil,
    business_type: nil,
    discarded_at: nil
  )
    workflow_status ||= Employee.workflow_statuses.keys.sample
    lifecycle_status ||= Employee.lifecycle_statuses.keys.sample
    business_type ||= Employee.business_types.keys.sample
    email ||= "employee_#{SecureRandom.hex}@gmail.com"
    name ||= Faker::Name.name
    description ||= "#{Faker::Job.title} in #{Faker::Commerce.department}"

    Employee.new(
      user: user,
      company: company,
      branch: branch,
      departments: departments,
      roles: roles,
      email: email,
      name: name,
      description: description,
      workflow_status: workflow_status,
      lifecycle_status: lifecycle_status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    employee = new(...)
    employee.save!
    employee
  end
end
