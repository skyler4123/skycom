class CreateCalendarSyncConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_sync_connections, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # 'calcom' | 'google' | 'outlook' — see CALENDAR_SYNC_PROVIDERS.
      t.string   :provider, null: false
      t.integer  :status, null: false, default: 0
      t.string   :external_organization_id
      t.string   :base_url

      # Encrypted at rest (Active Record encryption). Holds the provider API key.
      t.jsonb    :credentials, default: {}

      t.datetime :last_synced_at
      t.text     :last_sync_error

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

    add_index :calendar_sync_connections, [ :company_id, :provider ], unique: true
  end
end
