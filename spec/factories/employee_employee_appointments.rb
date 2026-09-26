# spec/factories/employee_employee_appointments.rb
FactoryBot.define do
  factory :employee_employee_appointment do
    association :company
    association :employee
    association :related_employee, factory: :employee

    initialize_with do
      Seed::EmployeeEmployeeAppointmentService.new(company: company, employee: employee, related_employee: related_employee)
    end
  end
end
