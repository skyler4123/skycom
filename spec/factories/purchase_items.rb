# spec/factories/purchase_items.rb
FactoryBot.define do
  factory :purchase_item do
    association :purchase

    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence(word_count: 10) }
    code { "PURIT-#{SecureRandom.hex(4).upcase}" }
    sku { Faker::Number.between(from: 100000, to: 999999).to_s }
    barcode { Faker::Number.between(from: 1000000000000, to: 9999999999999).to_s }
    status { PurchaseItem.statuses.keys.sample }
    business_type { PurchaseItem.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::PurchaseItemService.create(
        purchase: purchase,
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
