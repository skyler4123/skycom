class CreateChannelSyncLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :channel_sync_logs, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :channel_connection, null: false, foreign_key: true, type: :uuid

      # --- Attempt ---
      t.integer  :direction, null: false, default: 0
      t.string   :resource
      t.integer  :status, null: false, default: 0
      t.jsonb    :payload, default: {}
      t.text     :error_message
      t.datetime :started_at
      t.datetime :finished_at
      t.integer  :record_count, default: 0

      t.timestamps
    end

    add_index :channel_sync_logs, [ :channel_connection_id, :created_at ]
  end
end
