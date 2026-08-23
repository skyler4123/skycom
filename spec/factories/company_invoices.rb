# frozen_string_literal: true

FactoryBot.define do
  factory :company_invoice do
    company { create(:company, country: :us) }
    company_order { create(:company_order, company: company) }
    invoice_number { "INV-TEST-#{SecureRandom.hex(3).upcase}" }
    money_amount_cents { 500 }
    credit_amount { 500_000 }
    currency { :usd }
    payment_status { :unpaid }
  end
end
