# spec/factories/customers.rb
FactoryBot.define do
  factory :customer do
    association :company

    initialize_with do
      Seed::CustomerService.new(company: company)
    end
  end
end
