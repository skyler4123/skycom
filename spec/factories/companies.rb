# spec/factories/companies.rb
FactoryBot.define do
  factory :company do
    association :user # Automatically triggers Seed::UserService via the factory above

    initialize_with do
      Seed::CompanyService.create(user: user)
    end

    skip_create
  end
end
