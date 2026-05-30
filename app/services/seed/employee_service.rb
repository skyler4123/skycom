class Seed::EmployeeService
  def self.new(
    company:,
    branch: nil,
    departments: [],
    roles: [],
    category: nil,
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
    # Exclude "owner" from random selection - owner is created via Company#setup_owner_records
    business_type ||= (Employee.business_types.keys - [ "owner" ]).sample
    email ||= "employee_#{SecureRandom.hex}@gmail.com"
    name ||= Faker::Name.name
    description ||= "#{Faker::Job.title} in #{Faker::Commerce.department}"

    Employee.new(
      user: user,
      company: company,
      branch: branch,
      category: category,
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
    if employee.category.nil? && employee.company.present?
      employee.category = Seed::CategoryService.find_or_create_for(
        company: employee.company,
        resource_name: Employee.model_name.plural
      )
    end
    employee.save!
    employee
  end
end
