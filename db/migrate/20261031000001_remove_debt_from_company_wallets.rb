# frozen_string_literal: true

# Removes the abandoned debt balance concept. Credit deduction now allows a
# negative main balance instead of moving the shortfall into a separate debt
# column. The app is pre-release, so old debt audit rows are discarded rather
# than preserved.
class RemoveDebtFromCompanyWallets < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM company_wallet_logs WHERE balance_type = 2"
    remove_column :company_wallets, :debt_credit_balance, :bigint, default: 0, null: false
  end

  def down
    add_column :company_wallets, :debt_credit_balance, :bigint, default: 0, null: false
  end
end
