FactoryBot.define do
  factory :setting_group do
    company_group { nil }
    company { nil }
    content { "" }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-12-01 22:30:45" }
  end
end
