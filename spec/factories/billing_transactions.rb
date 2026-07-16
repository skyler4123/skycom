# frozen_string_literal: true

FactoryBot.define do
  factory :billing_transaction do
    company
    association :billing_invoice
    billing_payment_method {
      BillingPaymentMethod.find_or_create_by!(code: "WALLET_AUTO_DEBIT") do |bpm|
        bpm.name = "Wallet Auto-Debit"
        bpm.business_type = :b2b
        bpm.payment_mode = :cash
        bpm.workflow_status = :confirmed
      end
    }
    transaction_type { :top_up }
    amount_cents { 1000 }
    currency { :usd }
    balance_before_cents { 0 }
    balance_after_cents { 1000 }
    promo_balance_before_cents { 0 }
    promo_balance_after_cents { 0 }
    description { "Test transaction" }
  end
end
