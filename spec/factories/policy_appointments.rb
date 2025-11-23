FactoryBot.define do
  factory :policy_appointment do
    policy { nil }
    appoint_to { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:20:37" }
  end
end
