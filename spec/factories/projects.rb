FactoryBot.define do
  factory :project do
    company { nil }
    project_group { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:23:39" }
  end
end
