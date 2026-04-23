# spec/factories/inventories.rb
FactoryBot.define do
  factory :inventory do
    association :company

    initialize_with do
      Seed::InventoryService.new(company: company)
    end

  end
end
