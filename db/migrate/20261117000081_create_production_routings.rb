class CreateProductionRoutings < ActiveRecord::Migration[8.0]
  def change
    create_table :production_routings, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :bill_of_material, null: false, foreign_key: true, type: :uuid

      # --- Routing ---
      t.string  :name
      t.string  :version, null: false, default: "1"
      t.integer :status, null: false, default: 0

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

    add_index :production_routings, [ :company_id, :bill_of_material_id, :version ], unique: true, name: "idx_routing_version_unique"
  end
end
