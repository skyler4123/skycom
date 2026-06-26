# frozen_string_literal: true

FactoryBot.define do
  factory :daily_feature_log do
    company
    contract_feature
    log_date { Date.current }
  end
end
