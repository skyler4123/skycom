# spec/factories/customer_group_role_appointments.rb
FactoryBot.define do
  factory :customer_group_role_appointment do
    company
    role { association :role, company: company }
    customer_group { Seed::CustomerGroupService.create(company: company) }

    name { "#{role.name} Appointment" }
    description { "Role appointment for #{role.name}." }
    code { "ROLE-APT-#{SecureRandom.hex(4).upcase}" }
    discarded_at { nil }
  end
end
