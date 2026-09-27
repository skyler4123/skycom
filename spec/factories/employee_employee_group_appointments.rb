# spec/factories/employee_employee_group_appointments.rb
FactoryBot.define do
  factory :employee_employee_group_appointment do
    association :company
    association :employee
    association :employee_group

    initialize_with do
      Seed::EmployeeEmployeeGroupAppointmentService.new(company: company, employee: employee, employee_group: employee_group)
    end
  end
end
