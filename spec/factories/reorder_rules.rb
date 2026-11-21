# frozen_string_literal: true

FactoryBot.define do
  factory :reorder_rule do
    association :company
    association :product
    association :warehouse
    min_quantity { 6 }
    safety_stock { 4 }
    max_quantity { 20 }
    lead_time_days { 7 }
    is_active { true }
  end
end
