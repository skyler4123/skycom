class CreateBillingTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_transactions, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :billing_invoice, null: false, foreign_key: true, type: :uuid
      t.references :billing_payment_method, null: false, foreign_key: true, type: :uuid

      t.integer :transaction_type, null: false
      t.integer :amount_cents, null: false
      t.integer :currency, null: false

      t.integer :balance_before_cents, null: false
      t.integer :balance_after_cents, null: false
      t.integer :promo_balance_before_cents, null: false
      t.integer :promo_balance_after_cents, null: false

      t.text :description

      t.integer :status, default: 0, null: false
      t.string :gateway_reference
      t.jsonb :metadata
      t.timestamps
    end

    add_index :billing_transactions, :gateway_reference, unique: true
    add_index :billing_transactions, :status
    add_index :billing_transactions, [ :company_id, :created_at ]
  end
end
