class Seed::DepartmentService
  def self.new(
    company:,
    email: "department_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    Department.new(
      company: company,
      email: email,
      name: name,
      description: description
    )
  end

  def self.create(...)
    department = new(...)
    department.save!
    department
  end
end
