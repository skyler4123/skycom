# spec/factories/customers.rb
FactoryBot.define do
  factory :customer do
    association :company

    initialize_with do
      Seed::CustomerService.create(company: company)
    end

    skip_create
  end
end
