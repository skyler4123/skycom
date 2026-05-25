# spec/factories/employee_appointments.rb
FactoryBot.define do
  factory :employee_appointment do
    association :company
    association :employee
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::EmployeeAppointmentService.new(company: company, employee: employee, appoint_to: appoint_to)
    end
  end
end
