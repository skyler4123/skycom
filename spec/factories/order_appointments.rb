FactoryBot.define do
  factory :order_appointment do
    order { nil }
    appoint_from { nil }
    appoint_to { nil }
    appoint_for { nil }
    appoint_by { nil }
    unit_price { "9.99" }
    quantity { 1 }
    total_price { "9.99" }
    name { "MyString" }
    description { "MyString" }
    code { "MyString" }
    status { 1 }
    business_type { 1 }
    discarded_at { "2025-11-23 08:22:16" }
  end
end
