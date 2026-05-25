# spec/factories/employee_group_appointments.rb
FactoryBot.define do
  factory :employee_group_appointment do
    association :company
    association :employee_group
    association :appoint_to, factory: :employee

    initialize_with do
      Seed::EmployeeGroupAppointmentService.new(company: company, employee_group: employee_group, appoint_to: appoint_to)
    end
  end
end
