class Seed::EmployeeGroupService
  def self.new(
    company:,
    branch: nil,
    category: nil,
    email: "employee_group_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    EmployeeGroup.new(
      company: company,
      branch: branch,
      category: category,
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
    employee_group.save!
    employee_group
  end
end
