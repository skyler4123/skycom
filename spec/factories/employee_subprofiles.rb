# spec/factories/employee_subprofiles.rb
FactoryBot.define do
  factory :employee_subprofile do
    association :company
    association :employee
    association :employee_profile
    association :category
    name { "Subprofile #{SecureRandom.hex(4)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "ES-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { EmployeeSubprofile.lifecycle_statuses.keys.sample }
    workflow_status { EmployeeSubprofile.workflow_statuses.keys.sample }
    business_type { EmployeeSubprofile.business_types.keys.sample }
    discarded_at { nil }
  end
end
