class Seed::DepartmentService
  def self.create(
    company:,
    email: "department_#{SecureRandom.hex}@gmail.com",
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    department = Department.create!(
      company: company,
      email: email,
      name: name,
      description: description
    )
  end
end
