class CreateCalendarProcedures < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_procedures, id: :uuid, default: -> { "uuidv7()" } do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :calendar_position, null: false, foreign_key: true, type: :uuid
      t.references :branch, null: true, foreign_key: true, type: :uuid

      # Polymorphic bridge into core ERP models (Service), or nil for a
      # calendar-only procedure. See Calendar::SourceLinkConcern::SOURCE_TYPES.
      t.string   :source_type
      t.uuid     :source_id

      t.string   :name, null: false
      t.string   :code
      t.string   :slug, null: false
      t.text     :description
      t.integer  :duration_minutes, null: false, default: 30
      t.integer  :buffer_before_minutes, null: false, default: 0
      t.integer  :buffer_after_minutes, null: false, default: 0
      t.integer  :min_lead_minutes, null: false, default: 0
      t.string   :color, null: false, default: "#6366f1"
      t.boolean  :requires_location, null: false, default: false
      t.boolean  :requires_equipment, null: false, default: false
      t.integer  :requires_practitioners, null: false, default: 1

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

    add_index :calendar_procedures, [ :company_id, :name ], unique: true
    add_index :calendar_procedures, [ :company_id, :slug ], unique: true
    add_index :calendar_procedures, [ :source_type, :source_id ]
    add_index :calendar_procedures, [ :external_provider, :external_id ]
  end
end
