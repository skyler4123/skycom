class CreateCompanyEntitlements < ActiveRecord::Migration[8.0]
  def change
    create_table :company_entitlements, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Entitlement ---
      t.string  :feature_key, null: false
      t.boolean :is_enabled, null: false, default: true
      t.integer :limit_value
      t.datetime :expires_at

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

    add_index :company_entitlements, [ :company_id, :feature_key ], unique: true
  end
end
