# spec/factories/employee_event_appointments.rb
FactoryBot.define do
  factory :employee_event_appointment do
    association :company
    association :employee
    association :event

    initialize_with do
      Seed::EmployeeEventAppointmentService.new(company: company, employee: employee, event: event)
    end
  end
end
