class CreateStockSerials < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_serials, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :stock, null: false, foreign_key: true, type: :uuid
      t.references :stock_lot, foreign_key: true, type: :uuid
      t.references :storage_location, foreign_key: true, type: :uuid
      t.references :sold_order, foreign_key: { to_table: :orders }, type: :uuid

      # --- Unit ---
      t.string   :serial_number, null: false
      t.integer  :status, null: false, default: 0
      t.datetime :received_at
      t.datetime :sold_at
      t.date     :warranty_until

      # --- System Fields ---
      t.integer  :lifecycle_status, index: true
      t.integer  :workflow_status, index: true
      t.integer  :business_type, index: true
      t.datetime :expiration_date
      t.jsonb    :metadata, default: {}
      t.datetime :discarded_at, index: true
      t.string   :permission_resource_name

      t.timestamps
    end

    add_index :stock_serials, [ :company_id, :serial_number ], unique: true
    add_index :stock_serials, [ :company_id, :status ]

    add_foreign_key :stock_transactions, :stock_serials, column: :stock_serial_id
  end
end
