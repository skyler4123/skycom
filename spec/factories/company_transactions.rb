# frozen_string_literal: true

FactoryBot.define do
  factory :company_transaction do
    company_invoice { create(:company_invoice) }
    company { company_invoice.company }
    company_payment_method { create(:company_payment_method, :mock_qr) }
    transaction_type { :payment }
    money_amount_cents { company_invoice.money_amount_cents }
    currency { :usd }
    status { :completed }
    gateway_reference { "TXN-#{SecureRandom.hex(6).upcase}" }
  end
end
