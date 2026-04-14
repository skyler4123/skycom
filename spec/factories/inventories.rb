# spec/factories/inventories.rb
FactoryBot.define do
  factory :inventory do
    association :company

    initialize_with do
      Seed::InventoryService.create(company: company)
    end

    skip_create
  end
end
