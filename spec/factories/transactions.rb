# spec/factories/transactions.rb
FactoryBot.define do
  factory :transaction do
    association :company
    association :branch
    association :invoice
    amount_cents { 1000 }

    currency { :usd }
    workflow_status { :completed }
    business_type { :standard_payment }
  end
end
