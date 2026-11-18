class CreateReorderRules < ActiveRecord::Migration[8.0]
  def change
    create_table :reorder_rules, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid

      # --- Thresholds ---
      t.integer :min_quantity, null: false, default: 0
      t.integer :max_quantity, null: false, default: 0
      t.integer :safety_stock, null: false, default: 0
      t.integer :lead_time_days, null: false, default: 0
      t.integer :auto_action, null: false, default: 2
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

    add_index :reorder_rules, [ :product_id, :warehouse_id ], unique: true
  end
end
