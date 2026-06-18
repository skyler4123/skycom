class Seed::EmployeeGroupService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    property_mapping: nil,
    email: "employee_group_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    EmployeeGroup.new(
      company: company,
      branch: branch,
      category: category,
      property_mapping: property_mapping,
      email: email,
      name: name,
      description: description
    )
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
