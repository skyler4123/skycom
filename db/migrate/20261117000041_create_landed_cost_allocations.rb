class CreateLandedCostAllocations < ActiveRecord::Migration[8.0]
  def change
    create_table :landed_cost_allocations, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :landed_cost_charge, null: false, foreign_key: true, type: :uuid
      t.references :stock, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid

      # --- Share ---
      t.decimal :quantity, precision: 15, scale: 4, null: false, default: 0.0
      t.bigint  :allocated_cents, null: false, default: 0

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

    add_index :landed_cost_allocations, [ :landed_cost_charge_id, :stock_id ], unique: true, name: "idx_landed_cost_allocations_unique"
  end
end
