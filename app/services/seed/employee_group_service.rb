class Seed::EmployeeGroupService
  def self.run
    Company.all.each_with_index do |company, index|
      employee_group = company.employee_groups.create(
        name: "EmployeeGroup #{index}",
        description: Faker::Movie.quote
      )

      # 1. Create the single Tag object and assign it to a variable
      new_tag = Tag.create(
        company: company,
        name: "EMployee Group Tag #{employee_group.id}"
      )

      # 2. Add the single Tag object to the employee_group's tags collection
      employee_group.tags << new_tag

      # 3. Now you can safely call methods on the single new_tag object
      new_tag.tag_appointments.where(appoint_to: employee_group).update(
        value: "Value #{index}"
      )
    end
  end
end
