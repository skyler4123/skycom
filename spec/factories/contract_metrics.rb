# frozen_string_literal: true

FactoryBot.define do
  factory :contract_metric do
    billing_resource
    billing_contract
    name { "Test Metric" }
    free_allowance { 100 }
    unit_price_cents { 10 }
    lifecycle_status { :active }
  end
end
