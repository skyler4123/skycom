FactoryBot.define do
  factory :company do
    company_group { nil }
    parent_company { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    ownership_type { 1 }
    business_type { 1 }
    currency { 1 }
    registration_number { "MyString" }
    vat_id { "MyString" }
    address_line_1 { "MyString" }
    city { "MyString" }
    postal_code { "MyString" }
    country { "MyString" }
    email { "MyString" }
    phone_number { "MyString" }
    website { "MyString" }
    employee_count { 1 }
    fiscal_year_end_month { 1 }
    discarded_at { "2025-11-27 22:13:37" }
  end
end
