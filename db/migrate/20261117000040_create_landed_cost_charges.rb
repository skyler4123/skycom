class CreateLandedCostCharges < ActiveRecord::Migration[8.0]
  def change
    create_table :landed_cost_charges, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :stock_import, null: false, foreign_key: true, type: :uuid
      t.references :supplier, foreign_key: true, type: :uuid

      # --- Charge ---
      t.integer :charge_type, null: false, default: 0
      t.bigint  :amount_cents, null: false, default: 0
      t.integer :currency, default: 840
      t.integer :allocation_method, null: false, default: 1
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

    add_index :landed_cost_charges, [ :stock_import_id, :charge_type ]
  end
end
