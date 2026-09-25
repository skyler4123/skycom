# spec/factories/employee_group_role_appointments.rb
FactoryBot.define do
  factory :employee_group_role_appointment do
    company
    role { association :role, company: company }
    employee_group { association :employee_group, company: company }

    name { "#{role.name} Appointment" }
    description { "Role appointment for #{role.name}." }
    code { "ROLE-APT-#{SecureRandom.hex(4).upcase}" }
    discarded_at { nil }
  end
end
