# frozen_string_literal: true

FactoryBot.define do
  factory :shift_close do
    association :company
    branch { association :branch, company: company }
    closed_by { association :employee, company: company, branch: branch }
    business_date { Date.current }
    closed_by_name { closed_by.name }
    counted_cash_cents { 0 }
    opening_float_cents { 0 }
    expected_cash_cents { 0 }
    variance_cents { 0 }
    closed_at { Time.current }
  end
end
