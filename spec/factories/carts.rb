FactoryBot.define do
  factory :cart do
    company { nil }
    cart_group { nil }
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
    expiration_date { "2025-11-23 08:22:27" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:22:27" }
  end
end
