FactoryBot.define do
  factory :service do
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    duration { 1 }
    start_at { "2025-11-23 08:22:08" }
    business_type { 1 }
    discarded_at { "2025-11-23 08:22:08" }
  end
end
