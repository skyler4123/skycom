class CreateProductionOrderOperations < ActiveRecord::Migration[8.0]
  def change
    create_table :production_order_operations, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :production_order, null: false, foreign_key: true, type: :uuid
      t.references :production_operation, null: false, foreign_key: true, type: :uuid
      t.references :work_center, foreign_key: true, type: :uuid
      t.references :employee, foreign_key: true, type: :uuid

      # --- Execution ---
      t.integer  :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.integer  :logged_minutes, null: false, default: 0
      t.decimal  :produced_quantity, precision: 15, scale: 4, null: false, default: 0.0

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

    add_index :production_order_operations, [ :production_order_id, :production_operation_id ], unique: true, name: "idx_production_order_operations_unique"
    add_index :production_order_operations, [ :work_center_id, :status ]
  end
end
