# spec/factories/customer_subprofiles.rb
FactoryBot.define do
  factory :customer_subprofile do
    association :company
    association :customer
    association :customer_profile
    association :category
    name { "Subprofile #{SecureRandom.hex(4)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "CS-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { CustomerSubprofile.lifecycle_statuses.keys.sample }
    workflow_status { CustomerSubprofile.workflow_statuses.keys.sample }
    business_type { CustomerSubprofile.business_types.keys.sample }
    discarded_at { nil }
  end
end
