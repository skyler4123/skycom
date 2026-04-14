# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    # We allow FactoryBot to handle the sequence, then pass it to the service
    sequence(:email) { |n| "test_user_#{n}_#{SecureRandom.hex(4)}@skycom.vn" }

    initialize_with do
      Seed::UserService.create(email: email)
    end

    skip_create # Service already called .create!
  end
end
