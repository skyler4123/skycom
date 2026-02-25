class Seed::RoleAppointmentService
  def self.run
    Company.all.each_with_index do |company, index|
      roles = branch.roles
      employee_groups = branch.employee_groups
      employees = branch.employees
      employees.each do |employee|
        employee.roles << roles.sample
      end
      employee_groups.each do |employee_group|
        employee_group.roles << roles.sample
      end
    end
  end
end
