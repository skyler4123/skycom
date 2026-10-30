class Seed::EmployeeGroupService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    manager: nil,
    email: "employee_group_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    EmployeeGroup.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      manager: manager,
      email: email,
      name: name,
      description: description
    )
  end

  # Deterministic team lookup used by seeding. Re-running repairs the branch and
  # manager on an existing group instead of creating duplicates.
  def self.find_or_create!(company:, name:, branch: nil, manager: nil)
    employee_group = EmployeeGroup.find_or_initialize_by(company: company, name: name)
    employee_group.branch = branch
    employee_group.manager = manager
    if employee_group.category.nil? && company.present?
      employee_group.category = Seed::CategoryService.find_or_create_for(
        company: company,
        resource_name: EmployeeGroup.model_name.plural
      )
    end
    employee_group.property_mapping ||= employee_group.category&.default_property_mapping
    employee_group.save!
    employee_group
  end

  def self.create(...)
    employee_group = new(...)
    if employee_group.category.nil? && employee_group.company.present?
      employee_group.category = Seed::CategoryService.find_or_create_for(
        company: employee_group.company,
        resource_name: EmployeeGroup.model_name.plural
      )
    end
    if employee_group.property_mapping.nil? && employee_group.category.present?
      employee_group.property_mapping = employee_group.category.default_property_mapping
    end
    Seed::PropertyPopulator.populate(employee_group)
    employee_group.save!
    employee_group
  end
end
