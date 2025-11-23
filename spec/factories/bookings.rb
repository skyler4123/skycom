FactoryBot.define do
  factory :booking do
    company { nil }
    appoint_from { nil }
    appoint_to { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:23:55" }
  end
end
