class Seed::EmployeeGroupService
  def self.run
    Company.all.each do |company|
      5.times do |n|
        employee_group = EmployeeGroup.create!(
          name: "Employee Group #{n}",
          company: company
        )
      end
    end
  end
end
