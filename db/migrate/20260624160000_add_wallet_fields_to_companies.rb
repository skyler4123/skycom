class AddWalletFieldsToCompanies < ActiveRecord::Migration[8.0]
  def change
    change_table :companies do |t|
      t.integer :promo_balance_cents, default: 0, null: false
      t.integer :main_balance_cents, default: 0, null: false
      t.integer :soft_debt_threshold_cents, default: -10000, null: false
    end
  end
end
