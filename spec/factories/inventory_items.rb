# spec/factories/inventory_items.rb
FactoryBot.define do
  factory :inventory_item do
    association :inventory

    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "INV-#{SecureRandom.hex(4).upcase}" }
    sku { Faker::Number.between(from: 100000, to: 999999).to_s }
    barcode { Faker::Number.between(from: 1000000000000, to: 9999999999999).to_s }
    status { InventoryItem.statuses.keys.sample }
    business_type { InventoryItem.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::InventoryItemService.create(
        inventory: inventory,
        name: name,
        description: description,
        code: code,
        sku: sku,
        barcode: barcode,
        status: status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

    skip_create
  end
end
