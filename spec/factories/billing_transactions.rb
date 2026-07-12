# frozen_string_literal: true

FactoryBot.define do
  factory :billing_transaction do
    company
    association :billing_invoice
    transaction_type { :top_up }
    amount_cents { 1000 }
    currency { "USD" }
    balance_before_cents { 0 }
    balance_after_cents { 1000 }
    promo_balance_before_cents { 0 }
    promo_balance_after_cents { 0 }
    description { "Test transaction" }
  end
end
