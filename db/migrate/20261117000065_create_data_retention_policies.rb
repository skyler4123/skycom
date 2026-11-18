class CreateDataRetentionPolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :data_retention_policies, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Rule ---
      t.string  :resource_name, null: false
      t.integer :retention_days, null: false, default: 365
      t.integer :action, null: false, default: 0
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

    add_index :data_retention_policies, [ :company_id, :resource_name ], unique: true
  end
end
