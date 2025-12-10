FactoryBot.define do
  factory :article do
    article_group { nil }
    company_group { nil }
    company { nil }
    title { "MyString" }
    content { "" }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-12-10 17:31:12" }
  end
end
