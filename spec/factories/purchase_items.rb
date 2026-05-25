# spec/factories/purchase_items.rb
FactoryBot.define do
  factory :purchase_item do
    association :purchase

    initialize_with do
      Seed::PurchaseItemService.new(purchase: purchase)
    end
  end
end
