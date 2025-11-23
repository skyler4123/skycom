FactoryBot.define do
  factory :service_group_appointment do
    service_group { nil }
    appoint_from { nil }
    appoint_to { nil }
    appoint_for { nil }
    appoint_by { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    duration { 1 }
    start_at { "2025-11-23 08:22:08" }
    business_type { 1 }
    discarded_at { "2025-11-23 08:22:08" }
  end
end
