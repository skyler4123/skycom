FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user_#{n}@example.com" }
    password { "Password@1234" }
    password_confirmation { "Password@1234" }
    verified { true }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    username { Faker::Internet.username(specifier: 5..12) }
    phone_number { Faker::PhoneNumber.cell_phone }
  end
end