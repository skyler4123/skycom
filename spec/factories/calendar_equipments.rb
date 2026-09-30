# spec/factories/calendar_equipments.rb
FactoryBot.define do
  factory :calendar_equipment do
    company { association :company }

    sequence(:name) { |n| "Machine #{Faker::Device.model_name} #{n}" }
    sequence(:code) { |n| "EQP-#{SecureRandom.hex(3).upcase}#{n}" }
    description { Faker::Lorem.sentence }
    quantity { 1 }
    color { "#f59e0b" }
    bookable { true }
  end
end
