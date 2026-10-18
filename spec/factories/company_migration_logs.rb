FactoryBot.define do
  factory :company_migration_log do
    company_migration
    company { company_migration.company }
    record { create(:customer, company: company) }
    action { :created }
  end
end
