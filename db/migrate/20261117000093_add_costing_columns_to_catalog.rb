class AddCostingColumnsToCatalog < ActiveRecord::Migration[8.0]
  def change
    # --- Products: valuation, tracking flags and purchasing defaults ---
    add_reference :products, :tax_code, foreign_key: true, type: :uuid
    add_reference :products, :default_supplier, foreign_key: { to_table: :suppliers }, type: :uuid
    add_column :products, :cost_cents, :bigint, null: false, default: 0
    add_column :products, :is_kit, :boolean, null: false, default: false
    add_column :products, :track_lot, :boolean, null: false, default: false
    add_column :products, :track_serial, :boolean, null: false, default: false
    add_column :products, :unit_of_measure, :string
    add_column :products, :commodity_code, :string
    add_column :products, :weight_grams, :integer, null: false, default: 0
    add_column :products, :volume_cm3, :integer, null: false, default: 0

    # --- Stock transactions: location, lot and unit cost for FIFO valuation ---
    add_reference :stock_transactions, :stock_lot, foreign_key: true, type: :uuid
    add_reference :stock_transactions, :stock_serial, foreign_key: true, type: :uuid
    add_reference :stock_transactions, :storage_location, foreign_key: true, type: :uuid
    add_column :stock_transactions, :unit_cost_cents, :bigint, null: false, default: 0

    # --- Goods receipts: link back to the purchase order they fulfil ---
    add_reference :stock_imports, :purchase, foreign_key: true, type: :uuid
    add_column :stock_imports, :received_at, :datetime
    add_column :stock_imports, :quality_status, :integer
    add_column :stock_imports, :landed_cost_total_cents, :bigint, null: false, default: 0
    add_index :stock_imports, [ :company_id, :received_at ]

    # --- Customers / suppliers: tax identity and default terms ---
    add_reference :customers, :payment_term, foreign_key: true, type: :uuid
    add_column :customers, :tax_id, :string
    add_column :customers, :vat_id, :string

    add_reference :suppliers, :payment_term, foreign_key: true, type: :uuid
    add_column :suppliers, :tax_id, :string
    add_column :suppliers, :lead_time_days, :integer, null: false, default: 0
  end
end
