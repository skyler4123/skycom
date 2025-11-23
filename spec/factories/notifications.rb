FactoryBot.define do
  factory :notification do
    notification_group { nil }
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:24:03" }
  end
end
