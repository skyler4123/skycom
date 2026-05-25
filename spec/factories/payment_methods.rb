# spec/factories/payment_methods.rb
FactoryBot.define do
  factory :payment_method do
    name { Faker::Company.name }

    initialize_with do
      Seed::PaymentMethodService.new(name: name)
    end
  end
end
