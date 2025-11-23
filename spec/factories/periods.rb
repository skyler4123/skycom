FactoryBot.define do
  factory :period do
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    duration { 1 }
    start_at { "2025-11-23 08:23:56" }
    end_at { "2025-11-23 08:23:56" }
    expire_at { "2025-11-23 08:23:56" }
    discarded_at { "2025-11-23 08:23:56" }
  end
end
