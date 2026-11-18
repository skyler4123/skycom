class CreateStockCountLines < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_count_lines, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :stock_count, null: false, foreign_key: true, type: :uuid
      t.references :stock, null: false, foreign_key: true, type: :uuid
      t.references :storage_location, foreign_key: true, type: :uuid

      # --- Counted ---
      t.integer :expected_quantity, null: false, default: 0
      t.integer :counted_quantity
      t.integer :variance_quantity, null: false, default: 0
      t.text    :notes

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

    add_index :stock_count_lines, [ :stock_count_id, :stock_id ], unique: true
  end
end
