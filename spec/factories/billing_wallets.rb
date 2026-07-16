# frozen_string_literal: true

FactoryBot.define do
  factory :billing_wallet do
    company
    name { "#{company.name} Wallet" }
    currency { :usd }
    promo_balance_cents { 0 }
    main_balance_cents { 0 }
    soft_debt_threshold_cents { -10000 }
    hide_billing_alerts { false }
    lifecycle_status { :active }
  end
end
