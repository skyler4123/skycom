class CreateStockLots < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_lots, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid
      t.references :supplier, foreign_key: true, type: :uuid

      # --- Lot ---
      t.string  :lot_code, null: false
      t.date    :received_on
      t.date    :expires_on
      t.integer :status, null: false, default: 0
      t.string  :notes

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

    add_index :stock_lots, [ :company_id, :product_id, :warehouse_id, :lot_code ], unique: true, name: "idx_stock_lots_unique"
    add_index :stock_lots, [ :company_id, :expires_on ]
  end
end
