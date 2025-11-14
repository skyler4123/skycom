class Seed::EmployeeGroupService
  def self.run
    Company.all.each_with_index do |company, index|
      company.employee_groups.create(
        name: "EmployeeGroup #{index}",
        description: Faker::Movie.quote
      )
    end
  end
end
