# spec/factories/products.rb
FactoryBot.define do
  factory :product do
    association :company

    initialize_with do
      Seed::ProductService.new(company: company)
    end
  end
end
