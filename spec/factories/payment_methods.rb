FactoryBot.define do
  factory :payment_method do
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    currency { 1 }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:23:19" }
  end
end
