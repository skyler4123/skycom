class CreateIdentityProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :identity_providers, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, foreign_key: true, type: :uuid

      # --- Provider ---
      t.integer :provider_type, null: false, default: 0
      t.string  :name, null: false
      t.jsonb   :domains, default: []
      t.string  :client_id
      t.string  :client_secret
      t.string  :metadata_url
      t.boolean :is_enforced, null: false, default: false
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

    add_index :identity_providers, [ :company_id, :is_active ]
  end
end
