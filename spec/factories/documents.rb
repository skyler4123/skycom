FactoryBot.define do
  factory :document do
    document_group { nil }
    company_group { nil }
    company { nil }
    title { "MyString" }
    content { "" }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-12-10 17:23:48" }
  end
end
