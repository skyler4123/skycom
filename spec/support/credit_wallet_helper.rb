# frozen_string_literal: true

# Reusable wallet seeder for credit-deduction tests.
# See docs/CREDIT_DEDUCTION.md §7 — all deduction tests must seed via this helper.
module RandomizedWalletHelper
  # Clears the signup promo baseline, then seeds promo + main with random
  # integers so 1-3 deducts (cost 2 each) do not go negative. Returns a snapshot
  # for relative assertions.
  #
  # Why dual-both: validates promo-first priority
  # (CompanyCreditDeduction::BaseService drains promo → main) and ensures both
  # balances are exercised in one run.
  def seed_random_wallet!(company, promo_range: 200..500, main_range: 200..500)
    promo_start = rand(promo_range)
    main_start = rand(main_range)

    wallet = company.company_wallet
    wallet.update_columns(main_credit_balance: 0, promo_credit_balance: 0)
    wallet.add_to!(balance: :promo, amount: promo_start)
    wallet.add_to!(balance: :main, amount: main_start)

    { promo_start: promo_start, main_start: main_start }
  end
end

RSpec.configure do |config|
  config.include RandomizedWalletHelper
end
