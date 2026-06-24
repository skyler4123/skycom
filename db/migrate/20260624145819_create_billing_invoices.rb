class CreateBillingInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_invoices, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :billing_contract, null: false, foreign_key: true, type: :uuid

      t.string   :invoice_number, null: false
      
      # money-rails format for the finalized invoice amount
      t.integer  :price_cents, default: 0, null: false
      t.string   :price_currency, default: "USD", null: false
      
      t.datetime :period_start, null: false
      t.datetime :period_end, null: false
      t.datetime :due_at

      t.integer  :payment_status, default: 0, index: true # enum: unpaid, paid, voided, overdue
      t.integer  :lifecycle_status, default: 0, index: true # enum: draft, final
      t.timestamps
    end

    add_index :billing_invoices, :invoice_number, unique: true
  end
end