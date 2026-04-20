# spec/factories/companies.rb
FactoryBot.define do
  factory :company do
    user { create(:user, :company_owner) }

    initialize_with do
      Seed::CompanyService.create(user: user)
    end

    skip_create
  end
end
