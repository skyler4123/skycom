# spec/factories/employee_appointments.rb
FactoryBot.define do
  factory :employee_appointment do
    association :company
    association :employee
    association :appoint_to, factory: :employee

    name { "#{employee.name} Appointment" }
    description { "Employee appointment for #{employee.name}." }
    code { "EMP-APT-#{SecureRandom.hex(4).upcase}" }
    discarded_at { nil }

    initialize_with do
      Seed::EmployeeAppointmentService.new(
        company: company,
        employee: employee,
        appoint_to: appoint_to,
        name: name,
        description: description,
        code: code,
        discarded_at: discarded_at
      )
    end
  end
end
