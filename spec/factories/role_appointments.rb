FactoryBot.define do
  factory :role_appointment do
    role { nil }
    appoint_to { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:20:38" }
  end
end
