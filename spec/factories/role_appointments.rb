# spec/factories/role_appointments.rb
FactoryBot.define do
  factory :role_appointment do
    association :role
    association :appoint_to, factory: :employee

    name { "#{role.name} Appointment" }
    description { "Role appointment for #{role.name}." }
    code { "ROLE-APT-#{SecureRandom.hex(4).upcase}" }
    discarded_at { nil }
  end
end
