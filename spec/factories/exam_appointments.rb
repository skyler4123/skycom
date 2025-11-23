FactoryBot.define do
  factory :exam_appointment do
    exam { nil }
    appoint_from { nil }
    appoint_to { nil }
    appoint_for { nil }
    appoint_by { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:24:12" }
  end
end
