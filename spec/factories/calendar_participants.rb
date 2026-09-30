# spec/factories/calendar_participants.rb
FactoryBot.define do
  factory :calendar_participant do
    company { association :company }

    sequence(:name) { |n| "#{Faker::Name.name} #{n}" }
    sequence(:code) { |n| "PT-#{SecureRandom.hex(3).upcase}#{n}" }
    email { Faker::Internet.email }
    phone_number { Faker::PhoneNumber.phone_number }
  end
end
