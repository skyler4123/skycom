class AddAmountCentsToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :amount_cents, :integer, null: false, default: 0
  end
end
