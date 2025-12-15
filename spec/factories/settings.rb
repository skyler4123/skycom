FactoryBot.define do
  factory :setting do
    setting_group { nil }
    company_group { nil }
    company { nil }
    content { "" }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-12-01 22:30:46" }
  end
end
