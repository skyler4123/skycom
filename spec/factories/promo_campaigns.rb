# spec/factories/promo_campaigns.rb
FactoryBot.define do
  factory :promo_campaign do
    name { "Promo #{SecureRandom.hex(4)}" }
    description { "Test promo campaign" }
    amount { 300 }
    max_cap { 1000 }
    conditions { {} }
    scheduled_at { Time.current }
    status { :scheduled }
  end
end
