# spec/factories/products.rb
FactoryBot.define do
  factory :product do
    association :company

    initialize_with do
      Seed::ProductService.create(company: company)
    end

    skip_create
  end
end
