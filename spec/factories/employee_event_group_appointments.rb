# spec/factories/employee_event_group_appointments.rb
FactoryBot.define do
  factory :employee_event_group_appointment do
    association :company
    association :employee
    association :event_group

    initialize_with do
      Seed::EmployeeEventGroupAppointmentService.new(company: company, employee: employee, event_group: event_group)
    end
  end
end
