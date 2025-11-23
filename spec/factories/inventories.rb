FactoryBot.define do
  factory :inventory do
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:21:17" }
  end
end
