class CreateProductionOperations < ActiveRecord::Migration[8.0]
  def change
    create_table :production_operations, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :production_routing, null: false, foreign_key: true, type: :uuid
      t.references :work_center, foreign_key: true, type: :uuid

      # --- Step ---
      t.integer :position, null: false, default: 1
      t.string  :name, null: false
      t.integer :setup_minutes, null: false, default: 0
      t.decimal :run_minutes_per_unit, precision: 15, scale: 4, null: false, default: 0.0

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

    add_index :production_operations, [ :production_routing_id, :position ], unique: true
  end
end
