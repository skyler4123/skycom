class CreateWalletTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :wallet_transactions, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :billing_invoice, null: true, foreign_key: true, type: :uuid

      t.integer :transaction_type, null: false
      t.integer :amount_cents, default: 0, null: false
      t.string  :currency, default: "USD", null: false

      t.integer :balance_before_cents, default: 0, null: false
      t.integer :balance_after_cents, default: 0, null: false
      t.integer :promo_balance_before_cents, default: 0, null: false
      t.integer :promo_balance_after_cents, default: 0, null: false

      t.text :description

      t.timestamps
    end

    add_index :wallet_transactions, [ :company_id, :created_at ], name: "idx_wallet_tx_company_chrono"
  end
end
