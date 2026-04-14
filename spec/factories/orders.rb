# spec/factories/orders.rb
FactoryBot.define do
  factory :order do
    association :company

    initialize_with do
      Seed::OrderService.create(company: company)
    end

    skip_create
  end
end
