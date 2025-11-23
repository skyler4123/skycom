FactoryBot.define do
  factory :payment do
    invoice { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    currency { 1 }
    duration { 1 }
    exchange_rate { "9.99" }
    amount { "9.99" }
    payment_method { "MyString" }
    gateway_details { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:23:18" }
  end
end
