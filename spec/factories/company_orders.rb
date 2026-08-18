# frozen_string_literal: true

FactoryBot.define do
  factory :company_order do
    company { create(:company, country: :us) }
    user { company.user }
    money_amount_cents { 500 }
    credit_amount { 500_000 }
    currency { :usd }
    workflow_status { :pending }
  end
end
