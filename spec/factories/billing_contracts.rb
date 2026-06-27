# frozen_string_literal: true

FactoryBot.define do
  factory :billing_contract do
    company
    name { "Test Contract" }
    contract_type { :basic }
    lifecycle_status { :active }
    start_date { Time.current }
    fixed_monthly_price_cents { 0 }
    fixed_monthly_price_currency { "USD" }
  end
end
