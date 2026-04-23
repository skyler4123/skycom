# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test_user_#{n}_#{SecureRandom.hex(4)}@skycom.vn" }

    initialize_with do
      Seed::UserService.new(email: email, system_role: :company_employee)
    end


    trait :company_owner do
      initialize_with do
        Seed::UserService.new(email: email, system_role: :company_owner)
      end
    end
  end
end
