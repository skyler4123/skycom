# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    initialize_with do
      Seed::UserService.new(system_role: :company_employee)
    end

    trait :company_owner do
      initialize_with do
        Seed::UserService.new(system_role: :company_owner)
      end
    end
  end
end
