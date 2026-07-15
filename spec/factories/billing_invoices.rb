# frozen_string_literal: true

FactoryBot.define do
  factory :billing_invoice do
    company
    billing_contract
    invoice_number { "INV-#{Time.current.strftime('%Y%m')}-#{SecureRandom.hex(3).upcase}" }
    price_cents { 0 }
    currency { :usd }
    period_start { 1.month.ago.beginning_of_month }
    period_end { 1.month.ago.end_of_month }
    payment_status { :unpaid }
    lifecycle_status { :final }
  end
end
