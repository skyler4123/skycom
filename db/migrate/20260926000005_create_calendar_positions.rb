class CreateCalendarPositions < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_positions, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid

      t.string   :name, null: false
      t.string   :code
      t.text     :description
      t.string   :color, null: false, default: "#6366f1"
      t.integer  :default_duration_minutes, null: false, default: 30
      t.integer  :sort_order, null: false, default: 0

      # --- External Sync (future Cal.com / Google / Outlook) ---
      t.string   :external_provider
      t.string   :external_id
      t.string   :external_etag
      t.integer  :sync_status, null: false, default: 0
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

    add_index :calendar_positions, [ :company_id, :name ], unique: true
    add_index :calendar_positions, [ :external_provider, :external_id ]
  end
end
