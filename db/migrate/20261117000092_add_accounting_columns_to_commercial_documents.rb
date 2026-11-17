class AddAccountingColumnsToCommercialDocuments < ActiveRecord::Migration[8.0]
  def change
    # --- Orders: one table serves quote → sales order → credit note → return ---
    add_reference :orders, :payment_term, foreign_key: true, type: :uuid
    add_reference :orders, :price_list, foreign_key: true, type: :uuid
    add_reference :orders, :channel_connection, foreign_key: true, type: :uuid
    add_column :orders, :document_type, :integer, null: false, default: 1
    add_column :orders, :total_cents, :bigint, null: false, default: 0
    add_column :orders, :tax_cents, :bigint, null: false, default: 0
    add_column :orders, :currency_rate, :decimal, precision: 18, scale: 10, default: "1.0"
    add_column :orders, :converted_at, :datetime
    add_column :orders, :external_order_number, :string
    add_index :orders, [ :company_id, :document_type ]

    # --- Purchases: requisition → RFQ → PO → blanket → bill → return ---
    add_reference :purchases, :payment_term, foreign_key: true, type: :uuid
    add_column :purchases, :document_type, :integer, null: false, default: 2
    add_column :purchases, :total_cents, :bigint, null: false, default: 0
    add_column :purchases, :currency_rate, :decimal, precision: 18, scale: 10, default: "1.0"
    add_column :purchases, :converted_at, :datetime
    add_column :purchases, :approved_at, :datetime
    add_column :purchases, :received_at, :datetime
    add_column :purchases, :billed_at, :datetime
    add_index :purchases, [ :company_id, :document_type ]

    # --- Invoices: terms, tax, FX, dunning and subscription billing links ---
    add_reference :invoices, :payment_term, foreign_key: true, type: :uuid
    add_reference :invoices, :billing_schedule, foreign_key: true, type: :uuid
    add_reference :invoices, :credited_invoice, foreign_key: { to_table: :invoices }, type: :uuid
    add_column :invoices, :total_cents, :bigint, null: false, default: 0
    add_column :invoices, :tax_cents, :bigint, null: false, default: 0
    add_column :invoices, :currency_rate, :decimal, precision: 18, scale: 10, default: "1.0"
    add_column :invoices, :paid_at, :datetime
    add_column :invoices, :dunning_level, :integer, null: false, default: 0
    add_column :invoices, :last_reminded_at, :datetime
    add_index :invoices, [ :company_id, :dunning_level ]
  end
end
