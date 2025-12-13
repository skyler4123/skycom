FactoryBot.define do
  factory :document_group_appointment do
    document_group { nil }
    appoint_from { nil }
    appoint_to { nil }
    appoint_for { nil }
    appoint_by { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-12-10 17:23:49" }
  end
end
