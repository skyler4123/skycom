FactoryBot.define do
  factory :payment_method_appointment do
    payment_method { nil }
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:23:20" }
  end
end
