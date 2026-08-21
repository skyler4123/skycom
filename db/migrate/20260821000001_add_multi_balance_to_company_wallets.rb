# frozen_string_literal: true

# Multi-balance credit wallet: main (top-up), promo (credits), debt (absorbed shortfall).
# company_wallet_logs gains balance_type so each audit row records which balance moved.
class AddMultiBalanceToCompanyWallets < ActiveRecord::Migration[8.0]
  def change
    rename_column :company_wallets, :credit_balance, :main_credit_balance
    add_column :company_wallets, :promo_credit_balance, :bigint, null: false, default: 0
    add_column :company_wallets, :debt_credit_balance, :bigint, null: false, default: 0

    add_column :company_wallet_logs, :balance_type, :integer
  end
end
