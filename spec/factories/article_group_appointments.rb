FactoryBot.define do
  factory :article_group_appointment do
    article_group { nil }
    appoint_from { nil }
    appoint_to { nil }
    appoint_for { nil }
    appoint_by { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-12-10 17:31:13" }
  end
end
