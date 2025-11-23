FactoryBot.define do
  factory :inventory_item do
    inventory { nil }
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
    expiration_date { "2025-11-23 08:21:18" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:21:18" }
  end
end
