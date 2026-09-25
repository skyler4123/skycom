# spec/factories/department_role_appointments.rb
FactoryBot.define do
  factory :department_role_appointment do
    company
    role { association :role, company: company }
    department { association :department, company: company }

    name { "#{role.name} Appointment" }
    description { "Role appointment for #{role.name}." }
    code { "ROLE-APT-#{SecureRandom.hex(4).upcase}" }
    discarded_at { nil }
  end
end
