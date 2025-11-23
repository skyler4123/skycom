FactoryBot.define do
  factory :purchase_item do
    purchase { nil }
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
    expiration_date { "2025-11-23 08:22:32" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:22:32" }
  end
end
