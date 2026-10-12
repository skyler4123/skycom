# spec/factories/promo_grants.rb
FactoryBot.define do
  factory :promo_grant do
    association :promo_campaign
    association :company
    granted_amount { 300 }
    promo_before { 600 }
    promo_after { 900 }
  end
end
