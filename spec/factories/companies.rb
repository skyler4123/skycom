# spec/factories/companies.rb
FactoryBot.define do
  factory :company do
    user { create(:user, :company_owner) }

    initialize_with do
      Seed::CompanyService.new(user: user)
    end

    trait :with_main_balance do
      after(:create) { |c| c.update!(main_balance_cents: 10_000) }
    end

    trait :with_promo_balance do
      after(:create) { |c| c.update!(promo_balance_cents: 10_000) }
    end
  end
end
