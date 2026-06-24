# frozen_string_literal: true

FactoryBot.define do
  factory :contract_feature do
    billing_resource
    billing_contract
    name { "Test Feature" }
    monthly_flat_price_cents { 0 }
    lifecycle_status { :active }
  end
end
