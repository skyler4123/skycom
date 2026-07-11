# spec/factories/payment_methods.rb
FactoryBot.define do
  factory :payment_method do
    name { Faker::Company.name }
    code { "PM-#{SecureRandom.hex(4).upcase}" }
    business_type { PaymentMethod.business_types.keys.sample }

    initialize_with do
      Seed::PaymentMethodService.new(name: name, code: code, business_type: business_type)
    end
  end
end
