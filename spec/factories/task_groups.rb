FactoryBot.define do
  factory :task_group do
    company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:23:42" }
  end
end
