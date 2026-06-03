class Seed::DepartmentService
  def self.new(
    company:,
    category: nil,
    property_mapping: nil,
    email: "department_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    Department.new(
      company: company,
      category: category,
      property_mapping: property_mapping,
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
    if department.property_mapping.nil? && department.category.present?
      department.property_mapping = department.category.property_mapping
    end
    Seed::PropertyPopulator.populate(department)
    department.save!
    department
  end
end
