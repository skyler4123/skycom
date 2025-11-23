FactoryBot.define do
  factory :task do
    company { nil }
    task_group { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    currency { 1 }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:23:43" }
  end
end
