# spec/factories/calendar_locations.rb
FactoryBot.define do
  factory :calendar_location do
    company { association :company }

    sequence(:name) { |n| "Room #{Faker::Address.street_name} #{n}" }
    sequence(:code) { |n| "LOC-#{SecureRandom.hex(3).upcase}#{n}" }
    description { Faker::Lorem.sentence }
    capacity { 1 }
    color { "#0ea5e9" }
    bookable { true }
  end
end
