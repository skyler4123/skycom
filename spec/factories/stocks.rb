# spec/factories/stocks.rb
FactoryBot.define do
  factory :stock do
    association :warehouse
    association :product

    initialize_with do
      Seed::StockService.new(
        warehouse: warehouse,
        product: product,
        company: warehouse.company,
        branch: warehouse.branch
      )
    end
  end
end