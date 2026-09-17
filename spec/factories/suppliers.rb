# spec/factories/suppliers.rb
FactoryBot.define do
  factory :supplier do
    association :company
    association :category
    name { Faker::Company.name }
    description { Faker::Lorem.sentence(word_count: 15) }
    code { "SU-#{SecureRandom.hex(4).upcase}" }
    lifecycle_status { Supplier.lifecycle_statuses.keys.sample }
    workflow_status { Supplier.workflow_statuses.keys.sample }
    business_type { Supplier.business_types.keys.sample }
    discarded_at { nil }

    trait :with_company do
      association :company
    end
  end
end
