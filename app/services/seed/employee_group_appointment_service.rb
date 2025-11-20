class Seed::EmployeeGroupAppointmentService

  def self.run
    Company.all.each_with_index do |company, index|
      employee_groups = company.employee_groups
      employees = company.employees
      employees.each do |employee|
        employee.employee_groups << employee_groups.sample
      end
    end
  end
end
