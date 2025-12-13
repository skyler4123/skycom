FactoryBot.define do
  factory :event_group do
    company_group { nil }
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-30 20:35:43" }
  end
end
