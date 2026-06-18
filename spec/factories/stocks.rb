# spec/factories/stocks.rb
FactoryBot.define do
  factory :stock do
    association :warehouse
    association :product

    initialize_with do
      Seed::StockService.new(
        warehouse: warehouse,
        product_id: product.id,
        company: warehouse.company,
        branch: warehouse.branch
      )
    end
  end
end
