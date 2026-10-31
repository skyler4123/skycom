# spec/factories/companies.rb
FactoryBot.define do
  factory :company do
    user { create(:user, :company_owner) }

    initialize_with do
      Seed::CompanyService.new(user: user)
    end

    # Credit-focused specs need a deterministic empty wallet. This bypasses
    # balance mutations so it does not create wallet/usage log rows.
    trait :without_signup_promo do
      after(:create) do |company|
        company.company_wallet.update_columns(main_credit_balance: 0, promo_credit_balance: 0)
        company.update_columns(workflow_status: Company.workflow_statuses[:suspend])
        Rails.ram_cache.delete(CacheKeyService.company_suspended(company.id))
      end
    end
  end
end
