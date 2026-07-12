class AddBillingEnumsToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :billing_invoices, :movement_type, :integer
    add_column :billing_invoices, :target_balance, :integer
    add_column :billing_invoices, :created_by, :integer
    add_column :billing_invoices, :name, :string
    add_column :billing_invoices, :description, :text

    add_index :billing_invoices, :movement_type
    add_index :billing_invoices, :target_balance
    add_index :billing_invoices, :created_by

    change_column_null :billing_transactions, :billing_invoice_id, false
  end
end
