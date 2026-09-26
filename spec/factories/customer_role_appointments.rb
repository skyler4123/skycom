# spec/factories/customer_role_appointments.rb
FactoryBot.define do
  factory :customer_role_appointment do
    company
    role { association :role, company: company }
    customer { association :customer, company: company }

    name { "#{role.name} Appointment" }
    description { "Role appointment for #{role.name}." }
    code { "ROLE-APT-#{SecureRandom.hex(4).upcase}" }
    discarded_at { nil }
  end
end
