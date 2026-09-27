# spec/factories/policy_role_appointments.rb
FactoryBot.define do
  factory :policy_role_appointment do
    company
    policy { association :policy, company: company }
    role { association :role, company: company }
  end
end
