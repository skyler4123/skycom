# spec/factories/calendar_positions.rb
FactoryBot.define do
  factory :calendar_position do
    association :company

    sequence(:name) { |n| "#{Faker::Job.field} #{n}" }
    sequence(:code) { |n| "POS-#{SecureRandom.hex(3).upcase}#{n}" }
    description { Faker::Company.catch_phrase }
    color { "#6366f1" }
    default_duration_minutes { 30 }
    sort_order { 0 }
  end
end
