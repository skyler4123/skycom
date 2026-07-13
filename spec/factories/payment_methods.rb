# spec/factories/payment_methods.rb
FactoryBot.define do
  factory :payment_method do
    name { Faker::Company.name }
    code { "PM-#{SecureRandom.hex(4).upcase}" }
    business_type { PaymentMethod.business_types.keys.sample }
    payment_mode { :redirect }
    gateway_url { Seed::PaymentMethodService::MOCK_REDIRECT_URL }

    initialize_with do
      Seed::PaymentMethodService.new(
        name: name,
        code: code,
        business_type: business_type,
        payment_mode: payment_mode,
        gateway_url: gateway_url
      )
    end
  end
end
