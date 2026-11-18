class CreateChannelConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :channel_connections, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      # --- Connection ---
      t.integer :channel, null: false, default: 0
      t.string  :name, null: false
      t.jsonb   :credentials, default: {}
      t.integer :status, null: false, default: 0
      t.datetime :last_synced_at
      t.datetime :connected_at

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

    add_index :channel_connections, [ :company_id, :channel ]

    add_foreign_key :orders, :channel_connections, column: :channel_connection_id
  end
end
