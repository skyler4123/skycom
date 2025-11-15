class Seed::RoleAppointmentService
  def self.run
    Company.all.each_with_index do |company, index|
      roles = company.roles
      employee_groups = company.employee_groups
      employees = company.employees
      employees.each do |employee|
        employee.roles << roles.sample
      end
      employee_groups.each do |employee_group|
        employee_group.roles << roles.sample
      end
    end
  end
end
