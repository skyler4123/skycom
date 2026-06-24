# frozen_string_literal: true

FactoryBot.define do
  factory :daily_usage_log do
    company
    billing_resource
    usage_count { 0 }
    log_date { Date.current }
  end
end
