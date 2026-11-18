class CreateProductionOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :production_orders, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.references :bill_of_material, foreign_key: true, type: :uuid
      t.references :warehouse, null: false, foreign_key: true, type: :uuid

      # --- Order ---
      t.string   :code
      t.decimal  :quantity, precision: 15, scale: 4, null: false, default: 1.0
      t.integer  :status, null: false, default: 0
      t.integer  :priority, null: false, default: 1
      t.datetime :scheduled_start_at
      t.datetime :scheduled_end_at
      t.datetime :started_at
      t.datetime :completed_at
      t.text     :notes

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

    add_index :production_orders, [ :company_id, :status ]
    add_index :production_orders, [ :company_id, :scheduled_start_at ]
  end
end
