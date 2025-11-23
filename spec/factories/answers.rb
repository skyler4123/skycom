FactoryBot.define do
  factory :answer do
    question { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:24:11" }
  end
end
