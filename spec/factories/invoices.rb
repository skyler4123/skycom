# spec/factories/invoices.rb
FactoryBot.define do
  factory :invoice do
    association :order

    initialize_with do
      Seed::InvoiceService.new(order: order)
    end
  end
end
