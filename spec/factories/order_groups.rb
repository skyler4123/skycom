FactoryBot.define do
  factory :order_group do
    company { nil }
    customer { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    currency { 1 }
    duration { 1 }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:22:13" }
  end
end
