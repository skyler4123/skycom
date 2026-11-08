class CreateOperations < ActiveRecord::Migration[8.0]
  def change
    create_table :operations, id: :uuid do |t|
      # --- Multi-Tenant Scope ---
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :email, null: true, index: { unique: true }
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.string :phone_number
      t.integer :currency
      t.integer :country
      t.integer :timezone

      # --- Purpose ---
      t.integer :operation_type, null: false
      t.integer :resolution

      # --- System Configurations (Enums) ---
      t.string :external_id, index: true
      t.integer :lifecycle_status,   null: false, index: true
      t.integer :workflow_status,    null: false, index: true

      # --- Core Engine Layout Configurations ---
      # This stores grid rules, component placements, hidden widgets, or feature flags
      t.jsonb :metadata, null: false

      # --- Security and System Tracking ---
      t.string   :permission_resource_name, null: false
      t.datetime :expiration_date
      t.datetime :discarded_at, index: true
      t.timestamps
    end
    add_index :operations, [ :company_id, :operation_type ], unique: true,
      name: "index_operations_on_company_id_and_operation_type"
  end
end
