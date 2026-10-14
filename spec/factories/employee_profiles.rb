# spec/factories/employee_profiles.rb
FactoryBot.define do
  factory :employee_profile do
    association :company
    association :employee
    association :category
    name { "Profile #{SecureRandom.hex(4)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "EP-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { EmployeeProfile.lifecycle_statuses.keys.sample }
    workflow_status { EmployeeProfile.workflow_statuses.keys.sample }
    business_type { EmployeeProfile.business_types.keys.sample }
    discarded_at { nil }
  end
end
