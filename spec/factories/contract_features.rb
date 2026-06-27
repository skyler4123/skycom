# frozen_string_literal: true

FactoryBot.define do
  factory :contract_feature do
    association :billing_resource, :addon_feature
    billing_contract
    name { "Test Feature" }
    monthly_flat_price_cents { 0 }
    lifecycle_status { :active }
  end
end
