class CreateStorageLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :storage_locations, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid
      t.references :parent, foreign_key: { to_table: :storage_locations }, type: :uuid

      # --- Location ---
      t.string  :code, null: false
      t.string  :name
      t.integer :location_type, null: false, default: 3
      t.integer :pick_sequence, null: false, default: 0
      t.boolean :is_pickable, null: false, default: true
      t.boolean :is_active, null: false, default: true

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

    add_index :storage_locations, [ :warehouse_id, :code ], unique: true
    add_index :storage_locations, [ :warehouse_id, :pick_sequence ]

    add_foreign_key :stock_transactions, :storage_locations, column: :storage_location_id
  end
end
