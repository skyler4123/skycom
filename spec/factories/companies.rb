# spec/factories/companies.rb
FactoryBot.define do
  factory :company do
    user { create(:user, :company_owner) }

    initialize_with do
      Seed::CompanyService.new(user: user)
    end
  end
end
