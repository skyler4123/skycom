# frozen_string_literal: true

FactoryBot.define do
  factory :wallet_transaction do
    company
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
