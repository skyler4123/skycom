class CreatePages < ActiveRecord::Migration[8.0]
  def change
    create_table :pages, id: :uuid do |t|
      # --- Multi-Tenant Scope ---
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :branch,  null: false, foreign_key: true, type: :uuid

      # --- Identity ---
      t.string :email, null: true, index: { unique: true }
      t.string :name
      t.text   :description
      t.string :code, index: { unique: true }
      t.string :phone_number
      t.integer :currency_code
      t.integer :country_code
      t.string  :timezone

      # --- System Configurations (Enums) ---
      t.integer :business_type,      null: false, index: true
      t.integer :target_role,        null: false, index: true
      t.integer :target_resolution,  null: false, index: true
      t.integer :lifecycle_status,   null: false, index: true
      t.integer :workflow_status,    null: false, index: true

      # --- Core Engine Layout Configurations ---
      # This stores grid rules, component placements, hidden widgets, or feature flags
      t.jsonb :layout_manifest, null: false
      t.jsonb :metadata, null: false

      # --- Security and System Tracking ---
      t.string   :permission_resource_name, null: false
      t.datetime :expiration_date
      t.datetime :discarded_at, index: true
      t.timestamps
    end
    add_index :pages, [ :branch_id, :target_role, :target_resolution, :code ], unique: true
  end
end
