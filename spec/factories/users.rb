# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test_user_#{n}_#{SecureRandom.hex(4)}@skycom.vn" }
    sequence(:username) { |n| "user#{n}" }

    initialize_with do
      Seed::UserService.new(email: email, username: username, system_role: :company_employee)
    end


    trait :company_owner do
      initialize_with do
        Seed::UserService.new(email: email, username: username, system_role: :company_owner)
      end
    end
  end
end
