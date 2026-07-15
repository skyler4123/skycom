# frozen_string_literal: true

FactoryBot.define do
  factory :billing_contract do
    company
    name { "Test Contract" }
    contract_type { :basic }
    lifecycle_status { :draft }
    start_date { Time.current }
    fixed_monthly_price_cents { 0 }
    currency { :usd }
  end
end
