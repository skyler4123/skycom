# spec/factories/payments.rb
FactoryBot.define do
  factory :payment do
    association :invoice

    initialize_with do
      Seed::PaymentService.new(invoice: invoice)
    end
  end
end
