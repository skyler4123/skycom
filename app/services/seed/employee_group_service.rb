class Seed::EmployeeGroupService

  def self.run
    Company.all.each_with_index do |company, index|
      employee_group = company.employee_groups.create(
        name: "EmployeeGroup #{index}",
        description: Faker::Movie.quote
      )

      employee_group.attach_tag(name: "Employee Group #{employee_group.id} Tag")
    end
  end

  def self.create(
    company: Company.all.sample,
    name: "#{Faker::Job.field} Group",
    description: Faker::Movie.quote
  )
    employee_group = company.employee_groups.create!(
      name: name,
      description: description
    )

    # Attach a tag to the newly created group
    employee_group.attach_tag(name: "Employee Group #{employee_group.id} Tag")

    # Return the created object
    employee_group
  end
end
