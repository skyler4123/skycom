FactoryBot.define do
  factory :invoice do
    order { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    currency { 1 }
    duration { 1 }
    number { "MyString" }
    total { "MyString" }
    due_date { "2025-11-23 08:23:17" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:23:17" }
  end
end
