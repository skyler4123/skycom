class Seed::DepartmentService
  def self.new(
    company:,
    category: nil,
    email: "department_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    Department.new(
      company: company,
      category: category,
      email: email,
      name: name,
      description: description
    )
  end

  def self.create(...)
    department = new(...)
    if department.category.nil? && department.company.present?
      department.category = Seed::CategoryService.find_or_create_for(
        company: department.company,
        resource_name: Department.model_name.plural
      )
    end
    department.save!
    department
  end
end
