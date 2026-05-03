# spec/factories/role_appointments.rb
FactoryBot.define do
  factory :role_appointment do
    association :role
    association :appoint_to, factory: :employee

    name { "#{role.name} Appointment" }
    description { "Role appointment for #{role.name}." }
    code { "ROLE-APT-#{SecureRandom.hex(4).upcase}" }
    business_type { RoleAppointment.business_types.keys.sample }
    discarded_at { nil }
  end
end
