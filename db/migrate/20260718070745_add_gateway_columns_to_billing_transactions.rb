class AddGatewayColumnsToBillingTransactions < ActiveRecord::Migration[8.0]
  def change
    change_table :billing_transactions, bulk: true do |t|
      t.integer :status, default: 0, null: false
      t.string :gateway_reference
      t.jsonb :gateway_payload, default: {}
    end

    add_index :billing_transactions, :gateway_reference, unique: true
    add_index :billing_transactions, :status
  end
end
