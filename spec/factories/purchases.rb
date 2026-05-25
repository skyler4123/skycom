# spec/factories/purchases.rb
FactoryBot.define do
  factory :purchase do
    association :company

    initialize_with do
      Seed::PurchaseService.new(company: company)
    end
  end
end
