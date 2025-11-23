FactoryBot.define do
  factory :employee do
    user { nil }
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:20:51" }
  end
end
