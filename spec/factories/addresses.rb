# spec/factories/addresses.rb
FactoryBot.define do
  factory :address do
    line_1 { Faker::Address.street_address }
    line_2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state_or_province { Faker::Address.state }
    postal_code { Faker::Address.postcode }
    country { Address.countries.keys.sample }
  end
end
