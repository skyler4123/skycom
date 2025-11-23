FactoryBot.define do
  factory :policy do
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    resource { "MyString" }
    action { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:20:37" }
  end
end
