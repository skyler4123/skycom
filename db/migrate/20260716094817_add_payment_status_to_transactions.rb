class AddPaymentStatusToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :payment_status, :integer, default: 0, null: false
  end
end
