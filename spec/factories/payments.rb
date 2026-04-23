# spec/factories/payments.rb
FactoryBot.define do
  factory :payment do
    association :invoice
    association :company, factory: :company

    name { "Payment #{Faker::Lorem.sentence(word_count: 3)}" }
    description { Faker::Lorem.sentence(word_count: 10) }
    currency_code { Payment.currency_codes.keys.sample }
    exchange_rate { 1.0 }
    amount { Faker::Commerce.price }
    payment_method { Payment.payment_methods.keys.sample }
    status { Payment.statuses.keys.sample }
    business_type { Payment.business_types.keys.sample }
    discarded_at { nil }

    initialize_with do
      Seed::PaymentService.new(
        invoice: invoice,
        name: name,
        description: description,
        currency_code: currency_code,
        exchange_rate: exchange_rate,
        amount: amount,
        payment_method: payment_method,
        status: status,
        business_type: business_type,
        discarded_at: discarded_at
      )
    end

  end
end
