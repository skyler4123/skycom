# frozen_string_literal: true

# Reusable wallet seeder for credit-deduction tests.
# See docs/CREDIT_DEDUCTION.md §7 — all deduction tests must seed via this helper.
module RandomizedWalletHelper
  # Seeds promo + main with large random integers so 1-3 deducts (cost 2 each,
  # CREDIT_USAGE_RATES[:access_dashboard] in config/initializers/constants.rb)
  # never hit the debt path. Returns snapshot for relative assertions.
  #
  # Why dual-both: validates promo-first priority (CompanyCreditDeduction::BaseService
  # drains promo → main → debt, app/services/company_credit_deduction/base_service.rb:65)
  # and ensures both balances are exercised in one run.
  def seed_random_wallet!(company, promo_range: 200..500, main_range: 200..500)
    promo_start = rand(promo_range)
    main_start = rand(main_range)

    company.company_wallet.add_to!(balance: :promo, amount: promo_start) # app/models/company_wallet.rb:47
    company.company_wallet.add_to!(balance: :main, amount: main_start)

    { promo_start: promo_start, main_start: main_start, debt_start: 0 }
  end
end

RSpec.configure do |config|
  config.include RandomizedWalletHelper
end
