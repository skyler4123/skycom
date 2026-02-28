class Seed::DepartmentService
  def self.create(
    company:,
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    department = Department.create!(
      company: company,
      name: name,
      description: description
    )
  end
end
