FactoryBot.define do
  factory :subscription do
    subscription_group { nil }
    company_group { nil }
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-30 20:36:56" }
  end
end
