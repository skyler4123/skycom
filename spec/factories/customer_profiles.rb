# spec/factories/customer_profiles.rb
FactoryBot.define do
  factory :customer_profile do
    association :company
    association :customer
    association :category
    name { "Profile #{SecureRandom.hex(4)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "CP-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { CustomerProfile.lifecycle_statuses.keys.sample }
    workflow_status { CustomerProfile.workflow_statuses.keys.sample }
    business_type { CustomerProfile.business_types.keys.sample }
    discarded_at { nil }
  end
end
