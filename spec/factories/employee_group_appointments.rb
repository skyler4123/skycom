# spec/factories/employee_group_appointments.rb
FactoryBot.define do
  factory :employee_group_appointment do
    association :company
    association :employee_group
    association :appoint_to, factory: :employee

    name { "#{employee_group.name} Appointment" }
    description { "Employee group appointment for #{employee_group.name}." }
    code { "EGR-APT-#{SecureRandom.hex(4).upcase}" }
    discarded_at { nil }

    initialize_with do
      Seed::EmployeeGroupAppointmentService.new(
        employee_group: employee_group,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        discarded_at: discarded_at
      )
    end

  end
end
