FactoryBot.define do
  factory :product do
    company { nil }
    brand { nil }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    sku { "MyString" }
    barcode { "MyString" }
    upc { "MyString" }
    ean { "MyString" }
    manufacturer_code { "MyString" }
    serial_number { "MyString" }
    batch_number { "MyString" }
    expiration_date { "2025-11-23 08:21:35" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:21:35" }
  end
end
