class AddPaymentStatusToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :payment_status, :integer, null: false, default: 0
  end
end
