# frozen_string_literal: true

FactoryBot.define do
  factory :daily_active_log do
    company
    log_date { Date.current }
  end
end
