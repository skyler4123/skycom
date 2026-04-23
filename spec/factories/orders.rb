# spec/factories/orders.rb
FactoryBot.define do
  factory :order do
    association :company

    initialize_with do
      Seed::OrderService.new(company: company)
    end
  end
end
