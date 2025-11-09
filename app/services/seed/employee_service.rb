class Seed::EmployeeService
  def self.run
    Company.all.each do |company|
      10.times do |n|
        employee = Employee.create!(
          name: "Employee #{n}",
          company: company
        )
      end
    end
  end
end
